// lib/src/features/mail/presentation/widgets/web/preview/mail_renderer_web.dart

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
import '../../../../domain/repositories/mail_repository.dart';
import '../../../utils/cid_resolver.dart';
import 'mail_renderer.dart';

/// Web-specific HTML content renderer for mail
/// Handles iframe creation, postMessage communication, and scrolling
class MailWebRenderer implements MailRenderer {
  @override
  final ScrollController scrollController;

  @override
  final ValueChanged<double>? onHeightChanged;

  // Dependency injection for CID resolution
  final MailRepository repository;
  final String userEmail;

  // Web-specific state
  final Set<String> _registeredViewTypes = {};
  double _iframeHeight = 400;

  // Scroll accumulation for smooth scrolling
  double _accumulatedDeltaY = 0.0;
  bool _applyScheduled = false;

  // 🆕 Cache: prevent double CID resolution
  Future<String>? _cachedFuture;
  String? _cachedMailId;

  MailWebRenderer({
    required this.scrollController,
    required this.repository,
    required this.userEmail,
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

  // PostMessage listener - iframe’den height bilgisi almak için
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

        // iframe → Flutter: wheel delta
        if (decoded is Map && decoded['type'] == 'scrollFromIframe') {
          final deltaY = (decoded['deltaY'] as num?)?.toDouble() ?? 0.0;

          _accumulatedDeltaY += deltaY;

          if (scrollController.hasClients) {
            _scheduleApplyAccumulatedScroll();
          }
        }

        // iframe → Flutter: yükseklik güncellemesi
        if (decoded is Map && decoded['type'] == 'iframeHeight') {
          final newH = double.tryParse(decoded['height'].toString()) ?? 400;
          if (_iframeHeight != newH) {
            _iframeHeight = newH;
            // 🆕 sadece gerçekten farklıysa callback çağır
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
          pos.pointerScroll(dy);
        } else {
          final newOffset =
              (pos.pixels + dy).clamp(0.0, pos.maxScrollExtent);
          scrollController.jumpTo(newOffset);
        }
      } catch (e, st) {
        AppLogger.info('⚠️ applyAccumulatedScroll suppressed: $e\n$st');
      }
    });
  }

  /// Build HTML content section - now with caching
  Widget buildRenderedHtmlSection(MailDetail mailDetail) {
    if (!kIsWeb) {
      return _buildFallbackContent(mailDetail);
    }

    print('📧 MailWebRenderer: Building HTML section for mail ${mailDetail.id}');

    // 🆕 Eğer mail değiştiyse future’u sıfırla
    if (_cachedMailId != mailDetail.id) {
      _cachedMailId = mailDetail.id;
      _cachedFuture = _resolveHtmlContent(mailDetail);
    }

    return FutureBuilder<String>(
      future: _cachedFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(height: _iframeHeight);
        }

        if (snapshot.hasError) {
          print('❌ HTML resolution error: ${snapshot.error}');
          return _buildIframeWithHtml(mailDetail.hasHtmlContent
              ? mailDetail.htmlContent
              : _convertTextToHtml(mailDetail.textContent));
        }

        final resolvedHtml = snapshot.data ?? '';
        print('✅ HTML resolution complete, building iframe');

        return _buildIframeWithHtml(resolvedHtml);
      },
    );
  }

  /// Resolve HTML content with CID processing
  Future<String> _resolveHtmlContent(MailDetail mailDetail) async {
    print('📧 Starting HTML content resolution');

    String htmlContent = mailDetail.hasHtmlContent
        ? mailDetail.htmlContent
        : _convertTextToHtml(mailDetail.textContent);

    print('📧 Original HTML length: ${htmlContent.length}');

    if (CidResolver.containsCidReferences(htmlContent)) {
      print('🔧 Found CID references, resolving...');

      final analysis = CidResolver.analyzeCids(htmlContent, mailDetail);
      print('📊 CID Analysis: $analysis');

      htmlContent = await CidResolver.resolveCidsInHtml(
        htmlContent,
        mailDetail,
        userEmail,
        repository,
      );
      print('✅ CID resolution complete, new HTML length: ${htmlContent.length}');
    } else {
      print('ℹ️ No CID references found in HTML');
    }

    return htmlContent;
  }

  /// Build iframe with resolved HTML
  Widget _buildIframeWithHtml(String htmlContent) {
    final contentHash = htmlContent.hashCode.abs();
    final viewId = 'mail-iframe-$contentHash';

    if (!_registeredViewTypes.contains(viewId)) {
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

  /// Create iframe element
  web.HTMLIFrameElement _createIframe(String htmlContent) {
    final iframeHtml = _buildIframeHtml(htmlContent);

    final iframe = web.HTMLIFrameElement()
      ..srcdoc = iframeHtml.toJS
      ..className = 'korgan-preview-iframe'
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

  /// Iframe için HTML oluştur
  String _buildIframeHtml(String content) {
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <base target="_blank">
  <meta name="color-scheme" content="light">
  <style>
    :root { color-scheme: light; }
    html, body {
      margin: 0;
      padding: 16px;
      font-family: system-ui, -apple-system, "Segoe UI", Roboto, Arial, sans-serif;
      font-size: 14px;
      line-height: 1.5;
      color: #333 !important;
      background: #ffffff !important;
      overflow-x: auto !important;
      overflow-y: hidden !important;
      min-width: fit-content;
    }
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
    let lastReportedHeight = 0;
    let heightTimer = null;
    function measureHeight() {
      const bodyH = document.body.scrollHeight;
      const docH  = document.documentElement.scrollHeight;
      return Math.min(bodyH, docH) + 32;
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
    window.addEventListener('wheel', function (e) {
      if (Math.abs(e.deltaY) > Math.abs(e.deltaX)) {
        e.preventDefault();
        parent?.postMessage(JSON.stringify({ type: 'scrollFromIframe', deltaY: e.deltaY }), '*');
      }
    }, { passive: false });
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

  String _convertTextToHtml(String text) {
    return text.replaceAll('\n', '<br>');
  }
}
