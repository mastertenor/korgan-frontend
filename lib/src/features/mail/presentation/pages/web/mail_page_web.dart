// lib/src/features/mail/presentation/pages/web/mail_page_web.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter/foundation.dart';

import 'package:web/web.dart' as web;
import 'dart:js_interop';
import 'dart:convert';

import '../../../../../utils/app_logger.dart';
import '../../../../../utils/platform_view_registry.dart'; // Updated import
import '../../../domain/entities/mail.dart';
import '../../../domain/entities/mail_detail.dart';
import '../../providers/mail_providers.dart';
import '../../providers/mail_provider.dart';

import 'package:flutter/scheduler.dart';


/// Web-optimized mail page - SADECE Provider Integration ve Mail Listesi
class MailPageWeb extends ConsumerStatefulWidget {
  final String userEmail;

  const MailPageWeb({super.key, required this.userEmail});

  @override
  ConsumerState<MailPageWeb> createState() => _MailPageWebState();
}

class _MailPageWebState extends ConsumerState<MailPageWeb> {
  // Web-specific state
  String? _selectedMailId;
  final Set<String> _selectedMails = {};
  bool _isPreviewPanelVisible = true;
  
  // ScrollController
  final ScrollController _scrollController = ScrollController();

  // 👇 Yeni alanlar
  double _accumulatedDeltaY = 0.0;
  bool _applyScheduled = false;

  // 👇 Yardımcı metot: sınıfın İÇİNDE, fakat herhangi bir metodun DIŞINDA
  void _scheduleApplyAccumulatedScroll() {
    if (_applyScheduled) return;
    _applyScheduled = true;

    // Bir frame planla ve frame sonunda uygula
    SchedulerBinding.instance.scheduleFrame();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _applyScheduled = false;

      if (!mounted || !_scrollController.hasClients) return;

      final pos = _scrollController.position;
      final ready = pos.hasContentDimensions &&
                    pos.maxScrollExtent >= 0;
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
          final newOffset =
              (pos.pixels + dy).clamp(0.0, pos.maxScrollExtent);
          _scrollController.jumpTo(newOffset); // fallback
        }
      } catch (e, st) {
        AppLogger.info('⚠️ applyAccumulatedScroll suppressed: $e\n$st');
      }
    });
  }
  
  // Iframe management
  final Set<String> _registeredViewTypes = {}; // ViewType cache'i
  double _iframeHeight = 400; // Dynamic height

  @override
  void initState() {
    super.initState();
    AppLogger.info('🌐 MailPageWeb initialized for: ${widget.userEmail}');
    
    // PostMessage listener setup - iframe height için
    if (kIsWeb) {
      _setupPostMessageListener();
    }
    
    // Mail loading - sadece inbox
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeMailPage();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }



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

        // 1) Delta’yı biriktir
        _accumulatedDeltaY += deltaY;

        // 2) Controller hazırsa bu frame için tek uygulama planla
        if (!mounted || !_scrollController.hasClients) {
          //AppLogger.info('⚠️ scrollFromIframe skipped: controller not ready');
        } else {
          _scheduleApplyAccumulatedScroll(); // <- sınıf içinde tanımlı yardımcı metot
        }
      }

      // 📏 iframe → Flutter: yükseklik güncellemesi
      if (decoded is Map && decoded['type'] == 'iframeHeight') {
        final newH = double.tryParse(decoded['height'].toString()) ?? 400;
        if (mounted && _iframeHeight != newH) {
          setState(() => _iframeHeight = newH);
          AppLogger.info('🔧 iframe height set to: $_iframeHeight');
        }
      }
    } catch (e, st) {
      AppLogger.info('❌ PostMessage parse error: $e\n$st');
    }
  }.toJS);
}

  /// Initialize mail page - SADECE inbox yükle
  Future<void> _initializeMailPage() async {
    AppLogger.info('🌐 Initializing mail page for: ${widget.userEmail}');
    
    // Set user email
    ref.read(mailProvider.notifier).setCurrentUserEmail(widget.userEmail);
    
    // Load inbox folder
    await ref
        .read(mailProvider.notifier)
        .loadFolder(MailFolder.inbox, userEmail: widget.userEmail);
        
    AppLogger.info('🌐 Mail page initialization completed');
  }

  @override
  Widget build(BuildContext context) {
    // Provider watches
    final currentMails = ref.watch(currentMailsProvider);
    final isLoading = ref.watch(currentLoadingProvider);
    final error = ref.watch(currentErrorProvider);
    
    // Mail detail provider - seçili mail için
    final mailDetail = ref.watch(currentMailDetailProvider);
    final mailDetailLoading = ref.watch(mailDetailLoadingProvider);

    AppLogger.info('🌐 Web Provider State - Mail Count: ${currentMails.length}, Loading: $isLoading');

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // Main Content
          Expanded(
            child: Row(
              children: [
                // Sidebar - basit
                _buildSidebar(),
                
                // Mail List
                Expanded(
                  flex: _isPreviewPanelVisible ? 2 : 3,
                  child: _buildMailList(
                    currentMails: currentMails,
                    isLoading: isLoading,
                    error: error,
                  ),
                ),
                
                // Preview Panel
                if (_isPreviewPanelVisible)
                  Expanded(
                    flex: 2,
                    child: _buildPreviewPanel(mailDetail, mailDetailLoading),
                  ),
              ],
            ),
          ),
        ],
      ),
      
      // Floating Compose Button
      //floatingActionButton: _buildComposeButton(),
    );
  }

  // SIDEBAR - basit
  Widget _buildSidebar() {
    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        children: [
          // Compose Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // TODO: Compose
                },
                icon: const Icon(Icons.edit),
                label: const Text('Oluştur'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ),
          ),
          
          // Navigation - sadece inbox
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: [
                ListTile(
                  leading: const Icon(Icons.inbox, size: 20),
                  title: const Text('Gelen Kutusu', style: TextStyle(fontSize: 14)),
                  selected: true,
                  onTap: () {},
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // MAIL LIST
  Widget _buildMailList({
    required List<Mail> currentMails,
    required bool isLoading,
    required String? error,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: _isPreviewPanelVisible 
            ? Border(right: BorderSide(color: Colors.grey[300]!))
            : null,
      ),
      child: Column(
        children: [
          // Toolbar
          _buildMailToolbar(currentMails: currentMails),
          
          // Mail List Content
          Expanded(
            child: _buildMailListContent(
              currentMails: currentMails,
              isLoading: isLoading,
              error: error,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMailToolbar({required List<Mail> currentMails}) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Title
          Text(
            'Gelen Kutusu',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          
          const Spacer(),
          
          // Mail count
          Text(
            '${currentMails.length} mail',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMailListContent({
    required List<Mail> currentMails,
    required bool isLoading,
    required String? error,
  }) {
    // Loading state
    if (isLoading && currentMails.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // Error state  
    if (error != null && currentMails.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Mailler yüklenemedi',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Empty state
    if (currentMails.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Gelen kutunuz boş',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    // Mail list
    return ListView.builder(
      itemCount: currentMails.length,
      itemBuilder: (context, index) {
        final mail = currentMails[index];
        return _buildMailListItem(mail, index);
      },
    );
  }

  // Mail item - basit
  Widget _buildMailListItem(Mail mail, int index) {
    final isSelected = _selectedMails.contains(mail.id);
    final isCurrentlySelected = _selectedMailId == mail.id;
    
    return Material(
      color: isCurrentlySelected 
          ? Colors.blue.withOpacity(0.1)
          : Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedMailId = mail.id;
          });
          // Mail detail yükle
          ref.read(mailDetailProvider.notifier).loadMailDetail(
            mailId: mail.id,
            email: widget.userEmail,
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.grey[200]!),
            ),
          ),
          child: Row(
            children: [
              // Checkbox
              Transform.scale(
                scale: 0.8,
                child: Checkbox(
                  value: isSelected,
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        _selectedMails.add(mail.id);
                      } else {
                        _selectedMails.remove(mail.id);
                      }
                    });
                  },
                ),
              ),
              
              const SizedBox(width: 8),
              
              // Star
              Icon(
                mail.isStarred ? Icons.star : Icons.star_border,
                color: mail.isStarred ? Colors.amber : Colors.grey[400],
                size: 18,
              ),
              
              const SizedBox(width: 16),
              
              // Mail content
              Expanded(
                child: Row(
                  children: [
                    // Sender name
                    SizedBox(
                      width: 180,
                      child: Text(
                        mail.senderName,
                        style: TextStyle(
                          fontWeight: mail.isRead ? FontWeight.normal : FontWeight.bold,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // Subject
                    Expanded(
                      child: Text(
                        mail.subject,
                        style: TextStyle(
                          fontSize: 14,
                          color: mail.isRead ? Colors.grey[700] : Colors.black,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    
                    const SizedBox(width: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Preview panel - buildRenderedHtmlSection ile mail içeriği gösterimi
  Widget _buildPreviewPanel(MailDetail? mailDetail, bool isLoading) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Header
          Container(
            height: 48,
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  'Önizleme',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: _buildPreviewContent(mailDetail, isLoading),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewContent(MailDetail? mailDetail, bool isLoading) {
    // Loading state
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // No mail selected
    if (mailDetail == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.mail_outline, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Önizlemek için bir mail seçin',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    // Mail selected - show content using mobile pattern
    return _buildMailContent(context, mailDetail);
  }

  Widget _buildMailContent(BuildContext context, MailDetail mailDetail) {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mail header info
          _buildMailHeader(mailDetail),
          
          const SizedBox(height: 16),
          
          // Rendered HTML content
          _buildRenderedHtmlSection(mailDetail),
          
          // Attachments section
          _buildAttachmentsSection(mailDetail),
          
          // Extra bottom padding
          const SizedBox(height: 16),
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

  // Iframe element oluştur - temiz ve stabil
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

  // Web olmayan platformlar için fallback
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

  // HTML to Text converter - fallback için
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

  // Iframe için HTML oluştur - dynamic height ile postMessage
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
      background: #ffffff !important;  /* Gmail’deki gibi beyaz zemin */
      /* iframe içinde dikey kapalı, yatay açık */
      overflow-x: auto !important;
      overflow-y: hidden !important;
      min-width: fit-content;
    }

    /* Tarayıcı dark mode’a geçse bile görünümü sabitle */
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

  // Text to HTML converter
  String _convertTextToHtml(String text) {
    return text.replaceAll('\n', '<br>');
  }


}