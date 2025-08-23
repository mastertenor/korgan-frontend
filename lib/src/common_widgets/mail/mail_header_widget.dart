// lib/src/features/mail/presentation/widgets/common/mail_header_widget.dart

import 'package:flutter/material.dart';
import '../../features/mail/domain/entities/mail_detail.dart';

/// Ortak Mail Header Widget'ı
class MailHeaderWidget extends StatelessWidget {
  final MailDetail mailDetail;

  /// Styling options
  final EdgeInsetsGeometry? padding;
  final BoxDecoration? decoration;
  final TextStyle? subjectStyle;
  final TextStyle? labelStyle;
  final TextStyle? valueStyle;

  const MailHeaderWidget({
    super.key,
    required this.mailDetail,
    this.padding,
    this.decoration,
    this.subjectStyle,
    this.labelStyle,
    this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: decoration ??
          BoxDecoration(
            color: Colors.grey.shade50,
            border: Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(8),
          ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subject
          _buildSubject(context),
          const SizedBox(height: 12),

          // From section
          _buildFromSection(context),

          // To section
          _buildToSection(context),

          // CC section (only if ccRecipientNames is not empty)
          if (mailDetail.ccRecipientNames.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildCcSection(context),
          ],

          // Date section
          const SizedBox(height: 8),
          _buildDateSection(context),
        ],
      ),
    );
  }

  /// Subject başlığı
  Widget _buildSubject(BuildContext context) {
    return Text(
      mailDetail.subject.isEmpty ? '(Konu yok)' : mailDetail.subject,
      style: subjectStyle ??
          const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
    );
  }

  /// Gönderen bölümü
  Widget _buildFromSection(BuildContext context) {
    return _buildInfoRow(
      context,
      label: 'Gönderen',
      displayText: mailDetail.senderName,
    );
  }

  /// Alıcı bölümü — sadece modeldeki isimleri kullanır
  Widget _buildToSection(BuildContext context) {
    final recipientText = _getFormattedRecipients();
    return _buildInfoRow(
      context,
      label: 'Alıcı',
      displayText: recipientText,
    );
  }

  /// CC bölümü — sadece modeldeki isimleri kullanır
  Widget _buildCcSection(BuildContext context) {
    final ccText = _getFormattedCcRecipients();
    return _buildInfoRow(
      context,
      label: 'Cc',
      displayText: ccText,
    );
  }

  /// Tarih bölümü
  Widget _buildDateSection(BuildContext context) {
    // receivedDate varsa onu kullan, yoksa mevcut saat (fallback)
    final displayDate = mailDetail.receivedDate ?? DateTime.now();
    final formattedDate = MailTimeFormatter.formatFullDate(displayDate);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 70,
          child: Text(
            'Tarih',
            style: labelStyle ??
                TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ),
        Expanded(
          child: Text(
            formattedDate,
            style: valueStyle ??
                TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 13,
                ),
          ),
        ),
      ],
    );
  }

  // ------- SADELEŞTİRİLMİŞ METİN ÜRETİCİLERİ (yalnızca model verisi) -------

  /// Alıcı listesini formatla (yalnızca MailDetail.recipientNames)
String _getFormattedRecipients() {
  final names = mailDetail.recipientNames;
  if (names.isEmpty) return '(Bilinmiyor)';
  // Tüm isimleri virgülle yaz
  return names.join(', ');
}

  /// CC listesini formatla (yalnızca MailDetail.ccRecipientNames)
String _getFormattedCcRecipients() {
  final names = mailDetail.ccRecipientNames;
  if (names.isEmpty) return '';
  return names.join(', ');
}
  /// Bilgi satırı builder (Gönderen, Alıcı, CC için ortak)
  Widget _buildInfoRow(
    BuildContext context, {
    required String label,
    required String displayText,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: labelStyle ??
                TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ),
        Expanded(
          child: Text(
            displayText.isEmpty ? '(Bilinmiyor)' : displayText,
            style: valueStyle ??
                TextStyle(
                  color: Colors.grey.shade800,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ),
      ],
    );
  }
}

/// Mail time formatter utility
class MailTimeFormatter {
  static String formatFullDate(DateTime dateTime) {
    // Türkçe tarih formatı: "23 Ağustos 2025, 14:30"
    const months = [
      'Ocak',
      'Şubat',
      'Mart',
      'Nisan',
      'Mayıs',
      'Haziran',
      'Temmuz',
      'Ağustos',
      'Eylül',
      'Ekim',
      'Kasım',
      'Aralık'
    ];

    final day = dateTime.day.toString();
    final month = months[dateTime.month - 1];
    final year = dateTime.year.toString();
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');

    return '$day $month $year, $hour:$minute';
  }
}
