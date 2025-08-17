// lib/src/core/services/web_attachment_downloader.dart

import 'dart:async';
import 'dart:typed_data';
import 'dart:js_interop';
import 'package:web/web.dart';
import '../../features/mail/domain/entities/attachment.dart';
import '../../utils/app_logger.dart';
import 'attachment_models.dart';

/// Ultra simple web attachment downloader - NO CACHE
class WebAttachmentDownloadService {
  static WebAttachmentDownloadService? _instance;
  static WebAttachmentDownloadService get instance => 
    _instance ??= WebAttachmentDownloadService._();
  
  WebAttachmentDownloadService._();

  /// Initialize service
  Future<void> initialize() async {
    AppLogger.info('💾 [Web] Simple downloader initialized');
  }

  /// Get cached file - Always null (NO CACHE on web)
  Future<CachedFile?> getCachedFile(MailAttachment attachment, String email) async {
    return null; // Web'de cache yok
  }

  /// Direct download - NO CACHE, NO CachedFile return
  Future<void> downloadFile({
    required MailAttachment attachment,
    required String email,
    required Uint8List fileData,
  }) async {
    AppLogger.info('📥 [Web] Downloading: ${attachment.filename}');

    try {
      // Create blob and download
      final jsBuffer = fileData.buffer.toJS;
      final JSArray<BlobPart> parts = (<BlobPart>[jsBuffer]).toJS;
      final blob = Blob(parts, BlobPropertyBag(type: attachment.mimeType));
      final url = URL.createObjectURL(blob);
      
      // Create download link and trigger
      final anchor = HTMLAnchorElement()
        ..href = url
        ..download = attachment.filename
        ..style.display = 'none';
      
      document.body!.appendChild(anchor);
      anchor.click(); 
      document.body!.removeChild(anchor);
      URL.revokeObjectURL(url);
      
      AppLogger.info('✅ [Web] Download completed: ${attachment.filename}');
    } catch (e) {
      AppLogger.error('❌ [Web] Download failed: $e');
      throw Exception('Download failed: ${e.toString()}');
    }
  }

  /// Get download statistics - Always empty (no cache)
  Future<CacheStats> getDownloadStats() async {
    return CacheStats(
      totalFiles: 0,
      totalSizeBytes: 0,
      maxSizeBytes: 0,
      expiredFiles: 0,
      filesByType: {},
      isInitialized: true,
      cacheTimeout: Duration.zero,
      platform: 'web_no_cache',
    );
  }
}