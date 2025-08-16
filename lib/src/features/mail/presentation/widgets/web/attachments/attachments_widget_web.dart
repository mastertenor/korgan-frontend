// lib/src/features/mail/presentation/widgets/web/attachments/attachments_widget_web.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/entities/mail_detail.dart';
import '../../../../domain/entities/attachment.dart';
import '../../../providers/mail_providers.dart';
import '../../../../../../core/services/file_type_detector.dart';
import '../../../../../../utils/app_logger.dart';

/// Web version of Gmail-style horizontal attachments widget
/// 
/// Basit yaklaşım: Sadece tıkla ve indir
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
    if (!mailDetail.hasAttachments || mailDetail.attachmentsList.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final webDownloadUseCase = ref.read(webDownloadAttachmentUseCaseProvider);

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
                  color: theme.colorScheme.primary,
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
                
                return AttachmentCardWeb(
                  attachment: attachment,
                  mailDetail: mailDetail,
                  downloadUseCase: webDownloadUseCase,
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

/// Basit attachment card - Sadece tıkla ve indir
class AttachmentCardWeb extends StatefulWidget {
  final MailAttachment attachment;
  final MailDetail mailDetail;
  final dynamic downloadUseCase;
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
  bool _isDownloading = false;
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fileType = FileTypeDetector.autoDetect(
      mimeType: widget.attachment.mimeType,
      filename: widget.attachment.filename,
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: _isDownloading 
          ? SystemMouseCursors.wait 
          : SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _isDownloading ? null : _handleDownload,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 160,
          height: widget.cardHeight,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isHovered
                ? theme.colorScheme.primary.withOpacity(0.3)
                : theme.colorScheme.outline.withOpacity(0.2),
              width: _isHovered ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withOpacity(_isHovered ? 0.15 : 0.08),
                blurRadius: _isHovered ? 8 : 4,
                offset: Offset(0, _isHovered ? 4 : 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: _isDownloading ? null : _handleDownload,
              borderRadius: BorderRadius.circular(12),
              hoverColor: theme.colorScheme.primary.withOpacity(0.04),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // File icon and download icon
                    Row(
                      children: [
                        Container(
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
                        ),
                        const Spacer(),
                        if (_isDownloading)
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                theme.colorScheme.primary,
                              ),
                            ),
                          )
                        else
                          Icon(
                            Icons.download,
                            size: 16,
                            color: _isHovered 
                              ? theme.colorScheme.primary
                              : Colors.grey.shade600,
                          ),
                      ],
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // File name
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
                    
                    const SizedBox(height: 4),
                    
                    // File size
                    Text(
                      _formatFileSize(widget.attachment.size),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                        fontSize: 10,
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

  /// Basit download handler
Future<void> _handleDownload() async {
  if (_isDownloading) return;

  setState(() => _isDownloading = true);
  HapticFeedback.lightImpact();

  try {
    AppLogger.info('📥 [Web] Starting download for: ${widget.attachment.filename}');

    final result = await widget.downloadUseCase.call(
      attachment: widget.attachment,
      messageId: widget.mailDetail.messageId ?? widget.mailDetail.id,
      email: widget.mailDetail.senderEmail,
    );

    result.when(
      success: (webDownloadResult) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${webDownloadResult.filename} başarıyla kaydedildi (${webDownloadResult.formattedSize})'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      failure: (failure) {
        if (mounted) {
          // Check if user cancelled
          final isCancelled = failure.message.contains('iptal') || 
                            failure.message.toLowerCase().contains('cancel');
          
          if (!isCancelled) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('İndirme hatası: ${failure.message}'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      },
    );
  } catch (e) {
    AppLogger.error('❌ [Web] Download error: $e');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Beklenmeyen hata: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  } finally {
    if (mounted) {
      setState(() => _isDownloading = false);
    }
  }
}
  /// Format file size
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