// lib/src/features/mail/data/datasources/organization_remote_datasource.dart

import '../../../../core/network/api_client.dart';
import '../../../../utils/app_logger.dart';
import '../models/organization_model.dart';

/// Abstract interface for organization remote data source
///
/// Defines the contract for fetching organization data from the backend API.
/// Endpoint: GET /api/auth/user/organizations/
abstract class OrganizationRemoteDataSource {
  /// Get user's organizations from backend
  ///
  /// Returns: List of OrganizationModel
  /// Throws: Exception on network or parsing errors
  Future<List<OrganizationModel>> getUserOrganizations();
}

/// Concrete implementation of organization remote data source
///
/// Handles API communication for organization data using the existing ApiClient.
/// Follows the same pattern as AuthRemoteDataSourceImpl in your project.
class OrganizationRemoteDataSourceImpl implements OrganizationRemoteDataSource {
  final ApiClient _apiClient;

  /// Constructor - ApiClient dependency injection
  OrganizationRemoteDataSourceImpl(this._apiClient);

  @override
  Future<List<OrganizationModel>> getUserOrganizations() async {
    try {
      AppLogger.info('🏢 Organization DataSource: Fetching user organizations');

      final response = await _apiClient.get('/api/auth/user/organizations');

      if (response.statusCode == 200 && response.data != null) {
        AppLogger.info(
          '✅ Organization DataSource: Organizations fetched successfully',
        );

        // Extract data from server response format
        final responseData = response.data as Map<String, dynamic>;

        // Server wraps response in {success: true, data: [...]}
        if (responseData['success'] == true && responseData['data'] != null) {
          final data = responseData['data'] as List<dynamic>;

          // Parse organizations list
          final organizations = OrganizationModel.fromJsonList(data);

          AppLogger.info(
            '🏢 Organization DataSource: Parsed ${organizations.length} organizations',
          );

          return organizations;
        } else {
          AppLogger.error(
            '❌ Organization DataSource: Invalid response format - missing success or data',
          );
          throw Exception('Invalid response format: missing success or data');
        }
      } else {
        AppLogger.error(
          '❌ Organization DataSource: Invalid response - Status: ${response.statusCode}',
        );
        throw Exception('Invalid response from organizations API');
      }
    } catch (e) {
      AppLogger.error(
        '❌ Organization DataSource: Failed to fetch organizations - $e',
      );
      rethrow;
    }
  }
}
