/// Navigasyon Model Sınıfları
///
/// Bu dosya navigasyon bileşenleri için ortak model sınıflarını içerir.
/// Tüm navigation widget'ları tarafından paylaşılan veri yapılarını
/// merkezi bir yerde tanımlar.
///
/// Sorumlulukları:
/// - AppNavigationDestination model sınıfını tanımlamak
/// - Navigasyon öğeleri için ortak veri yapısı sağlamak
/// - Type consistency sağlamak
/// - Merkezi model yönetimi
library;

import 'package:flutter/material.dart';

/// Uygulama navigasyon hedef noktası model sınıfı
///
/// Bir navigasyon öğesini tanımlayan temel veri yapısı.
/// Tüm navigation bileşenleri (sidebar, rail, bottom nav) tarafından kullanılır.
///
/// Not: Flutter'ın built-in NavigationDestination widget'ı ile karışmasın diye
/// AppNavigationDestination olarak adlandırıldı.
class AppNavigationDestination {
  /// Navigasyon öğesinin ikonu
  final IconData icon;

  /// Navigasyon öğesinin metinsel etiketi
  final String label;

  /// Opsiyonel tooltip metni (varsayılan olarak label kullanılır)
  final String? tooltip;

  /// Opsiyonel badge/bildirim sayısı
  final int? badgeCount;

  /// Navigasyon öğesinin aktif/pasif durumu
  final bool enabled;

  const AppNavigationDestination({
    required this.icon,
    required this.label,
    this.tooltip,
    this.badgeCount,
    this.enabled = true,
  });

  /// Tooltip metnini döndürür (yoksa label kullanır)
  String get effectiveTooltip => tooltip ?? label;

  /// Badge gösterilmeli mi kontrolü
  bool get hasBadge => badgeCount != null && badgeCount! > 0;

  /// Debugging için string representation
  @override
  String toString() {
    return 'AppNavigationDestination(icon: $icon, label: $label, enabled: $enabled)';
  }

  /// Equality comparison
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppNavigationDestination &&
        other.icon == icon &&
        other.label == label &&
        other.tooltip == tooltip &&
        other.badgeCount == badgeCount &&
        other.enabled == enabled;
  }

  @override
  int get hashCode {
    return Object.hash(icon, label, tooltip, badgeCount, enabled);
  }

  /// Copy with method - immutable updates için
  AppNavigationDestination copyWith({
    IconData? icon,
    String? label,
    String? tooltip,
    int? badgeCount,
    bool? enabled,
  }) {
    return AppNavigationDestination(
      icon: icon ?? this.icon,
      label: label ?? this.label,
      tooltip: tooltip ?? this.tooltip,
      badgeCount: badgeCount ?? this.badgeCount,
      enabled: enabled ?? this.enabled,
    );
  }
}
