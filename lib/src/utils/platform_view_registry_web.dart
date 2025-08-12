

// lib/src/utils/platform_view_registry_web.dart

// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:html' as html;
import 'dart:ui_web' as ui;

/// Web-specific implementation of view factory registration
void registerViewFactoryImpl(
  String viewType,
  dynamic Function(int viewId) viewFactory,
) {
  // Cast the factory function to the correct type
  webViewFactory(int viewId) {
    final result = viewFactory(viewId);
    if (result is html.Element) {
      return result;
    }
    throw ArgumentError('View factory must return an html.Element on web');
  }
  
  ui.platformViewRegistry.registerViewFactory(viewType, webViewFactory);
}
