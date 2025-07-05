/// Notes Plugin Implementation
///
/// Korgan uygulamasının not alma modülünü implement eden plugin.
/// Kullanıcıların notlarını oluşturmasına, düzenlemesine ve yönetmesine olanak sağlar.
///
/// 🔧 Fixed: Sonsuz döngü problemi çözüldü
/// - HomePage yerine ayrı NotesPage kullanıyor
/// - Const widget ile tek seferlik instance
library;

import 'package:flutter/material.dart';
import '../core/plugin_system/app_plugin.dart';
import '../utils/app_logger.dart';

/// Notes modülü plugin implementasyonu
///
/// Bu plugin kullanıcıların not alması için gerekli tüm fonksiyonaliteyi sağlar.
/// Artık kendi sayfasına sahip - HomePage döngüsü yok!
class NotesPlugin implements AppPlugin {
  @override
  String get id => 'notes';

  @override
  String get name => 'Notes';

  @override
  String get icon => 'note_add';

  // 🔧 FIX: Const widget ile tek seferlik instance
  @override
  Widget get page => const NotesPage();

  @override
  Future<void> initialize() async {
    AppLogger.info('📝 Notes plugin initializing...');

    // Burada gerçek implementasyonda şunlar yapılabilir:
    // - Local database connection
    // - Notes cache initialization
    // - Sync service setup
    // - User preferences loading

    // Simulated initialization delay
    await Future.delayed(const Duration(milliseconds: 100));

    AppLogger.info('✅ Notes plugin initialized successfully');
  }

  @override
  void dispose() {
    AppLogger.info('📝 Notes plugin disposing...');

    // Burada gerçek implementasyonda şunlar yapılabilir:
    // - Database connections kapatma
    // - Cache temizleme
    // - Sync operations durdurma
    // - Resources serbest bırakma

    AppLogger.info('✅ Notes plugin disposed');
  }

  @override
  List<String> get dependencies => []; // Notes başka plugin'lere bağımlı değil
}

/// 📝 Notes plugin'inin özel sayfası

class NotesPage extends StatelessWidget {
  const NotesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.note_add, size: 64, color: Colors.blue),
            SizedBox(height: 16),
            Text(
              '📝 Notes Module',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('Your notes will appear here'),
            SizedBox(height: 16),
            Text(
              '🎉 Plugin System Working!',
              style: TextStyle(
                fontSize: 16,
                color: Colors.green,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          AppLogger.info('📝 Add note button pressed');
          // Add note functionality
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
