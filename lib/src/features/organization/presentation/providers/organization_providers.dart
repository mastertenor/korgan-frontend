// lib/src/features/organization/presentation/providers/organization_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../utils/app_logger.dart';
import '../../domain/entities/organization.dart';
import '../../data/datasources/organization_remote_datasource.dart';
import '../../data/repositories/organization_repository_impl.dart';
import '../../data/repositories/organization_repository.dart';
import '../../domain/usecases/get_user_organizations_usecase.dart';
import '../state/organization_state.dart';
import '../notifiers/organization_notifier.dart';

// ========== DEPENDENCY INJECTION PROVIDERS ==========

/// API Client Provider (reusing existing singleton)
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient.instance;
});

/// Organization Remote DataSource Provider
final organizationRemoteDataSourceProvider =
    Provider<OrganizationRemoteDataSource>((ref) {
      final apiClient = ref.read(apiClientProvider);
      return OrganizationRemoteDataSourceImpl(apiClient);
    });

/// Organization Repository Provider
final organizationRepositoryProvider = Provider<OrganizationRepository>((ref) {
  final remoteDataSource = ref.read(organizationRemoteDataSourceProvider);
  return OrganizationRepositoryImpl(remoteDataSource);
});

// ========== USE CASE PROVIDERS ==========

/// Get User Organizations UseCase Provider
final getUserOrganizationsUseCaseProvider =
    Provider<GetUserOrganizationsUseCase>((ref) {
      final repository = ref.read(organizationRepositoryProvider);
      return GetUserOrganizationsUseCase(repository);
    });

// ========== MAIN STATE PROVIDER ==========

/// Main Organization Provider
final organizationNotifierProvider =
    StateNotifierProvider<OrganizationNotifier, OrganizationState>((ref) {
      final notifier = OrganizationNotifier(
        getUserOrganizationsUseCase: ref.read(
          getUserOrganizationsUseCaseProvider,
        ),
      );

      AppLogger.info('🏢 Provider: OrganizationNotifier created');
      return notifier;
    });

// ========== CONVENIENCE PROVIDERS ==========

/// Current Organization State Provider
final organizationStateProvider = Provider<OrganizationState>((ref) {
  return ref.watch(organizationNotifierProvider);
});

/// Organizations List Provider
final organizationsProvider = Provider<List<Organization>>((ref) {
  return ref.watch(organizationNotifierProvider).organizations;
});

/// Selected Organization Provider
final selectedOrganizationProvider = Provider<Organization?>((ref) {
  return ref.watch(organizationNotifierProvider).selectedOrganization;
});

/// Selected Organization ID Provider
final selectedOrganizationIdProvider = Provider<String?>((ref) {
  return ref.watch(organizationNotifierProvider).selectedOrganizationId;
});

/// Organization Loading State Provider
final isOrganizationLoadingProvider = Provider<bool>((ref) {
  return ref.watch(organizationNotifierProvider).isAnyLoading;
});

/// Organization Error Provider
final organizationErrorProvider = Provider<String?>((ref) {
  return ref.watch(organizationNotifierProvider).error;
});

/// Has Organizations Provider
final hasOrganizationsProvider = Provider<bool>((ref) {
  return ref.watch(organizationNotifierProvider).hasOrganizations;
});

/// Is Organization Initialized Provider
final isOrganizationInitializedProvider = Provider<bool>((ref) {
  return ref.watch(organizationNotifierProvider).isInitialized;
});

// ========== SPECIFIC LOADING STATE PROVIDERS ==========

/// Is Loading Organizations Provider
final isLoadingOrganizationsProvider = Provider<bool>((ref) {
  return ref.watch(organizationNotifierProvider).isLoadingOrganizations;
});

/// Is Switching Organization Provider
final isSwitchingOrganizationProvider = Provider<bool>((ref) {
  return ref.watch(organizationNotifierProvider).isSwitchingOrganization;
});

// ========== ORGANIZATION ACTIONS PROVIDER ==========

/// Organization Actions Provider
///
/// Provides access to organization notifier methods for UI interactions
final organizationActionsProvider = Provider<OrganizationNotifier>((ref) {
  return ref.read(organizationNotifierProvider.notifier);
});

// ========== UTILITY PROVIDERS ==========

/// Check if specific organization is selected
final isOrganizationSelectedProvider = Provider.family<bool, String>((
  ref,
  organizationId,
) {
  return ref
      .watch(organizationNotifierProvider)
      .isOrganizationSelected(organizationId);
});

/// Get organization by ID
final organizationByIdProvider = Provider.family<Organization?, String>((
  ref,
  organizationId,
) {
  return ref
      .watch(organizationNotifierProvider)
      .getOrganizationById(organizationId);
});

// ========== INITIALIZATION PROVIDER ==========

/// User Organizations Provider (user is regular user)
final userOrganizationsProvider = Provider<List<Organization>>((ref) {
  final organizations = ref.watch(organizationsProvider);
  return organizations.where((org) => org.isUser).toList();
});
