// lib/src/utils/platform_view_registry_stub.dart

/// Stub implementation for non-web platforms
void registerViewFactoryImpl(
  String viewType,
  dynamic Function(int viewId) viewFactory,
) {
  // No-op implementation for non-web platforms
  // This ensures the code compiles on all platforms
}