// lib/src/features/organization/presentation/utils/organization_navigation_helper.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/organization_providers.dart';
import '../../domain/entities/organization.dart';
import '../../../../routing/route_constants.dart';
import '../../../../utils/app_logger.dart';
import '../../../mail/presentation/providers/mail_context_provider.dart';
import '../../../mail/presentation/providers/mail_providers.dart';
import '../../../mail/presentation/providers/unread_count_provider.dart';

/// Helper class for organization-aware navigation
///
/// This utility handles navigation between modules while ensuring the correct
/// organization context is maintained in URLs. Provides type-safe navigation
/// methods that automatically inject the current organization slug.
class OrganizationNavigationHelper {
  OrganizationNavigationHelper._();

  /// Navigate to mail module with organization context
  static void navigateToMail(
    BuildContext context,
    WidgetRef ref,
    String email, {
    String? folder,
    String? orgSlug,
  }) {
    final targetOrgSlug = orgSlug ?? _getCurrentOrgSlug(ref);
    if (targetOrgSlug == null) {
      AppLogger.error(
        'Navigation: No organization selected for mail navigation',
      );
      return;
    }

    final path = folder != null
        ? MailRoutes.orgFolderPath(targetOrgSlug, email, folder)
        : MailRoutes.orgDefaultFolderPath(targetOrgSlug, email);

    AppLogger.info('Navigation: Navigating to mail: $path');
    context.go(path);
  }

  /// Navigate to mail detail with organization context
  static void navigateToMailDetail(
    BuildContext context,
    WidgetRef ref,
    String email,
    String folder,
    String mailId, {
    String? orgSlug,
  }) {
    final targetOrgSlug = orgSlug ?? _getCurrentOrgSlug(ref);
    if (targetOrgSlug == null) {
      AppLogger.error(
        'Navigation: No organization selected for mail detail navigation',
      );
      return;
    }

    final path = MailRoutes.orgMailDetailPath(
      targetOrgSlug,
      email,
      folder,
      mailId,
    );
    AppLogger.info('Navigation: Navigating to mail detail: $path');
    context.go(path);
  }

  /// Navigate to CRM module with organization context
  static void navigateToCrm(
    BuildContext context,
    WidgetRef ref, {
    String? orgSlug,
  }) {
    final targetOrgSlug = orgSlug ?? _getCurrentOrgSlug(ref);
    if (targetOrgSlug == null) {
      AppLogger.error(
        'Navigation: No organization selected for CRM navigation',
      );
      return;
    }

    final path = CrmRoutes.orgCrmPath(targetOrgSlug);
    AppLogger.info('Navigation: Navigating to CRM: $path');
    context.go(path);
  }

  /// Navigate to Tasks module with organization context
  static void navigateToTasks(
    BuildContext context,
    WidgetRef ref, {
    String? orgSlug,
  }) {
    final targetOrgSlug = orgSlug ?? _getCurrentOrgSlug(ref);
    if (targetOrgSlug == null) {
      AppLogger.error(
        'Navigation: No organization selected for Tasks navigation',
      );
      return;
    }

    final path = TaskRoutes.orgTasksPath(targetOrgSlug);
    AppLogger.info('Navigation: Navigating to Tasks: $path');
    context.go(path);
  }

  /// Navigate to Dashboard module with organization context
  static void navigateToDashboard(
    BuildContext context,
    WidgetRef ref, {
    String? orgSlug,
  }) {
    final targetOrgSlug = orgSlug ?? _getCurrentOrgSlug(ref);
    if (targetOrgSlug == null) {
      AppLogger.error(
        'Navigation: No organization selected for Dashboard navigation',
      );
      return;
    }

    final path = DashboardRoutes.orgDashboardPath(targetOrgSlug);
    AppLogger.info('Navigation: Navigating to Dashboard: $path');
    context.go(path);
  }

  /// Navigate to home (no organization context needed)
  static void navigateToHome(BuildContext context) {
    AppLogger.info('Navigation: Navigating to Home');
    context.go(RouteConstants.home);
  }

  /// Switch organization and redirect to equivalent page in new organization context
  /// UPDATED: Now handles mail context switching automatically
  static void switchOrganization(
    BuildContext context,
    WidgetRef ref,
    Organization newOrg,
  ) {
    AppLogger.info('Navigation: Switching organization to: ${newOrg.slug}');

    // Update the selected organization
    ref
        .read(organizationNotifierProvider.notifier)
        .switchOrganization(newOrg.id);

    // Get current location to determine if we're in mail module
    final currentLocation = GoRouter.of(
      context,
    ).routerDelegate.currentConfiguration.uri.toString();
    final segments = currentLocation.split('/');
    final isInMailModule = segments.length > 2 && segments[2] == 'mail';

    if (isInMailModule) {
      // Special handling for mail module
      _handleMailModuleOrganizationSwitch(context, ref, newOrg, segments);
    } else {
      // Regular module switching
      final newLocation = _convertLocationToNewOrg(
        currentLocation,
        newOrg.slug,
      );
      if (newLocation != currentLocation) {
        AppLogger.info(
          'Navigation: Redirecting to new org context: $newLocation',
        );
        context.go(newLocation);
      }
    }
  }

  /// Handle organization switch when user is in mail module
/// Handle organization switch when user is in mail module
  static void _handleMailModuleOrganizationSwitch(
    BuildContext context,
    WidgetRef ref,
    Organization newOrg,
    List<String> segments,
  ) {
    AppLogger.info('🏢📧 Handling mail module organization switch');

    try {
      // Force refresh mail contexts for new organization
      ref.invalidate(availableMailContextsProvider);

      // Wait for new contexts to load, then pick first available
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        try {
          // Small delay to let providers update
          await Future.delayed(const Duration(milliseconds: 100));

          final newContexts = ref.read(availableMailContextsProvider);

          if (newContexts.isNotEmpty) {
            // Select first available context in new organization
            final firstContext = newContexts.first;
            ref
                .read(selectedMailContextProvider.notifier)
                .setContext(firstContext);

            // Extract current folder or default to inbox
            final currentFolder = segments.length > 4 ? segments[4] : 'inbox';

            // Invalidate mail providers to trigger fresh data
            ref.invalidate(currentMailsProvider);
            ref.invalidate(mailDetailProvider);

            // Clear mail cache and refresh for new context
            final mailNotifier = ref.read(mailProvider.notifier);
            final unreadCountNotifier = ref.read(unreadCountProvider.notifier);

            // Clear cache for clean state
            mailNotifier.clearFolderCache();

            // Force refresh unread counts for new user
            await unreadCountNotifier.refreshAllFoldersForUser(
              firstContext.emailAddress,
            );

            // Set new user email
            mailNotifier.setCurrentUserEmail(firstContext.emailAddress);

            // Navigate to mail with new context
            final newPath = MailRoutes.orgFolderPath(
              newOrg.slug,
              firstContext.emailAddress,
              currentFolder,
            );

            AppLogger.info(
              '🔗 Mail organization switch: Navigating to $newPath',
            );
            context.go(newPath);

            AppLogger.info(
              '✅ Mail organization switch completed: ${firstContext.emailAddress}',
            );
          } else {
            // No mail contexts available in new organization, redirect to dashboard
            AppLogger.warning(
              '⚠️ No mail contexts available in new organization',
            );
            final dashboardPath = DashboardRoutes.orgDashboardPath(newOrg.slug);
            context.go(dashboardPath);
          }
        } catch (e) {
          AppLogger.error('❌ Error during mail organization switch: $e');
          // Fallback to dashboard
          final dashboardPath = DashboardRoutes.orgDashboardPath(newOrg.slug);
          context.go(dashboardPath);
        }
      });
    } catch (e) {
      AppLogger.error('❌ Failed to handle mail organization switch: $e');
      // Fallback to regular organization switch
      final newLocation = _convertLocationToNewOrg(
        GoRouter.of(context).routerDelegate.currentConfiguration.uri
            .toString(), // FIX: GoRouter.of() ekledik
        newOrg.slug,
      );
      context.go(newLocation);
    }
  }
  /// Get current organization slug from route or provider
  static String? getCurrentOrgSlugFromRoute(BuildContext context) {
    final location = GoRouter.of(
      context,
    ).routerDelegate.currentConfiguration.uri.toString();
    final segments = location.split('/');

    if (segments.length > 1 && segments[1].isNotEmpty) {
      final potentialSlug = segments[1];
      if (RouteConstants.isValidOrgSlug(potentialSlug)) {
        return potentialSlug;
      }
    }

    return null;
  }

  /// Check if current route is organization-aware
  static bool isOrganizationRoute(BuildContext context) {
    return getCurrentOrgSlugFromRoute(context) != null;
  }

  /// Get current module from route
  static String? getCurrentModule(BuildContext context) {
    final location = GoRouter.of(
      context,
    ).routerDelegate.currentConfiguration.uri.toString();
    final segments = location.split('/');

    if (segments.length > 2 &&
        segments[1].isNotEmpty &&
        segments[2].isNotEmpty) {
      final potentialModule = segments[2];
      if (potentialModule.startsWith('mail') ||
          potentialModule.startsWith('crm') ||
          potentialModule.startsWith('tasks') ||
          potentialModule.startsWith('dashboard')) {
        return potentialModule;
      }
    }

    return null;
  }

  // ========== PRIVATE HELPERS ==========

  /// Get current organization slug from provider
  static String? _getCurrentOrgSlug(WidgetRef ref) {
    try {
      final selectedOrg = ref.read(selectedOrganizationProvider);
      return selectedOrg?.slug;
    } catch (e) {
      AppLogger.warning('Navigation: Could not get current organization: $e');
      return null;
    }
  }

  /// Convert current location to use new organization slug
  static String _convertLocationToNewOrg(
    String currentLocation,
    String newOrgSlug,
  ) {
    final segments = currentLocation.split('/');

    // If current route already has organization slug, replace it
    if (segments.length > 1 && RouteConstants.isValidOrgSlug(segments[1])) {
      segments[1] = newOrgSlug;
      return segments.join('/');
    }

    // If current route is a legacy route, add organization slug
    if (segments.length > 1 && segments[1] == 'mail') {
      return '/$newOrgSlug$currentLocation';
    }

    // For other routes, redirect to equivalent in new org (default to dashboard)
    return DashboardRoutes.orgDashboardPath(newOrgSlug);
  }
}

/// Extension methods for easier navigation from widgets
extension OrganizationNavigationExtension on BuildContext {
  /// Navigate to mail with current organization
  void goToOrgMail(
    WidgetRef ref,
    String email, {
    String? folder,
    String? orgSlug,
  }) {
    OrganizationNavigationHelper.navigateToMail(
      this,
      ref,
      email,
      folder: folder,
      orgSlug: orgSlug,
    );
  }

  /// Navigate to mail detail with current organization
  void goToOrgMailDetail(
    WidgetRef ref,
    String email,
    String folder,
    String mailId, {
    String? orgSlug,
  }) {
    OrganizationNavigationHelper.navigateToMailDetail(
      this,
      ref,
      email,
      folder,
      mailId,
      orgSlug: orgSlug,
    );
  }

  /// Navigate to CRM with current organization
  void goToOrgCrm(WidgetRef ref, {String? orgSlug}) {
    OrganizationNavigationHelper.navigateToCrm(this, ref, orgSlug: orgSlug);
  }

  /// Navigate to Tasks with current organization
  void goToOrgTasks(WidgetRef ref, {String? orgSlug}) {
    OrganizationNavigationHelper.navigateToTasks(this, ref, orgSlug: orgSlug);
  }

  /// Navigate to Dashboard with current organization
  void goToOrgDashboard(WidgetRef ref, {String? orgSlug}) {
    OrganizationNavigationHelper.navigateToDashboard(
      this,
      ref,
      orgSlug: orgSlug,
    );
  }

  /// Switch organization
  void switchOrg(WidgetRef ref, Organization newOrg) {
    OrganizationNavigationHelper.switchOrganization(this, ref, newOrg);
  }
}
