// lib/src/features/organization/data/repositories/organization_repository_impl.dart

import '../../../../core/utils/result.dart';
import '../../../../core/error/failures.dart' as failures;
import '../../../../core/error/exceptions.dart';
import '../../../../utils/app_logger.dart';
import '../../domain/entities/organization.dart';
import 'organization_repository.dart';
import '../datasources/organization_remote_datasource.dart';

class OrganizationRepositoryImpl implements OrganizationRepository {
  final OrganizationRemoteDataSource _remoteDataSource;

  /// Constructor with dependency injection
  OrganizationRepositoryImpl(this._remoteDataSource);

  @override
  Future<Result<List<Organization>>> getUserOrganizations() async {
    try {
      AppLogger.info('🏢 Organization Repository: Fetching user organizations');

      // Call data source to get organization models
      final organizationModels = await _remoteDataSource.getUserOrganizations();

      // Convert models to domain entities (UPDATED: toEntity → toDomain)
      final organizations = organizationModels
          .map((model) => model.toDomain())
          .where((org) => org.isValid) // Apply business validation
          .toList();

      // Sort organizations by name (business rule)
      organizations.sort((a, b) => a.name.compareTo(b.name));

      AppLogger.info(
        '✅ Organization Repository: Successfully fetched ${organizations.length} organizations',
      );

      // Log context summary for debugging
      final totalContexts = organizations
          .expand((org) => org.contexts)
          .length;
      AppLogger.debug(
        '📧 Organization Repository: Total mail contexts across all orgs: $totalContexts',
      );

      return Success(organizations);
    } on ServerException catch (e) {
      return Failure(_mapServerExceptionToFailure(e));
    } on NetworkException catch (e) {
      return Failure(_mapNetworkExceptionToFailure(e));
    } catch (e) {
      return Failure(
        failures.AppFailure.unknown(
          message:
              'Organizasyonlar alınırken beklenmeyen hata: ${e.toString()}',
        ),
      );
    }
  }

  /// Map ServerException to appropriate Failure
  failures.Failure _mapServerExceptionToFailure(ServerException exception) {
    switch (exception.statusCode) {
      case 400:
        return failures.ValidationFailure(
          message: exception.message,
          code: 'INVALID_REQUEST',
        );
      case 401:
        return failures.AuthFailure.tokenExpired();
      case 403:
        return failures.AuthFailure.permissionDenied();
      case 404:
        return failures.ServerFailure.notFound(
          message: 'Organizasyon listesi bulunamadı',
        );
      case 422:
        return failures.ValidationFailure(
          message: exception.message,
          code: 'VALIDATION_ERROR',
        );
      case 429:
        return failures.ServerFailure.rateLimited(message: exception.message);
      case 500:
      case 502:
      case 503:
      case 504:
        return failures.ServerFailure.internalError(message: exception.message);
      default:
        return failures.ServerFailure(
          message: exception.message,
          statusCode: exception.statusCode,
        );
    }
  }

  /// Map NetworkException to appropriate Failure
  failures.Failure _mapNetworkExceptionToFailure(NetworkException exception) {
    if (exception.message.toLowerCase().contains('timeout')) {
      return failures.NetworkFailure.connectionTimeout();
    }

    if (exception.message.toLowerCase().contains('connection')) {
      return failures.NetworkFailure.noConnection();
    }

    if (exception.message.toLowerCase().contains('ssl')) {
      return failures.NetworkFailure.sslError();
    }

    return failures.NetworkFailure(message: exception.message);
  }
}