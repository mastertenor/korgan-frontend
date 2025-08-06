// lib/src/common_widgets/shell/components/header/platform/web/global_header_web.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../../utils/app_logger.dart';

/// Web implementation of global header - Gmail-style design
/// 
/// Features:
/// - 64px fixed height professional header
/// - Logo + breadcrumb navigation on left
/// - Spacer to push right content to edge
/// - Profile dropdown on right (will be added)
/// - Clean shadows and borders
/// - Hover effects ready
/// 
/// Layout: [Logo + Breadcrumb] --- [Spacer] --- [Profile]
class GlobalHeaderWeb extends StatelessWidget {
  final String currentModule;

  const GlobalHeaderWeb({
    super.key,
    required this.currentModule,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64, // Gmail-style fixed height
      decoration: _buildHeaderDecoration(),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          _buildLeftSection(context),
          const Spacer(),
          _buildRightSection(context),
        ],
      ),
    );
  }

  BoxDecoration _buildHeaderDecoration() {
    return BoxDecoration(
      color: Colors.white,
      border: Border(
        bottom: BorderSide(
          color: Colors.grey[300]!,
          width: 1,
        ),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  Widget _buildLeftSection(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildAppLogo(context),
        const SizedBox(width: 16),
        _buildBreadcrumb(context),
      ],
    );
  }

  Widget _buildAppLogo(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.go('/');
        AppLogger.info('🏠 Navigated to home from logo');
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue[600]!, Colors.blue[700]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(
          Icons.dashboard_rounded,
          color: Colors.white,
          size: 22,
        ),
      ),
    );
  }

  Widget _buildBreadcrumb(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () {
            context.go('/');
            AppLogger.info('🏠 Navigated to home from app name');
          },
          child: Text(
            'Korgan',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
              letterSpacing: -0.5,
            ),
          ),
        ),
        if (currentModule.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Icon(
              Icons.chevron_right_rounded,
              color: Colors.grey[400],
              size: 20,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              currentModule,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.blue[700],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRightSection(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildProfilePlaceholder(),
      ],
    );
  }

  Widget _buildProfilePlaceholder() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.blue[600],
            child: const Text(
              'U',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Colors.grey[600],
            size: 18,
          ),
        ],
      ),
    );
  }
}
