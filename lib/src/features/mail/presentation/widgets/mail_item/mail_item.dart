// lib/src/features/mail/presentation/widgets/mail_item/mail_item.dart

import 'package:flutter/material.dart';
import 'package:korgan/src/features/mail/domain/entities/mail.dart';
import 'adaptive/mail_item_factory.dart';

/// The widget automatically adapts its behavior and appearance based on
/// the current platform, providing a native experience on each target.
class MailItem extends StatelessWidget {
  /// The mail entity to display
  final Mail mail;

  /// Whether this mail item is currently selected
  final bool isSelected;

  /// Callback fired when the mail item is tapped
  final VoidCallback? onTap;

  /// Callback fired when the mail is archived
  ///
  /// On mobile: triggered by right swipe gesture
  /// On desktop: triggered by context menu or hover action
  /// On web: triggered by hover action button
  final VoidCallback? onArchive;

  /// ✅ REMOVED: onDelete callback (now handled by Dismissible at page level)
  /// This keeps the MailItem component pure and platform-agnostic

  /// Callback fired when the star status is toggled
  ///
  /// Available on all platforms through direct interaction with the star icon
  final VoidCallback? onToggleStar;

  /// Callback fired when the selection status is toggled
  ///
  /// Used for bulk operations and multi-selection
  final VoidCallback? onToggleSelection;

  /// Callback fired when the read status is toggled
  ///
  /// Marks the mail as read/unread
  final VoidCallback? onToggleRead;

  const MailItem({
    super.key,
    required this.mail,
    required this.isSelected,
    this.onTap,
    this.onArchive,
    // ✅ REMOVED: this.onDelete,
    this.onToggleStar,
    required this.onToggleSelection,
    required this.onToggleRead,
  });

  @override
  Widget build(BuildContext context) {
    // Delegate to platform-specific factory
    return MailItemFactory.create(
      mail: mail,
      isSelected: isSelected,
      onTap: onTap,
      onArchive: onArchive,
      // ✅ REMOVED: onDelete: onDelete,
      onToggleStar: onToggleStar,
      onToggleSelection: onToggleSelection,
      onToggleRead: onToggleRead,
    );
  }
}
