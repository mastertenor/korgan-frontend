// lib/src/utils/platform_view_registry.dart

import 'package:flutter/foundation.dart';

// Platform-specific imports
import 'platform_view_registry_stub.dart'
    if (dart.library.html) 'platform_view_registry_web.dart';

/// Platform-agnostic wrapper for web view registry operations
class PlatformViewRegistry {
  /// Register a view factory for web platform
  /// 
  /// This method safely handles platform differences and only
  /// registers view factories on web platform
  static void registerViewFactory(
    String viewType,
    dynamic Function(int viewId) viewFactory,
  ) {
    if (kIsWeb) {
      registerViewFactoryImpl(viewType, viewFactory);
    } else {
      if (kDebugMode) {
        print('PlatformViewRegistry: Ignoring view factory registration on non-web platform');
      }
    }
  }
  
  /// Check if view factory registration is supported
  static bool get isSupported => kIsWeb;
}
