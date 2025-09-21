// lib/src/features/mail/presentation/widgets/web/tree/tree_loading_skeleton.dart

import 'package:flutter/material.dart';

/// Loading skeleton for tree widget
///
/// Displays animated shimmer effect while tree data is loading
class TreeLoadingSkeleton extends StatefulWidget {
  const TreeLoadingSkeleton({super.key});

  @override
  State<TreeLoadingSkeleton> createState() => _TreeLoadingSkeletonState();
}

class _TreeLoadingSkeletonState extends State<TreeLoadingSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(begin: -1.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Column(
          children: [
            _buildSkeletonItem(0),
            _buildSkeletonItem(1),
            _buildSkeletonItem(0),
            _buildSkeletonItem(2),
            _buildSkeletonItem(1),
            _buildSkeletonItem(0),
            _buildSkeletonItem(1),
            _buildSkeletonItem(0),
          ],
        );
      },
    );
  }

  /// Build individual skeleton item
  Widget _buildSkeletonItem(int level) {
    const double indentSize = 16.0;
    final double leftPadding = 8.0 + (level * indentSize);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: EdgeInsets.only(left: leftPadding, right: 8, top: 8, bottom: 8),
      child: Row(
        children: [
          // Expand indicator skeleton
          _buildShimmerBox(16, 16),

          const SizedBox(width: 6),

          // Icon skeleton
          _buildShimmerBox(16, 16),

          const SizedBox(width: 8),

          // Title skeleton
          Expanded(
            child: Container(
              width: _getRandomWidth(),
              height: 14,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.grey[300]!,
                    Colors.grey[100]!,
                    Colors.grey[300]!,
                  ],
                  stops: [0.0, _animation.value, 1.0],
                ),
              ),
            ),
          ),

          // Count badge skeleton (sometimes)
          if (level == 0 && DateTime.now().millisecondsSinceEpoch % 3 == 0) ...[
            const SizedBox(width: 8),
            _buildShimmerBox(24, 16, borderRadius: 10),
          ],
        ],
      ),
    );
  }

  /// Build shimmer box
  Widget _buildShimmerBox(double width, double height, {double? borderRadius}) {
    return Container(
      width: width == double.infinity ? null : width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius ?? 4),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Colors.grey[300]!, Colors.grey[100]!, Colors.grey[300]!],
          stops: [0.0, _animation.value, 1.0],
        ),
      ),
    );
  }

  /// Get random width for title skeleton
  double _getRandomWidth() {
    final random = DateTime.now().millisecondsSinceEpoch % 100;
    return 80 + (random % 60).toDouble(); // Between 80-140px
  }
}
