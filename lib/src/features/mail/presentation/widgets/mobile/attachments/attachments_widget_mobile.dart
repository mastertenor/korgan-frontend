// lib/src/features/mail/presentation/widgets/mobile/attachments/attachments_widget_mobile.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/entities/mail_detail.dart';
import '../../../../domain/entities/attachment.dart';
import '../../../providers/mail_providers.dart';
import '../../../../../../core/services/file_cache_service.dart';
import '../../../../../../core/services/file_type_detector.dart';
import '../../../../../../utils/app_logger.dart';
import '../../../pages/mobile/attachment_preview_page_mobile.dart';

/// Gmail-style horizontal attachments widget
///
/// Displays attachments as horizontal scrollable cards, similar to Gmail mobile app.
/// Features:
/// - Horizontal scroll with snap-to-card behavior
/// - File type icons and colors
/// - Download progress indicators
/// - Cache status checking
/// - Touch-friendly card design
/// - Hero animations for preview
class AttachmentsWidgetMobile extends ConsumerWidget {
  final MailDetail mailDetail;
  final EdgeInsetsGeometry? margin;
  final double cardHeight;

  const AttachmentsWidgetMobile({
    super.key,
    required this.mailDetail,
    this.margin,
    this.cardHeight = 100,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Check if mail has attachments
    if (!mailDetail.hasAttachments || mailDetail.attachmentsList.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final downloadUseCase = ref.read(downloadAttachmentUseCaseProvider);

 return Container(
  
  color: Colors.white,
  child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(
                  Icons.attach_file,
                  size: 18,
                  //color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  'Ekler (${mailDetail.attachmentsList.length})',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Horizontal attachment cards
          SizedBox(
            height: cardHeight,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: mailDetail.attachmentsList.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final attachment = mailDetail.attachmentsList[index];
                
                return AttachmentCard(
                  attachment: attachment,
                  mailDetail: mailDetail,
                  downloadUseCase: downloadUseCase,
                  cardHeight: cardHeight,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Individual attachment card widget
class AttachmentCard extends StatefulWidget {
  final MailAttachment attachment;
  final MailDetail mailDetail;
  final dynamic downloadUseCase; // DownloadAttachmentUseCase
  final double cardHeight;

  const AttachmentCard({
    super.key,
    required this.attachment,
    required this.mailDetail,
    required this.downloadUseCase,
    required this.cardHeight,
  });

  @override
  State<AttachmentCard> createState() => _AttachmentCardState();
}

class _AttachmentCardState extends State<AttachmentCard> {
  bool _isDownloading = false;
  bool _downloadCompleted = false;
  bool _isCheckingCache = true;
  CachedFile? _cachedFile;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkCacheStatus();
  }

  /// Check if file is already cached
  Future<void> _checkCacheStatus() async {
    try {
      AppLogger.debug('🔍 Checking cache for: ${widget.attachment.filename}');

      final cachedFile = await FileCacheService.instance.getCachedFile(
        widget.attachment,
        widget.mailDetail.senderEmail,
      );

      if (mounted) {
        setState(() {
          if (cachedFile != null) {
            _cachedFile = cachedFile;
            _downloadCompleted = true;
            AppLogger.info('✅ Cache hit for: ${widget.attachment.filename}');
          } else {
            _downloadCompleted = false;
            AppLogger.debug('❌ Cache miss for: ${widget.attachment.filename}');
          }
          _isCheckingCache = false;
        });
      }
    } catch (e) {
      AppLogger.error('❌ Cache check failed for ${widget.attachment.filename}: $e');
      
      if (mounted) {
        setState(() {
          _downloadCompleted = false;
          _isCheckingCache = false;
          _errorMessage = 'Cache kontrol hatası';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fileType = FileTypeDetector.autoDetect(
      mimeType: widget.attachment.mimeType,
      filename: widget.attachment.filename,
    );
    final canPreview = FileTypeDetector.canPreview(fileType);

    return GestureDetector(
      onTap: _isDownloading || _isCheckingCache ? null : _handleTap,
      child: Container(
        width: 160, // Fixed card width for horizontal scroll
        height: widget.cardHeight,
        decoration: BoxDecoration(
          color: _errorMessage != null 
            ? theme.colorScheme.errorContainer.withOpacity(0)
            : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _errorMessage != null
              ? theme.colorScheme.error.withOpacity(0.3)
              : theme.colorScheme.outline.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withOpacity(0.08),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // File icon and status
              Row(
                children: [
                  _buildFileIcon(fileType),
                  const Spacer(),
                  _buildStatusIcon(canPreview),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // File name (truncated) or error message
              Expanded(
                child: _errorMessage != null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.attachment.filename,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _errorMessage!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.error,
                            fontSize: 11,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ],
                    )
                  : Text(
                      widget.attachment.filename,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
              ),
              
              // File size and type (only if no error)
              if (_errorMessage == null)
                Text(
                  '${FileTypeDetector.getTypeName(fileType)} • ${_formatFileSize(widget.attachment.size)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                    fontSize: 11,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build file type icon with Hero animation
  Widget _buildFileIcon(SupportedFileType fileType) {
    return Hero(
      tag: 'attachment_${widget.attachment.id}',
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: FileTypeDetector.getColor(fileType).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          FileTypeDetector.getIcon(fileType),
          color: FileTypeDetector.getColor(fileType),
          size: 20,
        ),
      ),
    );
  }

  /// Build status icon (download/preview/loading)
  Widget _buildStatusIcon(bool canPreview) {
    if (_isCheckingCache || _isDownloading) {
      return SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Theme.of(context).colorScheme.primary,
        ),
      );
    }

    if (_errorMessage != null) {
      return Icon(
        Icons.error_outline,
        color: Theme.of(context).colorScheme.error,
        size: 16,
      );
    }

    if (_downloadCompleted && _cachedFile != null) {
      return Icon(
        canPreview ? Icons.visibility : Icons.open_in_new,
        color: canPreview ? Colors.blue : Colors.grey,
        size: 16,
      );
    }

    return Icon(
      Icons.download,
      color: Theme.of(context).colorScheme.primary,
      size: 16,
    );
  }

  /// Handle tap - download or preview
  Future<void> _handleTap() async {
    if (_downloadCompleted && _cachedFile != null) {
      _navigateToPreview();
      return;
    }

    await _handleDownload();
  }

  /// Handle download process
  Future<void> _handleDownload() async {
    if (_isDownloading || _downloadCompleted || _isCheckingCache) return;

    setState(() {
      _isDownloading = true;
      _errorMessage = null;
    });

    HapticFeedback.lightImpact();

    try {
      AppLogger.info('📎 Starting download for: ${widget.attachment.filename}');

      final result = await widget.downloadUseCase.call(
        attachment: widget.attachment,
        messageId: widget.mailDetail.messageId ?? widget.mailDetail.id,
        email: widget.mailDetail.senderEmail,
        forceDownload: false,
      );

      final cachedFile = result.when(
        success: (file) => file,
        failure: (failure) => throw Exception(failure.message),
      );

      setState(() {
        _downloadCompleted = true;
        _cachedFile = cachedFile;
        _isDownloading = false;
      });

      AppLogger.info('📎 Download completed: ${widget.attachment.filename}');

      // Show success snackbar
      if (mounted) {
        final fileType = FileTypeDetector.autoDetect(
          mimeType: widget.attachment.mimeType,
          filename: widget.attachment.filename,
        );
        final canPreview = FileTypeDetector.canPreview(fileType);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.attachment.filename} indirildi'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            action: canPreview
                ? SnackBarAction(
                    label: 'Görüntüle',
                    textColor: Colors.white,
                    onPressed: _navigateToPreview,
                  )
                : null,
            duration: Duration(seconds: canPreview ? 4 : 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isDownloading = false;
        _errorMessage = e.toString();
      });

      AppLogger.error('❌ Download failed for ${widget.attachment.filename}: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('İndirme hatası: ${widget.attachment.filename}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Navigate to preview page
  void _navigateToPreview() {
    if (_cachedFile == null) return;

    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          return AttachmentPreviewPage(
            cachedFile: _cachedFile!,
            attachment: widget.attachment,
            heroTag: 'attachment_${widget.attachment.id}',
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = 0.0;
          const end = 1.0;
          const curve = Curves.easeOutCubic;

          final fadeAnimation = Tween<double>(
            begin: begin,
            end: end,
          ).animate(CurvedAnimation(parent: animation, curve: curve));

          final scaleAnimation = Tween<double>(
            begin: 0.95,
            end: 1.0,
          ).animate(CurvedAnimation(parent: animation, curve: curve));

          return FadeTransition(
            opacity: fadeAnimation,
            child: ScaleTransition(scale: scaleAnimation, child: child),
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 250),
      ),
    );
  }

  /// Format file size for display
  String _formatFileSize(int size) {
    if (size < 1024) {
      return '${size}B';
    } else if (size < 1024 * 1024) {
      return '${(size / 1024).toStringAsFixed(1)}KB';
    } else {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
  }
}