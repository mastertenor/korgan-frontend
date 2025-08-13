// lib/src/features/mail/presentation/widgets/web/toolbar/toolbar_buttons/select_all_checkbox.dart

import 'package:flutter/material.dart';

/// Gmail-style select all checkbox
///
/// This checkbox supports three states:
/// - Unchecked: No mails selected
/// - Indeterminate: Some mails selected (partial selection)
/// - Checked: All mails selected
class SelectAllCheckbox extends StatelessWidget {
  final bool isAllSelected;
  final bool isPartiallySelected;
  final int totalMailCount;
  final bool isLoading;
  final ValueChanged<bool?>? onChanged;

  const SelectAllCheckbox({
    super.key,
    required this.isAllSelected,
    required this.isPartiallySelected,
    required this.totalMailCount,
    required this.isLoading,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Determine checkbox state
    bool? checkboxValue;
    if (isAllSelected) {
      checkboxValue = true;
    } else if (isPartiallySelected) {
      checkboxValue = null; // Indeterminate state
    } else {
      checkboxValue = false;
    }

    return Tooltip(
      message: getTooltipMessage(),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 🔧 MailItemWeb ile aynı layout pattern
            SizedBox(
              width: 32, // ← MailItemWeb ile aynı width
              child: Transform.scale(
              scale: 0.8,
              child: Checkbox(
                value: checkboxValue,
                tristate: true,
                onChanged: isLoading || totalMailCount == 0 ? null : onChanged,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                // 🎨 Renk parametreleri eklendi
                activeColor: const Color(0xFF1976D2),  // Seçili durum rengi (mavi)
                checkColor: Colors.white,              // Checkmark rengi (beyaz)
                focusColor: const Color(0xFF1976D2).withOpacity(0.1),
              ),
            ),
            ),
          ],
        ),
      ),
    );
  }

  /// Get appropriate tooltip message based on state
  String getTooltipMessage() {
    if (isLoading) {
      return 'Yükleniyor...';
    }
        
    if (totalMailCount == 0) {
      return 'Seçilecek mail yok';
    }
        
    if (isAllSelected) {
      return 'Tüm seçimi kaldır';
    } else if (isPartiallySelected) {
      return 'Tümünü seç';
    } else {
      return 'Tüm mailleri seç ($totalMailCount mail)';
    }
  }
}