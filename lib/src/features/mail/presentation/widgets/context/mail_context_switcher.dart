// lib/src/features/mail/presentation/widgets/context/mail_context_switcher.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../utils/app_logger.dart';
import '../../../../../routing/route_constants.dart';
import '../../../../organization/presentation/providers/organization_providers.dart';
import '../../../presentation/providers/mail_context_provider.dart';
import '../../../domain/entities/mail_context.dart';
import '../../providers/global_search_provider.dart';
import '../../providers/mail_providers.dart';
import '../../providers/mail_tree_provider.dart';
import '../../providers/unread_count_provider.dart';

/// Modern Mail context switcher widget for web header
///
/// Professional dropdown with animations, proper positioning, and modern interactions.
/// Based on ProfileDropdownWeb design patterns with blue theme.
///
/// Features:
/// - CompositedTransform for precise positioning
/// - Overlay system for proper layering
/// - Smooth animations (scale & opacity)
/// - Hover states and visual feedback
/// - Outside tap to close
/// - Material Design elevation and shadows
/// - Context switching with URL updates
/// - Cache invalidation on switch
class MailContextSwitcher extends ConsumerStatefulWidget {
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
  ConsumerState<MailContextSwitcher> createState() =>
      _MailContextSwitcherState();
}

class _MailContextSwitcherState extends ConsumerState<MailContextSwitcher>
    with TickerProviderStateMixin {
  bool _isHovered = false;
  bool _isDropdownOpen = false;
  OverlayEntry? _overlayEntry;
  final LayerLink _link = LayerLink();

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _removeDropdown();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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

    return CompositedTransformTarget(
      link: _link,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: _toggleDropdown,
          child: _buildCurrentContextDisplay(selectedContext),
        ),
      ),
    );
  }

  /// Build widget when user has only one context (no dropdown needed)
  Widget _buildSingleContext(MailContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.blue[200]!),
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

  /// Build current context display button with modern styling
/// Build current context display button with loading state only
  Widget _buildCurrentContextDisplay(MailContext? selectedContext) {
    
    final isOrgSwitching = ref.watch(isSwitchingOrganizationProvider);

    // Show loading if no context or org switching
    final showLoading = selectedContext == null || isOrgSwitching;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _isHovered || _isDropdownOpen ? Colors.grey[200] : Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: _isDropdownOpen ? Colors.blue[300]! : Colors.grey[300]!,
        ),
        boxShadow: _isDropdownOpen
            ? [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showLoading) ...[
            // Loading state - sadece yükleniyor göster
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[600]!),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Yükleniyor...',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ] else ...[
            // Normal context display
            _buildContextIcon(selectedContext),
            const SizedBox(width: 8),
            _buildContextInfo(selectedContext, isCompact: true),
          ],
          const SizedBox(width: 8),
          if (!showLoading) // Loading durumunda dropdown arrow gösterme
            AnimatedRotation(
              turns: _isDropdownOpen ? 0.5 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 16,
                color: Colors.grey[600],
              ),
            ),
        ],
      ),
    );
  }  
  
  void _toggleDropdown() {
    if (_isDropdownOpen) {
      _hideDropdown();
    } else {
      _showDropdown();
    }
  }

  void _showDropdown() {
    if (_overlayEntry != null) return;

    setState(() => _isDropdownOpen = true);
    AppLogger.debug('MailContextSwitcher: Opening context dropdown');

    _overlayEntry = OverlayEntry(builder: (context) => _buildDropdownOverlay());

    // Use root overlay for proper z-index layering
    final overlay = Overlay.of(context, rootOverlay: true);
    overlay.insert(_overlayEntry!);
    _animationController.forward();
  }

  void _hideDropdown() {
    if (_overlayEntry == null) return;

    setState(() => _isDropdownOpen = false);
    AppLogger.debug('MailContextSwitcher: Closing context dropdown');

    _animationController.reverse().then((_) {
      _removeDropdown();
    });
  }

  void _removeDropdown() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Widget _buildDropdownOverlay() {
    final availableContexts = ref.watch(availableMailContextsProvider);
    final selectedContext = ref.watch(selectedMailContextProvider);

    return GestureDetector(
      onTap: _hideDropdown,
      behavior: HitTestBehavior.opaque,
      child: Material(
        type: MaterialType.transparency,
        child: Stack(
          children: [
            // Full screen invisible overlay to capture outside taps
            const Positioned.fill(child: SizedBox.expand()),

            // Dropdown positioned using CompositedTransformFollower
            CompositedTransformFollower(
              link: _link,
              showWhenUnlinked: false,
              targetAnchor: Alignment.bottomLeft,
              followerAnchor: Alignment.topLeft,
              offset: const Offset(0, 6),
              child: GestureDetector(
                onTap: () {}, // Prevent dropdown content taps from bubbling up
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnimation.value,
                      alignment: Alignment.topLeft,
                      child: Opacity(
                        opacity: _opacityAnimation.value,
                        child: _buildDropdownContent(
                          availableContexts,
                          selectedContext,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownContent(
    List<MailContext> contexts,
    MailContext? selectedContext,
  ) {
    return Material(
      color: Colors.white,
      elevation: 20,
      shadowColor: Colors.black.withOpacity(0.25),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0x1F000000)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 280, maxWidth: 320),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDropdownHeader(),
            const Divider(height: 1),
            _buildContextList(contexts, selectedContext?.id),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(Icons.swap_horiz, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            'Mail Hesabı Seç',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContextList(List<MailContext> contexts, String? selectedId) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: contexts.map((context) {
          final isSelected = context.id == selectedId;
          return _buildContextMenuItem(context, isSelected);
        }).toList(),
      ),
    );
  }

  Widget _buildContextMenuItem(MailContext context, bool isSelected) {
    final hoverColor = Colors.blue.withOpacity(0.08);
    final pressColor = Colors.blue.withOpacity(0.15);
    final selectedBackground = Colors.blue.withOpacity(0.12);

    return Material(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _handleContextSwitch(context),
        borderRadius: BorderRadius.circular(8),
        overlayColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.hovered)) return hoverColor;
          if (states.contains(MaterialState.pressed)) return pressColor;
          return null;
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? selectedBackground : null,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              // Selection indicator
              Container(
                width: 4,
                height: 32,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blue[600] : Colors.transparent,
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
                    Text(
                      context.displayName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: isSelected ? Colors.blue[700] : Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (widget.showEmails) ...[
                      const SizedBox(height: 2),
                      Text(
                        context.emailAddress,
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected
                              ? Colors.blue[600]
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
                Icon(Icons.check_circle, size: 18, color: Colors.blue[600]),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Build context icon with blue theme
  Widget _buildContextIcon(MailContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(Icons.email, size: 14, color: Colors.blue[600]),
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
        if (widget.showEmails && !isCompact) ...[
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

  /// Handle context switching
/// Handle context switching with proper separation of concerns
  void _handleContextSwitch(MailContext newContext) {
    _hideDropdown();

    AppLogger.info(
      '🔄 MailContextSwitcher: Switching to context: ${newContext.emailAddress}',
    );

    // 1. Update context provider
    ref.read(selectedMailContextProvider.notifier).setContext(newContext);

    // 2. Immediate navigation (before async operations)
    _updateUrlWithNewEmail(newContext.emailAddress);

    // 3. Background data loading (async, no navigation)
    _invalidateMailData();

    // 4. Call callback if provided
    widget.onContextChanged?.call(newContext);

    AppLogger.info('✅ Context switch completed: ${newContext.emailAddress}');
  }
  /// Update URL with new email address using proper routing system
/// Update URL with new email address using safe navigation
  void _updateUrlWithNewEmail(String newEmail) {
    try {
      final currentUri = GoRouter.of(
        context,
      ).routerDelegate.currentConfiguration.uri;
      final segments = currentUri.pathSegments;

      AppLogger.debug('🔗 Current URL segments: $segments');

      String? targetUrl;

      // Expected format: [orgSlug, 'mail', email, folder] or [orgSlug, 'mail', email, folder, mailId]
      if (segments.length >= 4 && segments[1] == 'mail') {
        final orgSlug = segments[0];
        final currentFolder = segments[3];

        if (segments.length >= 5) {
          // Mail detail view - redirect to folder view with new email
          targetUrl = MailRoutes.orgFolderPath(
            orgSlug,
            newEmail,
            currentFolder,
          );
          AppLogger.info(
            '🔗 Context switch: Mail detail → folder view: $targetUrl',
          );
        } else {
          // Folder view - update with new email
          targetUrl = MailRoutes.orgFolderPath(
            orgSlug,
            newEmail,
            currentFolder,
          );
          AppLogger.info('🔗 Context switch: Folder view update: $targetUrl');
        }
      } else {
        AppLogger.warning(
          '🔗 Unexpected URL format for context switch: $segments',
        );
        // Fallback: try to extract org slug and redirect to inbox
        if (segments.isNotEmpty && RouteConstants.isValidOrgSlug(segments[0])) {
          targetUrl = MailRoutes.orgDefaultFolderPath(segments[0], newEmail);
          AppLogger.info('🔗 Fallback redirect to inbox: $targetUrl');
        }
      }

      // Safe navigation - immediate, no async gap
      if (targetUrl != null) {
        _safeNavigate(targetUrl);
      }
    } catch (e) {
      AppLogger.error('🔗 Error updating URL with new email: $e');
    }
  }
  /// Invalidate mail-related providers to trigger data refresh
/// Invalidate mail-related providers to trigger data refresh
  void _invalidateMailData() {
    try {
      // Immediate invalidations
      ref.invalidate(currentMailsProvider);
      ref.invalidate(mailDetailProvider);

      AppLogger.debug('🗑️ Mail data invalidated for context switch');

      // Async operations in background - NO NAVIGATION
      _loadMailDataAsync();
    } catch (e) {
      AppLogger.error('🗑️ Error invalidating mail data: $e');
    }
  }

// SADECE _loadMailDataAsync metodunu değiştir (470. satır civarı):

  /// Load mail data in background without navigation
  void _loadMailDataAsync() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final newEmail = ref.read(selectedMailContextProvider)?.emailAddress;
        if (newEmail != null) {
          final mailNotifier = ref.read(mailProvider.notifier);
          final unreadCountNotifier = ref.read(unreadCountProvider.notifier);

          // 1. Clear ALL mail and search states
          ref.read(mailSelectionProvider.notifier).clearAllSelections();
          ref.read(mailDetailProvider.notifier).clearData();
          ref.read(selectedMailIdProvider.notifier).state = null;

          // 2. GLOBAL SEARCH TEMİZLE
          final searchController = ref.read(globalSearchControllerProvider);
          searchController.clearSearch();

          // 🔥 3. YENİ: TreeNode sistemini temizle
          mailNotifier.clearNodeCache();
          ref.read(selectedTreeNodeProvider.notifier).state = null;

          // 4. Background operations
          mailNotifier.clearError();
          mailNotifier.setCurrentUserEmail(newEmail);

          // 5. Update unread counts
          await unreadCountNotifier.refreshAllFoldersForUser(newEmail);

          // 🔥 6. YENİ: TreeNode tabanlı yükleme (legacy yerine)
          await _loadFirstTreeNode(newEmail);

          AppLogger.info('✅ Mail data loaded with TreeNode system: $newEmail');
        }
      } catch (e) {
        AppLogger.error('❌ Error loading mail data: $e');
      }
    });
  }

  // 🔥 YENİ METOD EKLE: İlk TreeNode'u yükle (dosyanın sonuna ekle)
  Future<void> _loadFirstTreeNode(String userEmail) async {
    try {
      // Tree provider'ın hazır olmasını bekle
      await Future.delayed(const Duration(milliseconds: 200));

      final treeState = ref.read(mailTreeProvider);

      await treeState.when(
        data: (nodes) async {
          if (nodes.isNotEmpty) {
            final firstNode = nodes.first;

            // Node'u seç
            ref.read(selectedTreeNodeProvider.notifier).state = firstNode;

            // Mail listesini yükle
            await ref
                .read(mailProvider.notifier)
                .loadTreeNodeMails(
                  node: firstNode,
                  userEmail: userEmail,
                  forceRefresh: true,
                );

            AppLogger.info(
              '✅ Context switch: Auto-selected first tree node: ${firstNode.title}',
            );
          } else {
            AppLogger.warning(
              '⚠️ No tree nodes available after context switch',
            );
          }
        },
        loading: () async {
          AppLogger.info('🔄 Waiting for tree to load after context switch');
          // Tree henüz yüklenmemiş, tekrar dene
          await Future.delayed(const Duration(milliseconds: 300));
          await _loadFirstTreeNode(userEmail);
        },
        error: (error, stack) async {
          AppLogger.error('❌ Tree loading error after context switch: $error');
        },
      );
    } catch (e) {
      AppLogger.error('❌ Error loading first tree node: $e');
    }
  }
        /// Safe navigation helper - context mounted kontrolü ile
  bool _safeNavigate(String newUrl) {
    if (!mounted) {
      AppLogger.warning(
        '⚠️ Widget not mounted, skipping navigation to: $newUrl',
      );
      return false;
    }

    try {
      context.go(newUrl);
      AppLogger.info('🔗 Safe navigation completed: $newUrl');
      return true;
    } catch (e) {
      AppLogger.error('❌ Navigation failed: $e');
      return false;
    }
  }
}
