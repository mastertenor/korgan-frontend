// lib/src/common_widgets/shell/components/header/platform/web/global_header_web.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../../features/user/presentation/widgets/web/profile_dropdown_web.dart';
import '../../../../../../features/organization/presentation/widgets/organization_selector_web.dart';
import '../../../../../../features/mail/presentation/widgets/context/mail_context_switcher.dart';
import '../../../../../../utils/app_logger.dart';
import '../../../../../../routing/route_constants.dart';
import '../../widgets/global_search_widget.dart';

/// Web implementation of global header - Gmail-style design
///
/// Features:
/// - 64px fixed height professional header
/// - Logo + breadcrumb + organization selector + context switcher on left
/// - TreeNode-aware Global search widget (self-managed search)
/// - Profile dropdown on right
/// - Mail context switcher for mail module
/// - Clean shadows and borders
/// - Hover effects ready
///
/// Layout: [Logo + Breadcrumb + OrgSelector + ContextSwitcher] --- [Search Box] --- [Profile]
class GlobalHeaderWeb extends ConsumerWidget {
  final String currentModule;

  const GlobalHeaderWeb({super.key, required this.currentModule});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 64, // Gmail-style fixed height
      decoration: _buildHeaderDecoration(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildLeftSection(context),
          const SizedBox(width: 24), // Space before search
          Expanded(child: _buildCenterSection(context, ref)),
          const SizedBox(width: 24), // Space after search
          _buildRightSection(context),
        ],
      ),
    );
  }

  BoxDecoration _buildHeaderDecoration() {
    return BoxDecoration(
      color: Colors.white,
      border: Border(bottom: BorderSide(color: Colors.grey[300]!, width: 1)),
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
        const SizedBox(width: 16),
        const OrganizationSelectorWeb(),

        // Add context switcher for mail module
        if (_isMailModule()) ...[
          const SizedBox(width: 12),
          const MailContextSwitcher(
            showTypeBadges: true,
            showEmails: false, // Keep header compact
          ),
        ],
      ],
    );
  }

  /// Check if current module is mail
  bool _isMailModule() {
    return currentModule.toLowerCase() == 'mail';
  }

  /// Center section with TreeNode-aware search widget
  /// Widget now handles all search operations internally
  Widget _buildCenterSection(BuildContext context, WidgetRef ref) {
    // Only show search widget in mail module
    if (_isMailModule()) {
      return Center(
        child: GlobalSearchWidget(
          // Optional callbacks for additional logging/handling
          onSearch: (query) {
            AppLogger.info('Header: Search performed for "$query"');
          },
          onClear: () {
            AppLogger.info('Header: Search cleared');
          },
        ),
      );
    }

    // Return empty space for non-mail modules
    return const SizedBox.shrink();
  }

  Widget _buildAppLogo(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.go(RouteConstants.home);
        AppLogger.info('Navigated to home from logo');
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
            context.go(RouteConstants.home);
            AppLogger.info('Navigated to home from app name');
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
      children: [ProfileDropdownWeb()],
    );
  }
}
