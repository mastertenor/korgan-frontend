// lib/src/features/mail/presentation/widgets/web/attachments/attachments_widget_web.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/entities/mail_detail.dart';
import '../../../../domain/entities/attachment.dart';
import '../../../providers/mail_providers.dart';
import '../../../../../../core/services/file_cache_service.dart';
import '../../../../../../core/services/file_type_detector.dart';
import '../../../../../../utils/app_logger.dart';

/// Web version of Gmail-style horizontal attachments widget
///
/// Features (inherited from mobile):
/// - Horizontal scroll with snap-to-card behavior
/// - File type icons and colors
/// - Download progress indicators
/// - Cache status checking
/// 
/// Web enhancements:
/// - Mouse hover effects
/// - Right-click context menus
/// - Keyboard navigation
/// - Enhanced progress indicators
class AttachmentsWidgetWeb extends ConsumerWidget {
  final MailDetail mailDetail;
  final EdgeInsetsGeometry? margin;
  final double cardHeight;

  const AttachmentsWidgetWeb({
    super.key,
    required this.mailDetail,
    this.margin,
    this.cardHeight = 100,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Check if mail has attachments (same logic as mobile)
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
          // Header (same as mobile)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(
                  Icons.attach_file,
                  size: 18,
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

          // Horizontal attachment cards (same pattern as mobile)
          SizedBox(
            height: cardHeight,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: mailDetail.attachmentsList.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final attachment = mailDetail.attachmentsList[index];
                
                return AttachmentCardWeb(
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

/// Web-optimized individual attachment card
///
/// Enhanced version of mobile AttachmentCard with web-specific features
class AttachmentCardWeb extends StatefulWidget {
  final MailAttachment attachment;
  final MailDetail mailDetail;
  final dynamic downloadUseCase; // DownloadAttachmentUseCase
  final double cardHeight;

  const AttachmentCardWeb({
    super.key,
    required this.attachment,
    required this.mailDetail,
    required this.downloadUseCase,
    required this.cardHeight,
  });

  @override
  State<AttachmentCardWeb> createState() => _AttachmentCardWebState();
}

class _AttachmentCardWebState extends State<AttachmentCardWeb> {
  // Same state variables as mobile
  bool _isDownloading = false;
  bool _downloadCompleted = false;
  bool _isCheckingCache = true;
  CachedFile? _cachedFile;
  String? _errorMessage;

  // Web-specific state
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _checkCacheStatus();
  }

  /// Check if file is already cached (same logic as mobile)
  Future<void> _checkCacheStatus() async {
    try {
      AppLogger.debug('🔍 [Web] Checking cache for: ${widget.attachment.filename}');

      final cachedFile = await FileCacheService.instance.getCachedFile(
        widget.attachment,
        widget.mailDetail.senderEmail,
      );

      if (mounted) {
        setState(() {
          if (cachedFile != null) {
            _cachedFile = cachedFile;
            _downloadCompleted = true;
            AppLogger.info('✅ [Web] Cache hit for: ${widget.attachment.filename}');
          } else {
            _downloadCompleted = false;
            AppLogger.debug('❌ [Web] Cache miss for: ${widget.attachment.filename}');
          }
          _isCheckingCache = false;
        });
      }
    } catch (e) {
      AppLogger.error('❌ [Web] Cache check failed for ${widget.attachment.filename}: $e');

      if (mounted) {
        setState(() {
          _downloadCompleted = false;
          _isCheckingCache = false;
          _errorMessage = 'Cache kontrol hatası';
        });
      }
    }
  }

  /// Handle download (same logic as mobile + web logging)
  Future<void> _handleDownload() async {
    if (_isDownloading) return;

    setState(() {
      _isDownloading = true;
      _errorMessage = null;
    });

    try {
      AppLogger.info('📥 [Web] Starting download: ${widget.attachment.filename}');

      final result = await widget.downloadUseCase.call(
        attachment: widget.attachment,
        messageId: widget.mailDetail.messageId ?? widget.mailDetail.id,
        email: widget.mailDetail.senderEmail,
      );

      result.when(
        success: (cachedFile) {
          if (mounted) {
            setState(() {
              _cachedFile = cachedFile;
              _downloadCompleted = true;
            });
            AppLogger.info('✅ [Web] Download completed: ${widget.attachment.filename}');
          }
        },
        failure: (failure) {
          if (mounted) {
            setState(() {
              _errorMessage = 'İndirme başarısız';
            });
            AppLogger.error('❌ [Web] Download failed: ${failure.message}');
          }
        },
      );
    } catch (e) {
      AppLogger.error('❌ [Web] Download exception: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'İndirme hatası';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }

  /// Handle tap (same logic as mobile)
  void _handleTap() {
    if (_downloadCompleted && _cachedFile != null) {
      _handlePreview();
    } else if (!_isDownloading && !_isCheckingCache) {
      _handleDownload();
    }
  }

  /// Handle preview (placeholder for now)
  void _handlePreview() {
    AppLogger.info('🔍 [Web] Preview requested: ${widget.attachment.filename}');
    // TODO: Implement web preview modal
  }

  /// Web-specific: Handle right-click context menu
  void _handleRightClick() {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + renderBox.size.width,
        position.dy + renderBox.size.height,
      ),
      items: [
        if (_downloadCompleted && _cachedFile != null)
          PopupMenuItem(
            value: 'preview',
            child: Row(
              children: [
                Icon(Icons.visibility, size: 16),
                SizedBox(width: 8),
                Text('Önizleme'),
              ],
            ),
          ),
        PopupMenuItem(
          value: 'download',
          child: Row(
            children: [
              Icon(Icons.download, size: 16),
              SizedBox(width: 8),
              Text(_downloadCompleted ? 'Yeniden İndir' : 'İndir'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'info',
          child: Row(
            children: [
              Icon(Icons.info, size: 16),
              SizedBox(width: 8),
              Text('Dosya Bilgisi'),
            ],
          ),
        ),
      ],
    ).then((value) {
      switch (value) {
        case 'preview':
          _handlePreview();
          break;
        case 'download':
          _handleDownload();
          break;
        case 'info':
          _showFileInfo();
          break;
      }
    });
  }

  /// Show file information dialog
  void _showFileInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Dosya Bilgisi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Dosya Adı: ${widget.attachment.filename}'),
            Text('Boyut: ${widget.attachment.sizeFormatted}'),
            Text('Tip: ${widget.attachment.mimeType}'),
            if (_cachedFile != null)
              Text('Önbellek: Mevcut'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Kapat'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fileType = FileTypeDetector.autoDetect(
      mimeType: widget.attachment.mimeType,
      filename: widget.attachment.filename,
    );
    final canPreview = FileTypeDetector.canPreview(fileType);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: _isDownloading
          ? SystemMouseCursors.wait
          : _downloadCompleted
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
      child: GestureDetector(
        onSecondaryTap: _handleRightClick, // Web: Right-click support
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          width: 160, // Same as mobile
          height: widget.cardHeight,
          decoration: BoxDecoration(
            color: _errorMessage != null 
              ? theme.colorScheme.errorContainer.withOpacity(0.1)
              : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _errorMessage != null
                ? theme.colorScheme.error.withOpacity(0.3)
                : theme.colorScheme.outline.withOpacity(0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withOpacity(_isHovered ? 0.15 : 0.08), // Web: Hover effect
                blurRadius: _isHovered ? 8 : 4, // Web: Enhanced shadow on hover
                offset: Offset(0, _isHovered ? 4 : 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: _handleTap,
              borderRadius: BorderRadius.circular(12),
              hoverColor: theme.colorScheme.primary.withOpacity(0.04), // Web: Hover color
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // File icon and status (same layout as mobile)
                    Row(
                      children: [
                        _buildFileIcon(fileType),
                        const Spacer(),
                        _buildStatusIcon(canPreview),
                      ],
                    ),
                    
                    const SizedBox(height: 6),
                    
                    // File name and error message (overflow düzeltildi)
                    Flexible(
                      child: _errorMessage != null
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  widget.attachment.filename,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 12,
                                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _errorMessage!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.error,
                                  fontSize: 10,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  widget.attachment.filename,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 12,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.attachment.sizeFormatted,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build file icon (same as mobile)
  Widget _buildFileIcon(SupportedFileType fileType) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: FileTypeDetector.getColor(fileType).withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(
        FileTypeDetector.getIcon(fileType),
        color: FileTypeDetector.getColor(fileType),
        size: 20,
      ),
    );
  }

  /// Build status icon (same as mobile + web cursor hints)
  Widget _buildStatusIcon(bool canPreview) {
    if (_isCheckingCache) {
      return SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (_isDownloading) {
      return SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (_downloadCompleted && _cachedFile != null) {
      return Icon(
        canPreview ? Icons.visibility : Icons.open_in_new,
        size: 16,
        color: canPreview ? Colors.blue : Colors.grey.shade600,
      );
    }

    return Icon(
      Icons.download,
      size: 16,
      color: Colors.grey.shade600,
    );
  }
}