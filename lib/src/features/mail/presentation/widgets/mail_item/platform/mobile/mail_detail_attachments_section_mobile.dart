// lib/src/features/mail/presentation/widgets/mobile/mail_detail_attachments_section_mobile.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../domain/entities/mail_detail.dart';
import '../../../../providers/mail_providers.dart';
import '../../../../../../../utils/app_logger.dart';
import 'mail_attachment_list_tile_mobile.dart';

/// Mail detail attachments section widget
///
/// Shows all attachments in a mail with download functionality
/// 🆕 Updated to use new cache-enabled download API
class MailDetailAttachmentsSection extends ConsumerWidget {
  final MailDetail mailDetail;

  const MailDetailAttachmentsSection({super.key, required this.mailDetail});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Check if mail has attachments
    if (!mailDetail.hasAttachments || mailDetail.attachmentsList.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final downloadUseCase = ref.read(downloadAttachmentUseCaseProvider);

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header
            Row(
              children: [
                Icon(
                  Icons.attach_file,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Ekler (${mailDetail.attachmentsList.length})',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Attachments list
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: mailDetail.attachmentsList.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final attachment = mailDetail.attachmentsList[index];

                return AttachmentListTile(
                  attachment: attachment,
                  messageId: mailDetail.messageId ?? mailDetail.id,
                  email: mailDetail.senderEmail,
                  // 🆕 Updated onDownload callback for new API
                  onDownload: () async {
                    try {
                      AppLogger.info(
                        '📎 Download request for: ${attachment.filename}',
                      );

                      // Use new cache-enabled download API
                      final result = await downloadUseCase.call(
                        attachment: attachment,
                        messageId: mailDetail.messageId ?? mailDetail.id,
                        email: mailDetail.senderEmail,
                        forceDownload: false, // Use cache if available
                      );

                      return result.when(
                        success: (cachedFile) {
                          AppLogger.info(
                            '✅ Download success: ${attachment.filename}',
                          );
                          return cachedFile;
                        },
                        failure: (failure) {
                          AppLogger.error(
                            '❌ Download failed: ${failure.message}',
                          );
                          throw Exception(failure.message);
                        },
                      );
                    } catch (e) {
                      AppLogger.error('❌ Unexpected download error: $e');
                      rethrow;
                    }
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
