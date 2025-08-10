// lib/src/features/mail/domain/entities/bulk_delete_result.dart

/// Bulk delete operation result
/// 
/// Contains summary information about a bulk delete operation including
/// success/failure counts and detailed information for error handling.
class BulkDeleteResult {
  final int totalCount;
  final int successCount;
  final int failedCount;
  final List<String> failedMailIds;

  const BulkDeleteResult({
    required this.totalCount,
    required this.successCount,
    required this.failedCount,
    required this.failedMailIds,
  });

  /// Check if all mails were successfully deleted
  bool get isCompletelySuccessful => failedCount == 0;

  /// Check if there were any failures
  bool get hasFailures => failedCount > 0;

  /// Check if all mails failed to delete
  bool get isCompletelyFailed => successCount == 0;

  /// Check if some succeeded and some failed
  bool get isPartiallySuccessful => successCount > 0 && failedCount > 0;

  @override
  String toString() {
    return 'BulkDeleteResult(total: $totalCount, success: $successCount, failed: $failedCount)';
  }
}