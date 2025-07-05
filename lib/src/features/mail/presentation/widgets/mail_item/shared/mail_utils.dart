// lib/src/features/mail/presentation/widgets/mail_item/shared/mail_utils.dart

import 'package:flutter/material.dart';

/// Utility class for mail item related helper functions
///
/// Contains shared utility functions used across different platform
/// implementations of the mail item widget.
class MailUtils {
  const MailUtils._(); // Prevent instantiation

  /// Generates a consistent color for mail sender avatars based on sender name
  ///
  /// Uses the sender name's hash code to select from a predefined color palette,
  /// ensuring the same sender always gets the same color.
  static Color getAvatarColor(String senderName) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.red,
      Colors.indigo,
      Colors.pink,
      Colors.cyan,
      Colors.amber,
    ];

    final index = senderName.hashCode % colors.length;
    return colors[index.abs()];
  }

  /// Gets the first letter of sender name for avatar display
  ///
  /// Returns '?' if sender name is empty or null.
  static String getAvatarInitial(String senderName) {
    if (senderName.isEmpty) return '?';
    return senderName[0].toUpperCase();
  }

  /// Truncates text to specified length with ellipsis
  ///
  /// Useful for ensuring text fits within UI constraints.
  static String truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }
}
