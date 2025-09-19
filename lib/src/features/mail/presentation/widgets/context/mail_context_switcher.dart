// lib/src/features/mail/presentation/widgets/context/mail_context_switcher.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../utils/app_logger.dart';
import '../../../../../routing/route_constants.dart';
import '../../../presentation/providers/mail_context_provider.dart';
import '../../../domain/entities/mail_context.dart';
import '../../providers/mail_providers.dart';
import '../../providers/unread_count_provider.dart';

/// Mail context switcher widget for web header
///
/// This widget provides context switching functionality in the mail module header.
/// Similar to OrganizationSelectorWeb but for mail contexts.
///
/// Features:
/// - Dropdown-style context selector
/// - Current context display with type badge
/// - Context switching with URL updates
/// - Email invalidation on context switch
/// - Loading and error states
/// - Modern design matching organization selector
///
/// Layout: [Current Context Info] [Dropdown Arrow]
class MailContextSwitcher extends ConsumerWidget {
  /// Optional callback when context changes
  final void Function(MailContext context)? onContextChanged;

  /// Whether to show context type badges
  final bool showTypeBadges;

  /// Whether to show email addresses
  final bool showEmails;

  const MailContextSwitcher({
    super.key,
    this.onContextChanged,
    this.showTypeBadges = true,
    this.showEmails = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch context state
    final availableContexts = ref.watch(availableMailContextsProvider);
    final selectedContext = ref.watch(selectedMailContextProvider);
    final hasContexts = ref.watch(hasMailContextsProvider);

    AppLogger.debug(
      '🔄 MailContextSwitcher: Building with ${availableContexts.length} contexts',
    );

    // Don't show if no contexts available
    if (!hasContexts || availableContexts.isEmpty) {
      AppLogger.debug('🔄 MailContextSwitcher: No contexts available');
      return const SizedBox.shrink();
    }

    // Don't show dropdown if only one context
    if (availableContexts.length == 1) {
      return _buildSingleContext(availableContexts.first);
    }

    return _buildContextDropdown(
      context,
      ref,
      availableContexts,
      selectedContext,
    );
  }

  /// Build widget when user has only one context (no dropdown needed)
  Widget _buildSingleContext(MailContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildContextIcon(context),
          const SizedBox(width: 8),
          _buildContextInfo(context, isCompact: true),
        ],
      ),
    );
  }

  /// Build dropdown selector for multiple contexts
  Widget _buildContextDropdown(
    BuildContext context,
    WidgetRef ref,
    List<MailContext> contexts,
    MailContext? selectedContext,
  ) {
    return PopupMenuButton<String>(
      tooltip: 'Mail hesabı değiştir',
      offset: const Offset(0, 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      menuPadding: EdgeInsets.zero,
      child: _buildCurrentContextDisplay(selectedContext),
      itemBuilder: (context) =>
          _buildContextMenuItems(contexts, selectedContext?.id),
      onSelected: (contextId) => _handleContextSwitch(
        context,
        ref,
        contexts.firstWhere((c) => c.id == contextId),
      ),
    );
  }

  /// Build current context display button
  Widget _buildCurrentContextDisplay(MailContext? selectedContext) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (selectedContext != null) ...[
            _buildContextIcon(selectedContext),
            const SizedBox(width: 8),
            _buildContextInfo(selectedContext, isCompact: true),
          ] else ...[
            Icon(Icons.email, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Text(
              'Context seç',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
          const SizedBox(width: 8),
          Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.grey[600]),
        ],
      ),
    );
  }

  /// Build context icon with type indication
  Widget _buildContextIcon(MailContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: context.contextColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(context.contextIcon, size: 12, color: context.contextColor),
    );
  }

  /// Build context information display
  Widget _buildContextInfo(MailContext context, {bool isCompact = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          context.displayName,
          style: TextStyle(
            fontSize: isCompact ? 13 : 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (showEmails && !isCompact) ...[
          const SizedBox(height: 2),
          Text(
            context.emailAddress,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  /// Build context type badge
  Widget _buildContextTypeBadge(MailContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: context.contextColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: context.contextColor.withOpacity(0.3),
          width: 0.5,
        ),
      ),
      child: Text(
        context.contextTypeDisplayName,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: context.contextColor,
        ),
      ),
    );
  }

  /// Build dropdown menu items
  List<PopupMenuItem<String>> _buildContextMenuItems(
    List<MailContext> contexts,
    String? selectedId,
  ) {
    return contexts.map((context) {
      final isSelected = context.id == selectedId;

      return PopupMenuItem<String>(
        value: context.id,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              // Selection indicator
              Container(
                width: 4,
                height: 32,
                decoration: BoxDecoration(
                  color: isSelected ? context.contextColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),

              // Context icon
              _buildContextIcon(context),
              const SizedBox(width: 12),

              // Context info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            context.displayName,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: isSelected
                                  ? context.contextColor
                                  : Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (showTypeBadges) ...[
                          const SizedBox(width: 8),
                          _buildContextTypeBadge(context),
                        ],
                      ],
                    ),
                    if (showEmails) ...[
                      const SizedBox(height: 2),
                      Text(
                        context.emailAddress,
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected
                              ? context.contextColor.withOpacity(0.8)
                              : Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              // Check icon for selected item
              if (isSelected) ...[
                const SizedBox(width: 8),
                Icon(Icons.check, size: 16, color: context.contextColor),
              ],
            ],
          ),
        ),
      );
    }).toList();
  }

  /// Handle context switching
  void _handleContextSwitch(
    BuildContext context,
    WidgetRef ref,
    MailContext newContext,
  ) {
    AppLogger.info(
      '🔄 MailContextSwitcher: Switching to context: ${newContext.emailAddress}',
    );

    // 1. Update context provider
    ref.read(selectedMailContextProvider.notifier).setContext(newContext);

    // 2. Update URL with new email
    _updateUrlWithNewEmail(context, newContext.emailAddress);

    // 3. Invalidate mail-related providers to trigger refresh
    _invalidateMailData(ref);

    // 4. Call callback if provided
    onContextChanged?.call(newContext);

    AppLogger.info('✅ Context switch completed: ${newContext.emailAddress}');
  }

  /// Update URL with new email address using proper routing system
  void _updateUrlWithNewEmail(BuildContext context, String newEmail) {
    try {
      final currentUri = GoRouter.of(
        context,
      ).routerDelegate.currentConfiguration.uri;
      final segments = currentUri.pathSegments;

      AppLogger.debug('🔗 Current URL segments: $segments');

      // Expected format: [orgSlug, 'mail', email, folder] or [orgSlug, 'mail', email, folder, mailId]
      if (segments.length >= 4 && segments[1] == 'mail') {
        final orgSlug = segments[0];
        final currentFolder = segments[3];

        // Check if we're in mail detail view
        if (segments.length >= 5) {
          // Mail detail view - redirect to folder view with new email
          final newUrl = MailRoutes.orgFolderPath(
            orgSlug,
            newEmail,
            currentFolder,
          );
          AppLogger.info(
            '🔗 Context switch: Mail detail → folder view: $newUrl',
          );
          context.go(newUrl);
        } else {
          // Folder view - update with new email
          final newUrl = MailRoutes.orgFolderPath(
            orgSlug,
            newEmail,
            currentFolder,
          );
          AppLogger.info('🔗 Context switch: Folder view update: $newUrl');
          context.go(newUrl);
        }

        // Note: Query parameters will be handled by GoRouter automatically
        if (currentUri.query.isNotEmpty) {
          AppLogger.debug('🔗 Original query params: ${currentUri.query}');
        }
      } else {
        AppLogger.warning(
          '🔗 Unexpected URL format for context switch: $segments',
        );
        // Fallback: try to extract org slug and redirect to inbox
        if (segments.isNotEmpty && RouteConstants.isValidOrgSlug(segments[0])) {
          final fallbackUrl = MailRoutes.orgDefaultFolderPath(
            segments[0],
            newEmail,
          );
          AppLogger.info('🔗 Fallback redirect to inbox: $fallbackUrl');
          context.go(fallbackUrl);
        }
      }
    } catch (e) {
      AppLogger.error('🔗 Error updating URL with new email: $e');
    }
  }

/// Invalidate mail-related providers to trigger data refresh
  /// Invalidate mail-related providers to trigger data refresh
  void _invalidateMailData(WidgetRef ref) {
    try {
      // Invalidate mail providers to trigger fresh API calls
      ref.invalidate(currentMailsProvider);
      ref.invalidate(mailDetailProvider);

      // Clear any cached mail data
      AppLogger.debug('🗑️ Mail data invalidated for context switch');

      // CRITICAL: Force complete state reset and fresh reload
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        try {
          final newEmail = ref.read(selectedMailContextProvider)?.emailAddress;
          if (newEmail != null) {
            final mailNotifier = ref.read(mailProvider.notifier);
            final unreadCountNotifier = ref.read(unreadCountProvider.notifier);

            // 1. CRITICAL: Clear folder cache to bypass smart caching
            final currentFolder = ref.read(currentFolderProvider);
            mailNotifier.clearFolderCache(currentFolder);

            // 2. CRITICAL: Force refresh unread counts for new user context
            await unreadCountNotifier.refreshAllFoldersForUser(newEmail);

            // 3. Clear current error state
            mailNotifier.clearError();

            // 4. Set new email
            mailNotifier.setCurrentUserEmail(newEmail);

            // 5. Force folder refresh with forceRefresh=true to bypass cache
            mailNotifier.loadFolder(
              currentFolder,
              userEmail: newEmail,
              forceRefresh: true, // This bypasses the isStale check
            );

            AppLogger.info(
              '🔄 Forced fresh mail reload with cache clear and unread count refresh: $newEmail',
            );
          }
        } catch (e) {
          AppLogger.error('❌ Error forcing mail reload: $e');
        }
      });
    } catch (e) {
      AppLogger.error('🗑️ Error invalidating mail data: $e');
    }
  }
}
