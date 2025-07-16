import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../domain/entities/mail_detail.dart';
import '../../../../providers/mail_providers.dart';
import 'mail_attachment_list_tile_mobile.dart';

/// Mail detail attachments section widget
///
/// Shows all attachments in a mail with download functionality
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
                  onDownload:
                      ({
                        required String messageId,
                        required String attachmentId,
                        required String filename,
                        required String email,
                        String? mimeType,
                      }) async {
                        print('📎 Download request for: $filename');

                        final result = await downloadUseCase(
                          messageId: messageId,
                          attachmentId: attachmentId,
                          filename: filename,
                          email: email,
                          mimeType: mimeType,
                        );

                        return result.when(
                          success: (bytes) {
                            print('✅ Download success: ${bytes.length} bytes');
                            return bytes;
                          },
                          failure: (failure) {
                            print('❌ Download failed: ${failure.message}');
                            throw Exception(failure.message);
                          },
                        );
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
