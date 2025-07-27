// lib/src/features/mail/presentation/utils/reply_html_builder.dart

import '../../domain/entities/mail_detail.dart';

/// Gmail-style HTML builder for mail replies - FIXED VERSION
class ReplyHtmlBuilder {
  
  /// Build complete HTML for reply mail
  static String buildReplyHtml({
    required String userReplyText,
    required MailDetail originalMail,
  }) {
    final quoteDivider = _buildQuoteDivider(originalMail);
    final originalContent = _extractBodyContent(originalMail); // 🆕 Fixed extraction
    final userContent = _prepareUserContent(userReplyText);
    
    return '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <style>
        body { font-family: Arial, sans-serif; font-size: 14px; line-height: 1.6; margin: 0; padding: 0; }
        .user-reply { margin-bottom: 20px; }
        .quote-divider { color: #666; font-style: italic; margin: 20px 0 10px 0; font-size: 13px; }
        .gmail-quote { 
            border-left: 2px solid #ccc; 
            padding-left: 16px; 
            margin-left: 0;
            color: #666;
        }
    </style>
</head>
<body>
    <div class="user-reply">
        $userContent
    </div>
    
    <div class="quote-divider">
        $quoteDivider
    </div>
    
    <blockquote class="gmail-quote">
        $originalContent
    </blockquote>
</body>
</html>''';
  }

  /// 🆕 Extract only body content from full HTML document
  static String _extractBodyContent(MailDetail originalMail) {
    if (!originalMail.hasHtmlContent) {
      // No HTML content, use text content
      return _prepareUserContent(originalMail.safeTextContent);
    }

    String htmlContent = originalMail.safeHtmlContent;
    
    // Debug log
    print('🔧 Extracting body content from HTML (${htmlContent.length} chars)');
    
    // Try to extract body content
    String bodyContent = _extractBodyFromHtml(htmlContent);
    
    print('🔧 Extracted body content (${bodyContent.length} chars):');
    print('-----START BODY-----');
    print(bodyContent);
    print('-----END BODY-----');
    
    return bodyContent;
  }

  /// 🆕 Extract content from between <body> tags
  static String _extractBodyFromHtml(String fullHtml) {
    // Remove line breaks and normalize whitespace for regex
    String normalizedHtml = fullHtml.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    
    // Try to find body content with regex (case insensitive)
    RegExp bodyRegex = RegExp(r'<body[^>]*>(.*?)</body>', caseSensitive: false, dotAll: true);
    RegExp bodyOpenRegex = RegExp(r'<body[^>]*>', caseSensitive: false);
    
    Match? bodyMatch = bodyRegex.firstMatch(normalizedHtml);
    
    if (bodyMatch != null) {
      // Found complete body tags
      String bodyContent = bodyMatch.group(1) ?? '';
      print('✅ Found complete body tags, extracted ${bodyContent.length} chars');
      return bodyContent.trim();
    }
    
    // Fallback: Find opening body tag and take everything after it
    Match? bodyOpenMatch = bodyOpenRegex.firstMatch(normalizedHtml);
    if (bodyOpenMatch != null) {
      String afterBodyTag = normalizedHtml.substring(bodyOpenMatch.end);
      
      // Try to find closing body tag
      int closingBodyIndex = afterBodyTag.toLowerCase().lastIndexOf('</body>');
      if (closingBodyIndex != -1) {
        String bodyContent = afterBodyTag.substring(0, closingBodyIndex);
        print('✅ Found opening body tag, extracted ${bodyContent.length} chars');
        return bodyContent.trim();
      } else {
        // No closing body tag, take everything after opening tag
        print('⚠️ No closing body tag found, taking everything after opening tag');
        return afterBodyTag.trim();
      }
    }
    
    // Last resort: Remove DOCTYPE and html tags manually
    String cleaned = normalizedHtml;
    
    // Remove DOCTYPE
    cleaned = cleaned.replaceAll(RegExp(r'<!DOCTYPE[^>]*>', caseSensitive: false), '');
    
    // Remove opening html tag
    cleaned = cleaned.replaceAll(RegExp(r'<html[^>]*>', caseSensitive: false), '');
    
    // Remove closing html tag
    cleaned = cleaned.replaceAll(RegExp(r'</html>', caseSensitive: false), '');
    
    // Remove head section
    cleaned = cleaned.replaceAll(RegExp(r'<head[^>]*>.*?</head>', caseSensitive: false, dotAll: true), '');
    
    // Remove any remaining body tags
    cleaned = cleaned.replaceAll(RegExp(r'</?body[^>]*>', caseSensitive: false), '');
    
    print('⚠️ Manual cleanup performed, result ${cleaned.length} chars');
    return cleaned.trim();
  }

  /// Build quote divider text (Gmail style)
  static String _buildQuoteDivider(MailDetail originalMail) {
    final dateText = originalMail.formattedReceivedUtcLocalDateTime;
    final senderText = '${originalMail.senderName} &lt;${originalMail.senderEmail}&gt;';
    
    return '$dateText tarihinde $senderText şunu yazdı:';
  }

  /// Prepare user content (convert plain text to HTML)
  static String _prepareUserContent(String userText) {
    if (userText.trim().isEmpty) {
      return '';
    }
    
    // Convert plain text to HTML
    String htmlContent = userText
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;')
        .replaceAll('\n', '<br>');
    
    return '<div>$htmlContent</div>';
  }

  /// Format date for quote header (Turkish format)
  static String _formatDateForQuote(String dateString) {
    try {
      DateTime? date = DateTime.tryParse(dateString);
      
      if (date != null) {
        final months = [
          'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz',
          'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'
        ];
        final weekdays = ['Paz', 'Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt'];
        
        final day = date.day;
        final month = months[date.month - 1];
        final year = date.year;
        final weekday = weekdays[date.weekday % 7];
        final hour = date.hour.toString().padLeft(2, '0');
        final minute = date.minute.toString().padLeft(2, '0');
        
        return '$day $month $year $weekday, saat $hour:$minute';
      }
    } catch (e) {
      // Parse error - fallback to original
    }
    
    return dateString;
  }

  /// Build plain text version for email clients that don't support HTML
  static String buildReplyPlainText({
    required String userReplyText,
    required MailDetail originalMail,
  }) {
    final quoteDivider = _buildQuoteDivider(originalMail)
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>');
    
    final originalText = originalMail.safeTextContent;
    
    return '''$userReplyText

$quoteDivider

$originalText''';
  }

  /// Validate inputs before building HTML
  static bool canBuildReply({
    required String userReplyText,
    required MailDetail originalMail,
  }) {
    // User must have written something
    if (userReplyText.trim().isEmpty) {
      return false;
    }
    
    // Original mail must have basic info
    if (originalMail.senderEmail.isEmpty || originalMail.subject.isEmpty) {
      return false;
    }
    
    return true;
  }

  /// Get estimated HTML size in bytes
  static int getEstimatedHtmlSize({
    required String userReplyText,
    required MailDetail originalMail,
  }) {
    if (!canBuildReply(userReplyText: userReplyText, originalMail: originalMail)) {
      return 0;
    }
    
    final html = buildReplyHtml(
      userReplyText: userReplyText,
      originalMail: originalMail,
    );
    
    return html.length;
  }
}