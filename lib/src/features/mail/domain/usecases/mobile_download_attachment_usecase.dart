// lib/src/features/mail/domain/usecases/mobile_download_attachment_usecase.dart

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/error/failures.dart' as failures;
import '../repositories/mail_repository.dart';
import '../entities/attachment.dart';
import '../../../../utils/app_logger.dart';
import '../../../../core/services/attachment_service_factory.dart';
import '../../../../core/services/attachment_models.dart';

/// Enhanced use case for downloading email attachments with platform-aware processing
///
/// This use case handles:
/// - Mobile: Cache checking (Gmail benzeri 36 saat)
/// - Web: Direct browser download
/// - Background downloading
/// - Platform-specific file management
/// - Error handling
class MobileDownloadAttachmentUseCase {
  final MailRepository _repository;
  final PlatformAttachmentService _attachmentService;

  MobileDownloadAttachmentUseCase(this._repository, [PlatformAttachmentService? attachmentService])
    : _attachmentService = attachmentService ?? AttachmentServiceFactory.instance;

  /// Execute the download attachment use case with platform-aware processing
  ///
  /// [attachment] - Mail attachment entity
  /// [messageId] - Gmail message ID containing the attachment
  /// [email] - User's email address
  /// [forceDownload] - Force download even if cached (mobile only)
  ///
  /// Returns a Result containing either CachedFile or a Failure
  Future<Result<CachedFile>> call({
    required MailAttachment attachment,
    required String messageId,
    required String email,
    bool forceDownload = false,
  }) async {
    try {
      AppLogger.info('📎 Attachment request for: ${attachment.filename}');

      // Validate parameters
      final validation = _validateParams(
        attachment: attachment,
        messageId: messageId,
        email: email,
      );

      if (validation != null) {
        return Failure(validation);
      }

      // Initialize attachment service
      await _attachmentService.initialize();

      // Check for existing file first (unless forced)
      // Note: Web always returns null, Mobile checks cache
      if (!forceDownload) {
        final existingFile = await _attachmentService.getCachedFile(attachment, email);
        if (existingFile != null) {
          AppLogger.info('✅ File available: ${attachment.filename}');
          return Success(existingFile);
        }
      }

      // Download from remote
      AppLogger.info('📥 Downloading from remote: ${attachment.filename}');

      final downloadResult = await _repository.downloadAttachment(
        messageId: messageId,
        attachmentId: attachment.id,
        filename: attachment.filename,
        email: email,
        mimeType: attachment.mimeType,
      );

      return downloadResult.when(
        success: (bytes) async {
          try {
            // Process the downloaded file (cache on mobile, download on web)
            final processedFile = await _attachmentService.processFile(
              attachment: attachment,
              email: email,
              fileData: bytes,
            );

            AppLogger.info(
              '✅ File processed successfully: ${attachment.filename} (${bytes.length} bytes)',
            );
            return Success(processedFile);
          } catch (processError) {
            AppLogger.error(
              'File processing error (but download succeeded): $processError',
            );

            // Even if processing fails, we can still return a temporary file
            final tempFile = await _createTemporaryFile(attachment, bytes);
            return Success(tempFile);
          }
        },
        failure: (failure) {
          AppLogger.error('❌ Download failed: ${failure.message}');
          return Failure(failure);
        },
      );
    } catch (e) {
      AppLogger.error('❌ Unexpected error in download use case: $e');
      return Failure(
        failures.AppFailure.unknown(
          message:
              'Unexpected error during attachment download: ${e.toString()}',
        ),
      );
    }
  }

  /// Get or download multiple attachments
  Future<Result<List<CachedFile>>> downloadMultiple({
    required List<MailAttachment> attachments,
    required String messageId,
    required String email,
    bool forceDownload = false,
  }) async {
    try {
      final results = <CachedFile>[];
      final errors = <failures.Failure>[];

      for (final attachment in attachments) {
        final result = await call(
          attachment: attachment,
          messageId: messageId,
          email: email,
          forceDownload: forceDownload,
        );

        result.when(
          success: (file) => results.add(file),
          failure: (failure) => errors.add(failure),
        );
      }

      if (errors.isNotEmpty && results.isEmpty) {
        // All downloads failed
        return Failure(
          failures.AppFailure.unknown(
            message: 'All attachment downloads failed',
          ),
        );
      }

      if (errors.isNotEmpty) {
        // Some downloads failed
        AppLogger.warning(
          'Partial download success: ${results.length}/${attachments.length}',
        );
      }

      return Success(results);
    } catch (e) {
      AppLogger.error('❌ Unexpected error in multiple download: $e');
      return Failure(
        failures.AppFailure.unknown(
          message: 'Unexpected error during multiple downloads: ${e.toString()}',
        ),
      );
    }
  }

  /// Get file data for a processed file
  Future<Result<Uint8List>> getFileData(CachedFile file) async {
    try {
      final data = await _attachmentService.getFileData(file);
      if (data != null) {
        return Success(data);
      } else {
        return Failure(
          failures.CacheFailure.notFound(),
        );
      }
    } catch (e) {
      AppLogger.error('❌ Error getting file data: $e');
      return Failure(
        failures.AppFailure.unknown(
          message: 'Error accessing file data: ${e.toString()}',
        ),
      );
    }
  }

  /// Handle file action (re-download on web, open on mobile)
  Future<Result<void>> handleFileAction(CachedFile file) async {
    try {
      await _attachmentService.handleFileAction(file);
      return const Success(null);
    } catch (e) {
      AppLogger.error('❌ Error handling file action: $e');
      return Failure(
        failures.AppFailure.unknown(
          message: 'Error handling file action: ${e.toString()}',
        ),
      );
    }
  }

  /// Clear all cached/downloaded files
  Future<Result<void>> clearStorage() async {
    try {
      await _attachmentService.clearStorage();
      AppLogger.info('🧹 Storage cleared successfully');
      return const Success(null);
    } catch (e) {
      AppLogger.error('❌ Error clearing storage: $e');
      return Failure(
        failures.AppFailure.unknown(
          message: 'Error clearing storage: ${e.toString()}',
        ),
      );
    }
  }

  /// Get storage statistics
  Future<Result<CacheStats>> getStorageStats() async {
    try {
      final stats = await _attachmentService.getStorageStats();
      return Success(stats);
    } catch (e) {
      AppLogger.error('❌ Error getting storage stats: $e');
      return Failure(
        failures.AppFailure.unknown(
          message: 'Error getting storage statistics: ${e.toString()}',
        ),
      );
    }
  }

  /// Create temporary file when processing fails
  Future<CachedFile> _createTemporaryFile(
    MailAttachment attachment,
    Uint8List bytes,
  ) async {
    try {
      // For mobile, try to save to temp directory
      if (!kIsWeb) {
        final tempDir = await getTemporaryDirectory();
        final tempPath = '${tempDir.path}/temp_${attachment.filename}';
        final tempFile = File(tempPath);
        await tempFile.writeAsBytes(bytes);

        return CachedFile(
          id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
          filename: attachment.filename,
          mimeType: attachment.mimeType,
          localPath: tempPath,
          size: bytes.length,
          cachedAt: DateTime.now(),
          expiresAt: DateTime.now().add(Duration(minutes: 30)), // Short expiry for temp
          type: FileTypeDetector.fromMimeType(attachment.mimeType),
        );
      } else {
        // For web, create virtual temp file
        return CachedFile(
          id: 'web_temp_${DateTime.now().millisecondsSinceEpoch}',
          filename: attachment.filename,
          mimeType: attachment.mimeType,
          localPath: 'temp://${attachment.filename}',
          size: bytes.length,
          cachedAt: DateTime.now(),
          expiresAt: DateTime.now().add(Duration(minutes: 5)),
          type: FileTypeDetector.fromMimeType(attachment.mimeType),
        );
      }
    } catch (e) {
      AppLogger.error('Error creating temporary file: $e');
      // Return minimal temp file info
      return CachedFile(
        id: 'error_temp_${DateTime.now().millisecondsSinceEpoch}',
        filename: attachment.filename,
        mimeType: attachment.mimeType,
        localPath: 'error://temp',
        size: bytes.length,
        cachedAt: DateTime.now(),
        expiresAt: DateTime.now().add(Duration(minutes: 1)),
        type: FileTypeDetector.fromMimeType(attachment.mimeType),
      );
    }
  }

  /// Validate input parameters
  failures.Failure? _validateParams({
    required MailAttachment attachment,
    required String messageId,
    required String email,
  }) {
    if (attachment.filename.isEmpty) {
      return failures.ValidationFailure(
        message: 'Attachment filename cannot be empty',
        code: 'EMPTY_FILENAME',
      );
    }

    if (messageId.isEmpty) {
      return failures.ValidationFailure(
        message: 'Message ID cannot be empty',
        code: 'EMPTY_MESSAGE_ID',
      );
    }

    if (email.isEmpty) {
      return failures.ValidationFailure(
        message: 'Email cannot be empty',
        code: 'EMPTY_EMAIL',
      );
    }

    // Basic email validation
    const emailPattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
    final emailRegex = RegExp(emailPattern);
    final isValidEmail = emailRegex.hasMatch(email);

    if (!isValidEmail) {
      return failures.ValidationFailure(
        message: 'Invalid email format',
        code: 'INVALID_EMAIL_FORMAT',
      );
    }

    return null; // No validation errors
  }
}