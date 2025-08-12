// lib/src/features/mail/presentation/widgets/web/preview/mail_renderer.dart

import 'package:flutter/material.dart';
import '../../../../domain/entities/mail_detail.dart';

/// Platform-agnostic interface for mail rendering
abstract class MailRenderer {
  /// ScrollController for the mail content
  ScrollController get scrollController;
  
  /// Callback when iframe height changes (web-specific, ignored on other platforms)
  ValueChanged<double>? get onHeightChanged;
  
  /// Initialize the renderer (setup listeners, etc.)
  void initialize();
  
  /// Dispose resources and cleanup
  void dispose();
  
  /// Current iframe height (400 default for non-web)
  double get iframeHeight;
  
  /// Build the main mail content widget
  Widget buildMailContent(BuildContext context, MailDetail mailDetail);
}