// lib/src/features/mail/presentation/widgets/mobile/htmlrender/models/render_mode.dart

/// Defines the rendering mode for HtmlMailRenderer
enum RenderMode {
  /// Preview mode - Display mail content only (read-only)
  /// Used when viewing mail from mail list
  preview,

  /// Editor mode - Full mail composition/reply editor
  /// Used when replying to or composing new mail
  editor,
}

/// Extension methods for RenderMode
extension RenderModeExtension on RenderMode {
  /// Returns true if this is preview mode
  bool get isPreview => this == RenderMode.preview;

  /// Returns true if this is editor mode
  bool get isEditor => this == RenderMode.editor;

  /// Returns human-readable name for debugging
  String get name {
    switch (this) {
      case RenderMode.preview:
        return 'Preview';
      case RenderMode.editor:
        return 'Editor';
    }
  }

  /// Returns description for debugging
  String get description {
    switch (this) {
      case RenderMode.preview:
        return 'Read-only mail content display';
      case RenderMode.editor:
        return 'Interactive mail composition/reply editor';
    }
  }
}