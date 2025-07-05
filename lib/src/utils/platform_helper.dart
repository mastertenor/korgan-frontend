// =============================================================================
// DOSYA: lib/src/utils/platform_helper.dart
// =============================================================================

/// Platform detection utilities following CodeWithAndrea best practices
///
/// This utility provides safe platform detection that works across all Flutter
/// platforms including web. Always check [isWeb] first to avoid crashes.
///
/// Example usage:
/// ```dart
/// import 'package:your_app/src/utils/platform_helper.dart';
///
/// if (PlatformHelper.isWeb) {
///   // Web-specific code
/// } else if (PlatformHelper.isMobile) {
///   // Mobile-specific code
/// } else if (PlatformHelper.isDesktop) {
///   // Desktop-specific code
/// }
/// ```
library;

import 'dart:io' show Platform;

import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform, kDebugMode;
import 'package:korgan/src/utils/app_logger.dart';

/// Platform detection utility class
///
/// Provides a consistent API for detecting the current platform
/// across all Flutter targets including web.
class PlatformHelper {
  const PlatformHelper._(); // coverage:ignore-line

  // ============================================================================
  // PRIMARY PLATFORM DETECTION
  // ============================================================================

  /// Returns `true` if the app is running on the web platform
  ///
  /// This should always be checked first before using [Platform] methods
  /// to avoid runtime exceptions on web.
  static const bool isWeb = kIsWeb;

  /// Returns `true` if the app is running on mobile platforms (Android/iOS)
  static bool get isMobile {
    if (kIsWeb) {
      return defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS;
    }
    return Platform.isAndroid || Platform.isIOS;
  }

  /// Returns `true` if the app is running on desktop platforms (Windows/macOS/Linux)
  static bool get isDesktop {
    if (kIsWeb) {
      return defaultTargetPlatform != TargetPlatform.android &&
          defaultTargetPlatform != TargetPlatform.iOS;
    }
    return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  }

  // ============================================================================
  // SPECIFIC PLATFORM DETECTION
  // ============================================================================

  /// Returns `true` if the app is running on Android
  static bool get isAndroid {
    if (kIsWeb) return defaultTargetPlatform == TargetPlatform.android;
    return Platform.isAndroid;
  }

  /// Returns `true` if the app is running on iOS
  static bool get isIOS {
    if (kIsWeb) return defaultTargetPlatform == TargetPlatform.iOS;
    return Platform.isIOS;
  }

  /// Returns `true` if the app is running on Windows
  static bool get isWindows {
    if (kIsWeb) return false; // Cannot detect Windows specifically on web
    return Platform.isWindows;
  }

  /// Returns `true` if the app is running on macOS
  static bool get isMacOS {
    if (kIsWeb) return defaultTargetPlatform == TargetPlatform.macOS;
    return Platform.isMacOS;
  }

  /// Returns `true` if the app is running on Linux
  static bool get isLinux {
    if (kIsWeb) return defaultTargetPlatform == TargetPlatform.linux;
    return Platform.isLinux;
  }

  /// Returns `true` if the app is running on Fuchsia
  static bool get isFuchsia {
    if (kIsWeb) return defaultTargetPlatform == TargetPlatform.fuchsia;
    return Platform.isFuchsia;
  }

  // ============================================================================
  // PLATFORM CAPABILITIES
  // ============================================================================

  /// Returns `true` if the platform supports haptic feedback
  static bool get supportsHapticFeedback => isMobile;

  /// Returns `true` if the platform has a physical keyboard by default
  static bool get hasPhysicalKeyboard => isDesktop;

  /// Returns `true` if the platform supports touch input
  static bool get supportsTouchInput => isMobile || isWeb;

  /// Returns `true` if the platform supports mouse input
  static bool get supportsMouseInput => isDesktop || isWeb;

  /// Returns `true` if the platform requires safe area handling
  static bool get needsSafeArea => isMobile;

  // ============================================================================
  // PLATFORM GROUPING
  // ============================================================================

  /// Returns `true` if running on Apple platforms (iOS/macOS)
  ///
  /// Useful for Apple-specific features like App Store guidelines,
  /// Apple-specific UI patterns, etc.
  static bool get isApple {
    if (kIsWeb) {
      return defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS;
    }
    return Platform.isIOS || Platform.isMacOS;
  }

  /// Returns `true` if running on Google platforms (Android/Fuchsia)
  ///
  /// Useful for Google-specific features like Play Store guidelines,
  /// Material Design patterns, etc.
  static bool get isGoogle {
    if (kIsWeb) {
      return defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.fuchsia;
    }
    return Platform.isAndroid || Platform.isFuchsia;
  }

  /// Returns `true` if running on mobile web
  ///
  /// Useful for responsive design decisions when you need to differentiate
  /// between mobile web and desktop web experiences.
  static bool get isMobileWeb {
    if (!kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  /// Returns `true` if running on desktop web
  ///
  /// Useful for responsive design decisions when you need to differentiate
  /// between mobile web and desktop web experiences.
  static bool get isDesktopWeb {
    if (!kIsWeb) return false;
    return defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS;
  }

  // ============================================================================
  // PLATFORM INFORMATION
  // ============================================================================

  /// Returns a human-readable platform name
  ///
  /// Examples: 'Android', 'iOS', 'Windows', 'Android Web', etc.
  static String get platformName {
    if (kIsWeb) {
      return switch (defaultTargetPlatform) {
        TargetPlatform.android => 'Android Web',
        TargetPlatform.iOS => 'iOS Web',
        TargetPlatform.macOS => 'macOS Web',
        TargetPlatform.windows => 'Windows Web',
        TargetPlatform.linux => 'Linux Web',
        TargetPlatform.fuchsia => 'Fuchsia Web',
      };
    }

    return switch (Platform.operatingSystem) {
      'android' => 'Android',
      'ios' => 'iOS',
      'macos' => 'macOS',
      'windows' => 'Windows',
      'linux' => 'Linux',
      'fuchsia' => 'Fuchsia',
      _ => 'Unknown',
    };
  }

  /// Returns the current [TargetPlatform]
  ///
  /// Useful when you need the enum value for platform-specific logic.
  static TargetPlatform get targetPlatform => defaultTargetPlatform;

  /// Returns the operating system version string
  ///
  /// Only available on native platforms. Returns 'Web' for web platforms.
  static String get operatingSystemVersion {
    if (kIsWeb) return 'Web';
    return Platform.operatingSystemVersion;
  }

  // ============================================================================
  // DEBUG UTILITIES (CodeWithAndrea style - detailed and useful)
  // ============================================================================

  /// Returns comprehensive platform information for debugging
  ///
  /// This is useful during development to understand the current
  /// platform capabilities and configuration.
  static Map<String, dynamic> get debugInfo => {
    'platformName': platformName,
    'isWeb': isWeb,
    'isMobile': isMobile,
    'isDesktop': isDesktop,
    'targetPlatform': targetPlatform.name,
    'operatingSystemVersion': operatingSystemVersion,
    'capabilities': {
      'supportsHapticFeedback': supportsHapticFeedback,
      'hasPhysicalKeyboard': hasPhysicalKeyboard,
      'supportsTouchInput': supportsTouchInput,
      'supportsMouseInput': supportsMouseInput,
      'needsSafeArea': needsSafeArea,
    },
    'platformGroups': {
      'isApple': isApple,
      'isGoogle': isGoogle,
      'isMobileWeb': isMobileWeb,
      'isDesktopWeb': isDesktopWeb,
    },
  };

  /// Prints platform information to console in debug mode
  ///
  /// This is automatically filtered out in release builds.
  static void logPlatformInfo() {
    if (kDebugMode) {
      // Basic platform information
      AppLogger.info(
        'Platform Detection: $platformName (${targetPlatform.name})',
      );
      AppLogger.info(
        'Runtime Environment: ${isWeb ? "Web Browser" : "Native Application"}',
      );
      AppLogger.info('Device Category: ${isMobile ? "Mobile" : "Desktop"}');

      // System information (native only)
      if (!isWeb) {
        AppLogger.debug('OS Version: ${Platform.operatingSystemVersion}');
      }

      // Capability summary - only log active capabilities
      final capabilities = <String>[];
      if (supportsHapticFeedback) capabilities.add('haptic');
      if (hasPhysicalKeyboard) capabilities.add('keyboard');
      if (supportsTouchInput) capabilities.add('touch');
      if (supportsMouseInput) capabilities.add('mouse');
      if (needsSafeArea) capabilities.add('safeArea');

      if (capabilities.isNotEmpty) {
        AppLogger.debug('Active Capabilities: ${capabilities.join(", ")}');
      }

      // Platform ecosystem (only if relevant)
      if (isApple) {
        AppLogger.debug('Platform Ecosystem: Apple (iOS/macOS)');
      } else if (isGoogle) {
        AppLogger.debug('Platform Ecosystem: Google (Android/Fuchsia)');
      }

      // Web-specific information
      if (isWeb) {
        AppLogger.debug(
          'Web Context: ${isMobileWeb ? "Mobile Browser" : "Desktop Browser"}',
        );
      }
    }
  }

  static bool get shouldUseMobileExperience {
    // Native mobile platforms always get mobile experience
    if (!isWeb && isMobile) return true;

    // Web platforms: check the target platform
    if (isWeb && isMobileWeb) return true;

    return false;
  }

  /// Returns `true` if the user should get a desktop-optimized experience
  ///
  /// Optimized for mouse interactions, keyboard shortcuts, and larger screens.
  static bool get shouldUseDesktopExperience {
    // Native desktop platforms always get desktop experience
    if (!isWeb && isDesktop) return true;

    // Desktop web gets desktop experience
    if (isWeb && isDesktopWeb) return true;

    return false;
  }

  /// Returns `true` if the user should get a web-optimized experience
  ///
  /// This is specifically for desktop web browsers that can benefit from
  /// web-specific features like advanced hover states and CSS-like interactions.
  static bool get shouldUseWebExperience {
    // Only desktop web gets the full web experience
    return isWeb && isDesktopWeb;
  }

  /// Returns the recommended experience type for the current platform/context
  ///
  /// Useful for making experience decisions in widgets and components.
  static String get recommendedExperience {
    if (shouldUseMobileExperience) return 'mobile';
    if (shouldUseWebExperience) return 'web';
    if (shouldUseDesktopExperience) return 'desktop';
    return 'mobile'; // fallback
  }

  /// Debug information for experience detection
  static Map<String, dynamic> get experienceDebugInfo => {
    'recommendedExperience': recommendedExperience,
    'shouldUseMobileExperience': shouldUseMobileExperience,
    'shouldUseDesktopExperience': shouldUseDesktopExperience,
    'shouldUseWebExperience': shouldUseWebExperience,
    'reasoning': {
      'isWeb': isWeb,
      'isMobile': isMobile,
      'isDesktop': isDesktop,
      'isMobileWeb': isMobileWeb,
      'isDesktopWeb': isDesktopWeb,
    },
  };
}
