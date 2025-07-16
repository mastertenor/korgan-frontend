// lib/src/core/services/platform_file_manager.dart

import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart'; // 🆕 Correct import
import 'package:open_file/open_file.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'file_cache_service.dart';
import '../../utils/app_logger.dart';

/// Platform-specific file management service
/// Handles saving, sharing, and opening files like Gmail mobile
/// 🆕 Updated for share_plus 11.0.0 - Using SharePlus.instance.share(ShareParams)
class PlatformFileManager {
  static PlatformFileManager? _instance;
  static PlatformFileManager get instance =>
      _instance ??= PlatformFileManager._();
  PlatformFileManager._();

  /// Get platform-specific save directory
  /// iOS: Documents/Attachments (Files app integration)
  /// Android: Downloads/email (Gmail benzeri)
  Future<String> getSaveDirectory() async {
    if (Platform.isIOS) {
      return await _getIOSSavePath();
    } else if (Platform.isAndroid) {
      return await _getAndroidSavePath();
    } else {
      throw UnsupportedError('Platform not supported');
    }
  }

  /// iOS: Documents/Attachments folder (Files app integration)
  Future<String> _getIOSSavePath() async {
    final directory = await getApplicationDocumentsDirectory();
    final attachmentsDir = Directory('${directory.path}/Attachments');

    if (!await attachmentsDir.exists()) {
      await attachmentsDir.create(recursive: true);
    }

    return attachmentsDir.path;
  }

  /// Android: Downloads/email folder (Gmail benzeri)
  Future<String> _getAndroidSavePath() async {
    try {
      // Android 10+ (API 29+) - Scoped Storage
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;

      if (androidInfo.version.sdkInt >= 29) {
        // Use app-specific external storage (no permissions needed)
        final directory = await getExternalStorageDirectory();
        if (directory != null) {
          final emailDir = Directory('${directory.path}/Download/email');
          if (!await emailDir.exists()) {
            await emailDir.create(recursive: true);
          }
          return emailDir.path;
        }
      }

      // Android 13+ (API 33+) - Use media-specific directories
      if (androidInfo.version.sdkInt >= 33) {
        final directory = await getApplicationDocumentsDirectory();
        final emailDir = Directory('${directory.path}/Downloads');
        if (!await emailDir.exists()) {
          await emailDir.create(recursive: true);
        }
        return emailDir.path;
      }

      // Fallback to Downloads folder for older versions
      final directory = await getDownloadsDirectory();
      if (directory != null) {
        final emailDir = Directory('${directory.path}/email');
        if (!await emailDir.exists()) {
          await emailDir.create(recursive: true);
        }
        return emailDir.path;
      }

      // Final fallback
      final appDir = await getApplicationDocumentsDirectory();
      return appDir.path;
    } catch (e) {
      AppLogger.error('Error getting Android save path: $e');
      final appDir = await getApplicationDocumentsDirectory();
      return appDir.path;
    }
  }

  /// Check and request necessary permissions
  Future<bool> checkPermissions() async {
    if (Platform.isIOS) {
      // iOS doesn't need special permissions for Documents folder
      return true;
    } else if (Platform.isAndroid) {
      return await _checkAndroidPermissions();
    }
    return false;
  }

  /// Check Android permissions (updated for Android 13+)
  Future<bool> _checkAndroidPermissions() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;

      // Android 13+ (API 33+) - Use granular media permissions
      if (androidInfo.version.sdkInt >= 33) {
        // For file attachments, check specific permissions
        final permissions = [
          Permission.photos,
          Permission.videos,
          Permission.audio,
        ];

        bool allGranted = true;
        for (final permission in permissions) {
          if (await permission.status.isDenied) {
            final status = await permission.request();
            if (!status.isGranted) {
              allGranted = false;
            }
          }
        }
        return allGranted;
      }

      // Android 10-12 (API 29-32) - Scoped Storage
      if (androidInfo.version.sdkInt >= 29) {
        // No special permissions needed for app-specific storage
        return true;
      }

      // Android 9 and below - Legacy storage permission
      var status = await Permission.storage.status;
      if (status.isDenied) {
        status = await Permission.storage.request();
      }

      return status.isGranted;
    } catch (e) {
      AppLogger.error('Error checking Android permissions: $e');
      return false;
    }
  }

  /// Save cached file to platform-specific location
  Future<SaveResult> saveToDevice(CachedFile cachedFile) async {
    try {
      // Check permissions first
      if (!await checkPermissions()) {
        return SaveResult.failure('Storage permission denied');
      }

      final saveDir = await getSaveDirectory();
      final savePath = '$saveDir/${cachedFile.filename}';

      // Check if file already exists
      final saveFile = File(savePath);
      if (await saveFile.exists()) {
        // Generate unique filename
        final uniquePath = await _generateUniquePath(
          saveDir,
          cachedFile.filename,
        );
        await _copyFile(cachedFile.localPath, uniquePath);

        AppLogger.info('File saved to: $uniquePath');
        return SaveResult.success(uniquePath);
      } else {
        await _copyFile(cachedFile.localPath, savePath);

        AppLogger.info('File saved to: $savePath');
        return SaveResult.success(savePath);
      }
    } catch (e) {
      AppLogger.error('Error saving file to device: $e');
      return SaveResult.failure(e.toString());
    }
  }

  /// Generate unique file path to avoid conflicts
  Future<String> _generateUniquePath(String directory, String filename) async {
    final extension = filename.split('.').last;
    final nameWithoutExt = filename.substring(
      0,
      filename.length - extension.length - 1,
    );

    int counter = 1;
    String uniquePath;

    do {
      uniquePath = '$directory/${nameWithoutExt}_$counter.$extension';
      counter++;
    } while (await File(uniquePath).exists());

    return uniquePath;
  }

  /// Copy file from source to destination
  Future<void> _copyFile(String sourcePath, String destPath) async {
    final sourceFile = File(sourcePath);
    await sourceFile.copy(destPath);
  }

  /// 🆕 CORRECT: Share file using SharePlus.instance.share(ShareParams)
  Future<ShareResult> shareFile(CachedFile cachedFile) async {
    try {
      // Create XFile from cached file
      final xFile = XFile(cachedFile.localPath);

      // 🆕 Use correct SharePlus v11.0.0 API
      final result = await SharePlus.instance.share(
        ShareParams(
          files: [xFile],
          text: 'Sharing ${cachedFile.filename}',
          subject: cachedFile.filename,
        ),
      );

      if (result.status == ShareResultStatus.success) {
        AppLogger.info('File shared successfully: ${cachedFile.filename}');
        return ShareResult.success();
      } else if (result.status == ShareResultStatus.dismissed) {
        AppLogger.warning('File sharing dismissed by user');
        return ShareResult.failure('Share dismissed by user');
      } else {
        AppLogger.warning('File sharing unavailable');
        return ShareResult.failure('Share unavailable on this platform');
      }
    } catch (e) {
      AppLogger.error('Error sharing file: $e');
      return ShareResult.failure(e.toString());
    }
  }

  /// Open file with external app
  Future<OpenResult> openWithExternalApp(CachedFile cachedFile) async {
    try {
      final result = await OpenFile.open(cachedFile.localPath);

      switch (result.type) {
        case ResultType.done:
          AppLogger.info('File opened successfully: ${cachedFile.filename}');
          return OpenResult.success();
        case ResultType.noAppToOpen:
          AppLogger.warning(
            'No app found to open file: ${cachedFile.filename}',
          );
          return OpenResult.failure('No app found to open this file type');
        case ResultType.permissionDenied:
          AppLogger.error(
            'Permission denied to open file: ${cachedFile.filename}',
          );
          return OpenResult.failure('Permission denied');
        case ResultType.error:
          AppLogger.error('Error opening file: ${cachedFile.filename}');
          return OpenResult.failure('Error opening file');
        case ResultType.fileNotFound:
          AppLogger.error('File not found: ${cachedFile.filename}');
          return OpenResult.failure('File not found');
      }
    } catch (e) {
      AppLogger.error('Error opening file with external app: $e');
      return OpenResult.failure(e.toString());
    }
  }

  /// Get platform-specific action items for action sheet
  List<ActionItem> getActionItems(CachedFile cachedFile) {
    return [
      ActionItem(
        id: 'save',
        title: Platform.isIOS ? 'Save to Files' : 'Save to Downloads',
        subtitle: Platform.isIOS
            ? 'Save to Files app'
            : 'Save to Downloads/email folder',
        icon: 'download',
        action: () => saveToDevice(cachedFile),
      ),
      ActionItem(
        id: 'share',
        title: 'Share',
        subtitle: 'Share with other apps',
        icon: 'share',
        action: () => shareFile(cachedFile),
      ),
      ActionItem(
        id: 'open',
        title: 'Open with',
        subtitle: 'Open with another app',
        icon: 'open_in_new',
        action: () => openWithExternalApp(cachedFile),
      ),
    ];
  }

  /// Get human-readable file type description
  String getFileTypeDescription(SupportedFileType type) {
    switch (type) {
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
      case SupportedFileType.unknown:
        return 'Unknown File';
    }
  }

  /// Get appropriate icon name for file type
  String getFileTypeIcon(SupportedFileType type) {
    switch (type) {
      case SupportedFileType.pdf:
        return 'picture_as_pdf';
      case SupportedFileType.image:
        return 'image';
      case SupportedFileType.text:
        return 'description';
      case SupportedFileType.office:
        return 'table_chart';
      case SupportedFileType.video:
        return 'videocam';
      case SupportedFileType.audio:
        return 'audiotrack';
      case SupportedFileType.unknown:
        return 'attach_file';
    }
  }
}

/// Result classes for different operations
class SaveResult {
  final bool success;
  final String message;
  final String? filePath;

  SaveResult.success(this.filePath)
    : success = true,
      message = 'File saved successfully';
  SaveResult.failure(this.message) : success = false, filePath = null;
}

class ShareResult {
  final bool success;
  final String message;

  ShareResult.success() : success = true, message = 'File shared successfully';
  ShareResult.failure(this.message) : success = false;
}

class OpenResult {
  final bool success;
  final String message;

  OpenResult.success() : success = true, message = 'File opened successfully';
  OpenResult.failure(this.message) : success = false;
}

/// Action item for action sheet
class ActionItem {
  final String id;
  final String title;
  final String subtitle;
  final String icon;
  final Future<dynamic> Function() action;

  ActionItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.action,
  });
}
