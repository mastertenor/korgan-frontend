/// Korgan Plugin Registry
///
/// Tüm plugin'lerin merkezi yönetim sistemi.
/// Plugin'lerin kaydedilmesi, aktif edilmesi ve deaktif edilmesi işlemlerini yönetir.
///
/// Bu singleton pattern ile implement edilmiş registry:
/// - Mevcut tüm plugin'leri saklar
/// - Kullanıcı seçimlerine göre plugin'leri aktif/pasif eder
/// - Plugin dependencies'lerini yönetir
/// - Plugin lifecycle'ını takip eder
library;

import '../plugin_system/app_plugin.dart';
import '../../utils/app_logger.dart';

/// Merkezi plugin yönetim sistemi
///
/// Singleton pattern kullanarak app genelinde tek bir registry instance'ı sağlar.
/// Plugin'lerin kaydedilmesi, aktivasyonu ve deaktivasyonunu yönetir.
class PluginRegistry {
  // Singleton instance
  static final PluginRegistry _instance = PluginRegistry._internal();
  factory PluginRegistry() => _instance;
  PluginRegistry._internal();

  /// Kayıtlı tüm plugin'ler (id -> plugin mapping)
  static final Map<String, AppPlugin> _availablePlugins = {};

  /// Aktif plugin id'leri
  /// Home plugin default olarak aktif (çıkarılamaz core plugin)
  static final Set<String> _activePluginIds = {'home'};

  /// Plugin state'leri
  static final Map<String, PluginState> _pluginStates = {};

  // ========================
  // PLUGIN REGISTRATION
  // ========================

  /// Yeni bir plugin'i sisteme kaydeder
  ///
  /// [plugin] kaydedilecek plugin instance'ı
  ///
  /// Throws [ArgumentError] eğer aynı id'li plugin zaten kayıtlıysa
  static void register(AppPlugin plugin) {
    if (_availablePlugins.containsKey(plugin.id)) {
      throw ArgumentError(
        'Plugin with id "${plugin.id}" is already registered',
      );
    }

    _availablePlugins[plugin.id] = plugin;
    _pluginStates[plugin.id] = PluginState.registered;

    AppLogger.info('🔌 Plugin registered: ${plugin.name} (${plugin.id})');
  }

  /// Birden fazla plugin'i toplu olarak kaydeder
  ///
  /// [plugins] kaydedilecek plugin listesi
  static void registerAll(List<AppPlugin> plugins) {
    for (final plugin in plugins) {
      register(plugin);
    }
  }

  // ========================
  // PLUGIN ACTIVATION
  // ========================

  /// Belirli plugin'leri aktif eder
  ///
  /// [pluginIds] aktif edilecek plugin id'leri
  /// Dependencies otomatik olarak çözümlenir ve gerekli plugin'ler de aktif edilir.
  ///
  /// Returns: Aktivasyon işlemi tamamlandığında complete olan Future
  static Future<void> activatePlugins(List<String> pluginIds) async {
    AppLogger.info('🔄 Activating plugins: $pluginIds');

    // Dependencies'leri çözümle
    final allRequiredPlugins = _resolveDependencies(pluginIds);

    // Yeni aktif edilecek plugin'leri belirle
    final newPlugins = allRequiredPlugins
        .where((id) => !_activePluginIds.contains(id))
        .toList();

    // Plugin'leri initialize et
    for (final pluginId in newPlugins) {
      if (_availablePlugins.containsKey(pluginId)) {
        await _initializePlugin(pluginId);
      } else {
        AppLogger.warning('⚠️ Plugin not found: $pluginId');
      }
    }

    // Aktif plugin listesini güncelle
    _activePluginIds.addAll(allRequiredPlugins);

    AppLogger.info(
      '✅ Plugins activated. Total active: ${_activePluginIds.length}',
    );
  }

  /// Tek bir plugin'i aktif eder
  ///
  /// [pluginId] aktif edilecek plugin id'si
  static Future<void> activatePlugin(String pluginId) async {
    await activatePlugins([pluginId]);
  }

  /// Plugin'i deaktif eder
  ///
  /// [pluginId] deaktif edilecek plugin id'si
  /// Home plugin deaktif edilemez (core plugin)
  static Future<void> deactivatePlugin(String pluginId) async {
    if (pluginId == 'home') {
      AppLogger.warning('⚠️ Cannot deactivate core plugin: home');
      return;
    }

    if (!_activePluginIds.contains(pluginId)) {
      AppLogger.warning('⚠️ Plugin is not active: $pluginId');
      return;
    }

    AppLogger.info('🔄 Deactivating plugin: $pluginId');

    // Plugin'i dispose et
    if (_availablePlugins.containsKey(pluginId)) {
      await _disposePlugin(pluginId);
    }

    // Aktif listesinden çıkar
    _activePluginIds.remove(pluginId);

    AppLogger.info('✅ Plugin deactivated: $pluginId');
  }

  /// Plugin'in aktif durumunu toggle eder
  ///
  /// [pluginId] toggle edilecek plugin id'si
  static Future<void> togglePlugin(String pluginId) async {
    if (_activePluginIds.contains(pluginId)) {
      await deactivatePlugin(pluginId);
    } else {
      await activatePlugin(pluginId);
    }
  }

  // ========================
  // GETTERS
  // ========================

  /// Aktif plugin'leri döner
  ///
  /// Returns: Şu anda aktif olan plugin'lerin listesi
  static List<AppPlugin> get activePlugins {
    return _activePluginIds
        .where((id) => _availablePlugins.containsKey(id))
        .map((id) => _availablePlugins[id]!)
        .toList();
  }

  /// Mevcut tüm plugin'leri döner
  ///
  /// Returns: Kayıtlı tüm plugin'lerin listesi
  static List<AppPlugin> get availablePlugins =>
      _availablePlugins.values.toList();

  /// Plugin'in aktif olup olmadığını kontrol eder
  ///
  /// [pluginId] kontrol edilecek plugin id'si
  /// Returns: Plugin aktif ise true, değilse false
  static bool isPluginActive(String pluginId) {
    return _activePluginIds.contains(pluginId);
  }

  /// Plugin'in durumunu döner
  ///
  /// [pluginId] durumu sorgulanacak plugin id'si
  /// Returns: Plugin'in şu anki durumu
  static PluginState? getPluginState(String pluginId) {
    return _pluginStates[pluginId];
  }

  /// Aktif plugin id'lerini döner
  ///
  /// Returns: Aktif plugin id'lerinin set'i
  static Set<String> get activePluginIds => Set.from(_activePluginIds);

  // ========================
  // PRIVATE HELPERS
  // ========================

  /// Plugin'i initialize eder
  ///
  /// [pluginId] initialize edilecek plugin id'si
  static Future<void> _initializePlugin(String pluginId) async {
    final plugin = _availablePlugins[pluginId]!;

    try {
      _pluginStates[pluginId] = PluginState.initializing;
      AppLogger.debug('🔄 Initializing plugin: ${plugin.name}');

      await plugin.initialize();

      _pluginStates[pluginId] = PluginState.active;
      AppLogger.debug('✅ Plugin initialized: ${plugin.name}');
    } catch (e) {
      _pluginStates[pluginId] = PluginState.error;
      AppLogger.error('❌ Failed to initialize plugin ${plugin.name}: $e');
      rethrow;
    }
  }

  /// Plugin'i dispose eder
  ///
  /// [pluginId] dispose edilecek plugin id'si
  static Future<void> _disposePlugin(String pluginId) async {
    final plugin = _availablePlugins[pluginId]!;

    try {
      _pluginStates[pluginId] = PluginState.disposing;
      AppLogger.debug('🔄 Disposing plugin: ${plugin.name}');

      plugin.dispose();

      _pluginStates[pluginId] = PluginState.disposed;
      AppLogger.debug('✅ Plugin disposed: ${plugin.name}');
    } catch (e) {
      _pluginStates[pluginId] = PluginState.error;
      AppLogger.error('❌ Failed to dispose plugin ${plugin.name}: $e');
    }
  }

  /// Plugin dependencies'lerini çözümler
  ///
  /// [pluginIds] çözümlenecek plugin id'leri
  /// Returns: Dependencies dahil tüm gerekli plugin id'leri
  static Set<String> _resolveDependencies(List<String> pluginIds) {
    final required = <String>{};
    final toProcess = [...pluginIds];

    while (toProcess.isNotEmpty) {
      final current = toProcess.removeAt(0);

      if (required.contains(current)) continue;
      required.add(current);

      // Plugin'in dependencies'lerini ekle
      if (_availablePlugins.containsKey(current)) {
        final dependencies = _availablePlugins[current]!.dependencies;
        toProcess.addAll(dependencies);
      }
    }

    return required;
  }
}
