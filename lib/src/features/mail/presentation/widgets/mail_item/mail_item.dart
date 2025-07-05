// lib/src/features/mail/presentation/widgets/mail_item/mail_item.dart

import 'package:flutter/material.dart';
import 'package:korgan/src/features/mail/domain/entities/mail.dart';
import 'adaptive/mail_item_factory.dart';

/// Platform-adaptive mail item widget
///
/// This is the main entry point for displaying mail items across all platforms.
/// It automatically selects the appropriate platform-specific implementation
/// using the Platform-Adaptive Pattern.
///
/// ## Platform Implementations:
/// - **Mobile** (Android/iOS): Touch-optimized with swipe gestures
/// - **Desktop** (Windows/macOS/Linux): Mouse + keyboard optimized with context menus
/// - **Web**: Browser-optimized with Gmail-style hover actions
///
/// ## Usage:
/// ```dart
/// MailItem(
///   mail: Mail(
///     senderName: 'John Doe',
///     subject: 'Meeting Tomorrow',
///     content: 'Don\'t forget about our meeting...',
///     time: '10:30',
///     isRead: false,
///     isStarred: true,
///   ),
///   isSelected: false,
///   onTap: () => print('Mail tapped'),
///   onArchive: () => print('Mail archived'),
///   onDelete: () => print('Mail deleted'),
///   onToggleStar: () => print('Star toggled'),
///   onToggleSelection: () => print('Selection toggled'),
///   onToggleRead: () => print('Read status toggled'),
/// )
/// ```
///
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

  /// Callback fired when the mail is deleted
  ///
  /// On mobile: triggered by left swipe gesture (with confirmation)
  /// On desktop: triggered by context menu or hover action (with confirmation)
  /// On web: triggered by hover action button (with confirmation)
  final VoidCallback? onDelete;

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
    this.onDelete,
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
      onDelete: onDelete,
      onToggleStar: onToggleStar,
      onToggleSelection: onToggleSelection,
      onToggleRead: onToggleRead,
    );
  }
}
