/// Ana Uygulama Giriş Noktası
///
/// Bu dosya uygulamanın başlangıç ayarlarını yapar ve ana widget'ı başlatır.
/// Minimal yapıda tutularak sadece app bootstrap işlemlerini gerçekleştirir.
///
/// Sorumlulukları:
/// - Platform Helper ve Logger sistemlerini başlatmak
/// - Plugin Registry sistemini initialize etmek
/// - MaterialApp konfigürasyonunu yapmak
/// - Ana sayfa yönlendirmesini sağlamak
/// - Global theme ayarlarını tanımlamak
library;

import 'package:flutter/material.dart';
import 'src/utils/platform_helper.dart';
import 'src/utils/app_logger.dart';
import 'src/features/home/presentation/home_page.dart';
// 🔌 Plugin System Imports
import 'src/core/plugin_system/plugin_registry.dart';
import 'src/plugins/notes_plugin.dart';

void main() async {
  // Flutter binding'ini başlat
  WidgetsFlutterBinding.ensureInitialized();

  // Platform Helper sistemini başlat
  AppLogger.init();
  AppLogger.info('🚀 App Starting...');

  // Platform bilgilerini logla
  PlatformHelper.logPlatformInfo();

  // 🔌 Plugin sistemini initialize et
  await _initializePluginSystem();

  // Uygulamayı başlat
  runApp(const KorganApp());
}

/// Plugin sistemini başlatır
///
/// Tüm mevcut plugin'leri kaydeder ve sistem hazır hale getirir.
/// Yeni plugin'ler buraya eklenmelidir.
Future<void> _initializePluginSystem() async {
  AppLogger.info('🔌 Initializing Plugin System...');

  // Mevcut plugin'leri kaydet
  PluginRegistry.register(NotesPlugin());

  // Gelecekte eklenecek plugin'ler:
  // PluginRegistry.register(ChatPlugin());
  // PluginRegistry.register(TasksPlugin());
  // PluginRegistry.register(ContactsPlugin());
  // PluginRegistry.register(EmailPlugin());

  AppLogger.info(
    '✅ Plugin System initialized with ${PluginRegistry.availablePlugins.length} plugins',
  );

  // 🔧 Plugin'leri aktif et (Eksik olan kısım!)
  await PluginRegistry.activatePlugins(['notes']);

  // Aktif plugin'leri logla
  final activePlugins = PluginRegistry.activePlugins;
  AppLogger.info(
    '✅ Active plugins: ${activePlugins.map((p) => p.name).join(', ')}',
  );
}

/// Ana uygulama widget'ı
class KorganApp extends StatelessWidget {
  const KorganApp({super.key});

  @override
  Widget build(BuildContext context) {
    AppLogger.debug('Building KorganApp');

    return MaterialApp(
      title: 'Korgan',
      debugShowCheckedModeBanner: false,

      // Material 3 theme konfigürasyonu
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      themeMode: ThemeMode.system,

      // Ana sayfa
      home: const HomePage(),

      // Performance optimizations
      builder: (context, child) {
        AppLogger.debug('MaterialApp builder called');
        return child!;
      },
    );
  }

  /// Light theme konfigürasyonu
  ThemeData _buildLightTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
      navigationBarTheme: NavigationBarThemeData(elevation: 3, height: 80),
      navigationRailTheme: const NavigationRailThemeData(
        useIndicator: true,
        labelType: NavigationRailLabelType.selected,
        elevation: 0, // ✅ Explicit elevation value
      ),
    );
  }

  /// Dark theme konfigürasyonu
  ThemeData _buildDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.dark,
      ),
      appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
      navigationBarTheme: NavigationBarThemeData(elevation: 3, height: 80),
      navigationRailTheme: const NavigationRailThemeData(
        useIndicator: true,
        labelType: NavigationRailLabelType.selected,
        elevation: 0, // ✅ Explicit elevation value
      ),
    );
  }
}
