// lib/src/core/services/file_cache_service.dart

import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../../features/mail/domain/entities/attachment.dart';
import '../../utils/app_logger.dart';

/// Cached file model
class CachedFile {
  final String id;
  final String filename;
  final String mimeType;
  final String localPath;
  final int size;
  final DateTime cachedAt;
  final DateTime expiresAt;
  final SupportedFileType type;

  const CachedFile({
    required this.id,
    required this.filename,
    required this.mimeType,
    required this.localPath,
    required this.size,
    required this.cachedAt,
    required this.expiresAt,
    required this.type,
  });

  /// Check if cache is expired
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Check if file exists on disk
  Future<bool> get exists async => File(localPath).exists();

  /// Get file size on disk
  Future<int> get actualSize async {
    try {
      final file = File(localPath);
      return await file.length();
    } catch (e) {
      return 0;
    }
  }

  /// Convert to JSON for persistence
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'filename': filename,
      'mimeType': mimeType,
      'localPath': localPath,
      'size': size,
      'cachedAt': cachedAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'type': type.name,
    };
  }

  /// Create from JSON
  factory CachedFile.fromJson(Map<String, dynamic> json) {
    return CachedFile(
      id: json['id'] ?? '',
      filename: json['filename'] ?? '',
      mimeType: json['mimeType'] ?? '',
      localPath: json['localPath'] ?? '',
      size: json['size'] ?? 0,
      cachedAt: DateTime.parse(
        json['cachedAt'] ?? DateTime.now().toIso8601String(),
      ),
      expiresAt: DateTime.parse(
        json['expiresAt'] ?? DateTime.now().toIso8601String(),
      ),
      type: SupportedFileType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => SupportedFileType.unknown,
      ),
    );
  }
}

/// Supported file types for preview
enum SupportedFileType { pdf, image, text, office, video, audio, unknown }

/// File Cache Service - Gmail benzeri cache management
/// 🔧 Enhanced with better debugging and initialization
class FileCacheService {
  static const Duration _cacheTimeout = Duration(hours: 36); // Gmail benzeri
  static const int _maxCacheSize = 100 * 1024 * 1024; // 100MB
  static const String _cacheFolder = 'attachment_cache';
  static const String _indexFile = 'cache_index.json';

  static FileCacheService? _instance;
  static FileCacheService get instance => _instance ??= FileCacheService._();

  // 🆕 Initialization flag
  bool _isInitialized = false;

  FileCacheService._();

  /// 🆕 Initialize cache service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      AppLogger.info('💾 Initializing FileCacheService...');

      // Ensure cache directory exists
      final cacheDir = await _cacheDirectory;
      AppLogger.debug('📁 Cache directory: $cacheDir');

      // Load and validate index
      final index = await _loadCacheIndex();
      AppLogger.debug('📋 Loaded ${index.length} cache entries');

      // Validate cache integrity
      await _validateCacheIntegrity(index);

      _isInitialized = true;
      AppLogger.info('✅ FileCacheService initialized successfully');
    } catch (e) {
      AppLogger.error('❌ FileCacheService initialization failed: $e');
      _isInitialized = false;
      rethrow;
    }
  }

  /// Cache directory path
  Future<String> get _cacheDirectory async {
    final tempDir = await getTemporaryDirectory();
    final cacheDir = Directory('${tempDir.path}/$_cacheFolder');

    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
      AppLogger.debug('📁 Created cache directory: ${cacheDir.path}');
    }

    return cacheDir.path;
  }

  /// Cache index file path
  Future<String> get _indexPath async {
    final cacheDir = await _cacheDirectory;
    return '$cacheDir/$_indexFile';
  }

  /// 🆕 Validate cache integrity
  Future<void> _validateCacheIntegrity(Map<String, CachedFile> index) async {
    final invalidKeys = <String>[];

    for (final entry in index.entries) {
      final cachedFile = entry.value;

      // Check if file exists
      final fileExists = await cachedFile.exists;
      if (!fileExists) {
        AppLogger.warning(
          '🗑️ Removing invalid cache entry: ${cachedFile.filename} (file not found)',
        );
        invalidKeys.add(entry.key);
        continue;
      }

      // Check file size
      final actualSize = await cachedFile.actualSize;
      if (actualSize != cachedFile.size) {
        AppLogger.warning(
          '🗑️ Removing invalid cache entry: ${cachedFile.filename} (size mismatch: expected ${cachedFile.size}, got $actualSize)',
        );
        invalidKeys.add(entry.key);
        continue;
      }
    }

    // Remove invalid entries
    if (invalidKeys.isNotEmpty) {
      for (final key in invalidKeys) {
        index.remove(key);
      }
      await _saveCacheIndex(index);
      AppLogger.info(
        '🧹 Cleaned up ${invalidKeys.length} invalid cache entries',
      );
    }
  }

  /// Load cache index from disk
  Future<Map<String, CachedFile>> _loadCacheIndex() async {
    try {
      final indexPath = await _indexPath;
      final file = File(indexPath);

      if (!await file.exists()) {
        AppLogger.debug('📋 Cache index not found, creating new one');
        return {};
      }

      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;

      final index = json.map(
        (key, value) =>
            MapEntry(key, CachedFile.fromJson(value as Map<String, dynamic>)),
      );

      AppLogger.debug('📋 Loaded cache index with ${index.length} entries');
      return index;
    } catch (e) {
      AppLogger.error('Failed to load cache index: $e');
      return {};
    }
  }

  /// Save cache index to disk
  Future<void> _saveCacheIndex(Map<String, CachedFile> index) async {
    try {
      final indexPath = await _indexPath;
      final file = File(indexPath);

      final json = index.map((key, value) => MapEntry(key, value.toJson()));
      await file.writeAsString(jsonEncode(json));
      AppLogger.debug('💾 Saved cache index with ${index.length} entries');
    } catch (e) {
      AppLogger.error('Failed to save cache index: $e');
    }
  }

  /// Generate cache key for attachment
  String _generateCacheKey(MailAttachment attachment, String email) {
    // ID'yi çıkar, sadece sabit bilgileri kullan
    final input = '${attachment.filename}_${attachment.size}_$email';
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Determine file type from MIME type
  SupportedFileType _getFileType(String mimeType) {
    if (mimeType.startsWith('image/')) {
      return SupportedFileType.image;
    }
    if (mimeType.contains('pdf')) {
      return SupportedFileType.pdf;
    }
    if (mimeType.startsWith('text/')) {
      return SupportedFileType.text;
    }
    if (mimeType.contains('word') ||
        mimeType.contains('excel') ||
        mimeType.contains('powerpoint') ||
        mimeType.contains('spreadsheet')) {
      return SupportedFileType.office;
    }
    if (mimeType.startsWith('video/')) {
      return SupportedFileType.video;
    }
    if (mimeType.startsWith('audio/')) {
      return SupportedFileType.audio;
    }
    return SupportedFileType.unknown;
  }

  /// Get cached file or null if not cached/expired
  Future<CachedFile?> getCachedFile(
    MailAttachment attachment,
    String email,
  ) async {
    try {
      // Ensure cache is initialized
      if (!_isInitialized) {
        await initialize();
      }

      final cacheKey = _generateCacheKey(attachment, email);
      final index = await _loadCacheIndex();
      final cachedFile = index[cacheKey];

      if (cachedFile == null) {
        AppLogger.debug(
          '❌ Cache miss for: ${attachment.filename} (key: ${cacheKey.substring(0, 8)}...)',
        );
        return null;
      }

      if (cachedFile.isExpired) {
        AppLogger.debug('⏰ Cache expired for: ${attachment.filename}');
        await _removeCachedFile(cacheKey);
        return null;
      }

      if (!await cachedFile.exists) {
        AppLogger.debug('📂 Cache file missing for: ${attachment.filename}');
        await _removeCachedFile(cacheKey);
        return null;
      }

      AppLogger.debug('✅ Cache hit for: ${attachment.filename}');
      return cachedFile;
    } catch (e) {
      AppLogger.error('Error getting cached file: $e');
      return null;
    }
  }

  /// Cache file data
  Future<CachedFile> cacheFile(
    MailAttachment attachment,
    String email,
    Uint8List data,
  ) async {
    // Ensure cache is initialized
    if (!_isInitialized) {
      await initialize();
    }

    final cacheKey = _generateCacheKey(attachment, email);
    final cacheDir = await _cacheDirectory;
    final filePath = '$cacheDir/${cacheKey}_${attachment.filename}';

    // Write file to cache
    final file = File(filePath);
    await file.writeAsBytes(data);

    // Create cache entry
    final cachedFile = CachedFile(
      id: cacheKey,
      filename: attachment.filename,
      mimeType: attachment.mimeType,
      localPath: filePath,
      size: data.length,
      cachedAt: DateTime.now(),
      expiresAt: DateTime.now().add(_cacheTimeout),
      type: _getFileType(attachment.mimeType),
    );

    // Update cache index
    final index = await _loadCacheIndex();
    index[cacheKey] = cachedFile;
    await _saveCacheIndex(index);

    AppLogger.debug(
      '💾 Cached file: ${attachment.filename} (${data.length} bytes)',
    );

    // Clean up if cache is too large
    await _enforceCacheSize();

    return cachedFile;
  }

  /// Remove cached file
  Future<void> _removeCachedFile(String cacheKey) async {
    try {
      final index = await _loadCacheIndex();
      final cachedFile = index[cacheKey];

      if (cachedFile != null) {
        // Delete file from disk
        final file = File(cachedFile.localPath);
        if (await file.exists()) {
          await file.delete();
        }

        // Remove from index
        index.remove(cacheKey);
        await _saveCacheIndex(index);

        AppLogger.debug('🗑️ Removed cached file: ${cachedFile.filename}');
      }
    } catch (e) {
      AppLogger.error('Error removing cached file: $e');
    }
  }

  /// Get total cache size
  Future<int> getCacheSize() async {
    try {
      final index = await _loadCacheIndex();
      int totalSize = 0;

      for (final cachedFile in index.values) {
        totalSize += await cachedFile.actualSize;
      }

      return totalSize;
    } catch (e) {
      AppLogger.error('Error calculating cache size: $e');
      return 0;
    }
  }

  /// Enforce cache size limit
  Future<void> _enforceCacheSize() async {
    try {
      final index = await _loadCacheIndex();

      if (index.isEmpty) return;

      // Calculate total size
      int totalSize = 0;
      for (final cachedFile in index.values) {
        totalSize += await cachedFile.actualSize;
      }

      if (totalSize <= _maxCacheSize) return;

      AppLogger.info(
        '📦 Cache size limit exceeded (${totalSize / 1024 / 1024}MB), cleaning up...',
      );

      // Sort by access time (oldest first)
      final sortedEntries = index.entries.toList()
        ..sort((a, b) => a.value.cachedAt.compareTo(b.value.cachedAt));

      // Remove oldest files until under limit
      for (final entry in sortedEntries) {
        if (totalSize <= _maxCacheSize) break;

        final file = File(entry.value.localPath);
        if (await file.exists()) {
          totalSize -= await file.length();
          await file.delete();
        }

        index.remove(entry.key);
        AppLogger.debug('🗑️ Evicted cached file: ${entry.value.filename}');
      }

      await _saveCacheIndex(index);
      AppLogger.info('✅ Cache cleanup completed');
    } catch (e) {
      AppLogger.error('Error enforcing cache size: $e');
    }
  }

  /// Clear expired cache entries
  Future<void> clearExpiredCache() async {
    try {
      // Ensure cache is initialized
      if (!_isInitialized) {
        await initialize();
      }

      final index = await _loadCacheIndex();
      final now = DateTime.now();
      final expiredKeys = <String>[];

      for (final entry in index.entries) {
        if (now.isAfter(entry.value.expiresAt)) {
          expiredKeys.add(entry.key);
        }
      }

      for (final key in expiredKeys) {
        await _removeCachedFile(key);
      }

      AppLogger.info('🧹 Cleared ${expiredKeys.length} expired cache entries');
    } catch (e) {
      AppLogger.error('Error clearing expired cache: $e');
    }
  }

  /// Clear all cache
  Future<void> clearAllCache() async {
    try {
      final cacheDir = await _cacheDirectory;
      final directory = Directory(cacheDir);

      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }

      AppLogger.info('🗑️ Cleared all cache');
    } catch (e) {
      AppLogger.error('Error clearing all cache: $e');
    }
  }

  /// Get cache statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    // Ensure cache is initialized
    if (!_isInitialized) {
      await initialize();
    }

    final index = await _loadCacheIndex();
    final totalSize = await getCacheSize();

    return {
      'totalFiles': index.length,
      'totalSize': totalSize,
      'maxSize': _maxCacheSize,
      'usagePercent': totalSize > 0
          ? (totalSize / _maxCacheSize * 100).round()
          : 0,
      'isInitialized': _isInitialized,
    };
  }

  /// 🆕 Get detailed cache information for debugging
  Future<Map<String, dynamic>> getDetailedCacheInfo() async {
    try {
      final index = await _loadCacheIndex();
      final cacheDir = await _cacheDirectory;
      final totalSize = await getCacheSize();

      final filesByType = <String, int>{};
      final expiredCount = index.values.where((f) => f.isExpired).length;

      for (final file in index.values) {
        final typeName = file.type.name;
        filesByType[typeName] = (filesByType[typeName] ?? 0) + 1;
      }

      return {
        'cacheDirectory': cacheDir,
        'indexPath': await _indexPath,
        'totalFiles': index.length,
        'totalSize': totalSize,
        'totalSizeMB': (totalSize / 1024 / 1024).toStringAsFixed(2),
        'maxSize': _maxCacheSize,
        'maxSizeMB': (_maxCacheSize / 1024 / 1024).round(),
        'usagePercent': totalSize > 0
            ? (totalSize / _maxCacheSize * 100).round()
            : 0,
        'expiredFiles': expiredCount,
        'filesByType': filesByType,
        'isInitialized': _isInitialized,
        'cacheTimeout': _cacheTimeout.inHours,
      };
    } catch (e) {
      AppLogger.error('Error getting detailed cache info: $e');
      return {'error': e.toString()};
    }
  }
}
