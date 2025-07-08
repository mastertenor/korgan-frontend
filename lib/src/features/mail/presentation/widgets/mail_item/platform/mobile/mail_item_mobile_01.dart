// lib/src/features/mail/presentation/widgets/mail_item/platform/mobile/mail_item_mobile.dart

import 'package:flutter/material.dart';
import 'package:korgan/src/features/mail/domain/entities/mail.dart';
import '../../shared/mail_utils.dart';

/// Mobile-specific implementation of mail item widget
///
/// Optimized for touch interfaces with:
/// - Swipe gestures for archive/delete actions
/// - Touch-friendly sizing and spacing
/// - Haptic feedback support
/// - Mobile-specific interaction patterns
class MailItemMobile extends StatelessWidget {
  final Mail mail;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onArchive;
  final VoidCallback? onDelete;
  final VoidCallback? onToggleStar;
  final VoidCallback? onToggleSelection;
  final VoidCallback? onToggleRead;

  const MailItemMobile({
    super.key,
    required this.mail,
    this.isSelected = false,
    this.onTap,
    this.onArchive,
    this.onDelete,
    this.onToggleStar,
    this.onToggleSelection,
    this.onToggleRead,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key('mail-item-${mail.id}'), // Use unique mail ID
      // Sağa swipe - Arşivle (yeşil)
      background: Container(
        color: Colors.green,
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.only(left: 20),
        child: Row(
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
      // Sola swipe - Sil (kırmızı)
      secondaryBackground: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Sil',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.delete, color: Colors.white, size: 24),
          ],
        ),
      ),
      // Swipe işlemi tamamlandığında
      onDismissed: (direction) {
        if (direction == DismissDirection.startToEnd) {
          // Sağa swipe - Arşivle
          onArchive?.call();
        } else if (direction == DismissDirection.endToStart) {
          // Sola swipe - Sil
          onDelete?.call();
        }
      },
      // Swipe onayı istiyorsak
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          // Silme işlemi için onay iste
          return await _showDeleteConfirmation(context);
        }
        // Arşivleme için onay istemiyoruz
        return true;
      },
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Avatar circle
              CircleAvatar(
                radius: 20,
                backgroundColor: MailUtils.getAvatarColor(mail.senderName),
                child: Text(
                  MailUtils.getAvatarInitial(mail.senderName),
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              SizedBox(width: 12),

              // Mail content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                    SizedBox(height: 4),
                    Text(
                      mail.subject,
                      style: TextStyle(
                        fontWeight: mail.isRead
                            ? FontWeight.normal
                            : FontWeight.bold,
                        fontSize: 14,
                        color: mail.isRead ? Colors.grey[700] : Colors.black,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    // İçerik önizlemesi
                    SizedBox(height: 2),
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
                ),
              ),

              SizedBox(width: 8),

              // Star icon - Tıklanabilir
              GestureDetector(
                onTap: onToggleStar,
                child: Icon(
                  mail.isStarred ? Icons.star : Icons.star_border,
                  color: mail.isStarred ? Colors.amber : Colors.grey[400],
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool?> _showDeleteConfirmation(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Mail\'i Sil'),
        content: Text('Bu mail\'i silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Sil'),
          ),
        ],
      ),
    );
  }
}
