// lib/src/features/mail/presentation/widgets/mobile/preview/image_preview_widget.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_view/photo_view.dart';
import '../../../../../../utils/app_logger.dart';

/// Image preview widget with PhotoView
///
/// Features:
/// - Gesture-based zoom/pan
/// - Tap to toggle controls (like PDF viewer)
/// - Double tap to reset zoom via PhotoView
/// - Loading and error states
/// - Retry mechanism
/// - Theme-aware design
class ImagePreviewWidget extends StatefulWidget {
  final File file;
  final String? filename;

  const ImagePreviewWidget({super.key, required this.file, this.filename});

  @override
  State<ImagePreviewWidget> createState() => _ImagePreviewWidgetState();
}

class _ImagePreviewWidgetState extends State<ImagePreviewWidget> {
  late PhotoViewController _controller;
  bool _showControls = true;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _controller = PhotoViewController();
    _initializeImage();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Initialize image loading
  Future<void> _initializeImage() async {
    try {
      AppLogger.info('🖼️ Initializing image: ${widget.filename}');

      // Check file exists and is readable
      final exists = await widget.file.exists();
      if (!exists) {
        throw Exception('Image file not found: ${widget.file.path}');
      }

      // Check file size (basic validation)
      final fileSize = await widget.file.length();
      AppLogger.info('📊 Image file size: $fileSize bytes');

      // Small delay for smooth UX
      await Future.delayed(const Duration(milliseconds: 300));

      setState(() {
        _isLoading = false;
      });

      AppLogger.info('✅ Image initialized successfully');

      // Auto-hide controls after 3 seconds
      _autoHideControls();
    } catch (e) {
      AppLogger.error('❌ Image loading failed: $e');
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    return _buildImageViewer();
  }

  /// Build loading state (center circular progress)
  Widget _buildLoadingState() {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: theme.colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            'Resim yükleniyor...',
            style: TextStyle(color: theme.textTheme.bodyMedium?.color),
          ),
        ],
      ),
    );
  }

  /// Build error state with retry button
  Widget _buildErrorState() {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.broken_image, size: 64, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              'Resim yüklenemedi',
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
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _retryImageLoad,
              icon: const Icon(Icons.refresh),
              label: const Text('Tekrar Dene'),
            ),
          ],
        ),
      ),
    );
  }

  /// Build main image viewer
  Widget _buildImageViewer() {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: _toggleControls,
      child: Stack(
        children: [
          // PhotoView widget
          PhotoView(
            imageProvider: FileImage(widget.file),
            controller: _controller,
            minScale: PhotoViewComputedScale.contained * 0.8,
            maxScale: PhotoViewComputedScale.covered * 4.0,
            initialScale: PhotoViewComputedScale.contained,
            // Hero animation handled by parent AttachmentPreviewPage
            loadingBuilder: (context, event) {
              // Handle PhotoView internal loading
              if (event == null) {
                return _buildLoadingState();
              }

              final loaded = event.cumulativeBytesLoaded;
              final total = event.expectedTotalBytes ?? 1;
              final progress = loaded / total;

              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: progress,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Yükleniyor... ${(progress * 100).toInt()}%',
                      style: TextStyle(
                        color: theme.textTheme.bodyMedium?.color,
                      ),
                    ),
                  ],
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              AppLogger.error('PhotoView error: $error');
              return _buildPhotoViewError(error);
            },
            backgroundDecoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
            ),
            // Enable double tap to reset zoom
            enableRotation: false,
            gaplessPlayback: true,
          ),

          // Controls overlay (if visible)
          if (_showControls) _buildControlsOverlay(),
        ],
      ),
    );
  }

  /// Build PhotoView specific error
  Widget _buildPhotoViewError(Object error) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              'Görüntü hatası',
              style: TextStyle(
                color: theme.textTheme.headlineSmall?.color,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Resim formatı desteklenmiyor veya dosya bozuk',
              style: TextStyle(
                color: theme.textTheme.bodyMedium?.color,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _retryImageLoad,
              icon: const Icon(Icons.refresh),
              label: const Text('Tekrar Dene'),
            ),
          ],
        ),
      ),
    );
  }

  /// Build controls overlay (like PDF viewer)
  Widget _buildControlsOverlay() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black.withOpacity(0.7), Colors.transparent],
          ),
        ),
        padding: EdgeInsets.fromLTRB(
          16,
          MediaQuery.of(context).padding.top + 16,
          16,
          24,
        ),
        child: Row(
          children: [
            // Zoom reset button
            Material(
              color: Colors.transparent,
              child: IconButton(
                onPressed: _resetZoom,
                icon: const Icon(
                  Icons.center_focus_strong,
                  color: Colors.white,
                ),
                tooltip: 'Sığdır',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black.withOpacity(0.3),
                  shape: const CircleBorder(),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // File info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.filename != null)
                    Text(
                      widget.filename!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 4),
                  Text(
                    'Yakınlaştırmak için sıkıştırın • Hareket ettirmek için sürükleyin',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Toggle controls visibility (PDF viewer pattern)
  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });

    HapticFeedback.lightImpact();

    if (_showControls) {
      _autoHideControls();
    }
  }

  /// Auto-hide controls after 3 seconds
  void _autoHideControls() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _showControls) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  /// Reset zoom to fit screen (double tap alternative)
  void _resetZoom() {
    _controller.reset();
    HapticFeedback.lightImpact();

    AppLogger.debug('🔄 Image zoom reset');

    // Show feedback
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🖼️ Resim sığdırıldı'),
        duration: Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Retry image loading
  void _retryImageLoad() {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    HapticFeedback.lightImpact();
    AppLogger.info('🔄 Retrying image load: ${widget.filename}');

    _initializeImage();
  }
}
