// lib/src/features/mail/presentation/pages/attachment_preview_page.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../core/services/file_cache_service.dart';
import '../../../../../core/services/file_type_detector.dart';
import '../../../domain/entities/attachment.dart';
import '../../../../../utils/app_logger.dart';
import '../../widgets/mobile/preview/text_preview_widget.dart';
import '../../widgets/mobile/preview/pdfx_preview_widget.dart';
import '../../widgets/mobile/preview/image_preview_widget.dart';
import '../../widgets/mobile/preview/video_preview_widget.dart';
import '../../widgets/mobile/preview/audio_preview_widget.dart';

/// Full-screen attachment preview page
///
/// Supports different file types with specialized viewers:
/// - PDF: pdfx with zoom/pan (modern implementation)
/// - Images: photo_view with zoom/pan
/// - Videos: video_player with controls
/// - Audio: audioplayers with controls
/// - Text: scrollable text viewer
/// - Office: fallback to external app
/// - Unknown: file info + external app option
class AttachmentPreviewPage extends StatefulWidget {
  /// Cached file to preview
  final CachedFile cachedFile;

  /// Original attachment entity
  final MailAttachment attachment;

  /// Hero tag for animation (optional)
  final String? heroTag;

  const AttachmentPreviewPage({
    super.key,
    required this.cachedFile,
    required this.attachment,
    this.heroTag,
  });

  @override
  State<AttachmentPreviewPage> createState() => _AttachmentPreviewPageState();
}

class _AttachmentPreviewPageState extends State<AttachmentPreviewPage> {
  bool _isLoading = true;
  String? _errorMessage;
  bool _fileExists = false;

  @override
  void initState() {
    super.initState();
    _initializePreview();
  }

  /// Initialize preview - check file exists and validate
  Future<void> _initializePreview() async {
    try {
      AppLogger.info(
        '🔍 Initializing preview for: ${widget.attachment.filename}',
      );

      // Check if cached file exists
      final file = File(widget.cachedFile.localPath);
      final exists = await file.exists();

      if (!exists) {
        throw Exception(
          'Cached file not found: ${widget.cachedFile.localPath}',
        );
      }

      // Verify file size matches cache info
      final actualSize = await file.length();
      if (actualSize != widget.cachedFile.size) {
        AppLogger.warning(
          '⚠️ File size mismatch: expected ${widget.cachedFile.size}, got $actualSize',
        );
      }

      setState(() {
        _fileExists = true;
        _isLoading = false;
      });

      AppLogger.info('✅ Preview initialized successfully');
    } catch (e) {
      AppLogger.error('❌ Preview initialization failed: $e');

      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Use system theme - will follow app's light/dark mode
      appBar: _buildAppBar(),
      body: _buildBody(),
      bottomNavigationBar: _buildActionBar(),
    );
  }

  /// Build adaptive AppBar
  PreferredSizeWidget _buildAppBar() {
    final theme = Theme.of(context);

    return AppBar(
      // Use theme colors instead of hardcoded dark
      backgroundColor: theme.appBarTheme.backgroundColor,
      foregroundColor: theme.appBarTheme.foregroundColor,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () => Navigator.of(context).pop(),
        tooltip: 'Kapat',
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.attachment.filename,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            '${FileTypeDetector.getTypeName(widget.cachedFile.type)} • ${widget.attachment.sizeFormatted}',
            style: TextStyle(
              color: theme.textTheme.bodySmall?.color,
              fontSize: 12,
            ),
          ),
        ],
      ),
      actions: [
        // Share button
        IconButton(
          icon: const Icon(Icons.share),
          onPressed: _handleShare,
          tooltip: 'Paylaş',
        ),
        // More actions
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'save',
              child: Row(
                children: [
                  Icon(Icons.download, color: theme.iconTheme.color),
                  const SizedBox(width: 12),
                  const Text('Kaydet'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'open_external',
              child: Row(
                children: [
                  Icon(Icons.open_in_new, color: theme.iconTheme.color),
                  const SizedBox(width: 12),
                  const Text('Harici uygulamada aç'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'file_info',
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: theme.iconTheme.color),
                  const SizedBox(width: 12),
                  const Text('Dosya bilgisi'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Build main body content
  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (!_fileExists) {
      return _buildFileNotFoundState();
    }

    // Route to appropriate viewer based on file type
    return _buildPreviewWidget();
  }

  /// Build loading state
  Widget _buildLoadingState() {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: theme.colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            'Dosya yükleniyor...',
            style: TextStyle(color: theme.textTheme.bodyMedium?.color),
          ),
        ],
      ),
    );
  }

  /// Build error state
  Widget _buildErrorState() {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Dosya yüklenemedi',
              style: TextStyle(
                color: theme.textTheme.headlineSmall?.color,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Bilinmeyen hata',
              style: TextStyle(
                color: theme.textTheme.bodyMedium?.color,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Geri Dön'),
            ),
          ],
        ),
      ),
    );
  }

  /// Build file not found state
  Widget _buildFileNotFoundState() {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.file_present, size: 64, color: Colors.orange),
            const SizedBox(height: 16),
            Text(
              'Dosya bulunamadı',
              style: TextStyle(
                color: theme.textTheme.headlineSmall?.color,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Cache\'den silinmiş olabilir',
              style: TextStyle(
                color: theme.textTheme.bodyMedium?.color,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Geri Dön'),
            ),
          ],
        ),
      ),
    );
  }

  /// Build appropriate preview widget based on file type
  Widget _buildPreviewWidget() {
    final file = File(widget.cachedFile.localPath);

    // Add Hero widget for animation if heroTag provided
    Widget previewContent = _buildTypeSpecificViewer(file);

    if (widget.heroTag != null) {
      previewContent = Hero(
        tag: widget.heroTag!,
        child: Material(color: Colors.transparent, child: previewContent),
      );
    }

    return previewContent;
  }

  /// Build file type specific viewer
  Widget _buildTypeSpecificViewer(File file) {
    switch (widget.cachedFile.type) {
      case SupportedFileType.image:
        return _buildImageViewer(file);
      case SupportedFileType.pdf:
        return _buildPdfViewer(file);
      case SupportedFileType.text:
        return _buildTextViewer(file);
      case SupportedFileType.video:
        return _buildVideoViewer(file);
      case SupportedFileType.audio:
        return _buildAudioViewer(file);
      case SupportedFileType.office:
      case SupportedFileType.unknown:
        return _buildUnsupportedViewer(file);
    }
  }

  /// Image viewer - placeholder for photo_view implementation
  Widget _buildImageViewer(File file) {
    return ImagePreviewWidget(file: file, filename: widget.attachment.filename);
  }

  /// PDF viewer - modern pdfx implementation
  Widget _buildPdfViewer(File file) {
    // ✅ Changed from PdfPreviewWidget to PdfxPreviewWidget
    return PdfxPreviewWidget(file: file, filename: widget.attachment.filename);
  }

  /// Text viewer - fully functional implementation
  Widget _buildTextViewer(File file) {
    // Import the TextPreviewWidget
    return TextPreviewWidget(file: file, filename: widget.attachment.filename);
  }

  /// Video viewer - Basic video_player implementation
  Widget _buildVideoViewer(File file) {
    return VideoPreviewWidget(file: file, filename: widget.attachment.filename);
  }

  /// Audio viewer - AudioPlayers implementation
  Widget _buildAudioViewer(File file) {
    return AudioPreviewWidget(file: file, filename: widget.attachment.filename);
  }

  /// Unsupported file viewer
  Widget _buildUnsupportedViewer(File file) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.insert_drive_file,
              size: 64,
              color: theme.iconTheme.color?.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Önizleme mevcut değil',
              style: TextStyle(
                color: theme.textTheme.headlineSmall?.color,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.attachment.filename,
              style: TextStyle(
                color: theme.textTheme.bodyMedium?.color,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _handleOpenExternal,
              icon: const Icon(Icons.open_in_new),
              label: const Text('Harici uygulamada aç'),
            ),
          ],
        ),
      ),
    );
  }

  /// Build bottom action bar (optional)
  Widget? _buildActionBar() {
    // Only show for supported file types
    if (!FileTypeDetector.canPreview(widget.cachedFile.type)) {
      return null;
    }

    final theme = Theme.of(context);

    return Container(
      color: theme.scaffoldBackgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            TextButton.icon(
              onPressed: _handleShare,
              icon: Icon(Icons.share, color: theme.iconTheme.color),
              label: Text(
                'Paylaş',
                style: TextStyle(color: theme.textTheme.bodyLarge?.color),
              ),
            ),
            TextButton.icon(
              onPressed: _handleSave,
              icon: Icon(Icons.download, color: theme.iconTheme.color),
              label: Text(
                'Kaydet',
                style: TextStyle(color: theme.textTheme.bodyLarge?.color),
              ),
            ),
            TextButton.icon(
              onPressed: _handleOpenExternal,
              icon: Icon(Icons.open_in_new, color: theme.iconTheme.color),
              label: Text(
                'Harici aç',
                style: TextStyle(color: theme.textTheme.bodyLarge?.color),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========== ACTION HANDLERS ==========

  /// Handle share action
  void _handleShare() {
    HapticFeedback.lightImpact();
    AppLogger.info('📤 Share requested for: ${widget.attachment.filename}');

    // TODO: Implement share functionality using share_plus
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🚀 Share functionality coming in Phase 3!'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  /// Handle save to device action
  void _handleSave() {
    HapticFeedback.lightImpact();
    AppLogger.info('💾 Save requested for: ${widget.attachment.filename}');

    // TODO: Implement save to device functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('💾 Save to device coming in Phase 3!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  /// Handle open with external app
  void _handleOpenExternal() {
    HapticFeedback.lightImpact();
    AppLogger.info(
      '🔗 External app requested for: ${widget.attachment.filename}',
    );

    // TODO: Implement open_file integration
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🔗 Open with external app coming in Phase 3!'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  /// Handle menu actions
  void _handleMenuAction(String action) {
    HapticFeedback.selectionClick();

    switch (action) {
      case 'save':
        _handleSave();
        break;
      case 'open_external':
        _handleOpenExternal();
        break;
      case 'file_info':
        _showFileInfo();
        break;
    }
  }

  /// Show file information dialog
  void _showFileInfo() {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.dialogBackgroundColor,
        title: Text(
          'Dosya Bilgisi',
          style: TextStyle(color: theme.textTheme.titleLarge?.color),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Dosya Adı', widget.attachment.filename),
            _buildInfoRow(
              'Tip',
              FileTypeDetector.getTypeName(widget.cachedFile.type),
            ),
            _buildInfoRow('Boyut', widget.attachment.sizeFormatted),
            _buildInfoRow('MIME Type', widget.attachment.mimeType),
            _buildInfoRow(
              'Cache Tarihi',
              widget.cachedFile.cachedAt.toString().substring(0, 16),
            ),
            _buildInfoRow('Cache Path', widget.cachedFile.localPath),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  /// Build info row for file info dialog
  Widget _buildInfoRow(String label, String value) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: theme.textTheme.bodySmall?.color,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: theme.textTheme.bodyLarge?.color,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
