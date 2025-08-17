// lib/src/features/mail/domain/usecases/web_download_attachment_usecase.dart

import '../../../../core/utils/result.dart';
import '../../../../core/error/failures.dart' as failures;
import '../repositories/mail_repository.dart';
import '../entities/attachment.dart';
import '../../../../utils/app_logger.dart';
import '../../../../core/services/web_attachment_platform.dart';

/// Simplified web download use case
class WebDownloadAttachmentUseCase {
  final MailRepository _repository;
  final WebAttachmentDownloadService _webDownloader;

  WebDownloadAttachmentUseCase(
    this._repository, [
    WebAttachmentDownloadService? webDownloader,
  ]) : _webDownloader = webDownloader ?? WebAttachmentDownloadService.instance;

  /// Execute simple web download - NO CACHE
  Future<Result<WebDownloadResult>> call({
    required MailAttachment attachment,
    required String messageId,
    required String email,
  }) async {
    try {
      AppLogger.info('🌐 [Web] Download request: ${attachment.filename}');

      // Initialize
      await _webDownloader.initialize();

      // Download from server
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
            AppLogger.info('📦 [Web] Downloaded ${bytes.length} bytes, triggering browser download');

            // Direct browser download - NO CachedFile return!
            await _webDownloader.downloadFile(
              attachment: attachment,
              email: email,
              fileData: bytes,
            );

            AppLogger.info('✅ [Web] Download completed: ${attachment.filename}');

            return Success(WebDownloadResult(
              filename: attachment.filename,
              sizeBytes: bytes.length,
              method: 'browser_direct',
              success: true,
            ));

          } catch (downloadError) {
            AppLogger.error('❌ [Web] Browser download failed: $downloadError');
            return Failure(
              failures.AppFailure.unknown(
                message: 'Browser download failed: $downloadError',
              ),
            );
          }
        },
        failure: (failure) {
          AppLogger.error('❌ [Web] Server download failed: ${failure.message}');
          return Failure(failure);
        },
      );

    } catch (e) {
      AppLogger.error('❌ [Web] Unexpected error: $e');
      return Failure(
        failures.AppFailure.unknown(
          message: 'Download error: ${e.toString()}',
        ),
      );
    }
  }
}

/// Web download result
class WebDownloadResult {
  final String filename;
  final int sizeBytes;
  final String method;
  final bool success;

  const WebDownloadResult({
    required this.filename,
    required this.sizeBytes,
    required this.method,
    required this.success,
  });

  String get formattedSize {
    if (sizeBytes < 1024) return '${sizeBytes}B';
    if (sizeBytes < 1024 * 1024) return '${(sizeBytes / 1024).toStringAsFixed(1)}KB';
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
}

