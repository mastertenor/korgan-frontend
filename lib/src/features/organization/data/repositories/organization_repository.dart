// lib/src/features/organization/domain/repositories/organization_repository.dart

import '../../../../core/utils/result.dart';
import '../../domain/entities/organization.dart';

/// Abstract repository interface for organization operations
///
/// This interface defines the contract for organization-related business operations
/// across the entire application. Used by all modules (mail, CRM, tasks, accounting, etc.)
/// for organization switching functionality.
///
/// Business rules handled by this repository:
/// - Organization data validation
/// - Error handling and transformation
/// - Caching if needed in the future
abstract class OrganizationRepository {
  /// Get user's organizations from backend
  ///
  /// Returns a list of organizations that the current user belongs to.
  /// This is used for organization switching functionality across all modules.
  ///
  /// Business rules:
  /// - User must be authenticated (handled by interceptor)
  /// - Returns only organizations where user has valid membership
  /// - Organizations are returned sorted by name
  ///
  /// Returns:
  /// - Success: List<Organization> with user's organizations
  /// - Failure: NetworkFailure, ServerFailure, or ValidationFailure
  Future<Result<List<Organization>>> getUserOrganizations();
}
