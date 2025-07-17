// lib/src/features/mail/presentation/widgets/mobile/preview/video_preview_widget.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import '../../../../../../utils/app_logger.dart';

/// Video preview widget with basic video_player
///
/// Features:
/// - Basic video playback controls
/// - Tap to toggle controls (like PDF/Image viewer)
/// - Loading and error states
/// - Retry mechanism
/// - Theme-aware design
/// - Auto-hide controls
class VideoPreviewWidget extends StatefulWidget {
  final File file;
  final String? filename;

  const VideoPreviewWidget({super.key, required this.file, this.filename});

  @override
  State<VideoPreviewWidget> createState() => _VideoPreviewWidgetState();
}

class _VideoPreviewWidgetState extends State<VideoPreviewWidget> {
  late VideoPlayerController _controller;
  bool _showControls = true;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Initialize video player
  Future<void> _initializeVideo() async {
    try {
      AppLogger.info('🎬 Initializing video: ${widget.filename}');

      // Check file exists and is readable
      final exists = await widget.file.exists();
      if (!exists) {
        throw Exception('Video file not found: ${widget.file.path}');
      }

      // Check file size
      final fileSize = await widget.file.length();
      AppLogger.info('📊 Video file size: $fileSize bytes');

      // Create video controller from file
      _controller = VideoPlayerController.file(widget.file);

      // Initialize the controller
      await _controller.initialize();

      // Add listener for player state changes
      _controller.addListener(_onVideoPlayerStateChanged);

      setState(() {
        _isLoading = false;
        _isPlaying = false;
      });

      AppLogger.info('✅ Video initialized successfully');
      AppLogger.info('🎞️ Video duration: ${_controller.value.duration}');
      AppLogger.info('📏 Video size: ${_controller.value.size}');

      // Auto-hide controls after 3 seconds
      _autoHideControls();
    } catch (e) {
      AppLogger.error('❌ Video initialization failed: $e');
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  /// Listen to video player state changes
  void _onVideoPlayerStateChanged() {
    if (mounted) {
      setState(() {
        _isPlaying = _controller.value.isPlaying;
      });

      // Show controls when video ends
      if (_controller.value.isCompleted) {
        _showControlsTemporarily();
      }
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

    return _buildVideoPlayer();
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
            'Video yükleniyor...',
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
            Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              'Video yüklenemedi',
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
              onPressed: _retryVideoLoad,
              icon: const Icon(Icons.refresh),
              label: const Text('Tekrar Dene'),
            ),
          ],
        ),
      ),
    );
  }

  /// Build main video player
  Widget _buildVideoPlayer() {
    return GestureDetector(
      onTap: _toggleControls,
      child: Container(
        color: Colors.black, // Video player background
        child: Stack(
          children: [
            // Video player widget
            Center(
              child: AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              ),
            ),

            // Controls overlay (if visible)
            if (_showControls) _buildControlsOverlay(),

            // Center play button (when paused)
            if (!_isPlaying && _showControls) _buildCenterPlayButton(),
          ],
        ),
      ),
    );
  }

  /// Build center play button
  Widget _buildCenterPlayButton() {
    return Center(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          onPressed: _togglePlayPause,
          icon: Icon(
            _isPlaying ? Icons.pause : Icons.play_arrow,
            color: Colors.white,
            size: 64,
          ),
          iconSize: 64,
        ),
      ),
    );
  }

  /// Build controls overlay (like PDF/Image viewer)
  Widget _buildControlsOverlay() {
    final duration = _controller.value.duration;
    final position = _controller.value.position;

    return Column(
      children: [
        // Top controls
        _buildTopControls(),

        const Spacer(),

        // Bottom controls
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [Colors.black.withOpacity(0.8), Colors.transparent],
            ),
          ),
          padding: EdgeInsets.fromLTRB(
            16,
            24,
            16,
            MediaQuery.of(context).padding.bottom + 16,
          ),
          child: Column(
            children: [
              // Progress bar
              _buildProgressBar(),

              const SizedBox(height: 16),

              // Control buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Rewind button
                  IconButton(
                    onPressed: _rewind,
                    icon: const Icon(Icons.replay_10, color: Colors.white),
                    iconSize: 32,
                  ),

                  const SizedBox(width: 24),

                  // Play/Pause button
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: _togglePlayPause,
                      icon: Icon(
                        _isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                      ),
                      iconSize: 40,
                    ),
                  ),

                  const SizedBox(width: 24),

                  // Forward button
                  IconButton(
                    onPressed: _fastForward,
                    icon: const Icon(Icons.forward_10, color: Colors.white),
                    iconSize: 32,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Time display
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDuration(position),
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  Text(
                    _formatDuration(duration),
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build top controls
  Widget _buildTopControls() {
    return Container(
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
          // Reset/restart button
          Material(
            color: Colors.transparent,
            child: IconButton(
              onPressed: _restartVideo,
              icon: const Icon(Icons.restart_alt, color: Colors.white),
              tooltip: 'Başa dön',
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
                  'Oynatmak için dokunun • İleri/geri almak için kaydırın',
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
    );
  }

  /// Build progress bar
  Widget _buildProgressBar() {
    return VideoProgressIndicator(
      _controller,
      allowScrubbing: true,
      colors: VideoProgressColors(
        playedColor: Theme.of(context).colorScheme.primary,
        bufferedColor: Colors.white.withOpacity(0.3),
        backgroundColor: Colors.white.withOpacity(0.1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }

  /// Toggle controls visibility (PDF/Image viewer pattern)
  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });

    HapticFeedback.lightImpact();

    if (_showControls) {
      _autoHideControls();
    }
  }

  /// Show controls temporarily
  void _showControlsTemporarily() {
    setState(() {
      _showControls = true;
    });
    _autoHideControls();
  }

  /// Auto-hide controls after 3 seconds
  void _autoHideControls() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _showControls && _isPlaying) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  /// Toggle play/pause
  void _togglePlayPause() {
    HapticFeedback.lightImpact();

    if (_isPlaying) {
      _controller.pause();
    } else {
      _controller.play();
      _autoHideControls(); // Hide controls when playing
    }
  }

  /// Rewind 10 seconds
  void _rewind() {
    HapticFeedback.lightImpact();
    final currentPosition = _controller.value.position;
    final newPosition = currentPosition - const Duration(seconds: 10);
    _controller.seekTo(
      newPosition < Duration.zero ? Duration.zero : newPosition,
    );
    _showControlsTemporarily();
  }

  /// Fast forward 10 seconds
  void _fastForward() {
    HapticFeedback.lightImpact();
    final currentPosition = _controller.value.position;
    final duration = _controller.value.duration;
    final newPosition = currentPosition + const Duration(seconds: 10);
    _controller.seekTo(newPosition > duration ? duration : newPosition);
    _showControlsTemporarily();
  }

  /// Restart video from beginning
  void _restartVideo() {
    HapticFeedback.lightImpact();
    _controller.seekTo(Duration.zero);
    _controller.pause();
    _showControlsTemporarily();

    AppLogger.debug('🔄 Video restarted');

    // Show feedback
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🎬 Video başa alındı'),
        duration: Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Retry video loading
  void _retryVideoLoad() {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    HapticFeedback.lightImpact();
    AppLogger.info('🔄 Retrying video load: ${widget.filename}');

    // Dispose old controller
    _controller.dispose();

    _initializeVideo();
  }

  /// Format duration for display
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));

    if (duration.inHours > 0) {
      return '${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds';
    } else {
      return '$twoDigitMinutes:$twoDigitSeconds';
    }
  }
}
