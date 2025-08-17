// ========== GÜNCELLENECEK STUB ==========
// lib/src/core/services/web_attachment_stub.dart

import 'dart:typed_data';
import '../../features/mail/domain/entities/attachment.dart';
import '../../core/services/attachment_models.dart';

/// Mobile stub - should never be called
class WebAttachmentDownloadService {
  static WebAttachmentDownloadService? _instance;
  static WebAttachmentDownloadService get instance => 
    _instance ??= WebAttachmentDownloadService._();
  
  WebAttachmentDownloadService._();

  Future<void> initialize() async {}
  
  Future<CachedFile?> getCachedFile(MailAttachment attachment, String email) async => null;

  // NO CachedFile return - just void!
  Future<void> downloadFile({
    required MailAttachment attachment,
    required String email,
    required Uint8List fileData,
  }) async {
    throw UnsupportedError('Web download not supported on mobile');
  }

  Future<CacheStats> getDownloadStats() async {
    return CacheStats(
      totalFiles: 0,
      totalSizeBytes: 0,
      maxSizeBytes: 0,
      expiredFiles: 0,
      filesByType: {},
      isInitialized: false,
      cacheTimeout: Duration.zero,
      platform: 'mobile_stub',
    );
  }
}