// lib/src/features/mail/presentation/widgets/mobile/htmlrender/utils/preview_html_builder.dart

import '../../../../../domain/entities/mail_detail.dart';

/// HTML Builder for Preview Mode - Simple mail content display
class PreviewHtmlBuilder {
  /// Build complete HTML document for preview mode
  static String buildPreviewHtml({required MailDetail mailDetail}) {
    return _buildSimplePreviewHtml(mailDetail);
  }

  /// Build minimal preview HTML (no UnifiedHtmlRenderer features)
  static String _buildSimplePreviewHtml(MailDetail mailDetail) {
    final content = mailDetail.htmlContent.isNotEmpty
        ? mailDetail.htmlContent
        : _convertTextToHtml(mailDetail.textContent);

    return '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <style>
        ${_getMinimalStyles()}
    </style>
</head>
<body>
    <div class="preview-container">
        $content
    </div>
    <script>
        ${_getMinimalJavaScript()}
    </script>
</body>
</html>
    ''';
  }

  /// Minimal CSS styles for preview mode
  static String _getMinimalStyles() {
    return '''
        * {
            box-sizing: border-box;
        }
        
        body {
            margin: 0;
            padding: 0;
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            font-size: 16px;
            line-height: 1.5;
            background-color: #fff;
        }
        
        .preview-container {
            padding: 16px;
            word-wrap: break-word;
            overflow-wrap: break-word;
        }
        
        /* Basic responsive images */
        img {
            max-width: 100%;
            height: auto;
            display: block;
            margin: 8px auto;
        }
        
        /* Basic table optimization */
        table {
            width: 100%;
            max-width: 100%;
            border-collapse: collapse;
        }
        
        /* Prevent horizontal scroll */
        * {
            max-width: 100%;
        }
    ''';
  }

  /// Minimal JavaScript for preview mode
static String _getMinimalJavaScript() {
  return '''
    // Mail content loaded successfully
    console.log('📧 Mail content loaded successfully');
    
    // Height reporting function (Flutter tarafının bekleyebileceği callback)
    function updateHeight() {
        const height = Math.max(
            document.body.scrollHeight,
            document.body.offsetHeight,
            document.documentElement.clientHeight,
            document.documentElement.scrollHeight,
            document.documentElement.offsetHeight
        );
        
        if (window.flutter_inappwebview && window.flutter_inappwebview.callHandler) {
            window.flutter_inappwebview.callHandler('heightChanged', height);
        }
    }
    
    // Link'leri external browser'da aç
    document.addEventListener('click', function(e) {
      if (e.target.tagName === 'A' && e.target.href) {
        e.preventDefault();
        if (window.flutter_inappwebview) {
          window.flutter_inappwebview.callHandler('openLink', e.target.href);
        }
      }
    });
    
    // Height update event listeners
    document.addEventListener('DOMContentLoaded', updateHeight);
    window.addEventListener('resize', updateHeight);
    setTimeout(updateHeight, 100);
  ''';
}

  /// Helper method for text to HTML conversion
  static String _convertTextToHtml(String text) {
    if (text.trim().isEmpty) {
      return '<p>Bu mailde içerik bulunmuyor.</p>';
    }

    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('\n\n', '</p><p>')
        .replaceAll('\n', '<br>')
        .replaceAll(RegExp(r'^'), '<p>')
        .replaceAll(RegExp(r'$'), '</p>');
  }
}
