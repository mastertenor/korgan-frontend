// lib/src/features/organization/domain/usecases/get_user_organizations_usecase.dart

import '../../../../core/utils/result.dart';
import '../../../../core/error/failures.dart' as failures;
import '../entities/organization.dart';
import '../../data/repositories/organization_repository.dart';

/// Use case for fetching user's organizations
///
/// This use case encapsulates the business logic for retrieving organizations
/// that the current user belongs to. Used across all application modules for
/// organization switching functionality.
///
/// Business rules:
/// - User must be authenticated (handled by API interceptor)
/// - Returns organizations sorted alphabetically
/// - Filters out invalid/incomplete organization data
/// - Caches results if needed in the future
class GetUserOrganizationsUseCase {
  final OrganizationRepository _repository;

  GetUserOrganizationsUseCase(this._repository);

  /// Execute organization fetch operation
  ///
  /// Returns Result with List<Organization> on success
  /// Business validation is applied at repository level
  Future<Result<List<Organization>>> execute() async {
    // Delegate to repository - no additional validation needed at use case level
    // Repository handles:
    // - API communication
    // - Data validation
    // - Sorting by name
    // - Error handling and mapping
    return await _repository.getUserOrganizations();
  }

  /// Execute with validation for minimum organization count
  ///
  /// Some business scenarios might require user to belong to at least one organization
  /// [requireMinimumOne] If true, returns failure when user has no organizations
  Future<Result<List<Organization>>> executeWithValidation({
    bool requireMinimumOne = false,
  }) async {
    final result = await _repository.getUserOrganizations();

    return result.when(
      success: (organizations) {
        // Business rule: Check minimum organization requirement
        if (requireMinimumOne && organizations.isEmpty) {
          return Failure<List<Organization>>(
            failures.ValidationFailure(
              message: 'Hesabınız hiçbir organizasyona bağlı değil',
              code: 'NO_ORGANIZATIONS',
            ),
          );
        }

        return Success(organizations);
      },
      failure: (failure) => Failure<List<Organization>>(failure),
    );
  }
}
