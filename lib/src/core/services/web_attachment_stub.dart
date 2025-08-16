// lib/src/core/services/web_attachment_stub.dart

import 'dart:typed_data';
import '../../features/mail/domain/entities/attachment.dart';
import '../../utils/app_logger.dart';
import 'attachment_models.dart';

/// Stub implementation for non-web platforms (mobile/desktop)
/// This class should never be called on mobile since we use MobileFileCacheService
class WebAttachmentDownloadService {
  static WebAttachmentDownloadService? _instance;
  static WebAttachmentDownloadService get instance => _instance ??= WebAttachmentDownloadService._();
  
  bool _isInitialized = false;
  
  WebAttachmentDownloadService._();

  /// Initialize web download service (stub - should not be called)
  Future<void> initialize() async {
    AppLogger.warning('[Mobile] WebAttachmentDownloadService.initialize() called on non-web platform - this should not happen');
    _isInitialized = true;
    // Don't throw error, just warn and continue
  }

  /// Get cached file for attachment (stub)
  Future<CachedFile?> getCachedFile(MailAttachment attachment, String email) async {
    AppLogger.warning('[Mobile] WebAttachmentDownloadService.getCachedFile() called on non-web platform - returning null');
    return null;
  }

  /// Download file (stub)
  Future<CachedFile> downloadFile({
    required MailAttachment attachment,
    required String email,
    required Uint8List fileData,
  }) async {
    AppLogger.warning('[Mobile] WebAttachmentDownloadService.downloadFile() called on non-web platform - creating temporary entry');
    
    // Return a temporary download record that won't cause crashes
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

  /// Get file data (stub)
  Future<Uint8List?> getFileData(CachedFile downloadRecord) async {
    AppLogger.warning('[Mobile] WebAttachmentDownloadService.getFileData() called on non-web platform - returning null');
    return null;
  }

  /// Re-download file (stub)
  Future<void> reDownloadFile(CachedFile downloadRecord) async {
    AppLogger.warning('[Mobile] WebAttachmentDownloadService.reDownloadFile() called on non-web platform - no-op');
    // Don't throw error, just do nothing
  }

  /// Clear downloads (stub)
  Future<void> clearDownloads() async {
    AppLogger.warning('[Mobile] WebAttachmentDownloadService.clearDownloads() called on non-web platform - no-op');
    // Don't throw error, just do nothing
  }

  /// Get download statistics (stub)
  Future<CacheStats> getDownloadStats() async {
    AppLogger.warning('[Mobile] WebAttachmentDownloadService.getDownloadStats() called on non-web platform - returning empty stats');
    
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