// lib/src/features/mail/presentation/widgets/web/preview/mail_renderer_stub.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/entities/mail_detail.dart';
import '../../../../domain/repositories/mail_repository.dart';
import 'mail_renderer.dart';

/// Stub implementation for non-web platforms (mobile/desktop)
/// Provides simple text-only fallback without any web dependencies
class MailWebRenderer implements MailRenderer {
  @override
  final ScrollController scrollController;
  
  @override
  final ValueChanged<double>? onHeightChanged;
  
  // ✅ NEW: Additional parameters from usage in mail_page_detail_web.dart
  final MailRepository repository;
  final String userEmail;
  final WidgetRef? ref; // YENİ ALAN

  MailWebRenderer({
    required this.scrollController,
    required this.repository,        // ✅ Required parameter
    required this.userEmail,         // ✅ Required parameter
    this.onHeightChanged,
    this.ref, // YENİ PARAMETRE
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

  // ✅ EKSİK OLAN METOD - mobile/desktop için basit fallback
  Widget buildRenderedHtmlSection(MailDetail mailDetail) {
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