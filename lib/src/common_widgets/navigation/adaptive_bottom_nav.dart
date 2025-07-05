/// Mobil Alt Navigasyon Bileşeni
///
/// Bu dosya mobil cihazlar için alt navigasyon çubuğunu sağlar.
/// Material 3 tasarım kılavuzuna uygun olarak küçük ekranlar için
/// optimize edilmiş erişilebilir navigasyon deneyimi sunar.
///
/// 🔌 Plugin System + Static Items Integration:
/// - Statik navigation items (Modules, Settings, Profile)
/// - Plugin-aware navigation logic
/// - Material 3 NavigationBar implementation
///
/// Sorumlulukları:
/// - Mobil platformunda ana navigasyon sağlamak
/// - Statik items ile tutarlı UX sunmak
/// - Plugin ve statik sayfalar arası geçiş
/// - Thumb-friendly navigation sunmak
/// - Material 3 NavigationBar widget'ını kullanmak
/// - Icon + label kombinasyonu göstermek
/// - Safe area'yı dikkate almak
///
/// Tasarım Özellikleri:
/// - Material 3 NavigationBar
/// - Icon + label design
/// - Primary color selection
/// - Surface elevation
/// - Safe area handling
/// - Static item management
library;

import 'package:flutter/material.dart' as widgets;
import 'package:flutter/material.dart';
import 'navigation_models.dart';
import '../../utils/app_logger.dart';
import '../../core/plugin_system/plugin_registry.dart';

/// Mobil alt navigasyon widget'ı - Plugin + Static items destekli
class AdaptiveBottomNav extends StatelessWidget {
  /// Plugin navigation için yeni API
  final String? selectedPluginId;
  final ValueChanged<String>? onPluginSelected;

  /// Legacy support için eski API
  final int? selectedIndex;
  final List<AppNavigationDestination>? destinations;
  final ValueChanged<int>? onDestinationSelected;

  /// Statik items kullanılsın mı? (default: true)
  final bool useStaticItems;

  const AdaptiveBottomNav({
    super.key,
    // Plugin API
    this.selectedPluginId,
    this.onPluginSelected,
    // Legacy API
    this.selectedIndex,
    this.destinations,
    this.onDestinationSelected,
    // Options
    this.useStaticItems = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Statik items kullanılacaksa yeni API, yoksa legacy
    if (useStaticItems && onPluginSelected != null) {
      return _buildStaticNavigationBar(context, theme);
    } else {
      return _buildLegacyNavigationBar(context, theme);
    }
  }

  /// 🔌 Statik items ile NavigationBar
  Widget _buildStaticNavigationBar(BuildContext context, ThemeData theme) {
    // Statik navigation items
    final staticItems = [
      {'id': 'modules', 'icon': Icons.apps, 'label': 'Modules'},
      {'id': 'settings', 'icon': Icons.settings, 'label': 'Settings'},
      {'id': 'profile', 'icon': Icons.person, 'label': 'Profile'},
    ];

    // Şu anki seçim durumunu belirle
    int selectedIndex = 0; // Default: Modules
    if (selectedPluginId == 'settings') {
      selectedIndex = 1;
    } else if (selectedPluginId == 'profile') {
      selectedIndex = 2;
    }
    // Plugin seçiliyse 0 (Modules) olarak kalır

    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: (index) => _onStaticDestinationSelected(index),
      backgroundColor: theme.colorScheme.surface,
      surfaceTintColor: theme.colorScheme.surfaceTint,
      elevation: 3,
      height: 80,
      destinations: staticItems.map((item) {
        return widgets.NavigationDestination(
          icon: _buildIcon(item['icon'] as IconData, isSelected: false),
          selectedIcon: _buildIcon(item['icon'] as IconData, isSelected: true),
          label: item['label'] as String,
          tooltip: item['label'] as String,
        );
      }).toList(),
      animationDuration: const Duration(milliseconds: 300),
    );
  }

  /// Legacy NavigationBar (backward compatibility)
  Widget _buildLegacyNavigationBar(BuildContext context, ThemeData theme) {
    if (destinations == null || selectedIndex == null) {
      return const SizedBox.shrink();
    }

    return NavigationBar(
      selectedIndex: selectedIndex!,
      onDestinationSelected: _onLegacyDestinationSelected,
      backgroundColor: theme.colorScheme.surface,
      surfaceTintColor: theme.colorScheme.surfaceTint,
      elevation: 3,
      height: 80,
      destinations: _buildLegacyNavigationDestinations(),
      animationDuration: const Duration(milliseconds: 300),
    );
  }

  /// 🔌 Statik navigation seçim handler'ı
  void _onStaticDestinationSelected(int index) {
    switch (index) {
      case 0: // Modules
        AppLogger.debug('BottomNav: Modules selected');
        // İlk aktif plugin'e geç
        final activePlugins = PluginRegistry.activePlugins;
        if (activePlugins.isNotEmpty) {
          onPluginSelected?.call(activePlugins.first.id);
        } else {
          onPluginSelected?.call('modules');
        }
        break;
      case 1: // Settings
        AppLogger.debug('BottomNav: Settings selected');
        onPluginSelected?.call('settings');
        break;
      case 2: // Profile
        AppLogger.debug('BottomNav: Profile selected');
        onPluginSelected?.call('profile');
        break;
    }
  }

  /// Legacy navigasyon öğesi seçim handler'ı
  void _onLegacyDestinationSelected(int index) {
    if (destinations != null && index < destinations!.length) {
      final destination = destinations![index];
      AppLogger.debug(
        'BottomNav navigation: ${destination.label} (index: $index)',
      );
      onDestinationSelected?.call(index);
    }
  }

  /// Legacy NavigationBar için destination'ları dönüştür
  List<Widget> _buildLegacyNavigationDestinations() {
    if (destinations == null) return [];

    return destinations!.map((destination) {
      return widgets.NavigationDestination(
        icon: _buildIcon(destination.icon, isSelected: false),
        selectedIcon: _buildIcon(destination.icon, isSelected: true),
        label: destination.label,
        tooltip: destination.label,
      );
    }).toList();
  }

  /// Icon builder - Material 3 style
  Widget _buildIcon(IconData iconData, {required bool isSelected}) {
    return Container(
      padding: const EdgeInsets.all(2),
      child: Icon(
        iconData,
        size: isSelected ? 26 : 24,
        fill: isSelected ? 1.0 : 0.0, // Material 3 filled/outlined
      ),
    );
  }
}

// ========================
// CONVENIENCE CONSTRUCTORS
// ========================

/// Plugin sistemini kullanmak için kolaylık constructor'ı
class StaticBottomNav extends AdaptiveBottomNav {
  const StaticBottomNav({
    super.key,
    required super.selectedPluginId,
    required super.onPluginSelected,
  }) : super(useStaticItems: true);
}

/// Legacy sistemi kullanmak için kolaylık constructor'ı
class LegacyBottomNav extends AdaptiveBottomNav {
  const LegacyBottomNav({
    super.key,
    required int super.selectedIndex,
    required List<AppNavigationDestination> super.destinations,
    required super.onDestinationSelected,
  }) : super(useStaticItems: false);
}

// ========================
// ALTERNATIVE IMPLEMENTATIONS
// ========================

/// Material 2 style BottomNavigationBar Implementation
/// (Alternatif olarak - eski style tercih edilirse)
class Material2BottomNav extends StatelessWidget {
  final String? selectedPluginId;
  final ValueChanged<String>? onPluginSelected;

  const Material2BottomNav({
    super.key,
    required this.selectedPluginId,
    required this.onPluginSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Statik navigation items
    final staticItems = [
      {'id': 'modules', 'icon': Icons.apps, 'label': 'Modules'},
      {'id': 'settings', 'icon': Icons.settings, 'label': 'Settings'},
      {'id': 'profile', 'icon': Icons.person, 'label': 'Profile'},
    ];

    // Şu anki seçim durumunu belirle
    int selectedIndex = 0;
    if (selectedPluginId == 'settings') {
      selectedIndex = 1;
    } else if (selectedPluginId == 'profile') {
      selectedIndex = 2;
    }

    return BottomNavigationBar(
      currentIndex: selectedIndex,
      onTap: (index) {
        switch (index) {
          case 0:
            final activePlugins = PluginRegistry.activePlugins;
            if (activePlugins.isNotEmpty) {
              onPluginSelected?.call(activePlugins.first.id);
            }
            break;
          case 1:
            onPluginSelected?.call('settings');
            break;
          case 2:
            onPluginSelected?.call('profile');
            break;
        }
      },
      type: BottomNavigationBarType.fixed,
      backgroundColor: theme.colorScheme.surface,
      selectedItemColor: theme.colorScheme.primary,
      unselectedItemColor: theme.colorScheme.onSurface.withValues(alpha: 0.6),
      selectedLabelStyle: theme.textTheme.labelSmall?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: theme.textTheme.labelSmall,
      elevation: 8,
      items: staticItems.map((item) {
        return BottomNavigationBarItem(
          icon: Icon(item['icon'] as IconData),
          activeIcon: Icon(item['icon'] as IconData, fill: 1.0),
          label: item['label'] as String,
          tooltip: item['label'] as String,
        );
      }).toList(),
    );
  }
}

/// Adaptive Bottom Navigation Wrapper
/// Material 3 varsa NavigationBar, yoksa BottomNavigationBar kullan
class SmartBottomNav extends StatelessWidget {
  final String? selectedPluginId;
  final ValueChanged<String>? onPluginSelected;
  final bool useMaterial3;

  const SmartBottomNav({
    super.key,
    required this.selectedPluginId,
    required this.onPluginSelected,
    this.useMaterial3 = true,
  });

  @override
  Widget build(BuildContext context) {
    if (useMaterial3) {
      return StaticBottomNav(
        selectedPluginId: selectedPluginId,
        onPluginSelected: onPluginSelected,
      );
    } else {
      return Material2BottomNav(
        selectedPluginId: selectedPluginId,
        onPluginSelected: onPluginSelected,
      );
    }
  }
}
