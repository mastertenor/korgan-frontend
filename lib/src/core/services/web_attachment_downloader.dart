// lib/src/core/services/web_attachment_downloader.dart

import 'dart:async';
import 'dart:typed_data';
import 'dart:js_interop';
import 'dart:js_util' as js_util;
import 'package:web/web.dart';
import '../../features/mail/domain/entities/attachment.dart';
import '../../utils/app_logger.dart';
import 'attachment_models.dart';

/// Web-specific implementation - Browser download with save dialog
/// 
/// Modern browsers: Shows save file picker (File System Access API)
/// Legacy browsers: Direct download to Downloads folder
/// Features:
/// - Save location selection (modern browsers)
/// - Fallback to direct download
/// - No file caching (immediate download)
/// - User cancellation handling
class WebAttachmentDownloadService {
  static WebAttachmentDownloadService? _instance;
  static WebAttachmentDownloadService get instance => _instance ??= WebAttachmentDownloadService._();
  
  WebAttachmentDownloadService._();

  /// Initialize web service (no-op, no cache needed)
  Future<void> initialize() async {
    final supportsModernDownload = _supportsFileSystemAccess();
    final downloadMethod = supportsModernDownload ? 'File picker dialog' : 'Direct to Downloads';
    
    AppLogger.info('💾 [Web] WebAttachmentDownloadService initialized - $downloadMethod mode');
    
    // Debug: API durumunu kontrol et
    if (supportsModernDownload) {
      AppLogger.info('✅ [Web] File System Access API supported');
    } else {
      AppLogger.warning('⚠️ [Web] File System Access API not supported, using fallback');
    }
  }

  /// Get cached file - Always returns null (no cache on web)
  Future<CachedFile?> getCachedFile(MailAttachment attachment, String email) async {
    AppLogger.debug('🔍 [Web] getCachedFile called - always returns null (no cache)');
    return null; // Always cache miss, force download
  }

  /// Download file - Actually triggers browser download with save dialog
  Future<CachedFile> downloadFile({
    required MailAttachment attachment,
    required String email,
    required Uint8List fileData,
  }) async {
    AppLogger.info('📥 [Web] Download request: ${attachment.filename}');

    try {
      // Trigger browser download with save dialog
      await _triggerBrowserDownload(attachment.filename, fileData, attachment.mimeType);

      // Return a download record object for compatibility
      return CachedFile(
        id: 'web_download_${DateTime.now().millisecondsSinceEpoch}',
        filename: attachment.filename,
        mimeType: attachment.mimeType,
        localPath: _supportsFileSystemAccess() 
            ? 'user_selected://${attachment.filename}'  // User chose location
            : 'downloads://${attachment.filename}',     // Downloads folder
        size: fileData.length,
        cachedAt: DateTime.now(),
        expiresAt: DateTime.now().add(Duration(minutes: 1)), // Very short expiry
        type: FileTypeDetector.fromMimeType(attachment.mimeType),
      );
    } catch (e) {
      AppLogger.error('❌ [Web] Download failed: $e');
      
      // Check if user cancelled
      if (e.toString().contains('iptal') || 
          e.toString().toLowerCase().contains('abort') ||
          e.toString().toLowerCase().contains('cancel')) {
        throw Exception('Kullanıcı dosya kaydetmeyi iptal etti');
      } else {
        throw Exception('Dosya indirme hatası: ${e.toString()}');
      }
    }
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
      platform: 'web_direct',
    );
  }

  /// Trigger browser download with save dialog
  Future<void> _triggerBrowserDownload(String filename, Uint8List data, String mimeType) async {
    try {
      AppLogger.info('📥 [Web] Starting browser download: $filename (${data.length} bytes)');

      // Try modern File System Access API first (Chrome 86+, Edge 86+)
      if (_supportsFileSystemAccess()) {
        AppLogger.info('🚀 [Web] Attempting File System Access API download');
        await _downloadWithFileSystemAccess(filename, data, mimeType);
      } else {
        AppLogger.info('🔄 [Web] Using traditional download method (API not supported)');
        await _downloadWithTraditionalMethod(filename, data, mimeType);
      }
      
      AppLogger.info('✅ [Web] Browser download triggered successfully: $filename');
    } catch (e) {
      AppLogger.error('❌ [Web] Browser download failed: $e');
      
      // If modern method fails, try fallback
      if (_supportsFileSystemAccess()) {
        AppLogger.info('🔄 [Web] File System Access failed, trying fallback download method...');
        try {
          await _downloadWithTraditionalMethod(filename, data, mimeType);
          AppLogger.info('✅ [Web] Fallback download successful: $filename');
        } catch (fallbackError) {
          AppLogger.error('❌ [Web] Fallback download also failed: $fallbackError');
          rethrow;
        }
      } else {
        rethrow;
      }
    }
  }

  /// Check if File System Access API is supported
  bool _supportsFileSystemAccess() {
    try {
      // Daha güvenilir kontrol
      final hasAPI = js_util.hasProperty(window, 'showSaveFilePicker');
      final isSecureContext = window.isSecureContext;
      
      AppLogger.debug('🔍 [Web] API check - hasShowSaveFilePicker: $hasAPI, isSecureContext: $isSecureContext');
      
      return hasAPI && isSecureContext;
    } catch (e) {
      AppLogger.debug('🔍 [Web] API check failed: $e');
      return false;
    }
  }

  /// Download using File System Access API (shows save dialog)
  Future<void> _downloadWithFileSystemAccess(String filename, Uint8List data, String mimeType) async {
    try {
      AppLogger.info('🎯 [Web] Calling showSaveFilePicker for: $filename');

      // Daha basit options ile başla
      final options = js_util.jsify({
        'suggestedName': filename,
        'excludeAcceptAllOption': false,
        'types': [
          {
            'description': _getFileDescription(mimeType),
            'accept': {
              mimeType: [_getFileExtension(filename)],
            },
          }
        ],
      });

      AppLogger.debug('🎯 [Web] Options: ${options.toString()}');

      // User gesture gerekli - bu mutlaka user interaction içinde çağrılmalı
      final fileHandle = await js_util.promiseToFuture(
        js_util.callMethod(window, 'showSaveFilePicker', [options]),
      ).timeout(Duration(seconds: 30)); // Timeout ekle

      AppLogger.info('📁 [Web] File handle obtained, creating writable stream');

      // Create writable stream
      final writable = await js_util.promiseToFuture(
        js_util.callMethod(fileHandle, 'createWritable', []),
      );

      AppLogger.info('✍️ [Web] Writing data to file (${data.length} bytes)');

      // Write data - ArrayBuffer kullan
      final jsBuffer = data.buffer.toJS;
      await js_util.promiseToFuture(
        js_util.callMethod(writable, 'write', [jsBuffer]),
      );

      AppLogger.info('💾 [Web] Closing file stream');

      // Close the file
      await js_util.promiseToFuture(
        js_util.callMethod(writable, 'close', []),
      );
      
      AppLogger.info('✅ [Web] File saved with user-selected location: $filename');
    } on TimeoutException {
      AppLogger.warning('⏰ [Web] Save dialog timed out for: $filename');
      throw Exception('Dosya kaydetme işlemi zaman aşımına uğradı');
    } catch (e) {
      final msg = e.toString().toLowerCase();
      AppLogger.error('❌ [Web] File System Access error: $e');
      
      if (msg.contains('abort') || msg.contains('cancel') || msg.contains('user aborted')) {
        AppLogger.info('ℹ️ [Web] User cancelled save dialog for: $filename');
        throw Exception('Kullanıcı kaydetme işlemini iptal etti');
      } else if (msg.contains('gesture') || msg.contains('user activation')) {
        AppLogger.error('👆 [Web] No user gesture - File System Access requires user interaction');
        throw Exception('Dosya kaydetme işlemi kullanıcı etkileşimi gerektiriyor');
      } else if (msg.contains('permission')) {
        AppLogger.error('🔒 [Web] Permission denied');
        throw Exception('Dosya kaydetme izni reddedildi');
      }
      
      throw Exception('Dosya kaydetme hatası: $e');
    }
  }

  /// Download using traditional method (direct to Downloads)
  Future<void> _downloadWithTraditionalMethod(String filename, Uint8List data, String mimeType) async {
    try {
      AppLogger.info('📥 [Web] Using traditional download method: $filename');

      // Create blob
      final jsBuffer = data.buffer.toJS;
      final JSArray<BlobPart> parts = (<BlobPart>[jsBuffer]).toJS;
      final blob = Blob(parts, BlobPropertyBag(type: mimeType));

      final url = URL.createObjectURL(blob);
      
      // Create temporary download link
      final anchor = HTMLAnchorElement()
        ..href = url
        ..download = filename
        ..style.display = 'none';
      
      // Add to DOM, click, and remove
      document.body!.appendChild(anchor);
      anchor.click();
      document.body!.removeChild(anchor);
      
      // Clean up blob URL
      URL.revokeObjectURL(url);
      
      AppLogger.info('✅ [Web] Traditional download completed: $filename');
    } catch (e) {
      AppLogger.error('❌ [Web] Traditional download failed: $e');
      rethrow;
    }
  }

  /// Get file description for save dialog
  String _getFileDescription(String mimeType) {
    if (mimeType.startsWith('image/')) return 'Resim Dosyaları';
    if (mimeType.contains('pdf')) return 'PDF Belgeleri';
    if (mimeType.startsWith('text/')) return 'Metin Dosyaları';
    if (mimeType.startsWith('video/')) return 'Video Dosyaları';
    if (mimeType.startsWith('audio/')) return 'Ses Dosyaları';
    if (mimeType.contains('zip') || mimeType.contains('rar')) return 'Arşiv Dosyaları';
    if (mimeType.contains('word') || mimeType.contains('excel') || mimeType.contains('powerpoint')) {
      return 'Microsoft Office Belgeleri';
    }
    return 'Tüm Dosyalar';
  }

  /// Get file extension from filename
  String _getFileExtension(String filename) {
    final parts = filename.split('.');
    if (parts.length > 1) {
      return '.${parts.last}';
    }
    return '.*'; // Wildcard for unknown extensions
  }
}