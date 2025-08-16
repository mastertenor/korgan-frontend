// lib/src/core/services/web_attachment_downloader.dart

import 'dart:async';
import 'dart:typed_data';
import 'dart:js_interop';
import 'package:web/web.dart';
import '../../features/mail/domain/entities/attachment.dart';
import '../../utils/app_logger.dart';
import 'attachment_models.dart';

/// Simple web attachment downloader
/// 
/// Traditional browser download approach:
/// - Direct download to Downloads folder
/// - Browser notification appears automatically
/// - Shows in download manager
/// - No complex file picker logic
/// - Fast and reliable
class WebAttachmentDownloadService {
  static WebAttachmentDownloadService? _instance;
  static WebAttachmentDownloadService get instance => _instance ??= WebAttachmentDownloadService._();
  
  WebAttachmentDownloadService._();

  /// Initialize web service
  Future<void> initialize() async {
    AppLogger.info('💾 [Web] Simple downloader initialized - Direct to Downloads with notification');
  }

  /// Get cached file - Always returns null (no cache on web)
  Future<CachedFile?> getCachedFile(MailAttachment attachment, String email) async {
    AppLogger.debug('🔍 [Web] getCachedFile called - always returns null (no cache)');
    return null; // Always cache miss, force download
  }

  /// Simple download with browser notification
  Future<CachedFile> downloadFile({
    required MailAttachment attachment,
    required String email,
    required Uint8List fileData,
  }) async {
    AppLogger.info('📥 [Web] Starting simple download: ${attachment.filename}');

    try {
      // Direct traditional download
      await _directDownload(attachment.filename, fileData, attachment.mimeType);

      // Return download record for compatibility
      return CachedFile(
        id: 'web_download_${DateTime.now().millisecondsSinceEpoch}',
        filename: attachment.filename,
        mimeType: attachment.mimeType,
        localPath: 'downloads://${attachment.filename}',
        size: fileData.length,
        cachedAt: DateTime.now(),
        expiresAt: DateTime.now().add(Duration(minutes: 1)), // Very short expiry
        type: FileTypeDetector.fromMimeType(attachment.mimeType),
      );
    } catch (e) {
      AppLogger.error('❌ [Web] Download failed: $e');
      throw Exception('Dosya indirme hatası: ${e.toString()}');
    }
  }

  /// Direct download to Downloads folder with browser notification
  Future<void> _directDownload(String filename, Uint8List data, String mimeType) async {
    try {
      AppLogger.info('📥 [Web] Direct download: $filename (${data.length} bytes)');

      // Create blob
      final jsBuffer = data.buffer.toJS;
      final JSArray<BlobPart> parts = (<BlobPart>[jsBuffer]).toJS;
      final blob = Blob(parts, BlobPropertyBag(type: mimeType));

      final url = URL.createObjectURL(blob);
      
      // Create download link
      final anchor = HTMLAnchorElement()
        ..href = url
        ..download = filename
        ..style.display = 'none';
      
      // Add to DOM and trigger download
      document.body!.appendChild(anchor);
      anchor.click(); // This triggers browser download with notification
      document.body!.removeChild(anchor);
      
      // Clean up blob URL
      URL.revokeObjectURL(url);
      
      AppLogger.info('✅ [Web] Download completed with browser notification: $filename');
    } catch (e) {
      AppLogger.error('❌ [Web] Direct download failed: $e');
      rethrow;
    }
  }

  /// Public wrapper for backward compatibility
  Future<void> downloadWithTraditionalMethod(String filename, Uint8List data, String mimeType) async {
    return _directDownload(filename, data, mimeType);
  }

  /// Simplified methods for compatibility (not used in simple approach)
  Future<dynamic> showSavePickerFirst(String filename, String mimeType) async {
    AppLogger.info('🔄 [Web] showSavePickerFirst called - using direct download instead');
    return 'traditional_fallback';
  }

  Future<void> saveToFileHandle(dynamic fileHandle, Uint8List data, String filename) async {
    AppLogger.info('🔄 [Web] saveToFileHandle called - using direct download instead');
    await _directDownload(filename, data, 'application/octet-stream');
  }

  /// Get file data - Not supported (no storage)
  Future<Uint8List?> getFileData(CachedFile downloadRecord) async {
    AppLogger.warning('⚠️ [Web] getFileData called but no storage exists');
    return null;
  }

  /// Re-download file - Triggers new download
  Future<void> reDownloadFile(CachedFile downloadRecord) async {
    AppLogger.info('📥 [Web] Re-download requested: ${downloadRecord.filename}');
    throw Exception('File not stored - please download again');
  }

  /// Clear downloads - No-op (no storage exists)
  Future<void> clearDownloads() async {
    AppLogger.info('🧹 [Web] clearDownloads called - no storage to clear');
  }

  /// Get download statistics - Always empty
  Future<CacheStats> getDownloadStats() async {
    return CacheStats(
      totalFiles: 0,
      totalSizeBytes: 0,
      maxSizeBytes: 0,
      expiredFiles: 0,
      filesByType: {},
      isInitialized: true,
      cacheTimeout: Duration.zero,
      platform: 'web_simple',
    );
  }
}