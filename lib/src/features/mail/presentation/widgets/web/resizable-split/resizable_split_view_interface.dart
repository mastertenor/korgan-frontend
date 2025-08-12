import 'package:flutter/material.dart';

/// Platform-agnostic interface for resizable split view
abstract class ResizableSplitViewInterface extends StatefulWidget {
  /// Left child widget (or top child in horizontal mode)
  final Widget leftChild;

  /// Right child widget (or bottom child in horizontal mode)  
  final Widget rightChild;

  /// Whether to split vertically (true) or horizontally (false)
  final bool isVertical;

  /// Initial split ratio (0.0 to 1.0)
  final double initialRatio;

  /// Callback fired when ratio changes
  final ValueChanged<double>? onRatioChanged;

  /// Minimum ratio constraint
  final double minRatio;

  /// Maximum ratio constraint
  final double maxRatio;

  /// Splitter thickness in pixels
  final double splitterThickness;

  /// Splitter color
  final Color? splitterColor;

  /// Splitter hover color
  final Color? splitterHoverColor;

  const ResizableSplitViewInterface({
    super.key,
    required this.leftChild,
    required this.rightChild,
    this.isVertical = true,
    this.initialRatio = 0.5,
    this.onRatioChanged,
    this.minRatio = 0.1,
    this.maxRatio = 0.9,
    this.splitterThickness = 8.0,
    this.splitterColor,
    this.splitterHoverColor,
  });
}