/// Korgan App Plugin Interface
///
/// Bu interface tüm plugin'lerin implement etmesi gereken temel contract'ı tanımlar.
/// Her plugin bu interface'i implement ederek sistem içinde standart şekilde çalışabilir.
///
/// Plugin sistemi kullanıcıya hangi modülleri kullanacağını seçme imkanı verir.
/// Bu sayede app memory'si optimize edilir ve kullanıcı experience kişiselleştirilir.
library;

import 'package:flutter/material.dart';

/// Tüm Korgan plugin'lerinin implement etmesi gereken ana interface
///
/// Her plugin aşağıdaki bilgileri sağlamalıdır:
/// - Unique identifier ve kullanıcı dostu isim
/// - UI icon ve ana sayfa widget'ı
/// - Lifecycle management (initialize/dispose)
///
/// Example:
/// ```dart
/// class NotesPlugin implements AppPlugin {
///   @override
///   String get id => 'notes';
///
///   @override
///   String get name => 'Notes';
///
///   @override
///   Widget get page => NotesPage();
/// }
/// ```
abstract class AppPlugin {
  /// Plugin'in unique identifier'ı
  ///
  /// Sistem içinde plugin'i tanımlamak için kullanılır.
  /// Küçük harf, tire ile ayrılmış format önerilir: 'notes', 'chat', 'tasks'
  String get id;

  /// Plugin'in kullanıcı dostu adı
  ///
  /// UI'da gösterilecek isim. Türkçe veya İngilizce olabilir.
  /// Örnek: 'Notes', 'Notlar', 'Chat', 'Sohbet'
  String get name;

  /// Plugin'in icon adı
  ///
  /// Material Icons'dan icon seçilmelidir.
  /// Örnek: 'note_add', 'chat', 'task', 'email'
  String get icon;

  /// Plugin'in ana sayfa widget'ı
  ///
  /// Kullanıcı plugin'e tıkladığında gösterilecek widget.
  /// Tam bir sayfa (Scaffold içeren) olmalıdır.
  Widget get page;

  /// Plugin başlatma işlemleri
  ///
  /// Plugin aktif edildiğinde çağrılır.
  /// Database, services, cache vb. initialize işlemleri burada yapılabilir.
  ///
  /// Returns: Başlatma işlemi tamamlandığında complete olan Future
  Future<void> initialize() async {
    // Default implementation - override if needed
  }

  /// Plugin temizleme işlemleri
  ///
  /// Plugin deaktif edildiğinde çağrılır.
  /// Resources temizleme, subscriptions iptal etme vb. işlemler burada yapılır.
  void dispose() {
    // Default implementation - override if needed
  }

  /// Plugin'in diğer plugin'lere bağımlılıkları (opsiyonel)
  ///
  /// Eğer bu plugin başka plugin'lerin aktif olmasını gerektiriyorsa
  /// onların id'leri bu listede belirtilmelidir.
  ///
  /// Örnek: Email plugin, Contacts plugin'ine bağımlıysa
  /// ```dart
  /// @override
  /// List<String> get dependencies => ['contacts'];
  /// ```
  List<String> get dependencies => [];
}

/// Plugin lifecycle durumları
///
/// Plugin'lerin hangi aşamada olduğunu takip etmek için kullanılır.
enum PluginState {
  /// Plugin kayıtlı ama henüz initialize edilmemiş
  registered,

  /// Plugin initialize ediliyor
  initializing,

  /// Plugin aktif ve kullanıma hazır
  active,

  /// Plugin'de hata oluştu
  error,

  /// Plugin deaktive ediliyor
  disposing,

  /// Plugin tamamen deaktive edildi
  disposed,
}
