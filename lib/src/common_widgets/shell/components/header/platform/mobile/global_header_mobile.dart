// lib/src/common_widgets/shell/components/header/platform/mobile/global_header_mobile.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../../utils/app_logger.dart';
import '../../../../utils/shell_utils.dart';

/// Mobile implementation of global header - AppBar-style design
/// 
/// Features:
/// - AppBar-style native mobile feel
/// - Logo + module title layout
/// - Touch-friendly profile button
/// - Material Design 3 styling
/// - Larger touch targets
/// 
/// Layout: [Logo + Title] --- [Spacer] --- [Profile]
class GlobalHeaderMobile extends StatelessWidget {
  const GlobalHeaderMobile({super.key});

  @override
  Widget build(BuildContext context) {
    final currentModule = ShellUtils.getCurrentModule(context);
    final theme = Theme.of(context);
    
    return Container(
      height: 56, // Standard AppBar height for mobile
      decoration: _buildHeaderDecoration(theme),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Left Section: Logo + Module title
          _buildLeftSection(context, currentModule, theme),
          
          // Spacer: Push right content to the edge
          const Spacer(),
          
          // Right Section: Profile button
          _buildRightSection(context, theme),
        ],
      ),
    );
  }

  /// Header decoration - mobile AppBar styling
  BoxDecoration _buildHeaderDecoration(ThemeData theme) {
    return BoxDecoration(
      color: theme.colorScheme.surface,
      border: Border(
        bottom: BorderSide(
          color: theme.colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      // Subtle elevation for mobile
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ],
    );
  }

  /// Left section: Logo + module title
  Widget _buildLeftSection(BuildContext context, String currentModule, ThemeData theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // App Logo - touch-friendly size
        _buildAppLogo(context, theme),
        
        const SizedBox(width: 12),
        
        // App Name or Module Title
        _buildTitle(context, currentModule, theme),
      ],
    );
  }

  /// App logo - larger for mobile touch
  Widget _buildAppLogo(BuildContext context, ThemeData theme) {
    return GestureDetector(
      onTap: () {
        context.go('/');
        AppLogger.info('🏠 Mobile: Navigated to home from logo');
      },
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: theme.colorScheme.primary,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.dashboard_rounded,
          color: theme.colorScheme.onPrimary,
          size: 20,
        ),
      ),
    );
  }

  /// Title section - app name or module name
  Widget _buildTitle(BuildContext context, String currentModule, ThemeData theme) {
    final displayTitle = currentModule.isEmpty ? 'Korgan' : currentModule;
    
    return GestureDetector(
      onTap: () {
        if (currentModule.isNotEmpty) {
          // If in module, go to home
          context.go('/');
          AppLogger.info('🏠 Mobile: Navigated to home from module title');
        }
      },
      child: Text(
        displayTitle,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurface,
        ),
      ),
    );
  }

  /// Right section: Profile button (mobile-friendly)
  Widget _buildRightSection(BuildContext context, ThemeData theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Placeholder for Profile Dropdown
        // Will be replaced with: ProfileDropdown(),
        _buildProfilePlaceholder(theme),
      ],
    );
  }

  /// Temporary profile placeholder - will be replaced with ProfileDropdown
  Widget _buildProfilePlaceholder(ThemeData theme) {
    return GestureDetector(
      onTap: () {
        AppLogger.info('👤 Mobile profile tapped (placeholder)');
        // TODO: Show profile menu
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        child: CircleAvatar(
          radius: 18, // Larger for mobile touch
          backgroundColor: theme.colorScheme.primary,
          child: Text(
            'U', // Will be dynamic initials
            style: TextStyle(
              color: theme.colorScheme.onPrimary,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}