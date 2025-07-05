/// Desktop Kenar Çubuğu Bileşeni
///
/// Bu dosya desktop cihazlar için sol kenar çubuğu navigasyonunu sağlar.
/// Material 3 tasarım kılavuzuna uygun olarak geniş ekranlar için
/// optimize edilmiş navigasyon deneyimi sunar.
///
/// 🔌 Plugin System Integration:
/// - Aktif plugin'leri otomatik olarak navigation listesinde gösterir
/// - Plugin'lerin icon ve label bilgilerini kullanır
/// - Plugin seçimine göre navigation callback'lerini yönetir
///
/// Sorumlulukları:
/// - Desktop platformunda ana navigasyon sağlamak
/// - Plugin'leri dinamik olarak listelemek
/// - Uygulama başlığını ve logosunu göstermek
/// - Navigasyon öğelerini liste halinde sunmak
/// - Seçili öğeyi vurgulamak
/// - Kullanıcı etkileşimlerini yönetmek
///
/// Tasarım Özellikleri:
/// - Sabit 280px genişlik
/// - Material 3 color scheme
/// - Hover effects
/// - Selected state highlighting
/// - Plugin-aware navigation
library;

import 'package:flutter/material.dart';
import '../../utils/app_logger.dart';
import '../../core/plugin_system/plugin_registry.dart';

/// Desktop sidebar navigasyon widget'ı
///
/// Artık plugin sistemine entegre olarak aktif plugin'leri
/// otomatik olarak navigation listesinde gösterir.
class AdaptiveSidebar extends StatelessWidget {
  /// Şu anda seçili olan plugin'in id'si
  final String? selectedPluginId;

  /// Plugin seçildiğinde çağrılan callback
  final ValueChanged<String>? onPluginSelected;

  const AdaptiveSidebar({
    super.key,
    this.selectedPluginId,
    this.onPluginSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          right: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const Divider(height: 1),
          Expanded(child: _buildPluginList(context)),
          _buildSettingsSection(context),
          _buildFooter(context),
        ],
      ),
    );
  }

  /// Sidebar başlık alanı
  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
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
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Korgan',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Modular Platform',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 🔌 Plugin'leri dinamik olarak listeleyen bölüm
  Widget _buildPluginList(BuildContext context) {
    final activePlugins = PluginRegistry.activePlugins;

    AppLogger.debug(
      'Building sidebar with ${activePlugins.length} active plugins',
    );

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: activePlugins.length,
      itemBuilder: (context, index) {
        final plugin = activePlugins[index];
        return _buildPluginItem(context, plugin);
      },
    );
  }

  /// 🔌 Tek bir plugin navigasyon öğesi
  Widget _buildPluginItem(BuildContext context, plugin) {
    final isSelected = selectedPluginId == plugin.id;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            AppLogger.debug(
              'Sidebar plugin selected: ${plugin.name} (${plugin.id})',
            );
            onPluginSelected?.call(plugin.id);
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? colorScheme.primary.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.2),
                      width: 1,
                    )
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  _getIconData(plugin.icon),
                  size: 24,
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    plugin.name,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.onSurface.withValues(alpha: 0.8),
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Settings bölümü
  Widget _buildSettingsSection(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            AppLogger.debug('Settings tapped');
            // Settings sayfasına yönlendirme
            onPluginSelected?.call('settings');
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                Icon(
                  Icons.settings,
                  size: 24,
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Settings',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Sidebar alt bilgi alanı
  Widget _buildFooter(BuildContext context) {
    final theme = Theme.of(context);
    final activeCount = PluginRegistry.activePlugins.length;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.extension,
                size: 16,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 8),
              Text(
                '$activeCount Active Modules',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.desktop_windows,
                size: 16,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 8),
              Text(
                'Desktop Görünüm',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 🔌 Plugin icon string'ini IconData'ya çevirir
  IconData _getIconData(String iconName) {
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
        AppLogger.warning('Unknown icon: $iconName, using default');
        return Icons.extension;
    }
  }
}
