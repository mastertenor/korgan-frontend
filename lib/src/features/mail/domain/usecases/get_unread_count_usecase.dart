// lib/src/features/mail/domain/usecases/get_unread_count_usecase.dart

import '../../../../core/utils/result.dart';
import '../../../../core/error/failures.dart' as failures;
import '../repositories/mail_repository.dart';

/// UseCase for getting unread mail count for specific folder/labels
///
/// This use case handles:
/// - Folder-specific unread count
/// - Label-based filtering
/// - Error handling and validation
/// - Business logic for count formatting
class GetUnreadCountUseCase {
  final MailRepository _repository;

  GetUnreadCountUseCase(this._repository);

  /// Execute unread count request
  ///
  /// [userEmail] - User's email address (required)
  /// [labels] - Labels to filter by (e.g., ['INBOX'] for inbox count)
  ///
  /// Returns Result with unread count data:
  /// - success: true/false
  /// - unread: number of unread mails
  /// - query: Gmail query used for count
  /// - processingTimeMs: API processing time
  Future<Result<UnreadCountResult>> execute({
    required String userEmail,
    List<String>? labels,
  }) async {
    // Validate email format
    if (!_isValidEmail(userEmail)) {
      return Failure(failures.ValidationFailure.invalidEmail(email: userEmail));
    }

    // Call repository
    final result = await _repository.getUnreadCount(
      userEmail: userEmail,
      labels: labels,
    );

    return result.when(
      success: (data) {
        try {
          // Parse API response into domain object
          final unreadResult = UnreadCountResult.fromApiResponse(data);
          return Success(unreadResult);
        } catch (e) {
          return Failure(
            failures.AppFailure.unknown(
              message: 'API yanıtı parse edilemedi: ${e.toString()}',
            ),
          );
        }
      },
      failure: (failure) => Failure(failure),
    );
  }

  /// Validate email format
  bool _isValidEmail(String email) {
    return RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    ).hasMatch(email);
  }
}

/// Domain entity for unread count result
class UnreadCountResult {
  final bool success;
  final int unreadCount;
  final String query;
  final int processingTimeMs;

  const UnreadCountResult({
    required this.success,
    required this.unreadCount,
    required this.query,
    required this.processingTimeMs,
  });

  /// Create from API response
  factory UnreadCountResult.fromApiResponse(Map<String, dynamic> data) {
    return UnreadCountResult(
      success: data['success'] as bool? ?? false,
      unreadCount: data['unread'] as int? ?? 0,
      query: data['query'] as String? ?? '',
      processingTimeMs: data['processingTimeMs'] as int? ?? 0,
    );
  }

  /// Format count for UI display
  ///
  /// Returns:
  /// - Empty string if count is 0
  /// - Count as string if <= 99
  /// - ">99" if count > 99
  String get displayText {
    if (unreadCount == 0) {
      return '';
    } else if (unreadCount <= 99) {
      return unreadCount.toString();
    } else {
      return '>99';
    }
  }

  /// Whether to show badge (has unread mails)
  bool get shouldShowBadge => unreadCount > 0;

  @override
  String toString() {
    return 'UnreadCountResult(success: $success, unreadCount: $unreadCount, query: $query)';
  }
}
