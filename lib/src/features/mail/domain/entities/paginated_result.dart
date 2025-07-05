// lib/src/features/mail/domain/entities/paginated_result.dart

/// Generic paginated result wrapper for domain entities
///
/// This class wraps any list of entities with pagination metadata,
/// keeping the domain layer clean while supporting pagination.
class PaginatedResult<T> {
  final List<T> items;
  final String? nextPageToken;
  final int totalEstimate;
  final bool hasMore;

  const PaginatedResult({
    required this.items,
    this.nextPageToken,
    required this.totalEstimate,
    required this.hasMore,
  });

  /// Create empty paginated result
  factory PaginatedResult.empty() {
    return const PaginatedResult(items: [], totalEstimate: 0, hasMore: false);
  }

  /// Create first page result
  factory PaginatedResult.firstPage({
    required List<T> items,
    String? nextPageToken,
    required int totalEstimate,
  }) {
    return PaginatedResult(
      items: items,
      nextPageToken: nextPageToken,
      totalEstimate: totalEstimate,
      hasMore: nextPageToken != null && nextPageToken.isNotEmpty,
    );
  }

  /// Check if result is empty
  bool get isEmpty => items.isEmpty;

  /// Get item count
  int get count => items.length;

  /// Append more items (for load more functionality)
  PaginatedResult<T> appendItems({
    required List<T> newItems,
    String? newNextPageToken,
    required int newTotalEstimate,
  }) {
    return PaginatedResult(
      items: [...items, ...newItems],
      nextPageToken: newNextPageToken,
      totalEstimate: newTotalEstimate,
      hasMore: newNextPageToken != null && newNextPageToken.isNotEmpty,
    );
  }

  /// Replace items (for refresh functionality)
  PaginatedResult<T> replaceItems({
    required List<T> newItems,
    String? newNextPageToken,
    required int newTotalEstimate,
  }) {
    return PaginatedResult(
      items: newItems,
      nextPageToken: newNextPageToken,
      totalEstimate: newTotalEstimate,
      hasMore: newNextPageToken != null && newNextPageToken.isNotEmpty,
    );
  }

  @override
  String toString() {
    return 'PaginatedResult<$T>(items: ${items.length}, hasMore: $hasMore, nextToken: $nextPageToken)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PaginatedResult<T> &&
        other.nextPageToken == nextPageToken &&
        other.totalEstimate == totalEstimate &&
        other.items.length == items.length;
  }

  @override
  int get hashCode =>
      Object.hash(nextPageToken, totalEstimate, items.length, T);
}
