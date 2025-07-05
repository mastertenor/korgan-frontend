// lib/src/features/mail/presentation/widgets/mail_item/platform/desktop/mail_item_desktop.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:korgan/src/features/mail/domain/entities/mail.dart';
import '../../shared/mail_utils.dart';

/// Desktop-specific implementation of mail item widget
///
/// Optimized for desktop interfaces with:
/// - Right-click context menu support
/// - Hover effects and states
/// - Keyboard navigation support
/// - Dense layout for desktop screens
/// - Multi-selection capabilities
class MailItemDesktop extends StatefulWidget {
  final Mail mail;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onArchive;
  final VoidCallback? onDelete;
  final VoidCallback? onToggleStar;
  final VoidCallback? onToggleSelection;
  final VoidCallback? onToggleRead;

  const MailItemDesktop({
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
  State<MailItemDesktop> createState() => _MailItemDesktopState();
}

class _MailItemDesktopState extends State<MailItemDesktop> {
  bool _isHovered = false;
  bool _isSelected = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onSecondaryTapDown: _showContextMenu,
        child: InkWell(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: Duration(milliseconds: 150),
            padding: EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ), // Denser padding
            decoration: BoxDecoration(
              color: _getBackgroundColor(),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                // Avatar - smaller for desktop
                CircleAvatar(
                  radius: 16, // Smaller than mobile (20)
                  backgroundColor: MailUtils.getAvatarColor(
                    widget.mail.senderName,
                  ),
                  child: Text(
                    MailUtils.getAvatarInitial(widget.mail.senderName),
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12, // Smaller font
                    ),
                  ),
                ),

                SizedBox(width: 10), // Smaller spacing
                // Mail content - desktop layout
                Expanded(
                  child: Row(
                    children: [
                      // Sender name - fixed width
                      SizedBox(
                        width: 150,
                        child: Text(
                          widget.mail.senderName,
                          style: TextStyle(
                            fontWeight: widget.mail.isRead
                                ? FontWeight.normal
                                : FontWeight.w600,
                            fontSize: 14, // Smaller font for desktop
                            color: widget.mail.isRead
                                ? Colors.black87
                                : Colors.black,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      SizedBox(width: 12),

                      // Subject and content - flexible width
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.mail.subject,
                              style: TextStyle(
                                fontWeight: widget.mail.isRead
                                    ? FontWeight.normal
                                    : FontWeight.w500,
                                fontSize: 14,
                                color: widget.mail.isRead
                                    ? Colors.grey[700]
                                    : Colors.black,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            SizedBox(height: 1),
                            Text(
                              widget.mail.content,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ),

                      SizedBox(width: 8),

                      // Time
                      SizedBox(
                        width: 60,
                        child: Text(
                          widget.mail.time,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(width: 8),

                // Desktop-specific actions (visible on hover)
                if (_isHovered) ...[
                  _buildHoverAction(
                    icon: Icons.archive_outlined,
                    tooltip: 'Arşivle (A)',
                    onPressed: widget.onArchive,
                  ),
                  _buildHoverAction(
                    icon: Icons.delete_outlined,
                    tooltip: 'Sil (Delete)',
                    onPressed: widget.onDelete,
                  ),
                ],

                // Star icon - always visible
                GestureDetector(
                  onTap: widget.onToggleStar,
                  child: Tooltip(
                    message: widget.mail.isStarred
                        ? 'Yıldızı kaldır'
                        : 'Yıldızla',
                    child: Icon(
                      widget.mail.isStarred ? Icons.star : Icons.star_border,
                      color: widget.mail.isStarred
                          ? Colors.amber
                          : Colors.grey[400],
                      size: 18, // Smaller for desktop
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHoverAction({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: Icon(icon, size: 16),
        onPressed: onPressed,
        splashRadius: 12,
        padding: EdgeInsets.all(2),
        constraints: BoxConstraints(minWidth: 24, minHeight: 24),
      ),
    );
  }

  Color _getBackgroundColor() {
    if (_isSelected) return Theme.of(context).primaryColor.withOpacity(0.1);
    if (_isHovered) return Colors.grey.withOpacity(0.05);
    return Colors.transparent;
  }

  void _showContextMenu(TapDownDetails details) {
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        details.globalPosition.dx,
        details.globalPosition.dy,
        details.globalPosition.dx + 1,
        details.globalPosition.dy + 1,
      ),
      items: <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          value: 'open',
          child: Row(
            children: [
              Icon(Icons.mail_outline, size: 16),
              SizedBox(width: 8),
              Text('Aç'),
            ],
          ),
        ),
        PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'archive',
          child: Row(
            children: [
              Icon(Icons.archive_outlined, size: 16),
              SizedBox(width: 8),
              Text('Arşivle'),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'star',
          child: Row(
            children: [
              Icon(
                widget.mail.isStarred ? Icons.star : Icons.star_border,
                size: 16,
              ),
              SizedBox(width: 8),
              Text(widget.mail.isStarred ? 'Yıldızı Kaldır' : 'Yıldızla'),
            ],
          ),
        ),
        PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outlined, size: 16, color: Colors.red),
              SizedBox(width: 8),
              Text('Sil', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    ).then((value) {
      switch (value) {
        case 'open':
          widget.onTap?.call();
          break;
        case 'archive':
          widget.onArchive?.call();
          break;
        case 'star':
          widget.onToggleStar?.call();
          break;
        case 'delete':
          _showDeleteConfirmation();
          break;
      }
    });
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Mail\'i Sil'),
        content: Text('Bu mail\'i silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onDelete?.call();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Sil'),
          ),
        ],
      ),
    );
  }
}
