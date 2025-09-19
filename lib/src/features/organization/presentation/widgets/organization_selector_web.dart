// lib/src/features/organization/presentation/widgets/organization_selector_web.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../utils/app_logger.dart';
import '../../domain/entities/organization.dart';
import '../providers/organization_providers.dart';
import '../utils/organization_navigation_helper.dart';

/// Modern Organization selector widget for web header
///
/// Professional dropdown with animations, proper positioning, and modern interactions.
/// Matches MailContextSwitcher design patterns exactly.
///
/// Features:
/// - CompositedTransform for precise positioning
/// - Overlay system for proper layering
/// - Smooth animations (scale & opacity)
/// - Hover states and visual feedback
/// - Outside tap to close
/// - Material Design elevation and shadows
/// - Organization switching with navigation
class OrganizationSelectorWeb extends ConsumerStatefulWidget {
  const OrganizationSelectorWeb({super.key});

  @override
  ConsumerState<OrganizationSelectorWeb> createState() =>
      _OrganizationSelectorWebState();
}

class _OrganizationSelectorWebState
    extends ConsumerState<OrganizationSelectorWeb>
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
    // Watch organization state
    final organizations = ref.watch(organizationsProvider);
    final selectedOrg = ref.watch(selectedOrganizationProvider);
    final isLoading = ref.watch(isOrganizationLoadingProvider);
    final error = ref.watch(organizationErrorProvider);
    final isInitialized = ref.watch(isOrganizationInitializedProvider);

    // Don't show widget if not initialized or has error
    if (!isInitialized || error != null) {
      return const SizedBox.shrink();
    }

    // Don't show if no organizations
    if (organizations.isEmpty) {
      return const SizedBox.shrink();
    }

    // Don't show dropdown if only one organization
    if (organizations.length == 1) {
      return _buildSingleOrganization(organizations.first);
    }

    return CompositedTransformTarget(
      link: _link,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: _toggleDropdown,
          child: _buildCurrentOrganizationDisplay(selectedOrg, isLoading),
        ),
      ),
    );
  }

  /// Build widget when user has only one organization (no dropdown needed)
  Widget _buildSingleOrganization(Organization organization) {
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
          _buildOrganizationIcon(organization),
          const SizedBox(width: 8),
          _buildOrganizationInfo(organization, isCompact: true),
        ],
      ),
    );
  }

  /// Build current organization display button with modern styling
  Widget _buildCurrentOrganizationDisplay(
    Organization? selectedOrg,
    bool isLoading,
  ) {
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
          if (selectedOrg != null) ...[
            _buildOrganizationIcon(selectedOrg),
            const SizedBox(width: 8),
            _buildOrganizationInfo(selectedOrg, isCompact: true),
          ] else ...[
            Icon(Icons.business, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Text(
              'Organizasyon Seçin',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
          const SizedBox(width: 8),
          if (isLoading) ...[
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[600]!),
              ),
            ),
          ] else ...[
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
    AppLogger.debug('OrganizationSelector: Opening organization dropdown');

    _overlayEntry = OverlayEntry(builder: (context) => _buildDropdownOverlay());

    // Use root overlay for proper z-index layering
    final overlay = Overlay.of(context, rootOverlay: true);
    overlay.insert(_overlayEntry!);
    _animationController.forward();
  }

  void _hideDropdown() {
    if (_overlayEntry == null) return;

    setState(() => _isDropdownOpen = false);
    AppLogger.debug('OrganizationSelector: Closing organization dropdown');

    _animationController.reverse().then((_) {
      _removeDropdown();
    });
  }

  void _removeDropdown() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Widget _buildDropdownOverlay() {
    final organizations = ref.watch(organizationsProvider);
    final selectedOrg = ref.watch(selectedOrganizationProvider);

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
                          organizations,
                          selectedOrg,
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
    List<Organization> organizations,
    Organization? selectedOrg,
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
            _buildOrganizationList(organizations, selectedOrg?.id),
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
            'Organizasyon Seç',
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

  Widget _buildOrganizationList(
    List<Organization> organizations,
    String? selectedId,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: organizations.map((organization) {
          final isSelected = organization.id == selectedId;
          return _buildOrganizationMenuItem(organization, isSelected);
        }).toList(),
      ),
    );
  }

  Widget _buildOrganizationMenuItem(
    Organization organization,
    bool isSelected,
  ) {
    final hoverColor = Colors.blue.withOpacity(0.08);
    final pressColor = Colors.blue.withOpacity(0.15);
    final selectedBackground = Colors.blue.withOpacity(0.12);

    return Material(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _handleOrganizationSwitch(organization),
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

              // Organization icon
              _buildOrganizationIcon(organization),
              const SizedBox(width: 12),

              // Organization info
              Expanded(
                child: Text(
                  organization.shortDisplayName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? Colors.blue[700] : Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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

  /// Build organization icon
  Widget _buildOrganizationIcon(Organization organization) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(Icons.business, size: 14, color: Colors.blue[600]),
    );
  }

  /// Build organization information display
  Widget _buildOrganizationInfo(
    Organization organization, {
    bool isCompact = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          organization.shortDisplayName,
          style: TextStyle(
            fontSize: isCompact ? 13 : 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (organization.role.isNotEmpty && !isCompact) ...[
          const SizedBox(height: 2),
          Text(
            organization.roleDisplayName,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  /// Handle organization switching
  void _handleOrganizationSwitch(Organization organization) {
    _hideDropdown();

    AppLogger.info(
      '🏢 OrganizationSelector: Switching to organization: ${organization.slug}',
    );

    // Use navigation helper for organization switching
    OrganizationNavigationHelper.switchOrganization(context, ref, organization);

    AppLogger.info('✅ Organization switch completed: ${organization.slug}');
  }
}
