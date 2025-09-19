// lib/src/features/organization/presentation/notifiers/organization_notifier.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../utils/app_logger.dart';
import '../../domain/usecases/get_user_organizations_usecase.dart';
import '../state/organization_state.dart';

/// Organization state notifier for managing organization switching functionality
///
/// This notifier handles:
/// - Fetching user's organizations from API
/// - Organization selection/switching
/// - State management for UI components
/// - Persistent storage of selected organization
/// - Error handling and recovery
///
/// Used across all application modules for organization switching.
class OrganizationNotifier extends StateNotifier<OrganizationState> {
  final GetUserOrganizationsUseCase _getUserOrganizationsUseCase;

  OrganizationNotifier({
    required GetUserOrganizationsUseCase getUserOrganizationsUseCase,
  }) : _getUserOrganizationsUseCase = getUserOrganizationsUseCase,
       super(OrganizationState.initial()) {
    AppLogger.info('🏢 OrganizationNotifier: Initialized');
  }

  // ========== PUBLIC METHODS ==========

  /// Initialize organization data - fetch from API and restore selected org
  ///
  /// This should be called during app startup to load user's organizations
  /// and restore the previously selected organization from storage
  Future<void> initialize() async {
    AppLogger.info('🏢 OrganizationNotifier: Initializing...');

    // Set loading state
    state = OrganizationState.loadingOrganizations();

    try {
      // Fetch organizations from API
      final result = await _getUserOrganizationsUseCase.execute();

      await result.when(
        success: (organizations) async {
          AppLogger.info(
            '✅ OrganizationNotifier: Fetched ${organizations.length} organizations',
          );

          // Determine default selected organization
          String? selectedOrgId;

          if (organizations.isNotEmpty) {
            // Try to restore from persistent storage first
            selectedOrgId = await _getStoredOrganizationId();

            // If stored org doesn't exist in current list, select first one
            if (selectedOrgId == null ||
                !organizations.any((org) => org.id == selectedOrgId)) {
              selectedOrgId = organizations.first.id;
              AppLogger.info(
                '🎯 OrganizationNotifier: Using first org as default: $selectedOrgId',
              );
            } else {
              AppLogger.info(
                '🔄 OrganizationNotifier: Restored org from storage: $selectedOrgId',
              );
            }
            // ✅ CRITICAL FIX: Bu satırları ekle
            await _saveOrganizationId(selectedOrgId);
            AppLogger.info(
              '💾 OrganizationNotifier: Saved organization ID for API client: $selectedOrgId',
            );

          }

          // Update state with loaded organizations
          state = OrganizationState.loaded(
            organizations: organizations,
            selectedOrganizationId: selectedOrgId,
          );

          AppLogger.info('🏢 OrganizationNotifier: Initialization completed');
        },
        failure: (failure) async {
          AppLogger.error(
            '❌ OrganizationNotifier: Failed to fetch organizations - ${failure.message}',
          );

          state = OrganizationState.error(failure.message);
        },
      );
    } catch (e) {
      AppLogger.error(
        '❌ OrganizationNotifier: Unexpected error during initialization - $e',
      );

      state = OrganizationState.error(
        'Organizasyonlar yüklenirken beklenmeyen hata: $e',
      );
    }
  }

  /// Switch to a different organization
  ///
  /// [organizationId] ID of the organization to switch to
  /// Updates the selected organization and persists the choice
  Future<void> switchOrganization(String organizationId) async {
    final organization = state.getOrganizationById(organizationId);

    if (organization == null) {
      AppLogger.warning(
        '⚠️ OrganizationNotifier: Organization not found: $organizationId',
      );
      _setError('Organizasyon bulunamadı');
      return;
    }

    // Don't switch if already selected
    if (state.selectedOrganizationId == organizationId) {
      AppLogger.info(
        '🔄 OrganizationNotifier: Already selected org: $organizationId',
      );
      return;
    }

    AppLogger.info(
      '🔄 OrganizationNotifier: Switching to organization: ${organization.name} ($organizationId)',
    );

    // Set switching state
    state = state.copyWith(isSwitchingOrganization: true, clearError: true);

    try {
      // Save organization to persistent storage
      await _saveOrganizationId(organizationId);

      // Update selected organization
      state = state.copyWith(
        selectedOrganizationId: organizationId,
        isSwitchingOrganization: false,
      );

      AppLogger.info(
        '✅ OrganizationNotifier: Successfully switched to: ${organization.name}',
      );
    } catch (e) {
      AppLogger.error(
        '❌ OrganizationNotifier: Failed to switch organization - $e',
      );

      state = state.copyWith(
        isSwitchingOrganization: false,
        error: 'Organizasyon değiştirilemedi: $e',
      );
    }
  }

  /// Refresh organizations from API
  ///
  /// Useful when user wants to manually refresh the organization list
  /// or when organization data might have changed
  Future<void> refresh() async {
    AppLogger.info('🔄 OrganizationNotifier: Refreshing organizations...');

    if (state.isAnyLoading) {
      AppLogger.info(
        '⏳ OrganizationNotifier: Already loading, skipping refresh',
      );
      return;
    }
   

    // Set loading state
    state = state.copyWith(isLoadingOrganizations: true, clearError: true);

    try {
      final result = await _getUserOrganizationsUseCase.execute();

      await result.when(
        success: (organizations) async {
          AppLogger.info(
            '✅ OrganizationNotifier: Fetched ${organizations.length} organizations',
          );

          // Determine default selected organization
          String? selectedOrgId;

          if (organizations.isNotEmpty) {
            // Try to restore from persistent storage first
            selectedOrgId = await _getStoredOrganizationId();

            // If stored org doesn't exist in current list, select first one
            if (selectedOrgId == null ||
                !organizations.any((org) => org.id == selectedOrgId)) {
              selectedOrgId = organizations.first.id;
              AppLogger.info(
                '🎯 OrganizationNotifier: Using first org as default: $selectedOrgId',
              );
            } else {
              AppLogger.info(
                '🔄 OrganizationNotifier: Restored org from storage: $selectedOrgId',
              );
            }
            // Bu satırları ekle - initialize sırasında seçilen organization'ı kaydet
            await _saveOrganizationId(selectedOrgId);
            AppLogger.info(
              '💾 OrganizationNotifier: Saved organization ID for API client: $selectedOrgId',
            );

          }

          // Update state with loaded organizations
          state = OrganizationState.loaded(
            organizations: organizations,
            selectedOrganizationId: selectedOrgId,
          );

          AppLogger.info('🏢 OrganizationNotifier: Initialization completed');
        },
        failure: (failure) async {
          AppLogger.error(
            '❌ OrganizationNotifier: Failed to refresh organizations - ${failure.message}',
          );

          state = state.copyWith(
            isLoadingOrganizations: false,
            error: failure.message,
          );
        },
      );
    } catch (e) {
      AppLogger.error(
        '❌ OrganizationNotifier: Unexpected error during refresh - $e',
      );

      state = state.copyWith(
        isLoadingOrganizations: false,
        error: 'Organizasyonlar yenilenirken beklenmeyen hata: $e',
      );
    }
  }

  /// Clear any error state
  void clearError() {
    if (state.error != null) {
      AppLogger.info('🧹 OrganizationNotifier: Clearing error');
      state = state.copyWith(clearError: true);
    }
  }

  // ========== PRIVATE METHODS ==========

  /// Get stored organization ID from persistent storage
  Future<String?> _getStoredOrganizationId() async {
    try {
      // Use ApiClient global function directly
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('selected_organization_id');
    } catch (e) {
      AppLogger.error(
        '❌ OrganizationNotifier: Error getting stored org ID - $e',
      );
      return null;
    }
  }

  /// Save organization ID to persistent storage
  Future<void> _saveOrganizationId(String organizationId) async {
    try {
      // Use ApiClient global function directly
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selected_organization_id', organizationId);
      AppLogger.info(
        '💾 OrganizationNotifier: Saved organization ID: $organizationId',
      );
    } catch (e) {
      AppLogger.error('❌ OrganizationNotifier: Error saving org ID - $e');
      rethrow;
    }
  }

  /// Set error state
  void _setError(String error) {
    state = state.copyWith(error: error);
  }

  // ========== DISPOSE ==========

  @override
  void dispose() {
    AppLogger.info('🏢 OrganizationNotifier: Disposing...');
    super.dispose();
  }
}
