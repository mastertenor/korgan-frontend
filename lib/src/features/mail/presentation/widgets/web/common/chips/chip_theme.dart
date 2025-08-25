// lib/src/common_widgets/chips/chip_theme.dart

import 'package:flutter/material.dart';

/// Recipient chip'lerin görünümünü yöneten tema sınıfı
/// 
/// Farklı kullanım yerlerinde farklı renk ve stil kombinasyonları
/// sağlamak için factory constructors içerir.
class RecipientChipTheme {
  /// Chip'in arka plan rengi
  final Color backgroundColor;
  
  /// Chip'in border rengi
  final Color borderColor;
  
  /// Chip içindeki text rengi
  final Color textColor;
  
  /// Hover durumunda arka plan rengi (optional)
  final Color? hoverBackgroundColor;
  
  /// Hover durumunda border rengi (optional) 
  final Color? hoverBorderColor;
  
  /// Chip'in border radius değeri
  final double borderRadius;
  
  /// Chip içindeki padding
  final EdgeInsets padding;
  
  /// Remove icon rengi (compose modunda kullanılır)
  final Color? removeIconColor;
  
  /// Remove icon hover rengi
  final Color? removeIconHoverColor;

  const RecipientChipTheme({
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
    this.hoverBackgroundColor,
    this.hoverBorderColor,
    required this.borderRadius,
    required this.padding,
    this.removeIconColor,
    this.removeIconHoverColor,
  });

  /// Mail header widget'ında kullanılan tema
  /// 
  /// Özellikleri:
  /// - Normal: Gri background + gri text
  /// - Hover: Mavi background + mavi text
  /// - Remove button yok
  factory RecipientChipTheme.mailHeader() {
    return RecipientChipTheme(
      backgroundColor: Colors.grey.shade100,
      borderColor: Colors.grey.shade300,
      textColor: Colors.grey.shade800,
      hoverBackgroundColor: Colors.blue.shade100,
      hoverBorderColor: Colors.blue.shade300,
      borderRadius: 16.0,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }

  /// Compose recipients widget'ında kullanılan tema
  /// 
  /// Özellikleri:
  /// - Normal: Açık sarı background + altın sarısı border + siyah text
  /// - Hover: Daha koyu sarı background + altın sarısı border + siyah text
  /// - Remove button var
  factory RecipientChipTheme.compose() {
    return RecipientChipTheme(
      backgroundColor: const Color(0xFFFFF8DC),     // Pasif: çok açık sarı (cornsilk)
      borderColor: const Color(0xFFFFD700),         // Her ikisinde de altın sarısı border
      textColor: const Color(0xFF000000),           // Siyah text
      hoverBackgroundColor: const Color(0xFFFFEEA9), // Aktif: açık sarı
      hoverBorderColor: const Color(0xFFFFD700),     // Aktif'te de altın sarısı border
      borderRadius: 10.0,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      removeIconColor: const Color(0xFF333333),      // Siyah remove icon
      removeIconHoverColor: const Color(0xFF333333), // Hover'da biraz açık siyah
    );
  }

  /// Tema kopyalama ve değiştirme için copyWith methodu
  RecipientChipTheme copyWith({
    Color? backgroundColor,
    Color? borderColor,
    Color? textColor,
    Color? hoverBackgroundColor,
    Color? hoverBorderColor,
    double? borderRadius,
    EdgeInsets? padding,
    Color? removeIconColor,
    Color? removeIconHoverColor,
  }) {
    return RecipientChipTheme(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      borderColor: borderColor ?? this.borderColor,
      textColor: textColor ?? this.textColor,
      hoverBackgroundColor: hoverBackgroundColor ?? this.hoverBackgroundColor,
      hoverBorderColor: hoverBorderColor ?? this.hoverBorderColor,
      borderRadius: borderRadius ?? this.borderRadius,
      padding: padding ?? this.padding,
      removeIconColor: removeIconColor ?? this.removeIconColor,
      removeIconHoverColor: removeIconHoverColor ?? this.removeIconHoverColor,
    );
  }

  /// Debug için toString
  @override
  String toString() {
    return 'RecipientChipTheme(backgroundColor: $backgroundColor, borderColor: $borderColor, textColor: $textColor)';
  }
}