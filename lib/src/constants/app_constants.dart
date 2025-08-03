// lib/src/core/constants/app_constants.dart

/// Application-wide constants and configuration values
///
/// This class contains all the constant values used throughout the application
/// including app metadata, API configurations, and feature flags.
class AppConstants {
  // Prevent instantiation
  AppConstants._();

  // ========== APP METADATA ==========
  
  /// Application name
  static const String appName = 'Korgan Platform';
  
  /// Application version
  static const String appVersion = '1.0.0';
  
  /// Application description
  static const String appDescription = 'Modular Enterprise Platform';
  
  /// Company name
  static const String companyName = 'Korgan';

  // ========== PLATFORM CONFIGURATION ==========
  
  /// Minimum supported web viewport width
  static const double minWebViewportWidth = 320.0;
  
  /// Minimum supported web viewport height
  static const double minWebViewportHeight = 480.0;
  
  /// Desktop minimum window width
  static const double desktopMinWidth = 800.0;
  
  /// Desktop minimum window height
  static const double desktopMinHeight = 600.0;

  // ========== MODULE CONFIGURATION ==========
  
  /// Available modules in the platform
  static const List<String> availableModules = [
    'mail',
    'crm',
    'tasks',
    'files',
    'chat',
    'erp',
    'dashboard',
    'calendar',
    'contacts',
  ];
  
  /// Default active modules (for new users)
  static const List<String> defaultActiveModules = [
    'mail',
    'dashboard',
  ];

  // ========== LAYOUT CONFIGURATION ==========
  
  /// Mobile breakpoint (below this is mobile experience)
  static const double mobileBreakpoint = 600.0;
  
  /// Tablet breakpoint (between mobile and desktop)
  static const double tabletBreakpoint = 840.0;
  
  /// Desktop breakpoint (above this is full desktop experience)
  static const double desktopBreakpoint = 1200.0;
  
  /// Sidebar width for desktop layouts
  static const double sidebarWidth = 280.0;
  
  /// Navigation rail width for tablet layouts
  static const double navigationRailWidth = 80.0;

  // ========== ANIMATION CONFIGURATION ==========
  
  /// Standard animation duration
  static const Duration animationDuration = Duration(milliseconds: 300);
  
  /// Fast animation duration
  static const Duration fastAnimationDuration = Duration(milliseconds: 150);
  
  /// Slow animation duration
  static const Duration slowAnimationDuration = Duration(milliseconds: 500);

  // ========== MAIL MODULE CONFIGURATION ==========
  
  /// Default page size for mail lists
  static const int defaultMailPageSize = 20;
  
  /// Maximum page size for mail lists
  static const int maxMailPageSize = 100;
  
  /// Mail refresh interval (in seconds)
  static const int mailRefreshInterval = 300; // 5 minutes

  // ========== STORAGE CONFIGURATION ==========
  
  /// Cache expiration time (in minutes)
  static const int cacheExpirationMinutes = 30;
  
  /// Maximum cache size (in MB)
  static const int maxCacheSizeMB = 50;

  // ========== FEATURE FLAGS ==========
  
  /// Enable debug logging
  static const bool enableDebugLogging = true;
  
  /// Enable performance monitoring
  static const bool enablePerformanceMonitoring = true;
  
  /// Enable analytics
  static const bool enableAnalytics = false;
  
  /// Enable crash reporting
  static const bool enableCrashReporting = false;

  // ========== UI CONFIGURATION ==========
  
  /// Default padding value
  static const double defaultPadding = 16.0;
  
  /// Small padding value
  static const double smallPadding = 8.0;
  
  /// Large padding value
  static const double largePadding = 24.0;
  
  /// Default border radius
  static const double defaultBorderRadius = 8.0;
  
  /// Card elevation
  static const double cardElevation = 2.0;

  // ========== COLOR CONFIGURATION ==========
  
  /// Primary brand color (seed color for Material 3)
  static const int primaryColorValue = 0xFF2196F3; // Blue
  
  /// Success color
  static const int successColorValue = 0xFF4CAF50; // Green
  
  /// Warning color
  static const int warningColorValue = 0xFFFFC107; // Amber
  
  /// Error color
  static const int errorColorValue = 0xFFF44336; // Red

  // ========== ENVIRONMENT CONFIGURATION ==========
  
  /// Development environment flag
  static const bool isDevelopment = true;
  
  /// Production environment flag
  static const bool isProduction = false;
  
  /// Staging environment flag
  static const bool isStaging = false;
}