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
class FileCacheService {
  static const Duration _cacheTimeout = Duration(hours: 36); // Gmail benzeri
  static const int _maxCacheSize = 100 * 1024 * 1024; // 100MB
  static const String _cacheFolder = 'attachment_cache';
  static const String _indexFile = 'cache_index.json';

  static FileCacheService? _instance;
  static FileCacheService get instance => _instance ??= FileCacheService._();
  FileCacheService._();

  /// Cache directory path
  Future<String> get _cacheDirectory async {
    final tempDir = await getTemporaryDirectory();
    final cacheDir = Directory('${tempDir.path}/$_cacheFolder');

    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }

    return cacheDir.path;
  }

  /// Cache index file path
  Future<String> get _indexPath async {
    final cacheDir = await _cacheDirectory;
    return '$cacheDir/$_indexFile';
  }

  /// Load cache index from disk
  Future<Map<String, CachedFile>> _loadCacheIndex() async {
    try {
      final indexPath = await _indexPath;
      final file = File(indexPath);

      if (!await file.exists()) {
        return {};
      }

      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;

      return json.map(
        (key, value) =>
            MapEntry(key, CachedFile.fromJson(value as Map<String, dynamic>)),
      );
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
    } catch (e) {
      AppLogger.error('Failed to save cache index: $e');
    }
  }

  /// Generate cache key for attachment
  String _generateCacheKey(MailAttachment attachment, String email) {
    final input = '${attachment.id}_${attachment.filename}_$email';
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
      final cacheKey = _generateCacheKey(attachment, email);
      final index = await _loadCacheIndex();
      final cachedFile = index[cacheKey];

      if (cachedFile == null) {
        AppLogger.debug('Cache miss for: ${attachment.filename}');
        return null;
      }

      if (cachedFile.isExpired) {
        AppLogger.debug('Cache expired for: ${attachment.filename}');
        await _removeCachedFile(cacheKey);
        return null;
      }

      if (!await cachedFile.exists) {
        AppLogger.debug('Cache file missing for: ${attachment.filename}');
        await _removeCachedFile(cacheKey);
        return null;
      }

      AppLogger.debug('Cache hit for: ${attachment.filename}');
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
      'Cached file: ${attachment.filename} (${data.length} bytes)',
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

        AppLogger.debug('Removed cached file: ${cachedFile.filename}');
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
        AppLogger.debug('Evicted cached file: ${entry.value.filename}');
      }

      await _saveCacheIndex(index);
    } catch (e) {
      AppLogger.error('Error enforcing cache size: $e');
    }
  }

  /// Clear expired cache entries
  Future<void> clearExpiredCache() async {
    try {
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

      AppLogger.info('Cleared ${expiredKeys.length} expired cache entries');
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

      AppLogger.info('Cleared all cache');
    } catch (e) {
      AppLogger.error('Error clearing all cache: $e');
    }
  }

  /// Get cache statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    final index = await _loadCacheIndex();
    final totalSize = await getCacheSize();

    return {
      'totalFiles': index.length,
      'totalSize': totalSize,
      'maxSize': _maxCacheSize,
      'usagePercent': (totalSize / _maxCacheSize * 100).round(),
    };
  }
}
