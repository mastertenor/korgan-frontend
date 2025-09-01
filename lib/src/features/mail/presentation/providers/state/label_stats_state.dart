// lib/src/features/mail/presentation/providers/state/label_stats_state.dart

import '../../../domain/entities/label_stats.dart';

/// State class for Gmail label statistics
///
/// Manages the state of label statistics including loading states,
/// cached data, and error handling for the label stats feature.
class LabelStatsState {
  /// Map of label ID to label statistics
  final Map<String, LabelStats> labelStats;

  /// Loading state
  final bool isLoading;

  /// Error message if any
  final String? error;

  /// Last update timestamp for cache management
  final DateTime? lastUpdated;

  /// Whether the data is stale (needs refresh)
  final bool isStale;

  const LabelStatsState({
    this.labelStats = const {},
    this.isLoading = false,
    this.error,
    this.lastUpdated,
    this.isStale = false,
  });

  /// Create initial empty state
  factory LabelStatsState.initial() {
    return const LabelStatsState();
  }

  /// Create loading state
  factory LabelStatsState.loading() {
    return const LabelStatsState(isLoading: true);
  }

  /// Create error state
  factory LabelStatsState.error(String errorMessage) {
    return LabelStatsState(error: errorMessage);
  }

  /// Create success state with data
  factory LabelStatsState.success(List<LabelStats> stats) {
    final Map<String, LabelStats> statsMap = {};
    for (final stat in stats) {
      statsMap[stat.id] = stat;
    }

    return LabelStatsState(
      labelStats: statsMap,
      lastUpdated: DateTime.now(),
      isStale: false,
    );
  }

  /// Copy with updated values
  LabelStatsState copyWith({
    Map<String, LabelStats>? labelStats,
    bool? isLoading,
    String? error,
    DateTime? lastUpdated,
    bool? isStale,
  }) {
    return LabelStatsState(
      labelStats: labelStats ?? this.labelStats,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isStale: isStale ?? this.isStale,
    );
  }

  /// Get stats for specific label ID
  LabelStats? getStatsForLabel(String labelId) {
    return labelStats[labelId];
  }

  /// Check if stats exist for label
  bool hasStatsForLabel(String labelId) {
    return labelStats.containsKey(labelId);
  }

  /// Check if data should be refreshed (older than 5 minutes)
  bool get shouldRefresh {
    if (lastUpdated == null) return true;
    final now = DateTime.now();
    final difference = now.difference(lastUpdated!);
    return difference.inMinutes >= 5;
  }

  /// Get total labels count
  int get totalLabelsCount => labelStats.length;

  /// Check if any data exists
  bool get hasData => labelStats.isNotEmpty;

  /// Check if loading or has error
  bool get hasError => error != null;

  @override
  String toString() {
    return 'LabelStatsState(labelStats: ${labelStats.length}, isLoading: $isLoading, error: $error, lastUpdated: $lastUpdated)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LabelStatsState &&
        other.labelStats.length == labelStats.length &&
        other.isLoading == isLoading &&
        other.error == error &&
        other.lastUpdated == lastUpdated;
  }

  @override
  int get hashCode =>
      Object.hash(labelStats.length, isLoading, error, lastUpdated);
}
