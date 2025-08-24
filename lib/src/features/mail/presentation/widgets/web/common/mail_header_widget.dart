// lib/src/features/mail/presentation/widgets/common/mail_header_widget.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../domain/entities/mail_detail.dart';
import 'recipient_tooltip_widget.dart';

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

  /// Recipient chip'lerini oluştur
  List<Widget> _buildRecipientChips(BuildContext context, List<String> names) {
    final widgets = <Widget>[];
    for (int i = 0; i < names.length; i++) {
      widgets.add(SelectableRecipientChip(
        name: names[i],
        textStyle: valueStyle ??
            TextStyle(
              color: Colors.grey.shade800,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
      ));
      if (i < names.length - 1) {
        widgets.add(Text(
          ', ',
          style: valueStyle ??
              TextStyle(
                color: Colors.grey.shade800,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
        ));
      }
    }
    return widgets;
  }
}

/// Seçilebilir recipient chip widget'ı
class SelectableRecipientChip extends StatefulWidget {
  final String name;
  final TextStyle? textStyle;

  const SelectableRecipientChip({
    super.key,
    required this.name,
    this.textStyle,
  });

  @override
  State<SelectableRecipientChip> createState() => _SelectableRecipientChipState();
}

class _SelectableRecipientChipState extends State<SelectableRecipientChip> {
  bool _isHovered = false;
  OverlayEntry? _overlayEntry;

  // CompositedTransform için
  final LayerLink _layerLink = LayerLink();
  final GlobalKey _chipKey = GlobalKey();

  // Hover-köprüsü için
  bool _isTooltipHovered = false;
  Timer? _closeTimer;

  @override
  void dispose() {
    _closeTimer?.cancel();
    _removeOverlay();
    super.dispose();
  }

  // --- Hover-köprüsü yardımcıları ---
  void _scheduleClose() {
    _closeTimer?.cancel();
    _closeTimer = Timer(const Duration(milliseconds: 200), () {
      if (!_isTooltipHovered) _removeOverlay();
    });
  }

  void _cancelClose() {
    _closeTimer?.cancel();
  }

  void _showTooltip() {
    _removeOverlay();
    final ctx = _chipKey.currentContext;
    if (ctx == null) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => CompositedTransformFollower(
        link: _layerLink,
        showWhenUnlinked: false,

        // CHIP sol-alt ↔ TOOLTIP sol-üst
        targetAnchor: Alignment.bottomLeft,
        followerAnchor: Alignment.topLeft,
        offset: const Offset(0, 4), // chip'in altından 4px

        // genişlemeyi engelle
        child: UnconstrainedBox(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 250,
            child: Material(
              type: MaterialType.transparency,
              child: MouseRegion(
                onEnter: (_) {
                  _isTooltipHovered = true;
                  _cancelClose();          // tooltip'e girildi → kapanışı iptal et
                },
                onExit: (_) {
                  _isTooltipHovered = false;
                  _scheduleClose();        // tooltip'ten çıkıldı → gecikmeli kapat
                },
                child: RecipientTooltipWidget(
                  name: widget.name,
                  email: null,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context, rootOverlay: true).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: MouseRegion(
        onEnter: (_) {
          _cancelClose();                 // planlı kapanışı iptal et
          setState(() => _isHovered = true);
          _showTooltip();
        },
        onExit: (_) {
          setState(() => _isHovered = false);
          _scheduleClose();               // hemen kapatma, kısa gecikme ver
        },
        child: Container(
          key: _chipKey,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _isHovered ? Colors.blue.shade100 : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isHovered ? Colors.blue.shade300 : Colors.grey.shade300,
              width: 1,
            ),
          ),
          child: SelectableText(
            widget.name,
            style: widget.textStyle?.copyWith(
              color: _isHovered ? Colors.blue.shade700 : widget.textStyle?.color,
            ),
          ),
        ),
      ),
    );
  }
}

/// Mail time formatter utility
class MailTimeFormatter {
  static String formatFullDate(DateTime dateTime) {
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