// lib/src/features/mail/presentation/widgets/mobile/htmlrender/utils/editor_html_builder.dart

import '../../../../../domain/entities/mail_detail.dart';

/// HTML Builder for Editor Mode - With height reporting
class EditorHtmlBuilder {
  /// Build complete HTML document for editor mode
  static String buildEditorHtml({required MailDetail mailDetail}) {
    return _buildEditorHtml(mailDetail);
  }

  /// Build editor HTML with height reporting
  static String _buildEditorHtml(MailDetail mailDetail) {
    final content = mailDetail.htmlContent.isNotEmpty
        ? mailDetail.htmlContent
        : _convertTextToHtml(mailDetail.textContent);

    return '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=yes">
    <style>
        ${_getEditorStyles()}
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
            $content
        </div>
    </div>
    <script>
        ${_getEditorJavaScript()}
    </script>
</body>
</html>
    ''';
  }

  /// CSS styles for editor mode
  static String _getEditorStyles() {
    return '''
        * {
            box-sizing: border-box;
        }
        
html, body {
    overflow: auto;        // Her yönde scroll
    width: auto;           // Otomatik genişlik
    min-width: 100vw;      // En az viewport genişliği
}
        
        .container {
            padding: 16px;
            overflow: visible;
            min-width: max-content; // 🔥 Content boyutuna göre genişlik
            width: auto; // 🔥 Otomatik genişlik
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
        
        img, table, div {
            /* 🔥 Orijinal boyutları koru - max-width kısıtlaması yok */
            word-wrap: break-word;
            overflow-wrap: break-word;
        }
        
        /* Email content'inin orijinal boyutlarını koru */
        .original-quote * {
            max-width: none !important;
            width: auto !important;
        }
        
        /* Tablolar için özel ayarlar */
        .original-quote table {
            width: auto !important;
            max-width: none !important;
            table-layout: auto;
        }
        
        /* Images için orijinal boyut */
        .original-quote img {
            max-width: none !important;
            width: auto !important;
            height: auto !important;
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
    ''';
  }

  /// JavaScript for editor mode with height reporting
  static String _getEditorJavaScript() {
    return '''
      let isExpanded = true;

      function initializeSimplifiedEditor() {
          console.log('🚀 Ultra simplified editor initialized');
          updateHeight();
      }

      function updateHeight() {
          // Calculate the total height of the body/document
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
          if (window.flutter_inappwebview) {
              window.flutter_inappwebview.callHandler('onExpansionToggle', isExpanded);
          }
          updateHeight(); // Her toggle'da yükseklik bildir!
      }

      function getComposeData() {
          // Since there's no compose area, return empty data
          return {
              content: { compose: '', canSend: false },
              html: document.body.innerHTML
          };
      }

      // Height update event listeners
      document.addEventListener('DOMContentLoaded', initializeSimplifiedEditor);
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