// lib/src/core/services/file_type_detector.dart

import 'package:flutter/material.dart';
import 'attachment_models.dart';
import 'package:path/path.dart' as path;

/// Enhanced file type detection for attachment preview system
///
/// Uses shared models from cache_models.dart
class FileTypeDetector {
  const FileTypeDetector._(); // Prevent instantiation

  /// Enhanced file type detection from MIME type
  ///
  /// Uses both MIME type and filename for accurate detection
  static SupportedFileType detectFromMimeType(
    String mimeType, [
    String? filename,
  ]) {
    // Normalize MIME type
    final normalizedMime = mimeType.toLowerCase().trim();

    // Primary detection from MIME type
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

    // Office documents
    if (_isOfficeDocument(normalizedMime)) {
      return SupportedFileType.office;
    }

    // Archive files
    if (_isArchiveFile(normalizedMime)) {
      return SupportedFileType.archive;
    }

    // Fallback to filename detection if MIME type is generic
    if (filename != null && _isGenericMimeType(normalizedMime)) {
      return detectFromFilename(filename);
    }

    return SupportedFileType.unknown;
  }

  /// File type detection from filename extension
  ///
  /// Fallback method when MIME type is not reliable
  static SupportedFileType detectFromFilename(String filename) {
    final extension = path.extension(filename).toLowerCase();

    // Images
    if (_imageExtensions.contains(extension)) {
      return SupportedFileType.image;
    }

    // PDF
    if (extension == '.pdf') {
      return SupportedFileType.pdf;
    }

    // Text files
    if (_textExtensions.contains(extension)) {
      return SupportedFileType.text;
    }

    // Video files
    if (_videoExtensions.contains(extension)) {
      return SupportedFileType.video;
    }

    // Audio files
    if (_audioExtensions.contains(extension)) {
      return SupportedFileType.audio;
    }

    // Office documents
    if (_officeExtensions.contains(extension)) {
      return SupportedFileType.office;
    }

    // Archive files
    if (_archiveExtensions.contains(extension)) {
      return SupportedFileType.archive;
    }

    return SupportedFileType.unknown;
  }

  /// Get appropriate icon for file type (IconData - Widget için)
  ///
  /// Material Design 3 icons
  static IconData getIcon(SupportedFileType type) {
    switch (type) {
      case SupportedFileType.image:
        return Icons.image;
      case SupportedFileType.pdf:
        return Icons.picture_as_pdf;
      case SupportedFileType.text:
        return Icons.description;
      case SupportedFileType.video:
        return Icons.videocam;
      case SupportedFileType.audio:
        return Icons.audiotrack;
      case SupportedFileType.office:
        return Icons.work;
      case SupportedFileType.archive:
        return Icons.archive;
      case SupportedFileType.unknown:
        return Icons.insert_drive_file;
    }
  }

  /// Get appropriate color for file type (Color - Widget için)
  ///
  /// Material Design 3 color scheme
  static Color getColor(SupportedFileType type) {
    switch (type) {
      case SupportedFileType.image:
        return Colors.green;
      case SupportedFileType.pdf:
        return Colors.red;
      case SupportedFileType.text:
        return Colors.blue;
      case SupportedFileType.video:
        return Colors.purple;
      case SupportedFileType.audio:
        return Colors.orange;
      case SupportedFileType.office:
        return Colors.indigo;
      case SupportedFileType.archive:
        return Colors.brown;
      case SupportedFileType.unknown:
        return Colors.grey;
    }
  }

  /// Convenience method - same as cache_models extension
  static String getTypeName(SupportedFileType type) {
    return type.displayName;
  }

  /// Auto-detect file type from multiple sources
  ///
  /// Uses MIME type, filename, and file content for best accuracy
  static SupportedFileType autoDetect({
    String? mimeType,
    String? filename,
    List<int>? fileBytes,
  }) {
    // Try MIME type first if available
    if (mimeType != null && mimeType.isNotEmpty) {
      final typeFromMime = detectFromMimeType(mimeType, filename);
      if (typeFromMime != SupportedFileType.unknown) {
        return typeFromMime;
      }
    }

    // Try filename extension
    if (filename != null && filename.isNotEmpty) {
      final typeFromFilename = detectFromFilename(filename);
      if (typeFromFilename != SupportedFileType.unknown) {
        return typeFromFilename;
      }
    }

    // Try magic number detection (future enhancement)
    if (fileBytes != null && fileBytes.isNotEmpty) {
      // TODO: Implement magic number detection
      // This would be useful for files with wrong extensions
    }

    return SupportedFileType.unknown;
  }

  // ========== CONVENIENCE METHODS ==========

  /// Shorthand for fromMimeType (legacy compatibility)
  static SupportedFileType fromMimeType(String mimeType) {
    return detectFromMimeType(mimeType);
  }

  /// Shorthand for fromFilename (legacy compatibility)  
  static SupportedFileType fromFilename(String filename) {
    return detectFromFilename(filename);
  }

  // ========== PRIVATE HELPERS ==========

  /// Check if MIME type represents an Office document
  static bool _isOfficeDocument(String mimeType) {
    return mimeType.contains('word') ||
        mimeType.contains('excel') ||
        mimeType.contains('powerpoint') ||
        mimeType.contains('spreadsheet') ||
        mimeType.contains('presentation') ||
        mimeType.contains('document') ||
        mimeType.contains('msword') ||
        mimeType.contains('ms-excel') ||
        mimeType.contains('ms-powerpoint') ||
        mimeType.contains('officedocument');
  }

  /// Check if MIME type represents an archive file
  static bool _isArchiveFile(String mimeType) {
    return mimeType.contains('zip') ||
        mimeType.contains('rar') ||
        mimeType.contains('tar') ||
        mimeType.contains('gzip') ||
        mimeType.contains('7z') ||
        mimeType.contains('compress');
  }

  /// Check if MIME type is too generic to be useful
  static bool _isGenericMimeType(String mimeType) {
    return mimeType == 'application/octet-stream' ||
        mimeType == 'application/binary' ||
        mimeType == 'application/unknown' ||
        mimeType.isEmpty;
  }

  // ========== FILE EXTENSION SETS ==========

  static const Set<String> _imageExtensions = {
    '.jpg',
    '.jpeg',
    '.png',
    '.gif',
    '.bmp',
    '.webp',
    '.svg',
    '.tiff',
    '.tif',
    '.ico',
    '.heic',
    '.heif',
  };

  static const Set<String> _textExtensions = {
    '.txt',
    '.log',
    '.csv',
    '.json',
    '.xml',
    '.yaml',
    '.yml',
    '.md',
    '.markdown',
    '.rtf',
    '.html',
    '.htm',
    '.css',
    '.js',
    '.py',
    '.java',
    '.cpp',
    '.c',
    '.h',
    '.swift',
    '.kt',
    '.dart',
  };

  static const Set<String> _videoExtensions = {
    '.mp4',
    '.avi',
    '.mov',
    '.wmv',
    '.flv',
    '.webm',
    '.mkv',
    '.m4v',
    '.3gp',
    '.3g2',
    '.mpg',
    '.mpeg',
    '.mp2',
    '.mpe',
    '.mpv',
    '.m2v',
    '.f4v',
    '.f4p',
    '.f4a',
    '.f4b',
  };

  static const Set<String> _audioExtensions = {
    '.mp3',
    '.wav',
    '.flac',
    '.aac',
    '.ogg',
    '.wma',
    '.m4a',
    '.opus',
    '.ape',
    '.aiff',
    '.au',
    '.ra',
  };

  static const Set<String> _officeExtensions = {
    '.doc',
    '.docx',
    '.xls',
    '.xlsx',
    '.ppt',
    '.pptx',
    '.odt',
    '.ods',
    '.odp',
    '.pages',
    '.numbers',
    '.key',
  };

  static const Set<String> _archiveExtensions = {
    '.zip',
    '.rar',
    '.7z',
    '.tar',
    '.gz',
    '.bz2',
    '.xz',
    '.cab',
    '.iso',
    '.dmg',
  };
}