// lib/src/features/organization/data/datasources/organization_remote_datasource.dart

import '../../../../core/network/api_client.dart';
import '../../../../utils/app_logger.dart';
import '../models/organization_model.dart';

/// Abstract interface for organization remote data source
abstract class OrganizationRemoteDataSource {
  Future<List<OrganizationModel>> getUserOrganizations();
}

/// Concrete implementation of organization remote data source
class OrganizationRemoteDataSourceImpl implements OrganizationRemoteDataSource {
  final ApiClient _apiClient;

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

        // Server wraps response in {success: true, data: {organizations: [...], count: N}}
        if (responseData['success'] == true && responseData['data'] != null) {
          final dataObject = responseData['data'] as Map<String, dynamic>;

          // ✅ FIX: Extract organizations array from data object
          if (dataObject['organizations'] != null) {
            final organizationsArray =
                dataObject['organizations'] as List<dynamic>;

            // Parse organizations list
            final organizations = OrganizationModel.fromJsonList(
              organizationsArray,
            );

            AppLogger.info(
              '🏢 Organization DataSource: Parsed ${organizations.length} organizations',
            );
            return organizations;
          } else {
            AppLogger.error(
              '❌ Organization DataSource: Missing organizations array in data',
            );
            throw Exception(
              'Invalid response format: missing organizations array',
            );
          }
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
