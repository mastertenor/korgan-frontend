// lib/src/features/mail/presentation/widgets/mobile/preview/audio_preview_widget.dart

import 'dart:async'; // StreamSubscription için
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../../../../utils/app_logger.dart';

/// Audio preview widget with audioplayers
///
/// Features:
/// - Audio playback controls (play/pause)
/// - Progress bar with scrubbing
/// - Tap to toggle controls (consistent pattern)
/// - Loading and error states
/// - Duration display
/// - Simple waveform visualization
/// - 30s rewind/forward for audio
class AudioPreviewWidget extends StatefulWidget {
  final File file;
  final String? filename;

  const AudioPreviewWidget({super.key, required this.file, this.filename});

  @override
  State<AudioPreviewWidget> createState() => _AudioPreviewWidgetState();
}

class _AudioPreviewWidgetState extends State<AudioPreviewWidget>
    with TickerProviderStateMixin {
  late AudioPlayer _audioPlayer;
  bool _showControls = true;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  late AnimationController _waveAnimationController;

  // Stream subscriptions for proper disposal
  StreamSubscription<Duration>? _durationSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<PlayerState>? _playerStateSubscription;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _waveAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _initializeAudio();
  }

  @override
  void dispose() {
    // Cancel all stream subscriptions
    _durationSubscription?.cancel();
    _positionSubscription?.cancel();
    _playerStateSubscription?.cancel();

    // Dispose audio player and animation controller
    _audioPlayer.dispose();
    _waveAnimationController.dispose();

    super.dispose();
  }

  /// Initialize audio player
  Future<void> _initializeAudio() async {
    try {
      AppLogger.info('🎵 Initializing audio: ${widget.filename}');

      // Check file exists and is readable
      final exists = await widget.file.exists();
      if (!exists) {
        throw Exception('Audio file not found: ${widget.file.path}');
      }

      // Check file size
      final fileSize = await widget.file.length();
      AppLogger.info('📊 Audio file size: ${fileSize} bytes');

      // Set up listeners before playing with proper subscription handling
      _durationSubscription = _audioPlayer.onDurationChanged.listen((duration) {
        if (mounted) {
          setState(() {
            _duration = duration;
          });
        }
      });

      _positionSubscription = _audioPlayer.onPositionChanged.listen((position) {
        if (mounted) {
          setState(() {
            _position = position;
          });
        }
      });

      _playerStateSubscription = _audioPlayer.onPlayerStateChanged.listen((
        state,
      ) {
        if (mounted) {
          setState(() {
            _isPlaying = state == PlayerState.playing;
          });

          // Handle waveform animation
          if (_isPlaying) {
            _waveAnimationController.repeat();
          } else {
            _waveAnimationController.stop();
          }

          // Show controls when audio ends
          if (state == PlayerState.completed) {
            _showControlsTemporarily();
            _audioPlayer.seek(Duration.zero); // Reset to beginning
          }
        }
      });

      // Load the audio file
      await _audioPlayer.setSourceDeviceFile(widget.file.path);

      setState(() {
        _isLoading = false;
      });

      AppLogger.info('✅ Audio initialized successfully');
      AppLogger.info('🎞️ Audio duration: $_duration');

      // Auto-hide controls after 3 seconds
      _autoHideControls();
    } catch (e) {
      AppLogger.error('❌ Audio initialization failed: $e');
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

    return _buildAudioPlayer();
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
            'Ses dosyası yükleniyor...',
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
              'Ses dosyası yüklenemedi',
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
              onPressed: _retryAudioLoad,
              icon: const Icon(Icons.refresh),
              label: const Text('Tekrar Dene'),
            ),
          ],
        ),
      ),
    );
  }

  /// Build main audio player
  Widget _buildAudioPlayer() {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: _toggleControls,
      child: Container(
        color: theme.scaffoldBackgroundColor,
        child: Stack(
          children: [
            // Audio visualization (center)
            Center(child: _buildAudioVisualization()),

            // Controls overlay (if visible)
            if (_showControls) _buildControlsOverlay(),

            // Center play button (when paused)
            if (!_isPlaying && _showControls) _buildCenterPlayButton(),
          ],
        ),
      ),
    );
  }

  /// Build audio visualization (waveform-like)
  Widget _buildAudioVisualization() {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      height: 200,
      margin: const EdgeInsets.symmetric(horizontal: 40),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Audio icon
          Icon(
            Icons.audiotrack,
            size: 48,
            color: theme.colorScheme.primary.withOpacity(0.7),
          ),

          const SizedBox(height: 16),

          // Simple waveform visualization
          AnimatedBuilder(
            animation: _waveAnimationController,
            builder: (context, child) {
              return _buildWaveform();
            },
          ),

          const SizedBox(height: 16),

          // File info
          if (widget.filename != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                widget.filename!,
                style: TextStyle(
                  color: theme.textTheme.bodyLarge?.color,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
        ],
      ),
    );
  }

  /// Build simple waveform visualization
  Widget _buildWaveform() {
    final theme = Theme.of(context);

    return SizedBox(
      height: 60,
      width: 200,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(20, (index) {
          final animationValue = _waveAnimationController.value;
          final barHeight = _isPlaying
              ? (10 +
                        (sin((animationValue * 2 * pi) + (index * 0.5)) * 20)
                            .abs())
                    .toDouble()
              : (15 + (index % 3) * 5).toDouble();

          return Container(
            width: 4,
            height: barHeight,
            decoration: BoxDecoration(
              color: _isPlaying
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }),
      ),
    );
  }

  /// Build center play button
  Widget _buildCenterPlayButton() {
    final theme = Theme.of(context);

    return Center(
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.9),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: IconButton(
          onPressed: _togglePlayPause,
          icon: Icon(
            _isPlaying ? Icons.pause : Icons.play_arrow,
            color: Colors.white,
            size: 48,
          ),
          iconSize: 48,
          padding: const EdgeInsets.all(20),
        ),
      ),
    );
  }

  /// Build controls overlay
  Widget _buildControlsOverlay() {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Top controls
        _buildTopControls(),

        const Spacer(),

        // Bottom controls
        Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor.withOpacity(0.9),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            MediaQuery.of(context).padding.bottom + 24,
          ),
          child: Column(
            children: [
              // Time display
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDuration(_position),
                    style: TextStyle(
                      color: theme.textTheme.bodyMedium?.color,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    _formatDuration(_duration),
                    style: TextStyle(
                      color: theme.textTheme.bodyMedium?.color,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Progress bar
              _buildProgressBar(),

              const SizedBox(height: 24),

              // Control buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Rewind button (30s for audio)
                  IconButton(
                    onPressed: _rewind,
                    icon: Icon(
                      Icons.replay_30,
                      color: theme.colorScheme.onSurface,
                    ),
                    iconSize: 32,
                    tooltip: '30s geri',
                  ),

                  // Play/Pause button
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: _togglePlayPause,
                      icon: Icon(
                        _isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                      ),
                      iconSize: 40,
                      padding: const EdgeInsets.all(16),
                    ),
                  ),

                  // Forward button (30s for audio)
                  IconButton(
                    onPressed: _fastForward,
                    icon: Icon(
                      Icons.forward_30,
                      color: theme.colorScheme.onSurface,
                    ),
                    iconSize: 32,
                    tooltip: '30s ileri',
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
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.of(context).padding.top + 16,
        16,
        16,
      ),
      child: Row(
        children: [
          // Reset/restart button
          Material(
            color: Colors.transparent,
            child: IconButton(
              onPressed: _restartAudio,
              icon: Icon(Icons.restart_alt, color: theme.colorScheme.onSurface),
              tooltip: 'Başa dön',
              style: IconButton.styleFrom(
                backgroundColor: theme.colorScheme.surface.withOpacity(0.8),
                shape: const CircleBorder(),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Instructions
          Expanded(
            child: Text(
              'Oynatmak için dokunun • İleri/geri almak için kontrolleri kullanın',
              style: TextStyle(
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build progress bar
  Widget _buildProgressBar() {
    final theme = Theme.of(context);
    final maxDuration = _duration.inMilliseconds.toDouble();
    final currentPosition = _position.inMilliseconds.toDouble();

    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        activeTrackColor: theme.colorScheme.primary,
        inactiveTrackColor: theme.colorScheme.outline.withOpacity(0.3),
        thumbColor: theme.colorScheme.primary,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
        trackHeight: 4,
      ),
      child: Slider(
        value: maxDuration > 0 ? currentPosition.clamp(0.0, maxDuration) : 0.0,
        max: maxDuration > 0 ? maxDuration : 1.0,
        onChanged: (value) {
          final position = Duration(milliseconds: value.round());
          _audioPlayer.seek(position);
        },
        onChangeStart: (value) {
          _showControlsTemporarily();
        },
      ),
    );
  }

  /// Toggle controls visibility
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
  void _togglePlayPause() async {
    HapticFeedback.lightImpact();

    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.resume();
      _autoHideControls(); // Hide controls when playing
    }
  }

  /// Rewind 30 seconds (audio optimized)
  void _rewind() {
    HapticFeedback.lightImpact();
    final newPosition = _position - const Duration(seconds: 30);
    _audioPlayer.seek(
      newPosition < Duration.zero ? Duration.zero : newPosition,
    );
    _showControlsTemporarily();
  }

  /// Fast forward 30 seconds (audio optimized)
  void _fastForward() {
    HapticFeedback.lightImpact();
    final newPosition = _position + const Duration(seconds: 30);
    _audioPlayer.seek(newPosition > _duration ? _duration : newPosition);
    _showControlsTemporarily();
  }

  /// Restart audio from beginning
  void _restartAudio() {
    HapticFeedback.lightImpact();
    _audioPlayer.seek(Duration.zero);
    _audioPlayer.pause();
    _showControlsTemporarily();

    AppLogger.debug('🔄 Audio restarted');

    // Show feedback
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🎵 Ses başa alındı'),
        duration: Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Retry audio loading
  void _retryAudioLoad() {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    HapticFeedback.lightImpact();
    AppLogger.info('🔄 Retrying audio load: ${widget.filename}');

    // Cancel existing subscriptions
    _durationSubscription?.cancel();
    _positionSubscription?.cancel();
    _playerStateSubscription?.cancel();

    // Dispose old player
    _audioPlayer.dispose();
    _audioPlayer = AudioPlayer();

    _initializeAudio();
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
