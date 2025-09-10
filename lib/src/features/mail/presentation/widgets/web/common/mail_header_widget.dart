// lib/src/features/mail/presentation/widgets/common/mail_header_widget.dart
import 'package:flutter/material.dart';
import '../../../../domain/entities/mail_detail.dart';
import 'recipient_tooltip_widget.dart';
import 'chips/selectable_recipient_chip.dart';
import 'chips/chip_theme.dart';

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
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade200),
            ),            
          ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subject ve Tarih (aynı satırda)
          _buildSubjectWithDate(context),
          const SizedBox(height: 12),

          // From section
          _buildFromSection(context),
          const SizedBox(height: 8),

          // To section
          _buildToSection(context),

          // CC section (only if ccRecipientNames is not empty)
          if (mailDetail.ccRecipientNames.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildCcSection(context),
          ],
        ],
      ),
    );
  }

  /// Subject başlığı ve tarih (aynı satırda)
  Widget _buildSubjectWithDate(BuildContext context) {
    final displayDate = mailDetail.receivedDate ?? DateTime.now();
    final formattedDate = MailTimeFormatter.formatFullDate(displayDate);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            mailDetail.subject.isEmpty ? '(Konu yok)' : mailDetail.subject,
            style: subjectStyle ??
                const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        const SizedBox(width: 16),
        Text(
          formattedDate,
          style: valueStyle ??
              TextStyle(
                color: Colors.grey.shade700,
                fontSize: 13,
              ),
        ),
      ],
    );
  }

  /// Gönderen bölümü
  Widget _buildFromSection(BuildContext context) {
    return _buildInfoRowWithChips(
      context,
      label: 'Gönderen',
      names: [mailDetail.senderName],
    );
  }

  /// Alıcı bölümü — seçilebilir chip'ler
  Widget _buildToSection(BuildContext context) {
    return _buildInfoRowWithChips(
      context,
      label: 'Alıcı',
      names: mailDetail.recipientNames,
    );
  }

  /// CC bölümü — seçilebilir chip'ler
  Widget _buildCcSection(BuildContext context) {
    return _buildInfoRowWithChips(
      context,
      label: 'Cc',
      names: mailDetail.ccRecipientNames,
    );
  }

  /// Chip'ler için bilgi satırı (Alıcı ve CC için) - HİZALAMA DÜZELTİLDİ
  Widget _buildInfoRowWithChips(
    BuildContext context, {
    required String label,
    required List<String> names,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center, // Orta hizalama eklendi
      children: [
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: labelStyle ??
                TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ),
        Expanded(
          child: names.isEmpty
              ? Text(
                  '(Bilinmiyor)',
                  style: valueStyle ??
                      TextStyle(
                        color: Colors.grey.shade800,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                )
              : Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center, // Wrap için orta hizalama
                  children: _buildRecipientChips(context, names),
                ),
        ),
      ],
    );
  }

  /// Recipient chip'lerini oluştur - YENİ MODÜLER WIDGET KULLANARAK
  List<Widget> _buildRecipientChips(BuildContext context, List<String> names) {
    final widgets = <Widget>[];
    for (int i = 0; i < names.length; i++) {
      widgets.add(SelectableRecipientChip(
        name: names[i],
        chipTheme: RecipientChipTheme.mailHeader(),
        textStyle: valueStyle ??
            TextStyle(
              color: Colors.grey.shade800,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
        tooltipBuilder: (name) => RecipientTooltipWidget(
          name: name,
          email: null,
        ),
        // onRemoved: null, // Mail header'da remove button yok
      ));
    }
    return widgets;
  }
}

/// Mail time formatter utility
class MailTimeFormatter {
  /// Mail detail header için tam tarih formatı
  /// Örnek: "23 Ağustos 2025 Cumartesi, 11:54"
  static String formatFullDate(DateTime dateTime) {
    // Yerel saate çevir
    final localDate = dateTime.toLocal();
    final now = DateTime.now();

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
      'Aralık',
    ];

    const weekdays = [
      'Pazartesi',
      'Salı',
      'Çarşamba',
      'Perşembe',
      'Cuma',
      'Cumartesi',
      'Pazar',
    ];

    final day = localDate.day;
    final month = months[localDate.month - 1];
    final year = localDate.year;
    final weekday = weekdays[localDate.weekday - 1];
    final hour = localDate.hour.toString().padLeft(2, '0');
    final minute = localDate.minute.toString().padLeft(2, '0');

    // Yıl kontrolü
    if (year == now.year) {
      // Bu yıl: "23 Ağustos Cumartesi, 11:54"
      return '$day $month $weekday, $hour:$minute';
    } else {
      // Farklı yıl: "23 Ağustos 2025 Cumartesi, 11:54"
      return '$day $month $year $weekday, $hour:$minute';
    }
  }
}