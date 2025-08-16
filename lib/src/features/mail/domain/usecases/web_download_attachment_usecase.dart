// lib/src/features/mail/domain/usecases/web_download_attachment_usecase.dart

import '../../../../core/utils/result.dart';
import '../../../../core/error/failures.dart' as failures;
import '../repositories/mail_repository.dart';
import '../entities/attachment.dart';
import '../../../../utils/app_logger.dart';
import '../../../../core/services/web_attachment_platform.dart'; //// buraya dikkat normalde platform olanını eklemiştik.

/// Web-specific use case for downloading email attachments
///
/// Web Platform Flow:
/// 1. Show file save picker first (user selects location)
/// 2. If user cancels → return cancellation failure
/// 3. If user selects location → download file
/// 4. Write directly to selected location
class WebDownloadAttachmentUseCase {
  final MailRepository _repository;
  final WebAttachmentDownloadService _webDownloader;

  WebDownloadAttachmentUseCase(
    this._repository, [
    WebAttachmentDownloadService? webDownloader,
  ]) : _webDownloader = webDownloader ?? WebAttachmentDownloadService.instance;

  /// Execute web-specific download flow
  Future<Result<WebDownloadResult>> call({
    required MailAttachment attachment,
    required String messageId,
    required String email,
  }) async {
    try {
      AppLogger.info('🌐 [Web] Download request for: ${attachment.filename}');

      // Initialize web download service
      await _webDownloader.initialize();

      // STEP 1: Show save file picker FIRST
      AppLogger.info('📁 [Web] Showing save file picker for: ${attachment.filename}');
      
      final fileHandle = await _webDownloader.showSavePickerFirst(
        attachment.filename,
        attachment.mimeType,
      );

      // Check if user cancelled
      if (fileHandle == null) {
        AppLogger.info('ℹ️ [Web] User cancelled save dialog for: ${attachment.filename}');
        return Failure(
          failures.AppFailure.cancelled(),
        );
      }

      // Check for fallback mode
      final isFallbackMode = fileHandle == 'traditional_fallback';
      
      if (isFallbackMode) {
        AppLogger.info('🔄 [Web] Using traditional download fallback for: ${attachment.filename}');
      } else {
        AppLogger.info('✅ [Web] User selected save location for: ${attachment.filename}');
      }

      // STEP 2: Now download the file (user confirmed save location)
      AppLogger.info('📥 [Web] Starting download from server: ${attachment.filename}');

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
            AppLogger.info('📦 [Web] Download completed (${bytes.length} bytes), saving to user location');

            // STEP 3: Save to user-selected location
            if (isFallbackMode) {
              // Use traditional download method
              await _webDownloader.downloadWithTraditionalMethod(
                attachment.filename,
                bytes,
                attachment.mimeType,
              );
            } else {
              // Use modern File System Access API
              await _webDownloader.saveToFileHandle(
                fileHandle,
                bytes,
                attachment.filename,
              );
            }

            AppLogger.info('✅ [Web] File saved successfully: ${attachment.filename}');

            return Success(WebDownloadResult(
              filename: attachment.filename,
              sizeBytes: bytes.length,
              method: isFallbackMode ? 'traditional' : 'modern',
              success: true,
            ));

          } catch (saveError) {
            AppLogger.error('❌ [Web] Save error: $saveError');
            
            // Check if this is a user cancellation during save
            final errorMsg = saveError.toString().toLowerCase();
            if (errorMsg.contains('abort') || 
                errorMsg.contains('cancel') || 
                errorMsg.contains('iptal')) {
              return Failure(
                failures.AppFailure.cancelled(),
              );
            }

            return Failure(
              failures.AppFailure.unknown(
                message: 'Dosya kaydetme hatası: $saveError',
              ),
            );
          }
        },
        failure: (failure) {
          AppLogger.error('❌ [Web] Download from server failed: ${failure.message}');
          return Failure(failure);
        },
      );

    } catch (e) {
      AppLogger.error('❌ [Web] Unexpected error in web download use case: $e');
      
      return Failure(
        failures.AppFailure.unknown(
          message: 'Web download error: ${e.toString()}',
        ),
      );
    }
  }
}

/// Web download result model
class WebDownloadResult {
  final String filename;
  final int sizeBytes;
  final String method; // 'modern' or 'traditional'
  final bool success;

  const WebDownloadResult({
    required this.filename,
    required this.sizeBytes,
    required this.method,
    required this.success,
  });

  /// Size in human readable format
  String get formattedSize {
    if (sizeBytes < 1024) {
      return '${sizeBytes}B';
    } else if (sizeBytes < 1024 * 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(1)}KB';
    } else {
      return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
  }

  @override
  String toString() {
    return 'WebDownloadResult(filename: $filename, size: $formattedSize, method: $method)';
  }
}