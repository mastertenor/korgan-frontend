// lib/src/common_widgets/responsive/breakpoints.dart

/// Material 3 Design breakpoints for responsive design.
///
/// Based on Material Design 3 specifications:
/// https://m3.material.io/foundations/layout/applying-layout/window-size-classes
class Breakpoints {
  /// Private constructor to prevent instantiation.
  const Breakpoints._();

  // Material 3 Window Size Classes
  /// Compact: 0-600dp (Mobile phones)
  static const double compact = 600.0;

  /// Medium: 600-840dp (Tablets, large phones)
  static const double medium = 840.0;

  /// Expanded: 840-1200dp (Large tablets, foldables)
  static const double expanded = 1200.0;

  /// Large: 1200-1600dp (Desktops, laptops)
  static const double large = 1600.0;

  /// Extra Large: 1600dp+ (Large desktops, ultra-wide)
  // No upper limit for extraLarge

  // Legacy naming for backwards compatibility
  /// Alias for compact (mobile breakpoint)
  static const double mobile = compact;

  /// Alias for expanded (tablet breakpoint)
  static const double tablet = expanded;

  /// Alias for large (desktop breakpoint)
  static const double desktop = large;

  // Helper methods for breakpoint checking
  /// Returns true if width is in compact range (< 600dp)
  static bool isCompact(double width) => width < compact;

  /// Returns true if width is in medium range (600-840dp)
  static bool isMedium(double width) => width >= compact && width < medium;

  /// Returns true if width is in expanded range (840-1200dp)
  static bool isExpanded(double width) => width >= medium && width < expanded;

  /// Returns true if width is in large range (1200-1600dp)
  static bool isLarge(double width) => width >= expanded && width < large;

  /// Returns true if width is in extra large range (>= 1600dp)
  static bool isExtraLarge(double width) => width >= large;

  // Convenience methods with legacy naming
  /// Returns true if width is mobile-sized (< 600dp)
  static bool isMobileWidth(double width) => isCompact(width);

  /// Returns true if width is tablet-sized (600-1200dp)
  static bool isTabletWidth(double width) =>
      isMedium(width) || isExpanded(width);

  /// Returns true if width is desktop-sized (>= 1200dp)
  static bool isDesktopWidth(double width) =>
      isLarge(width) || isExtraLarge(width);

  /// Returns the current breakpoint name as string
  static String getBreakpointName(double width) {
    if (isCompact(width)) return 'Compact';
    if (isMedium(width)) return 'Medium';
    if (isExpanded(width)) return 'Expanded';
    if (isLarge(width)) return 'Large';
    return 'Extra Large';
  }

  /// Returns all breakpoint values as a list
  static List<double> get allBreakpoints => [compact, medium, expanded, large];
}
