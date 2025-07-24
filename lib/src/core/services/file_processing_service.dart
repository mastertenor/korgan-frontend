// lib/src/core/services/file_processing_service.dart

import 'dart:io';
import 'dart:convert';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;
import '../../features/mail/domain/entities/attachment_upload.dart';

/// File processing service for attachment handling
///
/// Provides utilities for:
/// - File → Base64 conversion
/// - MIME type detection
/// - File size validation
/// - AttachmentUpload entity creation
class FileProcessingService {
  
  // ========== CONSTANTS ==========
  
  /// Maximum file size in MB
  static const int maxFileSizeMB = 25;
  
  /// Maximum file size in bytes
  static const int maxFileSizeBytes = maxFileSizeMB * 1024 * 1024;
  
  /// Supported file types for attachments
  static const List<String> supportedMimeTypes = [
    // Images
    'image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'image/bmp', 'image/webp',
    // Documents
    'application/pdf', 'text/plain', 'text/html',
    'application/msword', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'application/vnd.ms-excel', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'application/vnd.ms-powerpoint', 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
    // Archives
    'application/zip', 'application/x-rar-compressed', 'application/x-7z-compressed',
    // Audio
    'audio/mpeg', 'audio/wav', 'audio/ogg', 'audio/mp4',
    // Video
    'video/mp4', 'video/avi', 'video/mov', 'video/wmv',
    // Other
    'application/json', 'application/xml',
  ];
  
  // ========== MAIN METHODS ==========
  
  /// Create AttachmentUpload from File
  ///
  /// This is the main method that combines all operations:
  /// 1. File validation
  /// 2. MIME type detection
  /// 3. Base64 conversion
  /// 4. AttachmentUpload entity creation
  static Future<AttachmentUpload> createAttachmentFromFile(File file) async {
    try {
      // 1. Validate file
      await _validateFile(file);
      
      // 2. Get file info
      final fileName = path.basename(file.path);
      final mimeType = detectMimeType(file.path);
      
      // 3. Convert to Base64
      final base64Content = await fileToBase64(file);
      
      // 4. Create AttachmentUpload entity
      return AttachmentUpload(
        content: base64Content,
        type: mimeType,
        filename: fileName,
        disposition: 'attachment',
      );
      
    } catch (e) {
      throw FileProcessingException('Failed to process file: ${e.toString()}');
    }
  }
  
  /// Convert File to Base64 string
  static Future<String> fileToBase64(File file) async {
    try {
      final bytes = await file.readAsBytes();
      return base64Encode(bytes);
    } catch (e) {
      throw FileProcessingException('Failed to convert file to Base64: ${e.toString()}');
    }
  }
  
  /// Detect MIME type from file path
  static String detectMimeType(String filePath) {
    final mimeType = lookupMimeType(filePath);
    return mimeType ?? 'application/octet-stream';
  }
  
  /// Check if file size is valid
  static Future<bool> isFileSizeValid(File file, {int? maxSizeMB}) async {
    try {
      final maxSize = (maxSizeMB ?? maxFileSizeMB) * 1024 * 1024;
      final fileSize = await file.length();
      return fileSize <= maxSize;
    } catch (e) {
      return false;
    }
  }
  
  /// Check if MIME type is supported
  static bool isMimeTypeSupported(String mimeType) {
    return supportedMimeTypes.contains(mimeType.toLowerCase());
  }
  
  /// Format file size for display
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
  
  /// Get file size in bytes
  static Future<int> getFileSize(File file) async {
    try {
      return await file.length();
    } catch (e) {
      throw FileProcessingException('Failed to get file size: ${e.toString()}');
    }
  }
  
  /// Get file extension
  static String getFileExtension(String fileName) {
    return path.extension(fileName).toLowerCase();
  }
  
  /// Check if file is an image
  static bool isImageFile(String mimeType) {
    return mimeType.startsWith('image/');
  }
  
  /// Check if file is a document
  static bool isDocumentFile(String mimeType) {
    return mimeType.startsWith('application/') || 
           mimeType.startsWith('text/');
  }
  
  /// Check if file is a video
  static bool isVideoFile(String mimeType) {
    return mimeType.startsWith('video/');
  }
  
  /// Check if file is an audio
  static bool isAudioFile(String mimeType) {
    return mimeType.startsWith('audio/');
  }
  
  // ========== PRIVATE VALIDATION METHODS ==========
  
  /// Validate file before processing
  static Future<void> _validateFile(File file) async {
    // Check if file exists
    if (!await file.exists()) {
      throw FileProcessingException('File does not exist');
    }
    
    // Check file size
    final isValidSize = await isFileSizeValid(file);
    if (!isValidSize) {
      final fileSizeBytes = await file.length();
      final fileSizeFormatted = formatFileSize(fileSizeBytes);
      throw FileProcessingException(
        'File size ($fileSizeFormatted) exceeds maximum limit (${maxFileSizeMB}MB)'
      );
    }
    
    // Check MIME type
    final mimeType = detectMimeType(file.path);
    if (!isMimeTypeSupported(mimeType)) {
      throw FileProcessingException('File type ($mimeType) is not supported');
    }
  }
}

/// Custom exception for file processing errors
class FileProcessingException implements Exception {
  final String message;
  
  const FileProcessingException(this.message);
  
  @override
  String toString() => 'FileProcessingException: $message';
}