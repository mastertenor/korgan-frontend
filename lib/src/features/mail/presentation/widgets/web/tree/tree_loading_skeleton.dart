import 'package:flutter/material.dart';

/// Basit loading skeleton for tree widget
class TreeLoadingSkeleton extends StatefulWidget {
  const TreeLoadingSkeleton({super.key});

  @override
  State<TreeLoadingSkeleton> createState() => _TreeLoadingSkeletonState();
}

class _TreeLoadingSkeletonState extends State<TreeLoadingSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildItem(0),
        _buildItem(1),
        _buildItem(0),
        _buildItem(2),
        _buildItem(1),
        _buildItem(0),
        _buildItem(1),
        _buildItem(0),
      ],
    );
  }

  Widget _buildItem(int level) {
    final leftPadding = 8.0 + (level * 16.0);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: EdgeInsets.only(left: leftPadding, right: 8, top: 8, bottom: 8),
      child: Row(
        children: [
          // Expand icon
          _buildBox(16, 16),
          const SizedBox(width: 6),

          // Folder icon
          _buildBox(16, 16),
          const SizedBox(width: 8),

          // Title
          Expanded(child: _buildBox(100 + (level * 20), 14)),

          // Badge (sadece level 0'da)
          if (level == 0) ...[const SizedBox(width: 8), _buildBox(24, 16)],
        ],
      ),
    );
  }

  Widget _buildBox(double width, double height) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: Color.lerp(
              Colors.grey[300],
              Colors.grey[200],
              _controller.value,
            ),
          ),
        );
      },
    );
  }
}
