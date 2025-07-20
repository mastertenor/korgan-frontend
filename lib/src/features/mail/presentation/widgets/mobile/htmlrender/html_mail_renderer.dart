// lib/src/features/mail/presentation/widgets/mobile/htmlrender/html_mail_renderer.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../../../../domain/entities/mail_detail.dart';
import 'models/render_mode.dart';
import 'utils/editor_html_builder.dart';
import 'utils/preview_html_builder.dart';

/// Main HTML Mail Renderer Widget
///
/// Supports two modes:
/// - Preview: Simple mail content display (minimal features)
/// - Editor: Full Yandex-style mail composition editor
class HtmlMailRenderer extends StatefulWidget {
  /// Rendering mode (preview or editor)
  final RenderMode mode;

  /// Mail detail data
  final MailDetail mailDetail;

  /// Current user email (required for editor mode)
  final String? currentUserEmail;

  /// Callbacks for editor mode
  final VoidCallback? onSend;
  final VoidCallback? onAttachFile;
  final VoidCallback? onMenuAction;
  final Function(String)? onContentChanged;
  final Function(double)? onHeightChanged;

  const HtmlMailRenderer({
    super.key,
    required this.mode,
    required this.mailDetail,
    this.currentUserEmail,
    this.onSend,
    this.onAttachFile,
    this.onMenuAction,
    this.onContentChanged,
    this.onHeightChanged
  });

  @override
  State<HtmlMailRenderer> createState() => _HtmlMailRendererState();
}

class _HtmlMailRendererState extends State<HtmlMailRenderer> {
  // Controllers and state
  InAppWebViewController? _webViewController;
  Timer? _debounceTimer;

  // State variables
  bool isLoading = true;
  double webViewHeight = 300;
  String? errorMessage;

  // Editor mode state (only used when mode is editor)
  String composeContent = '';
  String toField = '';
  String ccField = '';
  String bccField = '';
  String subjectField = '';
  String fromField = '';
  bool isOriginalExpanded = false;

  @override
  void initState() {
    super.initState();
    _initializeMode();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  /// Initialize based on mode
  void _initializeMode() {
    debugPrint('🎯 HtmlMailRenderer initializing in ${widget.mode.name} mode');

    if (widget.mode.isEditor) {
      _initializeEditorMode();
    } else {
      _initializePreviewMode();
    }
  }

  /// Initialize editor mode with mail data
  void _initializeEditorMode() {
    if (widget.currentUserEmail == null) {
      debugPrint('❌ Editor mode requires currentUserEmail');
      setState(() {
        errorMessage = 'Editor mode requires user email';
        isLoading = false;
      });
      return;
    }

    setState(() {
      // Reply field setup
      toField = widget.mailDetail.senderEmail;
      fromField = widget.currentUserEmail!;
      subjectField = _buildReplySubject(widget.mailDetail.subject);
      ccField = '';
      bccField = '';
      composeContent = '';
      isLoading = false;
    });

    debugPrint('✅ Editor mode initialized');
    debugPrint('📧 Reply to: $toField');
    debugPrint('📧 Subject: $subjectField');
  }

  /// Initialize preview mode
  void _initializePreviewMode() {
    setState(() {
      isLoading = false;
    });
    debugPrint('✅ Preview mode initialized');
  }

  @override
  Widget build(BuildContext context) {
    if (errorMessage != null) {
      return _buildErrorWidget();
    }

    if (isLoading) {
      return _buildLoadingWidget();
    }

    return _buildWebViewContent();
  }

  /// Build main WebView content
  Widget _buildWebViewContent() {
    return SizedBox(
      height: webViewHeight, // 🔥 FIX: Her iki mode için de height kullan
      child: Stack(
        children: [_buildWebView(), if (isLoading) _buildLoadingOverlay()],
      ),
    );
  }

  /// Build InAppWebView
  Widget _buildWebView() {
    return InAppWebView(
      initialData: InAppWebViewInitialData(
        data: _getHtmlContent(),
        mimeType: "text/html",
        encoding: "utf-8",
      ),
      initialSettings: InAppWebViewSettings(
        javaScriptEnabled: true,
        domStorageEnabled: false,
        verticalScrollBarEnabled: true,
        horizontalScrollBarEnabled: true,
        supportZoom: false,
        transparentBackground: false,
        useHybridComposition: true,
        allowsInlineMediaPlayback: true,
        allowFileAccess: false,
        allowContentAccess: false,
        allowsBackForwardNavigationGestures: false,
        clearCache: false,
        cacheEnabled: true,
        databaseEnabled: false,
        javaScriptCanOpenWindowsAutomatically: false,
        mediaPlaybackRequiresUserGesture: false,
      ),
      onWebViewCreated: (controller) {
        _webViewController = controller;
        _setupJavaScriptHandlers(controller);
      },
      onLoadStop: (controller, url) {
        setState(() => isLoading = false);

        if (widget.mode.isEditor) {
          _initializeEditor(controller);
        }
        
        // 🔥 FIX: Her iki mode için de height update çalıştır
        _updateWebViewHeight();
      },
      onReceivedError: (controller, request, error) {
        _handleWebViewError(error.description);
      },
      onLoadError: (controller, url, code, message) {
        _handleWebViewError(message);
      },
      onConsoleMessage: (controller, consoleMessage) {
        debugPrint('📝 WebView Console: ${consoleMessage.message}');
      },
    );
  }

  /// Get HTML content based on mode
  String _getHtmlContent() {
    switch (widget.mode) {
      case RenderMode.preview:
        return PreviewHtmlBuilder.buildPreviewHtml(
          mailDetail: widget.mailDetail,
        );
      case RenderMode.editor:
        return EditorHtmlBuilder.buildEditorHtml(
          mailDetail: widget.mailDetail,
        );
    }
  }

  /// Setup JavaScript handlers based on mode
  void _setupJavaScriptHandlers(InAppWebViewController controller) {
    // 🔥 FIX: Her iki mode için de height handler'ı ekle
    _setupHeightHandler(controller);
    
    if (widget.mode.isPreview) {
      _setupPreviewHandlers(controller);
    } else {
      _setupEditorHandlers(controller);
    }
  }

  /// 🔥 NEW: Ortak height handler (her iki mode için)
  void _setupHeightHandler(InAppWebViewController controller) {
    controller.addJavaScriptHandler(
      handlerName: 'heightChanged',
      callback: (args) {
        if (args.isNotEmpty && mounted) {
          final height = double.tryParse(args[0].toString()) ?? 300;
          setState(() {
            webViewHeight = height.clamp(200, double.infinity);
          });
          
          // Parent'a height değişikliğini bildir
          widget.onHeightChanged?.call(webViewHeight);
          
          debugPrint('📏 Height updated (${widget.mode.name}): $webViewHeight');
        }
      },
    );
  }

  /// Setup handlers for preview mode
  void _setupPreviewHandlers(InAppWebViewController controller) {
    // Link handler for preview mode
    controller.addJavaScriptHandler(
      handlerName: 'openLink',
      callback: (args) {
        if (args.isNotEmpty) {
          debugPrint('🔗 Link clicked: ${args[0]}');
          // Handle external link opening
        }
      },
    );
  }

  /// Setup handlers for editor mode (Yandex-style)
  void _setupEditorHandlers(InAppWebViewController controller) {
    // Data change handler
    controller.addJavaScriptHandler(
      handlerName: 'onDataChange',
      callback: (args) {
        if (args.isNotEmpty) {
          final data = args[0] as Map<String, dynamic>;

          setState(() {
            toField = data['to'] ?? '';
            ccField = data['cc'] ?? '';
            bccField = data['bcc'] ?? '';
            fromField = data['from'] ?? '';
            subjectField = data['subject'] ?? '';
            composeContent = data['compose'] ?? '';
          });

          // Notify parent about content changes
          widget.onContentChanged?.call(composeContent);

          debugPrint('📝 Editor fields updated:');
          debugPrint('  To: $toField');
          debugPrint('  Subject: $subjectField');
        }
      },
    );

    // Expansion toggle handler (original message)
    controller.addJavaScriptHandler(
      handlerName: 'onExpansionToggle',
      callback: (args) {
        if (args.isNotEmpty) {
          setState(() {
            isOriginalExpanded = args[0] as bool;
          });
          debugPrint(
            '📧 Original message ${isOriginalExpanded ? "expanded" : "collapsed"}',
          );
          
          // 🔥 FIX: Expansion değiştiğinde height'ı güncelle
          Future.delayed(const Duration(milliseconds: 300), () {
            _updateWebViewHeight();
          });
        }
      },
    );

    // Focus change handler
    controller.addJavaScriptHandler(
      handlerName: 'onFocusChange',
      callback: (args) {
        if (args.isNotEmpty) {
          final data = args[0] as Map<String, dynamic>;
          debugPrint(
            '🎯 Focus changed - Field: ${data['field']}, Focused: ${data['focused']}',
          );
        }
      },
    );
  }

  /// Initialize editor after WebView loads
  void _initializeEditor(InAppWebViewController controller) {
    debugPrint('✅ Editor loaded, initializing...');

    controller.evaluateJavascript(
      source: '''
        setTimeout(function() {
          if (typeof initializeYandexEditor === 'function') {
            initializeYandexEditor();
          }
        }, 100);
      ''',
    );
  }

  /// 🔥 FIX: Update WebView height for BOTH modes
  Future<void> _updateWebViewHeight() async {
    if (_webViewController == null) return;

    try {
      final result = await _webViewController!.evaluateJavascript(
        source: '''
        Math.max(
          document.body.scrollHeight,
          document.body.offsetHeight,
          document.documentElement.clientHeight,
          document.documentElement.scrollHeight,
          document.documentElement.offsetHeight
        ) + 50
      ''',
      );

      if (result != null && mounted) {
        final height = double.tryParse(result.toString()) ?? 300;
        setState(() {
          webViewHeight = height.clamp(200, double.infinity);
        });
        
        // Parent'a height değişikliğini bildir
        widget.onHeightChanged?.call(webViewHeight);
        
        debugPrint('📏 Height calculated (${widget.mode.name}): $webViewHeight');
      }
    } catch (e) {
      debugPrint('Height calculation error: $e');
    }
  }

  /// Handle WebView errors
  void _handleWebViewError(String message) {
    debugPrint('🔴 WebView Error: $message');

    // Resource error'ları ignore et (images, fonts, css, etc.)
    if (message.contains('.png') ||
        message.contains('.jpg') ||
        message.contains('.jpeg') ||
        message.contains('.gif') ||
        message.contains('.svg') ||
        message.contains('.woff') ||
        message.contains('.ttf') ||
        message.contains('.css') ||
        message.contains('ERR_CONNECTION_TIMED_OUT') ||
        message.contains('ERR_NAME_NOT_RESOLVED') ||
        message.contains('ERR_UNKNOWN_URL_SCHEME') ||
        message.contains('about:blank')) {
      // Just log and ignore - don't crash the mail view
      debugPrint('⚠️ Non-critical web asset error (ignored): $message');
      return;
    }

    // Sadece kritik main document error'ları için hata ekranı göster
    setState(() {
      isLoading = false;
      errorMessage = 'Mail content load error: $message';
    });
  }

  // ========== PUBLIC METHODS FOR EDITOR MODE ==========

  /// Check if editor can send (has required fields)
  bool canSend() {
    if (widget.mode.isPreview) return false;
    return toField.isNotEmpty && subjectField.isNotEmpty;
  }

  /// Get all editor data
  Future<Map<String, dynamic>?> getAllEditorData() async {
    if (widget.mode.isPreview || _webViewController == null) return null;

    try {
      final result = await _webViewController!.evaluateJavascript(
        source: 'getAllData()',
      );
      return result as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('Error getting editor data: $e');
      return null;
    }
  }

  // ========== HELPER METHODS ==========

  String _buildReplySubject(String originalSubject) {
    if (originalSubject.toLowerCase().startsWith('re:')) {
      return originalSubject;
    }
    return 'Re: $originalSubject';
  }

  // ========== UI WIDGETS ==========

  Widget _buildLoadingWidget() {
    return Container(
      height: 200,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Mail yükleniyor...'),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
            const SizedBox(height: 12),
            Text(
              errorMessage ?? 'Mail içeriği yüklenemedi',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red[700]),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  errorMessage = null;
                  isLoading = true;
                });
                _webViewController?.reload();
              },
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      ),
    );
  }
}