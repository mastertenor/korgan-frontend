// lib/src/features/mail/presentation/widgets/mail_item/platform/web/mail_item_web.dart

import 'package:flutter/material.dart';
import 'package:korgan/src/features/mail/domain/entities/mail.dart';
import '../../shared/mail_utils.dart';

class MailItemWeb extends StatefulWidget {
  final Mail mail;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onArchive;
  final VoidCallback? onDelete;
  final VoidCallback? onToggleStar;
  final VoidCallback? onToggleSelection;
  final VoidCallback? onToggleRead;

  const MailItemWeb({
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
  State<MailItemWeb> createState() => _MailItemWebState();
}

class _MailItemWebState extends State<MailItemWeb>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _animationController.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _animationController.reverse();
      },
      child: Stack(
        children: [
          // Main mail item content
          InkWell(
            onTap: widget.onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: widget.isSelected
                    ? Colors.blue.withOpacity(0.08)
                    : _isHovered
                    ? Colors.grey.withOpacity(0.03)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  // Checkbox
                  SizedBox(
                    width: 32,
                    child: Transform.scale(
                    scale: 0.8,
                    child: Checkbox(
                      value: widget.isSelected,
                      onChanged: (_) => widget.onToggleSelection?.call(),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      // 🎨 Aynı renk parametreleri eklendi
                      activeColor: const Color(0xFF1976D2),  // Seçili durum rengi (mavi)
                      checkColor: Colors.white,              // Checkmark rengi (beyaz)
                      focusColor: const Color(0xFF1976D2).withOpacity(0.1),
                    ),
                  )
                  ),

                  const SizedBox(width: 8),

                  // Star icon
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
                        size: 18,
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Avatar
                  CircleAvatar(
                    radius: 18, // Medium size for web
                    backgroundColor: MailUtils.getAvatarColor(
                      widget.mail.senderName,
                    ),
                    child: Text(
                      MailUtils.getAvatarInitial(widget.mail.senderName),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),

                  const SizedBox(width: 14),

                  // Mail content - Gmail web style layout
                  Expanded(
                    child: Row(
                      children: [
                        // Sender name - fixed width
                        SizedBox(
                          width: 200,
                          child: Text(
                            widget.mail.senderName,
                            style: TextStyle(
                              fontWeight: widget.mail.isRead
                                  ? FontWeight.normal
                                  : FontWeight.w600,
                              fontSize: 14,
                              color: widget.mail.isRead
                                  ? Colors.black87
                                  : Colors.black,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        const SizedBox(width: 16),

                        // Subject and content - flexible
                        Expanded(
                          child: RichText(
                            overflow: TextOverflow.ellipsis,
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: widget.mail.subject,
                                  style: TextStyle(
                                    fontWeight: widget.mail.isRead
                                        ? FontWeight.normal
                                        : FontWeight.w500,
                                    fontSize: 14,
                                    color: widget.mail.isRead
                                        ? Colors.grey[700]
                                        : Colors.black,
                                  ),
                                ),
                                TextSpan(
                                  text: ' - ${widget.mail.content}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 36),

                  // Time (right-aligned, hidden on hover)
                  if (!_isHovered)
                    SizedBox(
                      width: 80,
                      child: Text(
                        widget.mail.time,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        textAlign: TextAlign.right,
                      ),
                    ),

                  // Hover actions space
                  if (_isHovered) const SizedBox(width: 80),
                ],
              ),
            ),
          ),

          // Gmail-style hover overlay actions
          if (_isHovered)
            Positioned(
              right: 16,
              top: 0,
              bottom: 0,
              child: FadeTransition(
                opacity: _fadeAnimation,

                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHoverAction(
                      icon: Icons.delete_outlined,
                      tooltip: 'Sil',
                      onPressed:  widget.onArchive,
                    ),
                    _buildHoverAction(
                      icon: widget.mail.isRead
                          ? Icons.mark_email_unread_outlined
                          : Icons.mark_email_read_outlined,
                      tooltip: widget.mail.isRead
                          ? 'Okunmadı olarak işaretle'
                          : 'Okundu olarak işaretle',
                      onPressed: widget.onToggleRead,
                    ),
                  ],
                ),
              ),
            ),
        ],
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(icon, size: 20, color: Colors.grey[700]),
          ),
        ),
      ),
    );
  }

}
