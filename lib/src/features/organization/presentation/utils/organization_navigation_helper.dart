// lib/src/features/organization/presentation/utils/organization_navigation_helper.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../mail/presentation/providers/global_search_provider.dart';
import '../../../mail/presentation/providers/state/mail_state.dart';
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

    // Store the target path early - before async operations
    final currentFolder = segments.length > 4 ? segments[4] : 'inbox';

    try {
      // 1. Force refresh mail contexts for new organization
      ref.invalidate(availableMailContextsProvider);

      // 2. Use addPostFrameCallback to avoid blocking UI
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        try {
          // Wait for contexts with timeout
          await _waitForContextSelection(ref);

          // Get selected context
          final selectedContext = ref.read(selectedMailContextProvider);

          if (selectedContext != null) {
            // Setup mail state
            final mailNotifier = ref.read(mailProvider.notifier);
            mailNotifier.clearFolderCache();
            mailNotifier.setCurrentUserEmail(selectedContext.emailAddress);

            // Load mail state asynchronously
            _loadMailStateAsync(ref, selectedContext.emailAddress);

            // Navigate immediately with the stored path
            final newPath = MailRoutes.orgFolderPath(
              newOrg.slug,
              selectedContext.emailAddress,
              currentFolder,
            );

            // Safe navigation check
            if (_safeNavigate(context, newPath)) {
              AppLogger.info(
                '✅ Mail organization switch completed: ${selectedContext.emailAddress}',
              );
            }
          } else {
            // Fallback to dashboard
            final dashboardPath = DashboardRoutes.orgDashboardPath(newOrg.slug);
            _safeNavigate(context, dashboardPath);
          }
        } catch (e) {
          AppLogger.error('❌ Error during mail organization switch: $e');
          final dashboardPath = DashboardRoutes.orgDashboardPath(newOrg.slug);
          _safeNavigate(context, dashboardPath);
        }
      });
    } catch (e) {
      AppLogger.error('❌ Failed to handle mail organization switch: $e');
      final dashboardPath = DashboardRoutes.orgDashboardPath(newOrg.slug);
      _safeNavigate(context, dashboardPath);
    }
  }

/// Load mail state in background without blocking navigation
  static void _loadMailStateAsync(WidgetRef ref, String userEmail) {
    Future.microtask(() async {
      try {
        // 1. Clear ALL mail and search states
        ref.read(mailSelectionProvider.notifier).clearAllSelections();
        ref.read(mailDetailProvider.notifier).clearData();
        ref.read(selectedMailIdProvider.notifier).state = null;

        // 🆕 GLOBAL SEARCH TEMİZLE
        final searchController = ref.read(globalSearchControllerProvider);
        searchController.clearSearch();

        // 2. Load inbox in background
        await ref
            .read(mailProvider.notifier)
            .loadFolder(
              MailFolder.inbox,
              userEmail: userEmail,
              forceRefresh: true,
            );

        // 3. Update unread counts
        await ref
            .read(unreadCountProvider.notifier)
            .refreshAllFoldersForUser(userEmail);

        AppLogger.info(
          '✅ Mail state loaded with all states cleared including search',
        );
      } catch (e) {
        AppLogger.error('❌ Failed to load mail state: $e');
      }
    });
  }

  // Yardımcı method - context seçimini bekle
static Future<void> _waitForContextSelection(WidgetRef ref) async {
    int attempts = 0;
    const maxAttempts = 10; // Reduced to 1 second
    const delayMs = 100;

    while (attempts < maxAttempts) {
      await Future.delayed(const Duration(milliseconds: delayMs));

      final contexts = ref.read(availableMailContextsProvider);
      final selectedContext = ref.read(selectedMailContextProvider);

      if (contexts.isNotEmpty && selectedContext != null) {
        AppLogger.info(
          '✅ Context selection completed after ${attempts * delayMs}ms',
        );
        return;
      }

      attempts++;
    }

    AppLogger.warning(
      '⚠️ Context selection timeout after ${maxAttempts * delayMs}ms',
    );
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

static bool _safeNavigate(BuildContext context, String path) {
    if (!context.mounted) {
      AppLogger.warning(
        '⚠️ Context not mounted, skipping navigation to: $path',
      );
      return false;
    }

    try {
      context.go(path);
      AppLogger.info('🔗 Safe navigation completed: $path');
      return true;
    } catch (e) {
      AppLogger.error('❌ Navigation failed: $e');
      return false;
    }
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
