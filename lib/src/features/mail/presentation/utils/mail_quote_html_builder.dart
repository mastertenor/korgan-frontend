// lib/src/features/mail/presentation/widgets/web/compose/utils/mail_quote_html_builder.dart

import '../../domain/entities/mail_detail.dart';

/// Utility class for building HTML quote content from original mail
/// 
/// Creates Gmail-style quoted content for reply operations
class MailQuoteHtmlBuilder {
  
  /// Build complete quote HTML from original mail
  static String buildQuoteHtml(MailDetail originalMail) {
    final quoteHeader = _formatQuoteHeader(originalMail);
    final quoteContent = _prepareQuoteContent(originalMail);
    
    return '''
<div style="margin-top: 20px;">
  <div class="gmail_quote">
    <div style="margin-bottom: 10px; color: #666; font-size: 13px;">
      $quoteHeader
    </div>
    <blockquote style="margin:0 0 0 .8ex;border-left:1px #ccc solid;padding-left:1ex;color:#666;">
      $quoteContent
    </blockquote>
  </div>
</div>''';
  }

  /// Build simple quote content without wrapper (for minimal display)
  static String buildSimpleQuote(MailDetail originalMail) {
    final quoteContent = _prepareQuoteContent(originalMail);
    
    return '''
<blockquote style="margin:0 0 0 .8ex;border-left:1px #ccc solid;padding-left:1ex;color:#666;">
  $quoteContent
</blockquote>''';
  }

  /// Format quote header (From, Date, Subject info)
  static String _formatQuoteHeader(MailDetail originalMail) {
    final from = originalMail.formattedSender; // Using existing getter
    final date = _formatDate(originalMail.receivedDate ?? DateTime.parse(originalMail.time));
    final subject = originalMail.subject;
    
    return '''
On $date, $from wrote:<br>
<strong>Subject:</strong> $subject
''';
  }

  /// Prepare quote content from original mail
  static String _prepareQuoteContent(MailDetail originalMail) {
    String content;
    
    // Prefer HTML content if available
    if (originalMail.htmlContent.isNotEmpty) {
      content = originalMail.htmlContent;
    } else if (originalMail.textContent.isNotEmpty) {
      content = _textToHtml(originalMail.textContent);
    } else if (originalMail.content.isNotEmpty) {
      content = _textToHtml(originalMail.content);
    } else {
      content = '<p><em>Orijinal mesaj içeriği bulunamadı</em></p>';
    }
    
    // Clean and sanitize content for quote
    return _sanitizeQuoteContent(content);
  }

  /// Convert plain text to HTML with proper formatting
  static String _textToHtml(String plainText) {
    if (plainText.isEmpty) return '';
    
    return plainText
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('\n\n', '</p><p>')
        .replaceAll('\n', '<br>')
        .replaceAll(RegExp(r'^'), '<p>')
        .replaceAll(RegExp(r'$'), '</p>');
  }

  /// Sanitize quote content to prevent formatting issues
  static String _sanitizeQuoteContent(String htmlContent) {
    if (htmlContent.isEmpty) return '';
    
    // Remove any existing quote blocks to prevent nested quotes
    String cleaned = htmlContent.replaceAll(
      RegExp(r'<blockquote[^>]*>.*?</blockquote>', dotAll: true),
      '<p><em>[Quoted text removed]</em></p>'
    );
    
    // Remove script tags for security
    cleaned = cleaned.replaceAll(
      RegExp(r'<script[^>]*>.*?</script>', dotAll: true),
      ''
    );
    
    // Remove style tags that might conflict
    cleaned = cleaned.replaceAll(
      RegExp(r'<style[^>]*>.*?</style>', dotAll: true),
      ''
    );
    
    // Clean up extra whitespace
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
    
    return cleaned;
  }

  /// Format date for quote header
  static String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    
    final month = months[date.month - 1];
    final day = date.day;
    final year = date.year;
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    
    return '$month $day, $year at $hour:$minute';
  }

  /// Extract recipient names for quote header
  static String _formatRecipients(List<String> recipients) {
    if (recipients.isEmpty) return '';
    
    if (recipients.length == 1) {
      return recipients.first;
    }
    
    final names = recipients.take(3).join(', ');
    
    if (recipients.length > 3) {
      return '$names and ${recipients.length - 3} others';
    }
    
    return names;
  }

  /// Build extended quote header with all recipients (for reply-all)
  static String buildExtendedQuoteHeader(MailDetail originalMail) {
    final from = originalMail.formattedSender;
    final date = _formatDate(originalMail.receivedDate ?? DateTime.parse(originalMail.time));
    final subject = originalMail.subject;
    final to = _formatRecipients(originalMail.recipients);
    final cc = _formatRecipients(originalMail.ccRecipients);
    
    String header = '''
On $date, $from wrote:<br>
<strong>Subject:</strong> $subject<br>
<strong>To:</strong> $to''';
    
    if (cc.isNotEmpty) {
      header += '<br><strong>CC:</strong> $cc';
    }
    
    return header;
  }

  /// Build quote HTML with extended header (for reply-all scenarios)
  static String buildExtendedQuoteHtml(MailDetail originalMail) {
    final quoteHeader = buildExtendedQuoteHeader(originalMail);
    final quoteContent = _prepareQuoteContent(originalMail);
    
    return '''
<div style="margin-top: 20px;">
  <div class="gmail_quote">
    <div style="margin-bottom: 10px; color: #666; font-size: 13px;">
      $quoteHeader
    </div>
    <blockquote style="margin:0 0 0 .8ex;border-left:1px #ccc solid;padding-left:1ex;color:#666;">
      $quoteContent
    </blockquote>
  </div>
</div>''';
  }
}