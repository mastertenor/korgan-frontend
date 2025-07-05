// lib/src/features/mail/presentation/widgets/mail_item/adaptive/mail_item_factory.dart

import 'package:flutter/material.dart';
import 'package:korgan/src/utils/platform_helper.dart';
import 'package:korgan/src/features/mail/domain/entities/mail.dart';
import '../platform/mobile/mail_item_mobile.dart';
import '../platform/desktop/mail_item_desktop.dart';
import '../platform/web/mail_item_web.dart';

/// Factory class for creating platform-specific mail item implementations
///
/// This factory uses the Platform-Adaptive Pattern to automatically
/// select the appropriate mail item implementation based on the current platform.
///
/// Supports:
/// - Mobile platforms (Android/iOS) → MailItemMobile
/// - Desktop platforms (Windows/macOS/Linux) → MailItemDesktop
/// - Web platform → MailItemWeb
class MailItemFactory {
  const MailItemFactory._(); // Prevent instantiation

  /// Creates a platform-appropriate mail item widget
  ///
  /// Uses experience-based detection that considers both platform and context:
  /// - Mobile experience: Native mobile apps + mobile web browsers
  /// - Web experience: Desktop web browsers with full web features
  /// - Desktop experience: Native desktop apps
  ///
  /// This ensures mobile web users get touch-optimized experience while
  /// desktop web users get the full web experience with hover effects.
  static Widget create({
    required Mail mail,
    required bool isSelected,
    VoidCallback? onTap,
    VoidCallback? onArchive,
    VoidCallback? onDelete,
    VoidCallback? onToggleStar,
    VoidCallback? onToggleSelection,
    VoidCallback? onToggleRead,
  }) {
    // Use experience-based detection for better UX
    if (PlatformHelper.shouldUseMobileExperience) {
      return MailItemMobile(
        mail: mail,
        onTap: onTap,
        onArchive: onArchive,
        onDelete: onDelete,
        onToggleStar: onToggleStar,
      );
    } else if (PlatformHelper.shouldUseWebExperience) {
      return MailItemWeb(
        mail: mail,
        isSelected: isSelected,
        onTap: onTap,
        onArchive: onArchive,
        onDelete: onDelete,
        onToggleStar: onToggleStar,
        onToggleSelection: onToggleSelection,
        onToggleRead: onToggleRead,
      );
    } else if (PlatformHelper.shouldUseDesktopExperience) {
      return MailItemDesktop(
        mail: mail,
        onTap: onTap,
        onArchive: onArchive,
        onDelete: onDelete,
        onToggleStar: onToggleStar,
      );
    }

    // Fallback to mobile implementation
    return MailItemMobile(
      mail: mail,
      onTap: onTap,
      onArchive: onArchive,
      onDelete: onDelete,
      onToggleStar: onToggleStar,
    );
  }

  /// Creates a mobile-specific mail item widget
  ///
  /// Useful for testing or when you specifically need the mobile implementation.
  static Widget createMobile({
    required Mail mail,
    VoidCallback? onTap,
    VoidCallback? onArchive,
    VoidCallback? onDelete,
    VoidCallback? onToggleStar,
  }) {
    return MailItemMobile(
      mail: mail,
      onTap: onTap,
      onArchive: onArchive,
      onDelete: onDelete,
      onToggleStar: onToggleStar,
    );
  }

  /// Creates a desktop-specific mail item widget
  ///
  /// Useful for testing or when you specifically need the desktop implementation.
  static Widget createDesktop({
    required Mail mail,
    VoidCallback? onTap,
    VoidCallback? onArchive,
    VoidCallback? onDelete,
    VoidCallback? onToggleStar,
  }) {
    return MailItemDesktop(
      mail: mail,
      onTap: onTap,
      onArchive: onArchive,
      onDelete: onDelete,
      onToggleStar: onToggleStar,
    );
  }

  /// Creates a web-specific mail item widget
  ///
  /// Useful for testing or when you specifically need the web implementation.
  static Widget createWeb({
    required Mail mail,
    required bool isSelected,
    VoidCallback? onTap,
    VoidCallback? onArchive,
    VoidCallback? onDelete,
    VoidCallback? onToggleStar,
    VoidCallback? onToggleSelection,
    VoidCallback? onToggleRead,
  }) {
    return MailItemWeb(
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
