// lib/src/features/mail/domain/usecases/download_attachment_usecase.dart

import 'dart:typed_data';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/error/failures.dart' as failures;
import '../repositories/mail_repository.dart';
import '../entities/attachment.dart';
import '../../../../utils/app_logger.dart';
import '../../../../core/services/attachment_service_factory.dart';
import '../../../../core/services/attachment_models.dart';

/// Enhanced use case for downloading email attachments with caching
///
/// This use case handles:
/// - Cache checking (Gmail benzeri 36 saat)
/// - Background downloading
/// - Cache management
/// - Error handling
class DownloadAttachmentUseCase {
  final MailRepository _repository;
  final PlatformCacheService _cacheService;

  DownloadAttachmentUseCase(this._repository, [PlatformCacheService? cacheService])
    : _cacheService = cacheService ?? CacheServiceFactory.instance;

  /// Execute the download attachment use case with caching
  ///
  /// [attachment] - Mail attachment entity
  /// [messageId] - Gmail message ID containing the attachment
  /// [email] - User's email address
  /// [forceDownload] - Force download even if cached
  ///
  /// Returns a Result containing either CachedFile or a Failure
  Future<Result<CachedFile>> call({
    required MailAttachment attachment,
    required String messageId,
    required String email,
    bool forceDownload = false,
  }) async {
    try {
      AppLogger.info('📎 Download request for: ${attachment.filename}');

      // Validate parameters
      final validation = _validateParams(
        attachment: attachment,
        messageId: messageId,
        email: email,
      );

      if (validation != null) {
        return Failure(validation);
      }

      // Initialize cache service
      await _cacheService.initialize();

      // Check cache first (unless forced)
      if (!forceDownload) {
        final cachedFile = await _cacheService.getCachedFile(attachment, email);
        if (cachedFile != null) {
          AppLogger.info('✅ Cache hit for: ${attachment.filename}');
          return Success(cachedFile);
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
            // Cache the downloaded file - FIX: Use named parameters
            final cachedFile = await _cacheService.cacheFile(
              attachment: attachment,
              email: email,
              fileData: bytes,
            );

            AppLogger.info(
              '✅ Download & cache success: ${attachment.filename} (${bytes.length} bytes)',
            );
            return Success(cachedFile);
          } catch (cacheError) {
            AppLogger.error(
              'Cache error (but download succeeded): $cacheError',
            );

            // Even if caching fails, we can still return a temporary file
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
          success: (cachedFile) => results.add(cachedFile),
          failure: (failure) => errors.add(failure),
        );
      }

      if (errors.isNotEmpty && results.isEmpty) {
        // All downloads failed
        return Failure(errors.first);
      }

      return Success(results);
    } catch (e) {
      return Failure(
        failures.AppFailure.unknown(
          message: 'Failed to download multiple attachments: ${e.toString()}',
        ),
      );
    }
  }

  /// Get cached file if available
  Future<CachedFile?> getCachedFile(
    MailAttachment attachment,
    String email,
  ) async {
    try {
      await _cacheService.initialize();
      return await _cacheService.getCachedFile(attachment, email);
    } catch (e) {
      AppLogger.error('Error getting cached file: $e');
      return null;
    }
  }

  /// Check if attachment is cached
  Future<bool> isCached(MailAttachment attachment, String email) async {
    final cachedFile = await getCachedFile(attachment, email);
    return cachedFile != null;
  }

  /// Create temporary file when caching fails
  Future<CachedFile> _createTemporaryFile(
    MailAttachment attachment,
    Uint8List bytes,
  ) async {
    final tempDir = await getTemporaryDirectory();
    final tempPath = '${tempDir.path}/temp_${attachment.filename}';

    final file = File(tempPath);
    await file.writeAsBytes(bytes);

    return CachedFile(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      filename: attachment.filename,
      mimeType: attachment.mimeType,
      localPath: tempPath,
      size: bytes.length,
      cachedAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(hours: 1)), // 1 hour temp
      type: FileTypeDetector.fromMimeType(attachment.mimeType), // FIX: Use FileTypeDetector
    );
  }

  /// Validate input parameters with proper email regex handling
  failures.Failure? _validateParams({
    required MailAttachment attachment,
    required String messageId,
    required String email,
  }) {
    if (messageId.isEmpty) {
      return failures.ValidationFailure(
        message: 'Message ID cannot be empty',
        code: 'INVALID_MESSAGE_ID',
      );
    }

    if (attachment.id.isEmpty) {
      return failures.ValidationFailure(
        message: 'Attachment ID cannot be empty',
        code: 'INVALID_ATTACHMENT_ID',
      );
    }

    if (attachment.filename.isEmpty) {
      return failures.ValidationFailure(
        message: 'Filename cannot be empty',
        code: 'INVALID_FILENAME',
      );
    }

    if (email.isEmpty) {
      return failures.ValidationFailure(
        message: 'Email cannot be empty',
        code: 'INVALID_EMAIL',
      );
    }

    // 🔧 FIXED: Proper email validation without linting error
    const emailPattern = r'^[^@]+@[^@]+\.[^@]+$';
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