// lib/src/core/services/web_attachment_stub.dart

import 'dart:typed_data';
import '../../features/mail/domain/entities/attachment.dart';
import '../../utils/app_logger.dart';
import 'attachment_models.dart';

/// Stub implementation for non-web platforms (mobile/desktop)
/// This class should never be called on mobile since we use MobileFileCacheService
class WebFileCacheService {
  static WebFileCacheService? _instance;
  static WebFileCacheService get instance => _instance ??= WebFileCacheService._();
  
  bool _isInitialized = false;
  
  WebFileCacheService._();

  /// Initialize web cache service (stub - should not be called)
  Future<void> initialize() async {
    AppLogger.warning('[Mobile] WebFileCacheService.initialize() called on non-web platform - this should not happen');
    _isInitialized = true;
    // Don't throw error, just warn and continue
  }

  /// Get cached file for attachment (stub)
  Future<CachedFile?> getCachedFile(MailAttachment attachment, String email) async {
    AppLogger.warning('[Mobile] WebFileCacheService.getCachedFile() called on non-web platform - returning null');
    return null;
  }

  /// Cache downloaded file (stub)
  Future<CachedFile> cacheFile({
    required MailAttachment attachment,
    required String email,
    required Uint8List fileData,
  }) async {
    AppLogger.warning('[Mobile] WebFileCacheService.cacheFile() called on non-web platform - creating temporary entry');
    
    // Return a temporary cache entry that won't cause crashes
    return CachedFile(
      id: 'mobile_stub_${DateTime.now().millisecondsSinceEpoch}',
      filename: attachment.filename,
      mimeType: attachment.mimeType,
      localPath: 'stub://mobile/${attachment.filename}',
      size: fileData.length,
      cachedAt: DateTime.now(),
      expiresAt: DateTime.now().add(Duration(minutes: 5)),
      type: FileTypeDetector.fromMimeType(attachment.mimeType),
    );
  }

  /// Get cached file data (stub)
  Future<Uint8List?> getCachedFileData(CachedFile cachedFile) async {
    AppLogger.warning('[Mobile] WebFileCacheService.getCachedFileData() called on non-web platform - returning null');
    return null;
  }

  /// Download cached file (stub)
  Future<void> downloadCachedFile(CachedFile cachedFile) async {
    AppLogger.warning('[Mobile] WebFileCacheService.downloadCachedFile() called on non-web platform - no-op');
    // Don't throw error, just do nothing
  }

  /// Clear all cache (stub)
  Future<void> clearCache() async {
    AppLogger.warning('[Mobile] WebFileCacheService.clearCache() called on non-web platform - no-op');
    // Don't throw error, just do nothing
  }

  /// Get cache statistics (stub)
  Future<CacheStats> getCacheStats() async {
    AppLogger.warning('[Mobile] WebFileCacheService.getCacheStats() called on non-web platform - returning empty stats');
    
    return CacheStats(
      totalFiles: 0,
      totalSizeBytes: 0,
      maxSizeBytes: 0,
      expiredFiles: 0,
      filesByType: {},
      isInitialized: _isInitialized,
      cacheTimeout: Duration(hours: 36),
      platform: 'mobile_stub',
    );
  }
}