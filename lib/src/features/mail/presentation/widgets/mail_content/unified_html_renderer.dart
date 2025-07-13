// lib/src/features/mail/presentation/widgets/mail_content/html_renderer/unified_html_renderer.dart

import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../domain/entities/mail_detail.dart';

/// Unified HTML Renderer using InAppWebView 6.1.5
///
/// Bu widget email HTML içeriğini mobile-optimized şekilde render eder.
/// Gmail mobile benzeri deneyim sağlar.
class UnifiedHtmlRenderer extends StatefulWidget {
  final String htmlContent;
  final MailDetail mailDetail;
  final bool isReplyMode;
  final VoidCallback? onReply;
  final Function(String)? onReplyTextChanged;

  const UnifiedHtmlRenderer({
    super.key,
    required this.htmlContent,
    required this.mailDetail,
    this.isReplyMode = false,
    this.onReply,
    this.onReplyTextChanged,
  });

  @override
  State<UnifiedHtmlRenderer> createState() => _UnifiedHtmlRendererState();
}

class _UnifiedHtmlRendererState extends State<UnifiedHtmlRenderer> {
  InAppWebViewController? webViewController;
  double webViewHeight = 300;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();

    // Android WebView debugging için (safe platform detection)
    _initializeWebViewDebugging();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Theme-dependent operations can be done here if needed
  }

  /// WebView debugging setup (Android için)
  void _initializeWebViewDebugging() async {
    // Safe platform detection without Theme.of(context)
    if (!kIsWeb && Platform.isAndroid) {
      // Debug mode'da WebView debugging'i aktif et
      await InAppWebViewController.setWebContentsDebuggingEnabled(kDebugMode);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (errorMessage != null) {
      return _buildErrorWidget();
    }

    return Container(
      height: webViewHeight,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [_buildWebView(), if (isLoading) _buildLoadingWidget()],
        ),
      ),
    );
  }

  /// Build main WebView widget
  Widget _buildWebView() {
    return InAppWebView(
      initialData: InAppWebViewInitialData(
        data: _buildOptimizedHtml(),
        mimeType: "text/html",
        encoding: "utf-8",
      ),
      initialSettings: InAppWebViewSettings(
        // Performance
        javaScriptEnabled: true,
        domStorageEnabled: false,

        // 🚀 Critical responsive WebView settings
        supportZoom: false,
        displayZoomControls: false,
        builtInZoomControls: false,
        loadWithOverviewMode: true,
        useWideViewPort: true,

        // Media settings
        mediaPlaybackRequiresUserGesture: false,
        allowsInlineMediaPlayback: true,

        // Appearance
        transparentBackground: true,

        // UX optimizations
        disableContextMenu: true,
        verticalScrollBarEnabled: false,
        horizontalScrollBarEnabled: false,

        // Platform optimizations
        useHybridComposition: true,
        allowsBackForwardNavigationGestures: false,

        // URL handling
        useShouldOverrideUrlLoading: true,

        // 🚀 Mobile responsive key settings
        initialScale: 100,
        minimumLogicalFontSize: 1, // Don't override font sizes
        // Security
        allowFileAccess: false,
        allowContentAccess: false,
        blockNetworkLoads: false,
        blockNetworkImage: false,

        // Debug
        isInspectable: true,
      ),
      onWebViewCreated: (controller) async {
        webViewController = controller;

        // JavaScript handlers setup
        _setupJavaScriptHandlers(controller);
      },
      onLoadStop: (controller, url) async {
        setState(() => isLoading = false);

        // Height calculation
        await _updateWebViewHeight();
      },
      onReceivedError: (controller, request, error) {
        // Ignore common harmless errors
        if (error.description.contains('ERR_UNKNOWN_URL_SCHEME') ||
            error.description.contains('about:blank') ||
            request.url.toString().contains('about:blank')) {
          // Don't show error for these - they're expected
          return;
        }

        setState(() {
          isLoading = false;
          errorMessage = 'Email content load error: ${error.description}';
        });
      },
      onLoadError: (controller, url, code, message) {
        // Ignore common harmless errors
        if (message.contains('ERR_UNKNOWN_URL_SCHEME') ||
            url.toString().contains('about:blank') ||
            url.toString().startsWith('about:')) {
          // Don't show error for these - they're expected
          return;
        }

        setState(() {
          isLoading = false;
          errorMessage = 'Failed to load email: $message';
        });
      },
      shouldOverrideUrlLoading: (controller, navigationAction) async {
        final url = navigationAction.request.url.toString();
        return await _handleUrlOverride(url);
      },
    );
  }

  /// JavaScript communication setup
  void _setupJavaScriptHandlers(InAppWebViewController controller) {
    // Height update handler
    controller.addJavaScriptHandler(
      handlerName: 'heightChanged',
      callback: (args) {
        if (args.isNotEmpty && mounted) {
          final height = double.tryParse(args[0].toString()) ?? 300;
          setState(() {
            webViewHeight = height.clamp(200, 2000);
          });
        }
      },
    );

    // Reply handlers (gelecek için)
    controller.addJavaScriptHandler(
      handlerName: 'replyTextChanged',
      callback: (args) {
        if (args.isNotEmpty) {
          widget.onReplyTextChanged?.call(args[0].toString());
        }
      },
    );

    controller.addJavaScriptHandler(
      handlerName: 'sendReply',
      callback: (args) {
        widget.onReply?.call();
      },
    );
  }

  /// URL navigation handling
  Future<NavigationActionPolicy> _handleUrlOverride(String url) async {
    try {
      // Block problematic URLs
      if (url == 'about:blank' ||
          url.isEmpty ||
          url.startsWith('about:') ||
          url.startsWith('javascript:') ||
          url.contains('#')) {
        return NavigationActionPolicy.CANCEL;
      }

      final uri = Uri.tryParse(url);
      if (uri == null) return NavigationActionPolicy.CANCEL;

      if (uri.scheme == 'mailto') {
        // Email composition
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        }
        return NavigationActionPolicy.CANCEL;
      }

      if (uri.scheme == 'tel') {
        // Phone calls
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        }
        return NavigationActionPolicy.CANCEL;
      }

      if (uri.scheme == 'http' || uri.scheme == 'https') {
        // External links
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
        return NavigationActionPolicy.CANCEL;
      }

      // Block all other navigation attempts
      return NavigationActionPolicy.CANCEL;
    } catch (e) {
      debugPrint('URL handling error: $url, Error: $e');
      return NavigationActionPolicy.CANCEL;
    }
  }

  /// Dynamic height calculation
  Future<void> _updateWebViewHeight() async {
    if (webViewController == null) return;

    try {
      final result = await webViewController!.evaluateJavascript(
        source: '''
        Math.max(
          document.body.scrollHeight,
          document.body.offsetHeight,
          document.documentElement.clientHeight,
          document.documentElement.scrollHeight,
          document.documentElement.offsetHeight
        )
      ''',
      );

      if (result != null && mounted) {
        final height = double.tryParse(result.toString()) ?? 300;
        setState(() {
          webViewHeight = height.clamp(200, 2000);
        });
      }
    } catch (e) {
      debugPrint('Height calculation error: $e');
    }
  }

  /// Optimized HTML content builder
  String _buildOptimizedHtml() {
    return '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no, viewport-fit=cover">
</head>
<body style="margin:0;padding:0;">
    ${widget.htmlContent}
    <script>
        ${_getOptimizationJavaScript()}
    </script>
</body>
</html>
    ''';
  }

  // CSS function removed - no interference with original HTML

  /// JavaScript optimization
  String _getOptimizationJavaScript() {
    return '''
        // Height calculation ve reporting
        function updateHeight() {
            const height = Math.max(
                document.body.scrollHeight,
                document.body.offsetHeight,
                document.documentElement.clientHeight,
                document.documentElement.scrollHeight,
                document.documentElement.offsetHeight
            );
            
            // Flutter'a height report et
            if (window.flutter_inappwebview && window.flutter_inappwebview.callHandler) {
                window.flutter_inappwebview.callHandler('heightChanged', height);
            }
        }
        

        
        // Initialize after DOM loaded
        document.addEventListener('DOMContentLoaded', function() {
            // Initial height calculation
            updateHeight();
            
            // Observe content changes for dynamic height
            const observer = new MutationObserver(updateHeight);
            observer.observe(document.body, {
                childList: true,
                subtree: true,
                attributes: true
            });
            
            // Email-specific optimizations
            optimizeEmailContent();
        });
        
        // Window resize handler
        window.addEventListener('resize', updateHeight);
        
        // Delayed height update for async content
        setTimeout(updateHeight, 100);
        setTimeout(updateHeight, 500);
        
        // Email content optimizations
        function optimizeEmailContent() {
            // Ensure all images are responsive
            const images = document.querySelectorAll('img');
            images.forEach(img => {
                img.style.maxWidth = '100%';
                img.style.height = 'auto';
                img.style.display = 'block';
                img.style.margin = '8px auto';
            });
            
            // Optimize tables for mobile
            const tables = document.querySelectorAll('table');
            tables.forEach(table => {
                table.style.width = '100%';
                table.style.maxWidth = '100%';
                table.style.borderCollapse = 'collapse';
            });
            
            // Update height after optimizations
            setTimeout(updateHeight, 100);
        }
    ''';
  }

  /// Loading widget
  Widget _buildLoadingWidget() {
    return Container(
      color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Email yükleniyor...'),
          ],
        ),
      ),
    );
  }

  /// Error widget
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
              errorMessage ?? 'Email içeriği yüklenemedi',
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
                // Reload attempt
                webViewController?.reload();
              },
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      ),
    );
  }
}
