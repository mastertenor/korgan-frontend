// lib/src/core/services/attachment_service_factory.dart

import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../../features/mail/domain/entities/attachment.dart';
import 'attachment_models.dart';
import 'mobile_attachment_cache.dart';
import 'web_attachment_platform.dart';

/// Platform-aware cache service interface
abstract class PlatformCacheService {
  Future<void> initialize();
  Future<CachedFile?> getCachedFile(MailAttachment attachment, String email);
  Future<CachedFile> cacheFile({
    required MailAttachment attachment,
    required String email,
    required Uint8List fileData,
  });
  Future<Uint8List?> getCachedFileData(CachedFile cachedFile);
  Future<void> downloadCachedFile(CachedFile cachedFile);
  Future<void> clearCache();
  Future<CacheStats> getCacheStats();
}

/// Factory for creating platform-specific cache services
class CacheServiceFactory {
  static PlatformCacheService? _instance;
  
  /// Get the appropriate cache service for current platform
  static PlatformCacheService get instance {
    if (_instance != null) return _instance!;
    
    if (kIsWeb) {
      _instance = WebCacheServiceAdapter();
    } else {
      _instance = MobileCacheServiceAdapter();
    }
    
    return _instance!;
  }

  /// Reset instance (for testing)
  static void reset() {
    _instance = null;
  }
}

/// Web cache service adapter
class WebCacheServiceAdapter implements PlatformCacheService {
  final WebFileCacheService _webCache = WebFileCacheService.instance;
  
  @override
  Future<void> initialize() => _webCache.initialize();
  
  @override
  Future<CachedFile?> getCachedFile(MailAttachment attachment, String email) =>
      _webCache.getCachedFile(attachment, email);
  
  @override
  Future<CachedFile> cacheFile({
    required MailAttachment attachment,
    required String email,
    required Uint8List fileData,
  }) => _webCache.cacheFile(
    attachment: attachment,
    email: email,
    fileData: fileData,
  );
  
  @override
  Future<Uint8List?> getCachedFileData(CachedFile cachedFile) =>
      _webCache.getCachedFileData(cachedFile);
  
  @override
  Future<void> downloadCachedFile(CachedFile cachedFile) =>
      _webCache.downloadCachedFile(cachedFile);
  
  @override
  Future<void> clearCache() => _webCache.clearCache();
  
  @override
  Future<CacheStats> getCacheStats() => _webCache.getCacheStats();
}

/// Mobile cache service adapter
class MobileCacheServiceAdapter implements PlatformCacheService {
  final MobileFileCacheService _mobileCache = MobileFileCacheService.instance;
  
  @override
  Future<void> initialize() => _mobileCache.initialize();
  
  @override
  Future<CachedFile?> getCachedFile(MailAttachment attachment, String email) =>
      _mobileCache.getCachedFile(attachment, email);
  
  @override
  Future<CachedFile> cacheFile({
    required MailAttachment attachment,
    required String email,
    required Uint8List fileData,
  }) => _mobileCache.cacheFile(
    attachment: attachment,
    email: email,
    fileData: fileData,
  );
  
  @override
  Future<Uint8List?> getCachedFileData(CachedFile cachedFile) =>
      _mobileCache.getCachedFileData(cachedFile);
  
  @override
  Future<void> downloadCachedFile(CachedFile cachedFile) async {
    // Mobile implementation uses platform file manager
    // For now, we'll just get the file handle - full implementation depends on your mobile download logic
    final fileHandle = await _mobileCache.getCachedFileHandle(cachedFile);
    if (fileHandle == null) {
      throw Exception('Cached file not found: ${cachedFile.filename}');
    }
    
    // TODO: Implement mobile-specific download logic using PlatformFileManager
    // This might involve copying to Downloads folder or sharing via system share
    throw UnimplementedError('Mobile download implementation needed - use PlatformFileManager');
  }
  
  @override
  Future<void> clearCache() => _mobileCache.clearCache();
  
  @override
  Future<CacheStats> getCacheStats() => _mobileCache.getCacheStats();
}

/// Legacy compatibility layer for existing code
/// This allows gradual migration from old FileCacheService
class FileCacheService {
  static FileCacheService? _instance;
  static FileCacheService get instance => _instance ??= FileCacheService._();
  
  final PlatformCacheService _platformService = CacheServiceFactory.instance;
  
  FileCacheService._();
  
  /// Legacy method - redirects to platform service
  Future<void> initialize() => _platformService.initialize();
  
  /// Legacy method - redirects to platform service
  Future<CachedFile?> getCachedFile(
    MailAttachment attachment,
    String email,
  ) => _platformService.getCachedFile(attachment, email);
  
  /// Legacy method - redirects to platform service
  Future<CachedFile> cacheFile(
    MailAttachment attachment,
    String email,
    Uint8List data,
  ) => _platformService.cacheFile(
    attachment: attachment,
    email: email,
    fileData: data,
  );
  
  /// Legacy method - redirects to platform service
  Future<Map<String, dynamic>> getDetailedCacheInfo() async {
    final stats = await _platformService.getCacheStats();
    return stats.toJson();
  }
}