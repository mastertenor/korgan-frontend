// lib/src/features/mail/presentation/widgets/mobile/htmlrender/utils/editor_html_builder.dart

import '../../../../../domain/entities/mail_detail.dart';

/// HTML Builder for Editor Mode - Ultra simplified with horizontal scroll
class EditorHtmlBuilder {
  /// Build complete HTML document for editor mode
  static String buildEditorHtml({
    required MailDetail mailDetail,
    required String currentUserEmail,
  }) {
    return _buildUltraSimplifiedHtml(mailDetail);
  }

  static String _buildUltraSimplifiedHtml(MailDetail mailDetail) {
    final String originalHtmlContent = _getOriginalHtmlContent(mailDetail);
    
    return '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
        * {
            box-sizing: border-box;
        }
        
        html, body {
            margin: 0;
            padding: 0;
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            font-size: 16px;
            line-height: 1.5;
            background-color: #fff;
            /* Enable all scrolling */
            overflow: auto;
        }
        
        .container {
            padding: 16px;
            /* Allow horizontal overflow */
            overflow: visible;
            min-width: fit-content;
        }
        
        .quote-toggle {
            margin: 0 0 10px 0;
            padding: 12px;
            cursor: pointer;
            color: #1976d2;                    
            font-size: 14px;
            user-select: none;
        }
        
        .quote-toggle:hover {
            background: #e8e8e8;
        }
        
        .original-quote {
            border-left: 4px solid #e0e0e0;
            background-color: #f8f9fa;
            border-radius: 0 8px 8px 0;
            transition: all 0.3s ease;
            /* Allow horizontal overflow */
            overflow: auto;
        }
        
        .original-quote.expanded {
            padding: 16px;
            margin: 16px 0;
        }
        
        .original-quote.collapsed {
            max-height: 0;
            padding: 0;
            margin: 0;
            overflow: hidden;
        }
        
        /* Remove any width restrictions */
        img, table, div {
            /* No max-width restrictions */
        }
    </style>
</head>
<body>
    <div class="container">
        <!-- Quote Toggle -->
        <div class="quote-toggle" onclick="toggleQuote()">
            <span id="toggle-text">🔽 Orijinal mesajı gizle</span>
        </div>
        
        <!-- Original Quote -->
        <div class="original-quote expanded" id="original-quote">
            $originalHtmlContent
        </div>
    </div>
    
    <script>
        let isExpanded = true;
        
        function initializeSimplifiedEditor() {
            console.log('🚀 Ultra simplified editor initialized');
        }
        
        function toggleQuote() {
            const quote = document.getElementById('original-quote');
            const toggleText = document.getElementById('toggle-text');
            
            isExpanded = !isExpanded;
            
            if (isExpanded) {
                quote.className = 'original-quote expanded';
                toggleText.textContent = '🔽 Orijinal mesajı gizle';
            } else {
                quote.className = 'original-quote collapsed';
                toggleText.textContent = '🔼 Orijinal mesajı göster';
            }
            
            // Notify Flutter
            if (window.flutter_inappwebview) {
                window.flutter_inappwebview.callHandler('onExpansionToggle', isExpanded);
            }
        }
        
        function getComposeData() {
            // Since there's no compose area, return empty data
            return {
                content: { compose: '', canSend: false },
                html: document.body.innerHTML
            };
        }
        
        // Initialize
        if (document.readyState === 'loading') {
            document.addEventListener('DOMContentLoaded', initializeSimplifiedEditor);
        } else {
            initializeSimplifiedEditor();
        }
    </script>
</body>
</html>''';
  }

  /// Helper method for original content
  static String _getOriginalHtmlContent(MailDetail mailDetail) {
    if (mailDetail.htmlContent.isNotEmpty) {
      return mailDetail.htmlContent;
    }
    return _convertTextToHtml(mailDetail.textContent);
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