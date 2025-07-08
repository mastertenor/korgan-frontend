// lib/src/features/mail/presentation/widgets/mail_item/platform/mobile/mail_item_mobile.dart

import 'package:flutter/material.dart';
import 'package:korgan/src/features/mail/domain/entities/mail.dart';
import '../../shared/mail_utils.dart';

/// Mobile-specific implementation of mail item widget
///
/// ✅ SHOWCASE PATTERN: Pure content component optimized for touch interfaces
/// - Touch-friendly sizing and spacing
/// - Mobile-specific interaction patterns
/// - Platform-agnostic (no gesture handling - moved to page level)
/// - Reusable across different contexts (with/without swipe)
class MailItemMobile extends StatelessWidget {
  final Mail mail;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onArchive;
  // ✅ REMOVED: onDelete (gesture handling moved to page level)
  final VoidCallback? onToggleStar;
  final VoidCallback? onToggleSelection;
  final VoidCallback? onToggleRead;

  const MailItemMobile({
    super.key,
    required this.mail,
    this.isSelected = false,
    this.onTap,
    this.onArchive,
    // ✅ REMOVED: this.onDelete,
    this.onToggleStar,
    this.onToggleSelection,
    this.onToggleRead,
  });

  @override
  Widget build(BuildContext context) {
    // ✅ SHOWCASE PATTERN: Pure content widget - no gesture handling
    // Dismissible wrapper removed - handled at page level for better architecture
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        // ✅ Optional: Add selection indicator
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
            // ✅ Optional: Selection checkbox for multi-select
            if (isSelected)
              Padding(
                padding: EdgeInsets.only(right: 12),
                child: Icon(
                  Icons.check_circle,
                  color: Theme.of(context).primaryColor,
                  size: 20,
                ),
              ),

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
                            color: mail.isRead ? Colors.black87 : Colors.black,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        mail.time,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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

            // ✅ Optional: Unread indicator
            if (!mail.isRead)
              Padding(
                padding: EdgeInsets.only(left: 8),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/*
✅ SHOWCASE PATTERN BENEFITS:

1. 🎯 SINGLE RESPONSIBILITY
   - Only handles mail content display
   - No gesture logic mixed in
   - Pure, testable component

2. 🔄 REUSABILITY
   - Can be used in different contexts:
     * Archive view (no swipe needed)
     * Search results (different swipe)
     * Read-only mode (no swipe)
     * Desktop view (hover actions)

3. 🎨 PLATFORM AGNOSTIC
   - No mobile-specific gesture assumptions
   - Can work on any platform
   - Gesture behavior determined by parent

4. 🧪 TESTABILITY
   - Easy to test content rendering
   - No complex gesture mocking needed
   - Isolated from parent state management

5. 🛠️ MAINTAINABILITY
   - Clean separation of concerns
   - Gesture changes don't affect content
   - Content changes don't affect gestures
*/
