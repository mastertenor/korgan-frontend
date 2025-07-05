// =============================================================================
// ADIM 2: lib/src/utils/app_logger.dart Dosyası Oluşturun
// =============================================================================

/// Logger wrapper sınıfı - AppLogger
///
/// Bu sınıf logger package'ını wrap ediyor ve uygulama genelinde
/// tutarlı logging sağlıyor.
library;

import 'package:logger/logger.dart';
import 'package:flutter/foundation.dart';

class AppLogger {
  // Private logger instance
  static late Logger _logger;
  static bool _isInitialized = false;

  /// Logger'ı initialize et
  ///
  /// Bu method'u main.dart'ta çağırın
  static void init() {
    if (_isInitialized) return;

    _logger = Logger(
      printer: PrettyPrinter(
        methodCount: 2, // Stack trace satır sayısı
        errorMethodCount: 8, // Error durumunda stack trace satırı
        lineLength: 120, // Maksimum satır uzunluğu
        colors: true, // Renkli output
        printEmojis: true, // Emoji kullan
        // ignore: deprecated_member_use
        printTime: false, // Timestamp gösterme (console'da karışıklık yaratır)
      ),
      // Debug mode'da tüm loglar, production'da hiçbiri
      level: kDebugMode ? Level.debug : Level.off,
    );

    _isInitialized = true;

    // Initialize edildiğini bildir
    if (kDebugMode) {
      _logger.i('📝 AppLogger initialized successfully');
    }
  }

  /// Debug log (en detaylı)
  /// Development sırasında geçici debug bilgileri için
  static void debug(String message, [Object? error, StackTrace? stackTrace]) {
    _ensureInitialized();
    _logger.d(message, error: error, stackTrace: stackTrace);
  }

  /// Info log (genel bilgi)
  /// Normal uygulama akışı bilgileri için
  static void info(String message, [Object? error, StackTrace? stackTrace]) {
    _ensureInitialized();
    _logger.i(message, error: error, stackTrace: stackTrace);
  }

  /// Warning log (uyarı)
  /// Potansiyel problemler için
  static void warning(String message, [Object? error, StackTrace? stackTrace]) {
    _ensureInitialized();
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  /// Error log (hata)
  /// Actual errorlar için
  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    _ensureInitialized();
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  /// What a Terrible Failure (kritik hata)
  /// Asla olmaması gereken durumlar için
  static void wtf(String message, [Object? error, StackTrace? stackTrace]) {
    _ensureInitialized();
    _logger.f(message, error: error, stackTrace: stackTrace);
  }

  /// Logger'ın initialize edildiğinden emin ol
  static void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError(
        'AppLogger is not initialized. Call AppLogger.init() first.',
      );
    }
  }

  /// Logger'ı test et
  static void testAllLevels() {
    _ensureInitialized();

    debug('🐛 This is a DEBUG message - en detaylı');
    info('ℹ️ This is an INFO message - genel bilgi');
    warning('⚠️ This is a WARNING message - dikkat!');
    error('❌ This is an ERROR message - problem var!');
    wtf('💥 This is a WTF message - felaket!');
  }
}
