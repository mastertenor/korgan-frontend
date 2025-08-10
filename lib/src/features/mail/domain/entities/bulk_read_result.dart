// lib/src/features/mail/domain/entities/bulk_read_result.dart

/// Bulk read/unread operation result
/// 
/// Contains summary information about a bulk read/unread operation including
/// success/failure counts and detailed information for error handling.
class BulkReadResult {
  final int totalCount;
  final int successCount;
  final int failedCount;
  final List<String> failedMailIds;

  const BulkReadResult({
    required this.totalCount,
    required this.successCount,
    required this.failedCount,
    required this.failedMailIds,
  });

  /// Check if all mails were successfully processed
  bool get isCompletelySuccessful => failedCount == 0;

  /// Check if there were any failures
  bool get hasFailures => failedCount > 0;

  /// Check if all mails failed to process
  bool get isCompletelyFailed => successCount == 0;

  /// Check if some succeeded and some failed
  bool get isPartiallySuccessful => successCount > 0 && failedCount > 0;

  @override
  String toString() {
    return 'BulkReadResult(total: $totalCount, success: $successCount, failed: $failedCount)';
  }
}