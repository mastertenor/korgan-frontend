// lib/src/features/organization/presentation/widgets/organization_selector_web.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../utils/app_logger.dart';
import '../../domain/entities/organization.dart';
import '../providers/organization_providers.dart';
import '../utils/organization_navigation_helper.dart';

/// Web implementation of organization selector for header
///
/// This widget provides organization switching functionality in the web header.
/// Features:
/// - Dropdown-style organization selector
/// - Current organization display with role badge
/// - Loading and error states
/// - Hover effects and modern design
/// - Responsive to different screen sizes
///
/// Layout: [Current Org Name + Role] [Dropdown Arrow]
class OrganizationSelectorWeb extends ConsumerWidget {
  const OrganizationSelectorWeb({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

    // Don't show if no organizations or only one organization
    if (organizations.isEmpty || organizations.length == 1) {
      return _buildSingleOrganization(selectedOrg);
    }

    return _buildDropdownSelector(
      context,
      ref,
      organizations,
      selectedOrg,
      isLoading,
    );
  }

/// Build widget when user has only one organization (no dropdown needed)
  Widget _buildSingleOrganization(Organization? organization) {
    if (organization == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.blue[200]!, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.business, size: 16, color: Colors.blue[600]),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                organization
                    .shortDisplayName, // ✅ YENİ: Use shortDisplayName helper
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[700],
                ),
              ),
              if (organization.role.isNotEmpty)
                Text(
                  organization.roleDisplayName,
                  style: TextStyle(fontSize: 11, color: Colors.blue[600]),
                ),
            ],
          ),
        ],
      ),
    );
  }

/// Build dropdown selector for multiple organizations
  Widget _buildDropdownSelector(
    BuildContext context,
    WidgetRef ref,
    List<Organization> organizations,
    Organization? selectedOrg,
    bool isLoading,
  ) {
    return PopupMenuButton<String>(
      onSelected: (organizationId) => _handleOrganizationSelect(
        context,
        ref,
        organizationId,
      ), // ✅ context parametresi eklendi
      itemBuilder: (context) =>
          _buildDropdownItems(organizations, selectedOrg?.id),
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 8,
      child: _buildDropdownTrigger(selectedOrg, isLoading),
    );
  }

/// Build dropdown trigger (current organization display + arrow)
  Widget _buildDropdownTrigger(Organization? selectedOrg, bool isLoading) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey[300]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.business, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),

          if (selectedOrg != null) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  selectedOrg.shortDisplayName, // ✅ YENİ: Use shortDisplayName
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                if (selectedOrg.role.isNotEmpty)
                  Text(
                    selectedOrg.roleDisplayName,
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
              ],
            ),
          ] else ...[
            Text(
              'Organizasyon Seçin',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
          ],

          const SizedBox(width: 8),

          if (isLoading) ...[
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[600]!),
              ),
            ),
          ] else ...[
            Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.grey[600]),
          ],
        ],
      ),
    );
  }

/// Build dropdown menu items
  List<PopupMenuEntry<String>> _buildDropdownItems(
    List<Organization> organizations,
    String? selectedId,
  ) {
    return organizations.map((org) {
      final isSelected = org.id == selectedId;

      return PopupMenuItem<String>(
        value: org.id,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blue[600] : Colors.transparent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      org.shortDisplayName, // ✅ YENİ: Use shortDisplayName
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: isSelected ? Colors.blue[700] : Colors.black87,
                      ),
                    ),
                    if (org.role.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        org.roleDisplayName,
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected
                              ? Colors.blue[600]
                              : Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              if (isSelected) ...[
                Icon(Icons.check, size: 16, color: Colors.blue[600]),
              ],
            ],
          ),
        ),
      );
    }).toList();
  }
  
/// Handle organization selection - ✅ UPDATED with navigation
  void _handleOrganizationSelect(
    BuildContext context,
    WidgetRef ref,
    String organizationId,
  ) {
    AppLogger.info(
      '🏢 OrganizationSelector: User selected organization: $organizationId',
    );

    // Get the selected organization entity
    final organizations = ref.read(organizationsProvider);
    final selectedOrganization = organizations.firstWhere(
      (org) => org.id == organizationId,
      orElse: () => organizations.first, // Fallback to first organization
    );

    // ✅ YENİ: Use navigation helper for organization switching
    OrganizationNavigationHelper.switchOrganization(
      context,
      ref,
      selectedOrganization,
    );

    AppLogger.info('🔄 Organization switched to: ${selectedOrganization.slug}');
  }
}
