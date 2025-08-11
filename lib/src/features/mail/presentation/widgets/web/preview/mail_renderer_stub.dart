import 'package:flutter/material.dart';
import '../../../../domain/entities/mail_detail.dart';
import 'mail_renderer.dart';

/// Stub implementation for non-web platforms (mobile/desktop)
/// Provides simple text-only fallback without any web dependencies
class MailWebRenderer implements MailRenderer {
  @override
  final ScrollController scrollController;
  
  @override
  final ValueChanged<double>? onHeightChanged;

  MailWebRenderer({
    required this.scrollController,
    this.onHeightChanged,
  });

  @override
  void initialize() {
    // No-op for non-web platforms
  }

  @override
  void dispose() {
    // No-op for non-web platforms
  }

  @override
  double get iframeHeight => 400.0; // Fixed height for mobile

  @override
  Widget buildMailContent(BuildContext context, MailDetail mailDetail) {
    // Simple text-only implementation for mobile/desktop
    final textContent = mailDetail.textContent.isNotEmpty 
        ? mailDetail.textContent 
        : _stripHtmlTags(mailDetail.htmlContent);
        
    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      child: Container(
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
      ),
    );
  }

  /// Simple HTML tag stripper for mobile fallback
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
}