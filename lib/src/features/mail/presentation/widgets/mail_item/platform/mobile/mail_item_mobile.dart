// lib/src/features/mail/presentation/widgets/mail_item/platform/mobile/mail_item_mobile.dart

import 'package:flutter/material.dart';
import 'package:korgan/src/features/mail/domain/entities/mail.dart';
import '../../shared/mail_utils.dart';

/// Mobile-specific implementation of mail item widget with swipe gestures
class MailItemMobile extends StatelessWidget {
  final Mail mail;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onArchive; // Sağa kaydırma - Arşivle
  final VoidCallback? onToggleStar;
  final VoidCallback? onToggleSelection;
  final VoidCallback? onToggleRead;

  const MailItemMobile({
    super.key,
    required this.mail,
    this.isSelected = false,
    this.onTap,
    this.onArchive,
    this.onToggleStar,
    this.onToggleSelection,
    this.onToggleRead,
  });

  @override
  Widget build(BuildContext context) {
    // ✅ Dismissible widget - sadece sağa kaydırma ile arşivleme
    return Dismissible(
      key: Key('mail-${mail.id}'),

      // ✅ Sadece sağa kaydırmaya izin ver - arşivleme için
      direction: DismissDirection.endToStart,

      // ✅ Sağa swipe - Arşivle (yeşil)
      background: Container(
        color: Colors.green,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: const Row(
          children: [
            Icon(Icons.archive, color: Colors.white, size: 24),
            SizedBox(width: 8),
            Text(
              'Arşivle',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),

      // ✅ Swipe işlemi tamamlandığında - sadece arşivleme
      onDismissed: (direction) {
        // Sadece sağa swipe olacağı için direkt arşivle
        onArchive?.call();
      },

      // ✅ Mevcut mail item content'i
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: isSelected
              ? BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  border: Border(
                    left: BorderSide(
                      color: Theme.of(context).primaryColor,
                      width: 4,
                    ),
                  ),
                )
              : null,
          child: Row(
            children: [
              if (isSelected)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Icon(
                    Icons.check_circle,
                    color: Theme.of(context).primaryColor,
                    size: 20,
                  ),
                ),

              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: MailUtils.getAvatarColor(
                        mail.senderName,
                      ),
                      child: Text(
                        MailUtils.getAvatarInitial(mail.senderName),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Sender + Time
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  mail.senderName,
                                  style: TextStyle(
                                    fontWeight: mail.isRead
                                        ? FontWeight.normal
                                        : FontWeight.bold,
                                    fontSize: 16,
                                    color: mail.isRead
                                        ? Colors.black87
                                        : Colors.black,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                mail.time,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 4),

                          // Subject
                          Text(
                            mail.subject.isNotEmpty
                                ? mail.subject
                                : '(konu yok)',
                            style: TextStyle(
                              fontWeight: mail.isRead
                                  ? FontWeight.normal
                                  : FontWeight.bold,
                              fontSize: 14,
                              color: mail.isRead
                                  ? Colors.grey[700]
                                  : Colors.black,
                              fontStyle: mail.subject.isEmpty
                                  ? FontStyle.italic
                                  : FontStyle.normal,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),

                          // Content (if not empty)
                          if (mail.content.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              mail.content,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.normal,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ],

                          // Attachments (if any)
                          if (mail.hasAttachments) ...[
                            const SizedBox(height: 6),
                            _buildAttachmentIndicator(),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              GestureDetector(
                onTap: onToggleStar,
                child: Icon(
                  mail.isStarred ? Icons.star : Icons.star_border,
                  color: mail.isStarred ? Colors.amber : Colors.grey[400],
                  size: 24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Attachment indicator widget
  Widget _buildAttachmentIndicator() {
    return Row(
      children: [
        Icon(Icons.attach_file, size: 14, color: Colors.grey[500]),
        const SizedBox(width: 4),
        Text(
          '${mail.attachments.length} ek',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[500],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
