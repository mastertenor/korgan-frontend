// lib/src/features/user/presentation/widgets/web/profile_dropdown_web.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_providers.dart';
import '../../../../../utils/app_logger.dart';

/// Profile dropdown widget for web header
///
/// Google-style profile dropdown with proper layering and positioning
/// Uses CompositedTransformTarget/Follower for accurate positioning
/// and root overlay for proper z-index layering
class ProfileDropdownWeb extends ConsumerStatefulWidget {
  const ProfileDropdownWeb({super.key});

  @override
  ConsumerState<ProfileDropdownWeb> createState() => _ProfileDropdownWebState();
}

class _ProfileDropdownWebState extends ConsumerState<ProfileDropdownWeb>
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
    final user = ref.watch(currentUserProvider);
    //final isLoading = ref.watch(isAuthLoadingProvider);

    return CompositedTransformTarget(
      link: _link,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: _toggleDropdown,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _isHovered || _isDropdownOpen
                  ? Colors.grey[200]
                  : Colors.grey[100],
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: _isDropdownOpen ? Colors.blue[300]! : Colors.grey[200]!,
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
                _buildUserAvatar(user),
                const SizedBox(width: 8),
                AnimatedRotation(
                  turns: _isDropdownOpen ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Colors.grey[600],
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserAvatar(dynamic user) {

    final initials = user?.initials ?? 'U';

    return CircleAvatar(
      radius: 16,
      backgroundColor: Colors.blue[600],
      child: Text(
        initials,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
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
    AppLogger.debug('ProfileDropdown: Opening dropdown menu');

    _overlayEntry = OverlayEntry(builder: (context) => _buildDropdownOverlay());

    // Use root overlay for proper z-index layering
    final overlay = Overlay.of(context, rootOverlay: true);
    overlay.insert(_overlayEntry!);
    _animationController.forward();
  }

  void _hideDropdown() {
    if (_overlayEntry == null) return;

    setState(() => _isDropdownOpen = false);
    AppLogger.debug('ProfileDropdown: Closing dropdown menu');

    _animationController.reverse().then((_) {
      _removeDropdown();
    });
  }

  void _removeDropdown() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Widget _buildDropdownOverlay() {
    return GestureDetector(
      onTap: _hideDropdown,
      behavior:
          HitTestBehavior.opaque, // Ensure the entire overlay captures taps
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
              targetAnchor: Alignment.bottomRight,
              followerAnchor: Alignment.topRight,
              offset: const Offset(0, 6),
              child: GestureDetector(
                onTap: () {}, // Prevent dropdown content taps from bubbling up
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnimation.value,
                      alignment: Alignment.topRight,
                      child: Opacity(
                        opacity: _opacityAnimation.value,
                        child: _buildDropdownContent(),
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

  Widget _buildDropdownContent() {
    final user = ref.watch(currentUserProvider);
    final userDisplayName = ref.watch(userDisplayNameProvider);
    final userEmail = ref.watch(userEmailProvider);

    return Material(
      color: Colors.white,
      elevation: 20, // Higher elevation for prominent shadow
      shadowColor: Colors.black.withOpacity(0.25),
      surfaceTintColor: Colors.transparent, // Prevent Material 3 tinting
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0x1F000000)), // Subtle border
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 280, maxWidth: 320),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileSection(user, userDisplayName, userEmail),
            const Divider(height: 1),
            _buildMenuSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection(
    dynamic user,
    String userDisplayName,
    String userEmail,
  ) {
    final initials = user?.initials ?? 'U';

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.blue[600],
            child: Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userDisplayName.isNotEmpty ? userDisplayName : 'Kullanıcı',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  userEmail.isNotEmpty ? userEmail : 'user@example.com',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          _buildMenuItem(
            icon: Icons.person_outline,
            title: 'Profili Görüntüle',
            onTap: () {
              _hideDropdown();
              _handleViewProfile();
            },
          ),
          _buildMenuItem(
            icon: Icons.settings_outlined,
            title: 'Hesap Ayarları',
            onTap: () {
              _hideDropdown();
              _handleAccountSettings();
            },
          ),
          _buildMenuItem(
            icon: Icons.privacy_tip_outlined,
            title: 'Gizlilik',
            onTap: () {
              _hideDropdown();
              _handlePrivacySettings();
            },
          ),
          const Divider(height: 1),
          _buildMenuItem(
            icon: Icons.logout_rounded,
            title: 'Çıkış Yap',
            onTap: () {
              _hideDropdown();
              _handleSignOut();
            },
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final hoverColor = (isDestructive ? Colors.red : Colors.grey).withOpacity(
      0.10,
    );
    final pressColor = (isDestructive ? Colors.red : Colors.grey).withOpacity(
      0.20,
    );
    final textColor = isDestructive ? Colors.red[600] : Colors.grey[800];
    final iconColor = isDestructive ? Colors.red[600] : Colors.grey[600];

    return Material(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        overlayColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.hovered)) return hoverColor;
          if (states.contains(MaterialState.pressed)) return pressColor;
          return null;
        }),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(icon, size: 20, color: iconColor),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: textColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Action handlers (to be implemented)
  void _handleViewProfile() {
    AppLogger.info('ProfileDropdown: View profile clicked');
    // TODO: Navigate to profile page
  }

  void _handleAccountSettings() {
    AppLogger.info('ProfileDropdown: Account settings clicked');
    // TODO: Navigate to account settings
  }

  void _handlePrivacySettings() {
    AppLogger.info('ProfileDropdown: Privacy settings clicked');
    // TODO: Navigate to privacy settings
  }

  void _handleSignOut() {
    AppLogger.info('ProfileDropdown: Sign out clicked');
    // TODO: Implement logout
    // final authNotifier = ref.read(authNotifierProvider.notifier);
    // await authNotifier.logout();
    // if (mounted) {
    //   context.go('/login');
    // }
  }
}
