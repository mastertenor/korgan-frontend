// ignore_for_file: avoid_web_libraries_in_flutter
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

import 'package:web/web.dart' as web;
import 'dart:js_interop';
import 'dart:convert';

import '../../../../../../utils/app_logger.dart';
import '../../../../../../utils/platform_view_registry.dart';
import '../../../../domain/entities/mail_detail.dart';
import 'mail_renderer.dart';

/// Web-specific HTML content renderer for mail
/// Handles iframe creation, postMessage communication, and scrolling
class MailWebRenderer implements MailRenderer {
  @override
  final ScrollController scrollController;
  
  @override
  final ValueChanged<double>? onHeightChanged;

  // Web-specific state
  final Set<String> _registeredViewTypes = {};
  double _iframeHeight = 400;

  // Scroll accumulation for smooth scrolling
  double _accumulatedDeltaY = 0.0;
  bool _applyScheduled = false;

  MailWebRenderer({
    required this.scrollController,
    this.onHeightChanged,
  });

  @override
  void initialize() {
    if (kIsWeb) {
      _setupPostMessageListener();
    }
  }

  @override
  void dispose() {
    // Cleanup if needed
  }

  @override
  double get iframeHeight => _iframeHeight;

  // PostMessage listener - iframe'den height bilgisi almak için
  void _setupPostMessageListener() {
    if (!kIsWeb) return;

    web.window.addEventListener('message', (web.Event event) {
      final messageEvent = event as web.MessageEvent;
      final rawData = messageEvent.data;
      if (rawData == null) return;

      String s;
      if (rawData.isA<JSString>()) {
        s = (rawData as JSString).toDart;
      } else {
        s = rawData.toString();
      }
      if (s.isEmpty || !s.trimLeft().startsWith('{')) return;

      try {
        final decoded = jsonDecode(s);

        // 🔁 iframe → Flutter: wheel delta
        if (decoded is Map && decoded['type'] == 'scrollFromIframe') {
          final deltaY = (decoded['deltaY'] as num?)?.toDouble() ?? 0.0;

          // 1) Delta'yı biriktir
          _accumulatedDeltaY += deltaY;

          // 2) Controller hazırsa bu frame için tek uygulama planla
          if (scrollController.hasClients) {
            _scheduleApplyAccumulatedScroll();
          }
        }

        // 📏 iframe → Flutter: yükseklik güncellemesi
        if (decoded is Map && decoded['type'] == 'iframeHeight') {
          final newH = double.tryParse(decoded['height'].toString()) ?? 400;
          if (_iframeHeight != newH) {
            _iframeHeight = newH;
            onHeightChanged?.call(_iframeHeight);
            AppLogger.info('🔧 iframe height set to: $_iframeHeight');
          }
        }
      } catch (e, st) {
        AppLogger.info('❌ PostMessage parse error: $e\n$st');
      }
    }.toJS);
  }

  /// Schedule accumulated scroll application
  void _scheduleApplyAccumulatedScroll() {
    if (_applyScheduled) return;
    _applyScheduled = true;

    // Bir frame planla ve frame sonunda uygula
    SchedulerBinding.instance.scheduleFrame();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _applyScheduled = false;

      if (!scrollController.hasClients) return;

      final pos = scrollController.position;
      final ready = pos.hasContentDimensions && pos.maxScrollExtent >= 0;
      if (!ready) {
        AppLogger.info('⚠️ applyAccumulatedScroll skipped: position not ready');
        return;
      }

      final dy = _accumulatedDeltaY;
      _accumulatedDeltaY = 0.0;

      try {
        if (pos is ScrollPositionWithSingleContext) {
          pos.pointerScroll(dy); // animasyonsuz & güvenli
        } else {
          final newOffset = (pos.pixels + dy).clamp(0.0, pos.maxScrollExtent);
          scrollController.jumpTo(newOffset); // fallback
        }
      } catch (e, st) {
        AppLogger.info('⚠️ applyAccumulatedScroll suppressed: $e\n$st');
      }
    });
  }

  /// Build mail content widget with HTML rendering
  Widget buildMailContent(BuildContext context, MailDetail mailDetail) {
    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mail header info
          _buildMailHeader(mailDetail),
                   
          // Rendered HTML content
          _buildRenderedHtmlSection(mailDetail),
          
          // Attachments section
          _buildAttachmentsSection(mailDetail),
          
          // Extra bottom padding
          //const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildMailHeader(MailDetail mailDetail) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subject
          Text(
            mailDetail.subject,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          // From section
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 70,
                child: Text(
                  'Gönderen',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mailDetail.senderName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      mailDetail.senderEmail,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Date
          Row(
            children: [
              Icon(
                Icons.schedule,
                size: 16,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 8),
              Text(
                mailDetail.formattedReceivedDate,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // buildRenderedHtmlSection - Web için iframe kullanımı (stabil version with fixed registry)
  Widget _buildRenderedHtmlSection(MailDetail mailDetail) {
    // Web check - sadece web'de çalışsın
    if (!kIsWeb) {
      return _buildFallbackContent(mailDetail);
    }

    // HTML content hazırla
    final htmlContent = mailDetail.htmlContent.isNotEmpty 
        ? mailDetail.htmlContent 
        : _convertTextToHtml(mailDetail.textContent);

    // Unique view ID oluştur - hash ile unique yap
    final contentHash = htmlContent.hashCode.abs();
    final viewId = 'mail-iframe-$contentHash';
    
    // ViewType daha önce register edilmiş mi kontrol et
    if (!_registeredViewTypes.contains(viewId)) {
      // Platform-safe registration using our utility
      PlatformViewRegistry.registerViewFactory(
        viewId,
        (int viewId) => _createIframe(htmlContent),
      );
      _registeredViewTypes.add(viewId);
      AppLogger.info('📝 Registered new viewType: $viewId');
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      height: _iframeHeight,
      child: HtmlElementView(viewType: viewId),
    );
  }

  Widget _buildAttachmentsSection(MailDetail mailDetail) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ],
      ),
    );
  }

  /// Create iframe element - temiz ve stabil
  web.HTMLIFrameElement _createIframe(String htmlContent) {
    final iframeHtml = _buildIframeHtml(htmlContent);
    
    final iframe = web.HTMLIFrameElement()
      ..srcdoc = iframeHtml.toJS
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.overflow = 'auto';

    return iframe;
  }

  /// Web olmayan platformlar için fallback
  Widget _buildFallbackContent(MailDetail mailDetail) {
    final textContent = mailDetail.textContent.isNotEmpty 
        ? mailDetail.textContent 
        : _stripHtmlTags(mailDetail.htmlContent);
        
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SelectableText(
        textContent,
        style: const TextStyle(
          fontSize: 14,
          height: 1.5,
          color: Colors.black87,
        ),
      ),
    );
  }

  /// HTML to Text converter - fallback için
  String _stripHtmlTags(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll(RegExp(r'&nbsp;'), ' ')
        .replaceAll(RegExp(r'&amp;'), '&')
        .replaceAll(RegExp(r'&lt;'), '<')
        .replaceAll(RegExp(r'&gt;'), '>')
        .replaceAll(RegExp(r'&quot;'), '"')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Iframe için HTML oluştur - dynamic height ile postMessage
  String _buildIframeHtml(String content) {
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <!-- Tüm linkler yeni sekmede -->
  <base target="_blank">
  <!-- Tarayıcıya yalnızca light şema kullandığımızı bildir -->
  <meta name="color-scheme" content="light">
  <style>
    :root { color-scheme: light; } /* Form kontrolleri/scrollbar için de light */

    html, body {
      margin: 0;
      padding: 16px;
      font-family: system-ui, -apple-system, "Segoe UI", Roboto, Arial, sans-serif;
      font-size: 14px;
      line-height: 1.5;
      color: #333 !important;          /* Dark mode devralımını kır */
      background: #ffffff !important;  /* Gmail'deki gibi beyaz zemin */
      /* iframe içinde dikey kapalı, yatay açık */
      overflow-x: auto !important;
      overflow-y: hidden !important;
      min-width: fit-content;
    }

    /* Tarayıcı dark mode'a geçse bile görünümü sabitle */
    @media (prefers-color-scheme: dark) {
      html, body {
        color: #333 !important;
        background: #ffffff !important;
      }
    }
  </style>
</head>
<body>
  $content

  <script>
    // ---- Boy yükseklik raporlama (debounced)
    let lastReportedHeight = 0;
    let heightTimer = null;

    function measureHeight() {
      const bodyH = document.body.scrollHeight;
      const docH  = document.documentElement.scrollHeight;
      return Math.min(bodyH, docH) + 32; // az bir padding
    }

    function reportHeightDebounced() {
      clearTimeout(heightTimer);
      heightTimer = setTimeout(() => {
        const h = measureHeight();
        if (h !== lastReportedHeight) {
          lastReportedHeight = h;
          parent?.postMessage(JSON.stringify({ type: 'iframeHeight', height: h }), '*');
        }
      }, 50);
    }

    window.addEventListener('load', reportHeightDebounced);
    window.addEventListener('resize', reportHeightDebounced);
    setTimeout(reportHeightDebounced, 100);
    setTimeout(reportHeightDebounced, 500);
    setTimeout(reportHeightDebounced, 1000);

    new MutationObserver(reportHeightDebounced).observe(document.documentElement, {
      childList: true, subtree: true, attributes: true, characterData: true
    });

    document.querySelectorAll('img').forEach(img => {
      if (img.complete) reportHeightDebounced();
      else img.addEventListener('load', reportHeightDebounced);
    });

    // ---- Dikey tekeri parent'a pasla; yatay iframe'de kalsın
    window.addEventListener('wheel', function (e) {
      if (Math.abs(e.deltaY) > Math.abs(e.deltaX)) {
        e.preventDefault();
        parent?.postMessage(JSON.stringify({ type: 'scrollFromIframe', deltaY: e.deltaY }), '*');
      }
    }, { passive: false });

    // (Opsiyonel) Flutter -> iframe scroll senkronu
    window.addEventListener('message', function (event) {
      try {
        const msg = JSON.parse(event.data);
        if (msg?.type === 'scrollFromFlutter') {
          const offset = msg.scrollOffset || 0;
          window.scrollTo(0, offset);
        }
      } catch {}
    });
  </script>
</body>
</html>
''';
  }

  /// Text to HTML converter
  String _convertTextToHtml(String text) {
    return text.replaceAll('\n', '<br>');
  }
}