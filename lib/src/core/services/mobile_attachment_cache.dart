// lib/src/core/services/mobile_attachment_cache.dart

import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../../features/mail/domain/entities/attachment.dart';
import '../../utils/app_logger.dart';
import 'attachment_models.dart';
import 'file_type_detector.dart'; // 🆕 Import shared models

/// Mobile File Cache Service - Gmail benzeri cache management
/// 🔧 Enhanced with better debugging and initialization
/// ✅ Uses shared models from cache_models.dart
/// ✅ Mobile-specific file system operations
class MobileFileCacheService {
  static const Duration _cacheTimeout = Duration(hours: 36); // Gmail benzeri
  static const int _maxCacheSize = 100 * 1024 * 1024; // 100MB
  static const String _cacheFolder = 'attachment_cache';
  static const String _indexFile = 'cache_index.json';

  static MobileFileCacheService? _instance;
  static MobileFileCacheService get instance => _instance ??= MobileFileCacheService._();

  // 🆕 Initialization flag
  bool _isInitialized = false;

  MobileFileCacheService._();

  /// 🆕 Initialize cache service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      AppLogger.info('💾 [Mobile] Initializing MobileFileCacheService...');

      // Ensure cache directory exists
      final cacheDir = await _cacheDirectory;
      AppLogger.debug('📁 [Mobile] Cache directory: $cacheDir');

      // Load and validate index
      final index = await _loadCacheIndex();
      AppLogger.debug('📋 [Mobile] Loaded ${index.length} cache entries');

      // Validate cache integrity
      await _validateCacheIntegrity(index);

      _isInitialized = true;
      AppLogger.info('✅ [Mobile] MobileFileCacheService initialized successfully');
    } catch (e) {
      AppLogger.error('❌ [Mobile] MobileFileCacheService initialization failed: $e');
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
      AppLogger.debug('📁 [Mobile] Created cache directory: ${cacheDir.path}');
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
          '🗑️ [Mobile] Removing invalid cache entry: ${cachedFile.filename} (file not found)',
        );
        invalidKeys.add(entry.key);
        continue;
      }

      // Check file size
      final actualSize = await cachedFile.actualSize;
      if (actualSize != cachedFile.size) {
        AppLogger.warning(
          '🗑️ [Mobile] Removing invalid cache entry: ${cachedFile.filename} (size mismatch: expected ${cachedFile.size}, got $actualSize)',
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
        '🧹 [Mobile] Cleaned up ${invalidKeys.length} invalid cache entries',
      );
    }
  }

  /// Load cache index from disk
  Future<Map<String, CachedFile>> _loadCacheIndex() async {
    try {
      final indexPath = await _indexPath;
      final file = File(indexPath);

      if (!await file.exists()) {
        AppLogger.debug('📋 [Mobile] Cache index not found, creating new one');
        return {};
      }

      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;

      final index = json.map(
        (key, value) =>
            MapEntry(key, CachedFile.fromJson(value as Map<String, dynamic>)),
      );

      AppLogger.debug('📋 [Mobile] Loaded cache index with ${index.length} entries');
      return index;
    } catch (e) {
      AppLogger.error('[Mobile] Failed to load cache index: $e');
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
      AppLogger.debug('💾 [Mobile] Saved cache index with ${index.length} entries');
    } catch (e) {
      AppLogger.error('[Mobile] Failed to save cache index: $e');
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
          '❌ [Mobile] Cache miss for: ${attachment.filename} (key: ${cacheKey.substring(0, 8)}...)',
        );
        return null;
      }

      if (cachedFile.isExpired) {
        AppLogger.debug('⏰ [Mobile] Cache expired for: ${attachment.filename}');
        await _removeCachedFile(cacheKey);
        return null;
      }

      if (!await cachedFile.exists) {
        AppLogger.debug('📂 [Mobile] Cache file missing for: ${attachment.filename}');
        await _removeCachedFile(cacheKey);
        return null;
      }

      AppLogger.debug('✅ [Mobile] Cache hit for: ${attachment.filename}');
      return cachedFile;
    } catch (e) {
      AppLogger.error('[Mobile] Error getting cached file: $e');
      return null;
    }
  }

  /// Cache file data
  Future<CachedFile> cacheFile({
    required MailAttachment attachment,
    required String email,
    required Uint8List fileData,
  }) async {
    // Ensure cache is initialized
    if (!_isInitialized) {
      await initialize();
    }

    final cacheKey = _generateCacheKey(attachment, email);
    final cacheDir = await _cacheDirectory;
    final filePath = '$cacheDir/${cacheKey}_${attachment.filename}';

    // Write file to cache
    final file = File(filePath);
    await file.writeAsBytes(fileData);

    // Create cache entry
    final cachedFile = CachedFile(
      id: cacheKey,
      filename: attachment.filename,
      mimeType: attachment.mimeType,
      localPath: filePath,
      size: fileData.length,
      cachedAt: DateTime.now(),
      expiresAt: DateTime.now().add(_cacheTimeout),
      type: FileTypeDetector.detectFromMimeType(attachment.mimeType),
    );

    // Update cache index
    final index = await _loadCacheIndex();
    index[cacheKey] = cachedFile;
    await _saveCacheIndex(index);

    AppLogger.debug(
      '💾 [Mobile] Cached file: ${attachment.filename} (${fileData.length} bytes)',
    );

    // Clean up if cache is too large
    await _enforceCacheSize();

    return cachedFile;
  }

  /// Get cached file data (for mobile file system)
  Future<Uint8List?> getCachedFileData(CachedFile cachedFile) async {
    try {
      final file = File(cachedFile.localPath);
      if (!await file.exists()) {
        AppLogger.warning('🗑️ [Mobile] Cache file not found: ${cachedFile.filename}');
        return null;
      }
      return await file.readAsBytes();
    } catch (e) {
      AppLogger.error('❌ [Mobile] Error reading cached file data: $e');
      return null;
    }
  }

  /// Get file handle for cached file (mobile-specific)
  Future<File?> getCachedFileHandle(CachedFile cachedFile) async {
    try {
      final file = File(cachedFile.localPath);
      if (await file.exists()) {
        return file;
      }
      return null;
    } catch (e) {
      AppLogger.error('❌ [Mobile] Error getting file handle: $e');
      return null;
    }
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

        AppLogger.debug('🗑️ [Mobile] Removed cached file: ${cachedFile.filename}');
      }
    } catch (e) {
      AppLogger.error('[Mobile] Error removing cached file: $e');
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
      AppLogger.error('[Mobile] Error calculating cache size: $e');
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
        '📦 [Mobile] Cache size limit exceeded (${totalSize / 1024 / 1024}MB), cleaning up...',
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
        AppLogger.debug('🗑️ [Mobile] Evicted cached file: ${entry.value.filename}');
      }

      await _saveCacheIndex(index);
      AppLogger.info('✅ [Mobile] Cache cleanup completed');
    } catch (e) {
      AppLogger.error('[Mobile] Error enforcing cache size: $e');
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

      AppLogger.info('🧹 [Mobile] Cleared ${expiredKeys.length} expired cache entries');
    } catch (e) {
      AppLogger.error('[Mobile] Error clearing expired cache: $e');
    }
  }

  /// Clear all cache
  Future<void> clearCache() async {
    try {
      final cacheDir = await _cacheDirectory;
      final directory = Directory(cacheDir);

      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }

      AppLogger.info('🗑️ [Mobile] Cleared all cache');
    } catch (e) {
      AppLogger.error('[Mobile] Error clearing all cache: $e');
    }
  }

  /// Get cache statistics
  Future<CacheStats> getCacheStats() async {
    try {
      // Ensure cache is initialized
      if (!_isInitialized) {
        await initialize();
      }

      final index = await _loadCacheIndex();
      final totalSize = await getCacheSize();
      int expiredCount = 0;
      final filesByType = <SupportedFileType, int>{};
      final now = DateTime.now();

      for (final cachedFile in index.values) {
        if (now.isAfter(cachedFile.expiresAt)) {
          expiredCount++;
        }
        
        filesByType[cachedFile.type] = (filesByType[cachedFile.type] ?? 0) + 1;
      }

      return CacheStats(
        totalFiles: index.length,
        totalSizeBytes: totalSize,
        maxSizeBytes: _maxCacheSize,
        expiredFiles: expiredCount,
        filesByType: filesByType,
        isInitialized: _isInitialized,
        cacheTimeout: _cacheTimeout,
        platform: 'mobile',
      );
    } catch (e) {
      AppLogger.error('[Mobile] Error getting cache stats: $e');
      return CacheStats(
        totalFiles: 0,
        totalSizeBytes: 0,
        maxSizeBytes: _maxCacheSize,
        expiredFiles: 0,
        filesByType: {},
        isInitialized: false,
        cacheTimeout: _cacheTimeout,
        platform: 'mobile',
      );
    }
  }

  /// 🆕 Get detailed cache information for debugging (legacy compatibility)
  Future<Map<String, dynamic>> getDetailedCacheInfo() async {
    final stats = await getCacheStats();
    return stats.toJson();
  }

Future<void> handleFileAction(CachedFile file) async {
    try {
      AppLogger.info('🎯 [Mobile] Handling file action for: ${file.filename}');

      final fileHandle = await getCachedFileHandle(file);
      if (fileHandle == null) {
        AppLogger.error('❌ [Mobile] Cached file not found: ${file.filename}');
        throw Exception('Cached file not found: ${file.filename}');
      }

      // Verify file still exists and is readable
      if (!await fileHandle.exists()) {
        AppLogger.error('❌ [Mobile] File does not exist: ${file.localPath}');
        throw Exception('File does not exist: ${file.filename}');
      }

      AppLogger.info('🚀 [Mobile] Opening file with system app: ${file.filename}');

      // TODO: Implement platform-specific file opening
      // 
      // This requires platform-specific implementation using:
      // - Android: Intent with ACTION_VIEW
      // - iOS: UIDocumentInteractionController
      // - Or use packages like open_file, url_launcher
      // 
      // For now, we'll throw with implementation guidance
      throw UnimplementedError(
        'Mobile file opening not yet implemented. '
        'Consider using packages like "open_file" or "url_launcher" '
        'to open file: ${file.localPath}'
      );

    } catch (e) {
      AppLogger.error('❌ [Mobile] Error handling file action: $e');
      rethrow;
    }
  }  
}