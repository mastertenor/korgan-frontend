/// Adaptatif Scaffold Yöneticisi
///
/// Bu dosya ekran boyutuna göre uygun scaffold yapısını seçer ve oluşturur.
/// Material 3 tasarım kılavuzuna uygun olarak farklı cihazlar için farklı
/// navigasyon kalıpları sunar.
///
/// 🔌 Plugin System Integration:
/// - Plugin navigation state'ini yönetir
/// - Aktif plugin'e göre content area'yı günceller
/// - Plugin-aware responsive navigation sağlar
///
/// Sorumlulukları:
/// - Ekran boyutuna göre scaffold yapısı kararı vermek
/// - AppBar, Drawer, BottomNavigationBar görünürlüğünü yönetmek
/// - Navigation bileşenlerini koordine etmek
/// - Plugin navigation state'ini yönetmek
/// - Responsive layout mantığını scaffold seviyesinde uygulamak
///
/// Navigation Patterns:
/// - Mobile (< 600dp): AppBar + Drawer + BottomNav + Content
/// - Tablet (840-1200dp): AppBar + NavigationRail + Content
/// - Desktop (> 1200dp): Sidebar + Content (AppBar yok)
library;

import 'package:flutter/material.dart';
import '../../../../common_widgets/responsive/breakpoints.dart';
import '../../../../common_widgets/navigation/sidebar.dart';
import '../../../../common_widgets/navigation/adaptive_rail.dart';
import '../../../../utils/app_logger.dart';
import '../../../../core/plugin_system/plugin_registry.dart';

/// Adaptatif scaffold widget'ı - Plugin sistemini destekleyen responsive scaffold
class AdaptiveScaffold extends StatefulWidget {
  /// Ana içerik alanında gösterilecek widget (opsiyonel)
  /// Eğer verilmezse aktif plugin'in sayfası gösterilir
  final Widget? body;

  /// Başlangıç plugin'i (opsiyonel)
  final String? initialPluginId;

  const AdaptiveScaffold({super.key, this.body, this.initialPluginId});

  @override
  State<AdaptiveScaffold> createState() => _AdaptiveScaffoldState();
}

class _AdaptiveScaffoldState extends State<AdaptiveScaffold> {
  /// Şu anda seçili olan plugin id'si
  late String _selectedPluginId;

  @override
  void initState() {
    super.initState();
    _initializeSelectedPlugin();
  }

  /// Başlangıç plugin'ini ayarla
  void _initializeSelectedPlugin() {
    final activePlugins = PluginRegistry.activePlugins;

    if (widget.initialPluginId != null &&
        activePlugins.any((p) => p.id == widget.initialPluginId)) {
      _selectedPluginId = widget.initialPluginId!;
    } else if (activePlugins.isNotEmpty) {
      _selectedPluginId = activePlugins.first.id;
    } else {
      _selectedPluginId = 'notes'; // Fallback
    }

    AppLogger.debug(
      'AdaptiveScaffold initialized with plugin: $_selectedPluginId',
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        // Ekran boyutuna göre platform türünü belirle
        final isDesktop =
            Breakpoints.isLarge(width) || Breakpoints.isExtraLarge(width);
        final isTablet = Breakpoints.isExpanded(width);
        final isMobile =
            Breakpoints.isCompact(width) || Breakpoints.isMedium(width);

        return Scaffold(
          // AppBar: Desktop'ta yok, diğerlerinde var
          appBar: _buildAppBar(isDesktop),

          // Drawer: Sadece mobile'da var
          drawer: _buildDrawer(isMobile),

          // Ana içerik alanı - Her platform için farklı yapı
          body: _buildAdaptiveBody(isDesktop, isTablet, isMobile),

          // Bottom Navigation: Sadece mobile'da var
          bottomNavigationBar: _buildBottomNavigationBar(isMobile),
        );
      },
    );
  }

  /// AppBar oluşturma mantığı
  PreferredSizeWidget? _buildAppBar(bool isDesktop) {
    if (isDesktop) {
      // Desktop'ta AppBar yok
      return null;
    }

    // Seçili plugin'in adını al
    final pluginName = _getSelectedPluginName();

    return AppBar(title: Text(pluginName), centerTitle: true, elevation: 0);
  }

  /// Drawer oluşturma mantığı
  Widget? _buildDrawer(bool isMobile) {
    if (!isMobile) {
      // Mobile olmayan cihazlarda drawer yok
      return null;
    }

    // 🔌 Plugin-aware drawer
    final activePlugins = PluginRegistry.activePlugins;
    final theme = Theme.of(context);

    return Drawer(
      child: Column(
        children: [
          // Drawer header
          DrawerHeader(
            decoration: BoxDecoration(color: theme.colorScheme.primary),
            child: Row(
              children: [
                Icon(
                  Icons.dashboard,
                  color: theme.colorScheme.onPrimary,
                  size: 32,
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Korgan',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Modular Platform',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onPrimary.withValues(
                          alpha: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Plugin listesi
          Expanded(
            child: ListView.builder(
              itemCount: activePlugins.length,
              itemBuilder: (context, index) {
                final plugin = activePlugins[index];
                final isSelected = _selectedPluginId == plugin.id;

                return ListTile(
                  leading: Icon(_getIconData(plugin.icon)),
                  title: Text(plugin.name),
                  selected: isSelected,
                  onTap: () {
                    _onPluginSelected(plugin.id);
                    Navigator.of(context).pop(); // Drawer'ı kapat
                  },
                );
              },
            ),
          ),

          // Settings
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Navigator.of(context).pop();
              AppLogger.debug('Settings tapped from drawer');
            },
          ),
        ],
      ),
    );
  }

  /// Platform-aware ana içerik alanı
  Widget _buildAdaptiveBody(bool isDesktop, bool isTablet, bool isMobile) {
    if (isDesktop) {
      // Desktop: Sidebar + Content
      return Row(
        children: [
          AdaptiveSidebar(
            selectedPluginId: _selectedPluginId,
            onPluginSelected: _onPluginSelected,
          ),
          Expanded(child: SafeArea(child: _buildContent())),
        ],
      );
    } else if (isTablet) {
      // Tablet: NavigationRail + Content
      return Row(
        children: [
          AdaptiveRail(
            selectedPluginId: _selectedPluginId,
            onPluginSelected: _onPluginSelected,
          ),
          const VerticalDivider(width: 1),
          Expanded(child: SafeArea(child: _buildContent())),
        ],
      );
    } else {
      // Mobile: Sadece content
      return SafeArea(child: _buildContent());
    }
  }

  /// Bottom navigation bar oluşturma mantığı
  Widget? _buildBottomNavigationBar(bool isMobile) {
    if (!isMobile) {
      // Mobile olmayan cihazlarda bottom nav yok
      return null;
    }

    // 📱 Statik 3 item ile bottom nav
    final staticItems = [
      {'id': 'modules', 'icon': Icons.apps, 'label': 'Modules'},
      {'id': 'settings', 'icon': Icons.settings, 'label': 'Settings'},
      {'id': 'profile', 'icon': Icons.person, 'label': 'Profile'},
    ];

    int selectedIndex = 0;
    if (_selectedPluginId == 'settings') selectedIndex = 1;
    if (_selectedPluginId == 'profile') selectedIndex = 2;

    return BottomNavigationBar(
      currentIndex: selectedIndex,
      type: BottomNavigationBarType.fixed,
      onTap: (index) {
        switch (index) {
          case 0: // Modules
            final activePlugins = PluginRegistry.activePlugins;
            _onPluginSelected(
              activePlugins.isNotEmpty ? activePlugins.first.id : 'modules',
            );
            break;
          case 1: // Settings
            _onPluginSelected('settings');
            break;
          case 2: // Profile
            _onPluginSelected('profile');
            break;
        }
      },
      items: staticItems
          .map(
            (item) => BottomNavigationBarItem(
              icon: Icon(item['icon'] as IconData),
              label: item['label'] as String,
            ),
          )
          .toList(),
    );
  }

  /// 🔌 Content area - Plugin'in sayfasını veya custom body'yi gösterir
  Widget _buildContent() {
    // Eğer custom body verilmişse onu kullan
    if (widget.body != null) {
      return widget.body!;
    }

    // Yoksa aktif plugin'in sayfasını göster
    final activePlugins = PluginRegistry.activePlugins;
    if (activePlugins.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.extension_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No plugins available'),
          ],
        ),
      );
    }

    final selectedPlugin = activePlugins.firstWhere(
      (plugin) => plugin.id == _selectedPluginId,
      orElse: () =>
          activePlugins.first, // Always return first plugin as fallback
    );

    // Plugin'in sayfasını göster - debug log kaldırıldı
    // AppLogger.debug('Displaying content for plugin: ${selectedPlugin.name}');
    return selectedPlugin.page;
  }

  /// 🔌 Plugin seçim callback'i
  void _onPluginSelected(String pluginId) {
    if (_selectedPluginId != pluginId) {
      setState(() {
        _selectedPluginId = pluginId;
      });
      AppLogger.info('Plugin selected in AdaptiveScaffold: $pluginId');
    }
  }

  /// Seçili plugin'in adını döner
  String _getSelectedPluginName() {
    final activePlugins = PluginRegistry.activePlugins;
    if (activePlugins.isEmpty) return 'Korgan';

    final selectedPlugin = activePlugins.firstWhere(
      (plugin) => plugin.id == _selectedPluginId,
      orElse: () =>
          activePlugins.first, // Always return first plugin as fallback
    );
    return selectedPlugin.name;
  }

  /// Plugin icon string'ini IconData'ya çevirir
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
        return Icons.extension;
    }
  }
}
