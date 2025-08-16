// lib/src/core/services/attachment_models.dart

import 'dart:io';

/// Cached file model - Platform independent
/// Used by both mobile and web cache services
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

  /// Check if file exists (Mobile only - Web will override)
  Future<bool> get exists async {
    try {
      // This will work only on mobile
      return File(localPath).exists();
    } catch (e) {
      // On web, File() will fail, return true for web cache paths
      return localPath.startsWith('web_cache://');
    }
  }

  /// Get file size on disk (Mobile only - Web will override)
  Future<int> get actualSize async {
    try {
      final file = File(localPath);
      return await file.length();
    } catch (e) {
      // On web, return the stored size
      return size;
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

  /// Create a copy with updated fields
  CachedFile copyWith({
    String? id,
    String? filename,
    String? mimeType,
    String? localPath,
    int? size,
    DateTime? cachedAt,
    DateTime? expiresAt,
    SupportedFileType? type,
  }) {
    return CachedFile(
      id: id ?? this.id,
      filename: filename ?? this.filename,
      mimeType: mimeType ?? this.mimeType,
      localPath: localPath ?? this.localPath,
      size: size ?? this.size,
      cachedAt: cachedAt ?? this.cachedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      type: type ?? this.type,
    );
  }

  @override
  String toString() {
    return 'CachedFile(id: $id, filename: $filename, size: $size, type: $type)';
  }
}

/// Supported file types for preview
enum SupportedFileType { 
  pdf, 
  image, 
  text, 
  office, 
  video, 
  audio, 
  archive,
  unknown 
}

/// Extension methods for SupportedFileType
extension SupportedFileTypeExtension on SupportedFileType {
  /// Get display name for file type
  String get displayName {
    switch (this) {
      case SupportedFileType.pdf:
        return 'PDF Document';
      case SupportedFileType.image:
        return 'Image';
      case SupportedFileType.text:
        return 'Text Document';
      case SupportedFileType.office:
        return 'Office Document';
      case SupportedFileType.video:
        return 'Video';
      case SupportedFileType.audio:
        return 'Audio';
      case SupportedFileType.archive:
        return 'Archive';
      case SupportedFileType.unknown:
        return 'File';
    }
  }

  /// Check if file type supports preview
  bool get supportsPreview {
    switch (this) {
      case SupportedFileType.pdf:
      case SupportedFileType.image:
      case SupportedFileType.text:
      case SupportedFileType.video:
      case SupportedFileType.audio:
        return true;
      case SupportedFileType.office:
      case SupportedFileType.archive:
      case SupportedFileType.unknown:
        return false;
    }
  }

  /// Get appropriate icon for file type
  String get iconName {
    switch (this) {
      case SupportedFileType.pdf:
        return 'picture_as_pdf';
      case SupportedFileType.image:
        return 'image';
      case SupportedFileType.text:
        return 'description';
      case SupportedFileType.office:
        return 'work';
      case SupportedFileType.video:
        return 'videocam';
      case SupportedFileType.audio:
        return 'audiotrack';
      case SupportedFileType.archive:
        return 'archive';
      case SupportedFileType.unknown:
        return 'insert_drive_file';
    }
  }
}

/// Cache statistics model
class CacheStats {
  final int totalFiles;
  final int totalSizeBytes;
  final int maxSizeBytes;
  final int expiredFiles;
  final Map<SupportedFileType, int> filesByType;
  final bool isInitialized;
  final Duration cacheTimeout;
  final String platform;

  const CacheStats({
    required this.totalFiles,
    required this.totalSizeBytes,
    required this.maxSizeBytes,
    required this.expiredFiles,
    required this.filesByType,
    required this.isInitialized,
    required this.cacheTimeout,
    required this.platform,
  });

  /// Total size in MB
  double get totalSizeMB => totalSizeBytes / (1024 * 1024);

  /// Max size in MB
  double get maxSizeMB => maxSizeBytes / (1024 * 1024);

  /// Usage percentage
  int get usagePercent => totalSizeBytes > 0 
      ? ((totalSizeBytes / maxSizeBytes) * 100).round() 
      : 0;

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'totalFiles': totalFiles,
      'totalSizeBytes': totalSizeBytes,
      'totalSizeMB': totalSizeMB.toStringAsFixed(2),
      'maxSizeBytes': maxSizeBytes,
      'maxSizeMB': maxSizeMB.round(),
      'usagePercent': usagePercent,
      'expiredFiles': expiredFiles,
      'filesByType': filesByType.map((k, v) => MapEntry(k.name, v)),
      'isInitialized': isInitialized,
      'cacheTimeoutHours': cacheTimeout.inHours,
      'platform': platform,
    };
  }

  /// Create from JSON
  factory CacheStats.fromJson(Map<String, dynamic> json) {
    final filesByTypeJson = json['filesByType'] as Map<String, dynamic>? ?? {};
    final filesByType = <SupportedFileType, int>{};
    
    for (final entry in filesByTypeJson.entries) {
      final type = SupportedFileType.values.firstWhere(
        (e) => e.name == entry.key,
        orElse: () => SupportedFileType.unknown,
      );
      filesByType[type] = entry.value as int? ?? 0;
    }

    return CacheStats(
      totalFiles: json['totalFiles'] ?? 0,
      totalSizeBytes: json['totalSizeBytes'] ?? 0,
      maxSizeBytes: json['maxSizeBytes'] ?? 0,
      expiredFiles: json['expiredFiles'] ?? 0,
      filesByType: filesByType,
      isInitialized: json['isInitialized'] ?? false,
      cacheTimeout: Duration(hours: json['cacheTimeoutHours'] ?? 36),
      platform: json['platform'] ?? 'unknown',
    );
  }

  @override
  String toString() {
    return 'CacheStats(files: $totalFiles, size: ${totalSizeMB.toStringAsFixed(2)}MB, usage: $usagePercent%, platform: $platform)';
  }
}

/// File type detector utility
class FileTypeDetector {
  const FileTypeDetector._();

  /// Detect file type from MIME type
  static SupportedFileType fromMimeType(String mimeType) {
    final normalizedMime = mimeType.toLowerCase().trim();

    if (normalizedMime.startsWith('image/')) {
      return SupportedFileType.image;
    }
    if (normalizedMime.contains('pdf')) {
      return SupportedFileType.pdf;
    }
    if (normalizedMime.startsWith('text/')) {
      return SupportedFileType.text;
    }
    if (normalizedMime.startsWith('video/')) {
      return SupportedFileType.video;
    }
    if (normalizedMime.startsWith('audio/')) {
      return SupportedFileType.audio;
    }
    if (normalizedMime.contains('zip') || 
        normalizedMime.contains('rar') || 
        normalizedMime.contains('archive')) {
      return SupportedFileType.archive;
    }
    if (normalizedMime.contains('word') ||
        normalizedMime.contains('excel') ||
        normalizedMime.contains('powerpoint') ||
        normalizedMime.contains('office') ||
        normalizedMime.contains('spreadsheet')) {
      return SupportedFileType.office;
    }
    
    return SupportedFileType.unknown;
  }

  /// Detect file type from filename extension
  static SupportedFileType fromFilename(String filename) {
    final extension = filename.split('.').last.toLowerCase();

    switch (extension) {
      case 'pdf':
        return SupportedFileType.pdf;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
      case 'svg':
      case 'bmp':
        return SupportedFileType.image;
      case 'txt':
      case 'md':
      case 'csv':
      case 'log':
      case 'json':
      case 'xml':
        return SupportedFileType.text;
      case 'mp4':
      case 'avi':
      case 'mov':
      case 'wmv':
      case 'mkv':
      case 'webm':
        return SupportedFileType.video;
      case 'mp3':
      case 'wav':
      case 'aac':
      case 'flac':
      case 'ogg':
        return SupportedFileType.audio;
      case 'zip':
      case 'rar':
      case '7z':
      case 'tar':
      case 'gz':
        return SupportedFileType.archive;
      case 'doc':
      case 'docx':
      case 'xls':
      case 'xlsx':
      case 'ppt':
      case 'pptx':
        return SupportedFileType.office;
      default:
        return SupportedFileType.unknown;
    }
  }
}