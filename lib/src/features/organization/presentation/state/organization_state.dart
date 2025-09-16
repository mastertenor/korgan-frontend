// lib/src/features/organization/presentation/state/organization_state.dart

import 'package:equatable/equatable.dart';
import '../../domain/entities/organization.dart';

/// State class for organization management
///
/// Holds the current state of organization data including:
/// - List of user's organizations
/// - Currently selected organization
/// - Loading states for different operations
/// - Error messages
///
/// Used by OrganizationNotifier and consumed by widgets across the app.
class OrganizationState extends Equatable {
  /// List of organizations user belongs to
  final List<Organization> organizations;

  /// Currently selected organization ID
  final String? selectedOrganizationId;

  /// Loading state for fetching organizations
  final bool isLoadingOrganizations;

  /// Loading state for switching organization
  final bool isSwitchingOrganization;

  /// Error message if any operation fails
  final String? error;

  /// Indicates if organizations have been loaded at least once
  final bool isInitialized;

  const OrganizationState({
    this.organizations = const [],
    this.selectedOrganizationId,
    this.isLoadingOrganizations = false,
    this.isSwitchingOrganization = false,
    this.error,
    this.isInitialized = false,
  });

  // ========== FACTORY CONSTRUCTORS ==========

  /// Initial state - nothing loaded yet
  factory OrganizationState.initial() {
    return const OrganizationState();
  }

  /// Loading organizations from API
  factory OrganizationState.loadingOrganizations() {
    return const OrganizationState(isLoadingOrganizations: true);
  }

  /// Organizations loaded successfully
  factory OrganizationState.loaded({
    required List<Organization> organizations,
    String? selectedOrganizationId,
  }) {
    return OrganizationState(
      organizations: organizations,
      selectedOrganizationId: selectedOrganizationId,
      isInitialized: true,
    );
  }

  /// Error state
  factory OrganizationState.error(String error) {
    return OrganizationState(error: error, isInitialized: true);
  }

  // ========== GETTERS ==========

  /// Get currently selected organization
  Organization? get selectedOrganization {
    if (selectedOrganizationId == null) return null;

    try {
      return organizations.firstWhere(
        (org) => org.id == selectedOrganizationId,
      );
    } catch (e) {
      return null;
    }
  }

  /// Check if any loading operation is in progress
  bool get isAnyLoading {
    return isLoadingOrganizations || isSwitchingOrganization;
  }

  /// Check if user has organizations
  bool get hasOrganizations {
    return organizations.isNotEmpty;
  }

  /// Check if a specific organization is selected
  bool isOrganizationSelected(String organizationId) {
    return selectedOrganizationId == organizationId;
  }

  /// Get organization by ID
  Organization? getOrganizationById(String id) {
    try {
      return organizations.firstWhere((org) => org.id == id);
    } catch (e) {
      return null;
    }
  }

  // ========== COPY WITH ==========

  OrganizationState copyWith({
    List<Organization>? organizations,
    String? selectedOrganizationId,
    bool? isLoadingOrganizations,
    bool? isSwitchingOrganization,
    String? error,
    bool? isInitialized,
    bool clearError = false,
    bool clearSelectedOrganization = false,
  }) {
    return OrganizationState(
      organizations: organizations ?? this.organizations,
      selectedOrganizationId: clearSelectedOrganization
          ? null
          : (selectedOrganizationId ?? this.selectedOrganizationId),
      isLoadingOrganizations:
          isLoadingOrganizations ?? this.isLoadingOrganizations,
      isSwitchingOrganization:
          isSwitchingOrganization ?? this.isSwitchingOrganization,
      error: clearError ? null : (error ?? this.error),
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }

  // ========== EQUATABLE ==========

  @override
  List<Object?> get props => [
    organizations,
    selectedOrganizationId,
    isLoadingOrganizations,
    isSwitchingOrganization,
    error,
    isInitialized,
  ];

  @override
  String toString() {
    return 'OrganizationState('
        'organizations: ${organizations.length}, '
        'selectedId: $selectedOrganizationId, '
        'isLoadingOrgs: $isLoadingOrganizations, '
        'isSwitching: $isSwitchingOrganization, '
        'error: $error, '
        'isInitialized: $isInitialized'
        ')';
  }
}
