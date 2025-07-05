// lib/common_widgets/mail/mail_item.dart
import 'package:flutter/material.dart';

class MailItem extends StatelessWidget {
  final String senderName;
  final String subject;
  final String content; // Yeni eklenen alan
  final String time;
  final bool isRead;
  final bool isStarred;
  final VoidCallback? onTap;
  final VoidCallback? onArchive; // Sağa swipe - Arşivle
  final VoidCallback? onDelete; // Sola swipe - Sil
  final VoidCallback? onToggleStar; // Yıldızı aç/kapat

  const MailItem({
    super.key,
    required this.senderName,
    required this.subject,
    required this.content, // Yeni eklenen alan
    required this.time,
    this.isRead = false,
    this.isStarred = false,
    this.onTap,
    this.onArchive,
    this.onDelete,
    this.onToggleStar,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key('mail-${senderName}-${subject}'),
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
                backgroundColor: _getAvatarColor(),
                child: Text(
                  senderName.isNotEmpty ? senderName[0].toUpperCase() : '?',
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
                            senderName,
                            style: TextStyle(
                              fontWeight: isRead
                                  ? FontWeight.normal
                                  : FontWeight.bold,
                              fontSize: 16,
                              color: isRead ? Colors.black87 : Colors.black,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          time,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      subject,
                      style: TextStyle(
                        fontWeight: isRead
                            ? FontWeight.normal
                            : FontWeight.bold,
                        fontSize: 14,
                        color: isRead ? Colors.grey[700] : Colors.black,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    // Yeni eklenen içerik önizlemesi
                    SizedBox(height: 2),
                    Text(
                      content,
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
                  isStarred ? Icons.star : Icons.star_border,
                  color: isStarred ? Colors.amber : Colors.grey[400],
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

  Color _getAvatarColor() {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.red,
      Colors.indigo,
    ];

    final index = senderName.hashCode % colors.length;
    return colors[index.abs()];
  }
}
