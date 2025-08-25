// lib/src/features/mail/presentation/widgets/common/chips/selectable_recipient_chip.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'chip_theme.dart';

/// Modüler seçilebilir recipient chip widget'ı
/// 
/// Özellikler:
/// - RecipientChipTheme ile özelleştirilebilir görünüm
/// - Optional onRemoved callback (null ise X button yok)
/// - Optional tooltipBuilder (null ise tooltip yok)
/// - Hover effects ve overlay tooltip sistemi
/// - Farklı kullanım senaryoları için optimize edilmiş
class SelectableRecipientChip extends StatefulWidget {
  /// Gösterilecek isim
  final String name;
  
  /// Chip'in görünüm teması
  final RecipientChipTheme chipTheme;
  
  /// Text stili (tema rengini override edebilir)
  final TextStyle? textStyle;
  
  /// Tooltip widget builder (null ise tooltip gösterilmez)
  final Widget Function(String name)? tooltipBuilder;
  
  /// Remove callback (null ise X button gösterilmez)
  final VoidCallback? onRemoved;

  const SelectableRecipientChip({
    super.key,
    required this.name,
    required this.chipTheme,
    this.textStyle,
    this.tooltipBuilder,
    this.onRemoved,
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
    // Eğer tooltipBuilder null ise tooltip gösterme
    if (widget.tooltipBuilder == null) return;
    
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
                child: widget.tooltipBuilder!(widget.name),
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
    // Text stili - önce widget'tan gelen, sonra tema'dan gelen
    final effectiveTextStyle = widget.textStyle ?? TextStyle(
      color: widget.chipTheme.textColor,
      fontSize: 14,
      fontWeight: FontWeight.w500,
    );

    // Hover durumuna göre renkler
    final backgroundColor = _isHovered && widget.chipTheme.hoverBackgroundColor != null
        ? widget.chipTheme.hoverBackgroundColor!
        : widget.chipTheme.backgroundColor;
        
    final borderColor = _isHovered && widget.chipTheme.hoverBorderColor != null
        ? widget.chipTheme.hoverBorderColor!
        : widget.chipTheme.borderColor;

    return CompositedTransformTarget(
      link: _layerLink,
      child: MouseRegion(
        key: _chipKey,
        onEnter: (_) {
          setState(() => _isHovered = true);
          _cancelClose();
          _showTooltip();
        },
        onExit: (_) {
          setState(() => _isHovered = false);
          _scheduleClose();
        },
        child: Container(
          padding: widget.chipTheme.padding,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(widget.chipTheme.borderRadius),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // İsim metni
              Text(
                widget.name,
                style: effectiveTextStyle,
              ),
              
              // Remove button (sadece onRemoved varsa göster)
              if (widget.onRemoved != null) ...[
                const SizedBox(width: 4),
                InkWell(
                  onTap: widget.onRemoved,
                  borderRadius: BorderRadius.circular(6), // Daire şeklinde hover area
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: widget.chipTheme.removeIconColor ?? widget.chipTheme.textColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close,
                      size: 12,
                      color: Colors.white, // İç ikon beyaz/açık gri
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}