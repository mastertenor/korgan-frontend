// lib/src/features/auth/presentation/pages/factory/login_page_factory.dart

import 'package:flutter/material.dart';
import '../../../../../utils/platform_helper.dart';
import '../../../../../utils/app_logger.dart';
import '../platform/web/login_page_web.dart';
import '../platform/mobile/login_page_mobile.dart';

/// Factory for creating platform-specific login page implementations
///
/// Follows the same pattern as MailItemFactory in the project.
/// Routes to appropriate platform-specific login experience:
/// - Web: Centered modal card style (Gmail-like)
/// - Mobile: Full screen with mobile-optimized UX
/// - Desktop: Falls back to mobile experience for now
class LoginPageFactory {
  const LoginPageFactory._(); // Prevent instantiation

  /// Creates platform-appropriate login page widget
  ///
  /// Uses experience-based detection that considers both platform and context:
  /// - Mobile experience: Native mobile apps + mobile web browsers
  /// - Web experience: Desktop web browsers with full web features
  /// - Desktop experience: Native desktop apps (fallback to mobile for now)
  static Widget create() {
    AppLogger.debug('🔑 LoginPageFactory: Creating platform-aware login page');

    // Use experience-based detection for better UX
    if (PlatformHelper.shouldUseWebExperience) {
      AppLogger.debug('🌐 LoginPageFactory: Using web login experience');
      return const LoginPageWeb();
    } else if (PlatformHelper.shouldUseMobileExperience) {
      AppLogger.debug('📱 LoginPageFactory: Using mobile login experience');
      return const LoginPageMobile();
    } else if (PlatformHelper.shouldUseDesktopExperience) {
      AppLogger.debug(
        '🖥️ LoginPageFactory: Using mobile login experience (desktop fallback)',
      );
      return const LoginPageMobile(); // Desktop fallback to mobile for now
    }

    // Fallback to mobile implementation
    AppLogger.debug('⚠️ LoginPageFactory: Fallback to mobile login experience');
    return const LoginPageMobile();
  }

  /// Creates web-specific login page widget
  ///
  /// Useful for testing or when you specifically need the web implementation.
  static Widget createWeb() {
    AppLogger.debug('🌐 LoginPageFactory: Creating web login page');
    return const LoginPageWeb();
  }

  /// Creates mobile-specific login page widget
  ///
  /// Useful for testing or when you specifically need the mobile implementation.
  static Widget createMobile() {
    AppLogger.debug('📱 LoginPageFactory: Creating mobile login page');
    return const LoginPageMobile();
  }
}
