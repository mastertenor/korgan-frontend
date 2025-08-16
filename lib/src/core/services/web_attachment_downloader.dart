// lib/src/core/services/web_attachment_downloader.dart

import 'dart:html' as html;
import 'dart:typed_data';
import '../../features/mail/domain/entities/attachment.dart';
import '../../utils/app_logger.dart';
import 'attachment_models.dart';

/// Web-specific implementation - Direct download to browser Downloads folder
/// 
/// Gmail web benzeri: No caching, direct download on every click
class WebFileCacheService {
  static WebFileCacheService? _instance;
  static WebFileCacheService get instance => _instance ??= WebFileCacheService._();
  
  WebFileCacheService._();

  /// Initialize web service (no-op, no cache needed)
  Future<void> initialize() async {
    AppLogger.info('💾 [Web] WebFileCacheService initialized - Direct download mode');
  }

  /// Get cached file - Always returns null (no cache on web)
  Future<CachedFile?> getCachedFile(MailAttachment attachment, String email) async {
    AppLogger.debug('🔍 [Web] getCachedFile called - always returns null (no cache)');
    return null; // Always cache miss, force download
  }

  /// Cache file - Actually triggers direct browser download
  Future<CachedFile> cacheFile({
    required MailAttachment attachment,
    required String email,
    required Uint8List fileData,
  }) async {
    AppLogger.info('📥 [Web] Direct download triggered: ${attachment.filename}');

    // Trigger browser download immediately
    await _triggerBrowserDownload(attachment.filename, fileData, attachment.mimeType);

    // Return a temporary "cached" file object for compatibility
    return CachedFile(
      id: 'web_download_${DateTime.now().millisecondsSinceEpoch}',
      filename: attachment.filename,
      mimeType: attachment.mimeType,
      localPath: 'downloads://${attachment.filename}', // Virtual path
      size: fileData.length,
      cachedAt: DateTime.now(),
      expiresAt: DateTime.now().add(Duration(minutes: 1)), // Very short expiry
      type: FileTypeDetector.fromMimeType(attachment.mimeType),
    );
  }

  /// Get cached file data - Not supported (no cache)
  Future<Uint8List?> getCachedFileData(CachedFile cachedFile) async {
    AppLogger.warning('⚠️ [Web] getCachedFileData called but no cache exists');
    return null;
  }

  /// Download cached file - Triggers new download
  Future<void> downloadCachedFile(CachedFile cachedFile) async {
    AppLogger.info('📥 [Web] Re-download requested: ${cachedFile.filename}');
    throw Exception('File not cached - please download again');
  }

  /// Clear cache - No-op (no cache exists)
  Future<void> clearCache() async {
    AppLogger.info('🧹 [Web] clearCache called - no cache to clear');
  }

  /// Get cache statistics - Always empty
  Future<CacheStats> getCacheStats() async {
    return CacheStats(
      totalFiles: 0,
      totalSizeBytes: 0,
      maxSizeBytes: 0,
      expiredFiles: 0,
      filesByType: {},
      isInitialized: true,
      cacheTimeout: Duration.zero,
      platform: 'web_direct',
    );
  }

  /// Trigger browser download to Downloads folder
  Future<void> _triggerBrowserDownload(String filename, Uint8List data, String mimeType) async {
    try {
      AppLogger.info('📥 [Web] Starting browser download: $filename (${data.length} bytes)');

      // Create blob from file data
      final blob = html.Blob([data], mimeType);
      final url = html.Url.createObjectUrlFromBlob(blob);
      
      // Create temporary download link
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', filename)
        ..style.display = 'none';
      
      // Add to DOM, click, and remove
      html.document.body?.append(anchor);
      anchor.click();
      anchor.remove();
      
      // Clean up blob URL
      html.Url.revokeObjectUrl(url);
      
      AppLogger.info('✅ [Web] Browser download triggered successfully: $filename');
    } catch (e) {
      AppLogger.error('❌ [Web] Browser download failed: $e');
      rethrow;
    }
  }
}