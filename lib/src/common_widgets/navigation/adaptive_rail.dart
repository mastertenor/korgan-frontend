/// Tablet Navigasyon Rayı Bileşeni
///
/// Bu dosya tablet cihazlar için sol navigasyon rayını (rail) sağlar.
/// Material 3 tasarım kılavuzuna uygun olarak orta boy ekranlar için
/// optimize edilmiş compact navigasyon deneyimi sunar.
///
/// 🔌 Plugin System Integration:
/// - Aktif plugin'leri otomatik olarak rail'de gösterir
/// - Plugin seçimine göre navigation callback'lerini yönetir
/// - Plugin icon ve label bilgilerini kullanır
///
/// Sorumlulukları:
/// - Tablet platformunda space-efficient navigasyon sağlamak
/// - Plugin'leri dinamik olarak listelemek
/// - Icon-based compact navigation sunmak
/// - Label'ları sadece seçili öğe için göstermek
/// - Material 3 NavigationRail widget'ını kullanmak
/// - Hover ve seçim durumlarını yönetmek
///
/// Tasarım Özellikleri:
/// - Compact 80px genişlik
/// - Icon-focused design
/// - Selected label display
/// - Material 3 styling
/// - Vertical layout
/// - Plugin-aware navigation
library;

import 'package:flutter/material.dart';
import 'navigation_models.dart';
import '../../utils/app_logger.dart';
import '../../core/plugin_system/plugin_registry.dart';

/// Tablet navigasyon rayı widget'ı
///
/// Artık plugin sistemine entegre olarak aktif plugin'leri
/// NavigationRail formatında gösterir.
class AdaptiveRail extends StatelessWidget {
  /// Şu anda seçili olan plugin'in id'si (yeni API)
  final String? selectedPluginId;

  /// Plugin seçildiğinde çağrılan callback (yeni API)
  final ValueChanged<String>? onPluginSelected;

  /// Legacy support için eski API
  final int? selectedIndex;
  final List<AppNavigationDestination>? destinations;
  final ValueChanged<int>? onDestinationSelected;

  const AdaptiveRail({
    super.key,
    this.selectedPluginId,
    this.onPluginSelected,
    // Legacy API support
    this.selectedIndex,
    this.destinations,
    this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Plugin sistemini kullan, legacy fall back
    final activePlugins = PluginRegistry.activePlugins;
    final usingPluginSystem =
        selectedPluginId != null || activePlugins.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          right: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: NavigationRail(
        selectedIndex: usingPluginSystem
            ? _getPluginSelectedIndex(activePlugins)
            : (selectedIndex ?? 0),
        onDestinationSelected: _onDestinationSelected,
        labelType: NavigationRailLabelType.selected,
        useIndicator: true,
        backgroundColor: theme.colorScheme.surface,
        minWidth: 80.0,
        minExtendedWidth: 200.0,
        destinations: usingPluginSystem
            ? _buildPluginDestinations(activePlugins)
            : _buildLegacyDestinations(),
        leading: _buildLeading(context),
        trailing: _buildTrailing(context),
      ),
    );
  }

  /// 🔌 Plugin sisteminden NavigationRail destinations oluştur
  List<NavigationRailDestination> _buildPluginDestinations(
    List<dynamic> activePlugins,
  ) {
    return activePlugins.map((plugin) {
      return NavigationRailDestination(
        icon: Icon(_getPluginIconData(plugin.icon)),
        selectedIcon: Icon(
          _getPluginIconData(plugin.icon),
          fill: 1.0, // Material 3 filled icon style
        ),
        label: Text(plugin.name),
        padding: const EdgeInsets.symmetric(vertical: 4),
      );
    }).toList();
  }

  /// Legacy destinations için backward compatibility
  List<NavigationRailDestination> _buildLegacyDestinations() {
    if (destinations == null) return [];

    return destinations!.map((destination) {
      return NavigationRailDestination(
        icon: Icon(destination.icon),
        selectedIcon: Icon(
          destination.icon,
          fill: 1.0, // Material 3 filled icon style
        ),
        label: Text(destination.label),
        padding: const EdgeInsets.symmetric(vertical: 4),
      );
    }).toList();
  }

  /// Seçili plugin'in index'ini hesapla
  int _getPluginSelectedIndex(List<dynamic> activePlugins) {
    if (selectedPluginId == null || activePlugins.isEmpty) return 0;

    final index = activePlugins.indexWhere(
      (plugin) => plugin.id == selectedPluginId,
    );
    return index >= 0 ? index : 0;
  }

  /// Navigasyon öğesi seçim handler'ı
  void _onDestinationSelected(int index) {
    final activePlugins = PluginRegistry.activePlugins;

    if (activePlugins.isNotEmpty && onPluginSelected != null) {
      // Plugin sistemini kullan
      if (index >= 0 && index < activePlugins.length) {
        final selectedPlugin = activePlugins[index];
        AppLogger.debug('Rail plugin selected: ${selectedPlugin.name}');
        onPluginSelected!(selectedPlugin.id);
      }
    } else if (destinations != null && onDestinationSelected != null) {
      // Legacy sistemi kullan
      if (index >= 0 && index < destinations!.length) {
        final destination = destinations![index];
        AppLogger.debug(
          'Rail navigation: ${destination.label} (index: $index)',
        );
        onDestinationSelected!(index);
      }
    }
  }

  /// Rail başlık bölümü - Logo
  Widget _buildLeading(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(top: 16, bottom: 24),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.dashboard,
              color: theme.colorScheme.onPrimary,
              size: 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'K',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Rail alt bölümü - Platform bilgisi + Plugin count
  Widget? _buildTrailing(BuildContext context) {
    final theme = Theme.of(context);
    final activePluginCount = PluginRegistry.activePlugins.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondaryContainer.withValues(
                alpha: 0.3,
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              Icons.tablet,
              size: 16,
              color: theme.colorScheme.onSecondaryContainer.withValues(
                alpha: 0.7,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tablet',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              fontSize: 10,
            ),
          ),
          // Plugin count indicator
          if (activePluginCount > 0) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$activePluginCount',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Plugin icon string'ini IconData'ya çevirir
  IconData _getPluginIconData(String iconName) {
    switch (iconName) {
      case 'note_add':
        return Icons.note_add;
      case 'chat':
        return Icons.chat;
      case 'task':
        return Icons.task;
      case 'email':
        return Icons.email;
      case 'contacts':
        return Icons.contacts;
      case 'calendar':
        return Icons.calendar_today;
      case 'dashboard':
        return Icons.dashboard;
      case 'home':
        return Icons.home;
      default:
        return Icons.extension;
    }
  }
}
