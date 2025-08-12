import 'package:flutter/material.dart';
import 'resizable_split_view_interface.dart';

/// Stub implementation for non-web platforms (mobile/desktop)
/// Provides simple Row/Column layout without web dependencies
class ResizableSplitView extends ResizableSplitViewInterface {
  const ResizableSplitView({
    super.key,
    required super.leftChild,
    required super.rightChild,
    super.isVertical = true,
    super.initialRatio = 0.5,
    super.onRatioChanged,
    super.minRatio = 0.1,
    super.maxRatio = 0.9,
    super.splitterThickness = 8.0,
    super.splitterColor,
    super.splitterHoverColor,
  });

  @override
  State<ResizableSplitView> createState() => _ResizableSplitViewStubState();
}

class _ResizableSplitViewStubState extends State<ResizableSplitView> {
  @override
  Widget build(BuildContext context) {
    // Simple fixed layout for mobile/desktop - no web dependencies
    if (widget.isVertical) {
      return Row(
        children: [
          Expanded(
            flex: (widget.initialRatio * 100).round(),
            child: widget.leftChild,
          ),
          Container(
            width: widget.splitterThickness,
            color: widget.splitterColor ?? Colors.grey[300],
            child: const SizedBox.expand(),
          ),
          Expanded(
            flex: ((1.0 - widget.initialRatio) * 100).round(),
            child: widget.rightChild,
          ),
        ],
      );
    } else {
      return Column(
        children: [
          Expanded(
            flex: (widget.initialRatio * 100).round(),
            child: widget.leftChild,
          ),
          Container(
            height: widget.splitterThickness,
            color: widget.splitterColor ?? Colors.grey[300],
            child: const SizedBox.expand(),
          ),
          Expanded(
            flex: ((1.0 - widget.initialRatio) * 100).round(),
            child: widget.rightChild,
          ),
        ],
      );
    }
  }
}