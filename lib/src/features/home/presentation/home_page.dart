/// Ana Sayfa Bileşeni
///
/// Bu dosya uygulamanın ana sayfasını yönetir. Kullanıcı etkileşimlerini,
/// sayfa durumunu (state) ve iş mantığını (business logic) içerir.
///
/// 🔌 Plugin System Integration:
/// - Artık eski navigation destinations yerine plugin sistemini kullanır
/// - Plugin navigation state'ini yönetir
/// - AdaptiveScaffold bileşenine plugin desteği sağlar
///
/// Sorumlulukları:
/// - Plugin navigation state'ini yönetmek
/// - Sayfa geçişlerini koordine etmek
/// - AdaptiveScaffold bileşenine veri sağlamak
/// - Backward compatibility sağlamak
///
/// Kullanım:
/// ```dart
/// MaterialApp(home: HomePage())
/// ```
library;

import 'package:flutter/material.dart';
import '../../../utils/app_logger.dart';
import '../../../utils/platform_helper.dart';
import 'widgets/adaptive_scaffold.dart';

/// Ana sayfa widget'ı - Plugin sistemini destekleyen adaptive versiyon
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    AppLogger.info(
      'Building HomePage for platform: ${PlatformHelper.platformName}',
    );

    // 🔌 Plugin sistemini kullanan AdaptiveScaffold
    // Body belirtmiyoruz - otomatik olarak seçili plugin'in sayfası gösterilecek
    return const AdaptiveScaffold();
  }
}

// ========================
// LEGACY SUPPORT
// ========================

/// Eski HomePage implementasyonu için backward compatibility
///
/// Eğer plugin sistemi olmadan eski navigation'ı kullanmak istersen
/// bu class'ı kullanabilirsin.
class LegacyHomePage extends StatefulWidget {
  const LegacyHomePage({super.key});

  @override
  State<LegacyHomePage> createState() => _LegacyHomePageState();
}

class _LegacyHomePageState extends State<LegacyHomePage> {
  /// Şu anda seçili olan navigasyon öğesinin index'i
  int selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    AppLogger.info('LegacyHomePage initialized');
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      body: _buildCurrentPage(), // Custom body ile eski navigation davranışı
    );
  }

  /// Seçili sayfaya göre içerik oluşturur
  Widget _buildCurrentPage() {
    switch (selectedIndex) {
      case 0:
        return _buildHomePage();
      case 1:
        return _buildSettingsPage();
      case 2:
        return _buildAboutPage();
      default:
        return _buildHomePage();
    }
  }

  /// Ana sayfa içeriği
  Widget _buildHomePage() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.home, size: 64, color: Colors.blue),
          SizedBox(height: 16),
          Text(
            'Ana Sayfa',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text('Korgan uygulamasına hoş geldiniz!'),
        ],
      ),
    );
  }

  /// Ayarlar sayfası içeriği
  Widget _buildSettingsPage() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.settings, size: 64, color: Colors.green),
          SizedBox(height: 16),
          Text(
            'Ayarlar',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text('Uygulama ayarlarını buradan yapabilirsiniz.'),
        ],
      ),
    );
  }

  /// Hakkında sayfası içeriği
  Widget _buildAboutPage() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.info, size: 64, color: Colors.orange),
          SizedBox(height: 16),
          Text(
            'Hakkında',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text('Korgan v1.0 - Platform Helper Demo'),
        ],
      ),
    );
  }
}
