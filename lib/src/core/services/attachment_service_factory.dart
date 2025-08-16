// lib/src/core/services/attachment_service_factory.dart

import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../../features/mail/domain/entities/attachment.dart';
import 'attachment_models.dart';
import 'mobile_attachment_cache.dart';
import 'web_attachment_platform.dart';

/// Platform-aware attachment service interface
/// Web: Direct download, Mobile: Cache management
abstract class PlatformAttachmentService {
  Future<void> initialize();
  Future<CachedFile?> getCachedFile(MailAttachment attachment, String email);
  Future<CachedFile> processFile({
    required MailAttachment attachment,
    required String email,
    required Uint8List fileData,
  });
  Future<Uint8List?> getFileData(CachedFile file);
  Future<void> handleFileAction(CachedFile file);
  Future<void> clearStorage();
  Future<CacheStats> getStorageStats();
}

/// Factory for creating platform-specific attachment services
class AttachmentServiceFactory {
  static PlatformAttachmentService? _instance;
  
  /// Get the appropriate attachment service for current platform
  static PlatformAttachmentService get instance {
    if (_instance != null) return _instance!;
    
    if (kIsWeb) {
      _instance = WebAttachmentServiceAdapter();
    } else {
      _instance = MobileAttachmentServiceAdapter();
    }
    
    return _instance!;
  }

  /// Reset instance (for testing)
  static void reset() {
    _instance = null;
  }
}

/// Web attachment service adapter (Direct download)
class WebAttachmentServiceAdapter implements PlatformAttachmentService {
  final WebAttachmentDownloadService _webDownloader = WebAttachmentDownloadService.instance;
  
  @override
  Future<void> initialize() => _webDownloader.initialize();
  
  @override
  Future<CachedFile?> getCachedFile(MailAttachment attachment, String email) =>
      _webDownloader.getCachedFile(attachment, email);
  
  @override
  Future<CachedFile> processFile({
    required MailAttachment attachment,
    required String email,
    required Uint8List fileData,
  }) => _webDownloader.downloadFile(
    attachment: attachment,
    email: email,
    fileData: fileData,
  );
  
  @override
  Future<Uint8List?> getFileData(CachedFile file) =>
      _webDownloader.getFileData(file);
  
  @override
  Future<void> handleFileAction(CachedFile file) =>
      _webDownloader.reDownloadFile(file);
  
  @override
  Future<void> clearStorage() => _webDownloader.clearDownloads();
  
  @override
  Future<CacheStats> getStorageStats() => _webDownloader.getDownloadStats();
}

/// Mobile attachment service adapter (Cache management)
class MobileAttachmentServiceAdapter implements PlatformAttachmentService {
  final MobileFileCacheService _mobileCache = MobileFileCacheService.instance;
  
  @override
  Future<void> initialize() => _mobileCache.initialize();
  
  @override
  Future<CachedFile?> getCachedFile(MailAttachment attachment, String email) =>
      _mobileCache.getCachedFile(attachment, email);
  
  @override
  Future<CachedFile> processFile({
    required MailAttachment attachment,
    required String email,
    required Uint8List fileData,
  }) => _mobileCache.cacheFile(
    attachment: attachment,
    email: email,
    fileData: fileData,
  );
  
  @override
  Future<Uint8List?> getFileData(CachedFile file) =>
      _mobileCache.getCachedFileData(file);
  
  @override
  Future<void> handleFileAction(CachedFile file) async {
    // Mobile implementation uses platform file manager
    final fileHandle = await _mobileCache.getCachedFileHandle(file);
    if (fileHandle == null) {
      throw Exception('Cached file not found: ${file.filename}');
    }
    
    // TODO: Implement mobile-specific download logic using PlatformFileManager
    // This might involve copying to Downloads folder or sharing via system share
    throw UnimplementedError('Mobile download implementation needed - use PlatformFileManager');
  }
  
  @override
  Future<void> clearStorage() => _mobileCache.clearCache();
  
  @override
  Future<CacheStats> getStorageStats() => _mobileCache.getCacheStats();
}