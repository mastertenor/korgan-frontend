// lib/src/features/mail/presentation/providers/unread_count_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../utils/app_logger.dart';
import '../../domain/usecases/get_unread_count_usecase.dart';
import '../providers/mail_providers.dart';

import 'state/mail_constants.dart';
import 'state/mail_state.dart';

/// State class for unread count management
class UnreadCountState {
  /// Map of folder -> unread count
  final Map<MailFolder, int> counts;

  /// Loading states for each folder
  final Map<MailFolder, bool> loading;

  /// Error states for each folder
  final Map<MailFolder, String?> errors;

  /// Last refresh time for each folder
  final Map<MailFolder, DateTime> lastRefresh;

  const UnreadCountState({
    this.counts = const {},
    this.loading = const {},
    this.errors = const {},
    this.lastRefresh = const {},
  });

  /// Get count for specific folder
  int getCount(MailFolder folder) => counts[folder] ?? 0;

  /// Check if folder is loading
  bool isLoading(MailFolder folder) => loading[folder] ?? false;

  /// Get error for folder
  String? getError(MailFolder folder) => errors[folder];

  /// Check if folder needs refresh (older than 5 minutes)
  bool needsRefresh(MailFolder folder) {
    final lastTime = lastRefresh[folder];
    if (lastTime == null) return true;

    final now = DateTime.now();
    final difference = now.difference(lastTime);
    return difference.inMinutes >= 1;
  }

  /// Get display text for folder count
  String getDisplayText(MailFolder folder) {
    final count = getCount(folder);
    if (count == 0) {
      return '';
    } else if (count <= 99) {
      return count.toString();
    } else {
      return '>99';
    }
  }

  /// Check if should show badge for folder
  bool shouldShowBadge(MailFolder folder) => getCount(folder) > 0;

  /// Copy with updates
  UnreadCountState copyWith({
    Map<MailFolder, int>? counts,
    Map<MailFolder, bool>? loading,
    Map<MailFolder, String?>? errors,
    Map<MailFolder, DateTime>? lastRefresh,
  }) {
    return UnreadCountState(
      counts: counts ?? this.counts,
      loading: loading ?? this.loading,
      errors: errors ?? this.errors,
      lastRefresh: lastRefresh ?? this.lastRefresh,
    );
  }

  /// Update count for specific folder
  UnreadCountState updateCount(MailFolder folder, int count) {
    return copyWith(
      counts: {...counts, folder: count},
      loading: {...loading, folder: false},
      errors: {...errors, folder: null},
      lastRefresh: {...lastRefresh, folder: DateTime.now()},
    );
  }

  /// Set loading state for folder
  UnreadCountState setLoading(MailFolder folder, bool isLoading) {
    return copyWith(
      loading: {...loading, folder: isLoading},
      errors: isLoading ? {...errors, folder: null} : errors,
    );
  }

  /// Set error for folder
  UnreadCountState setError(MailFolder folder, String error) {
    return copyWith(
      loading: {...loading, folder: false},
      errors: {...errors, folder: error},
    );
  }
}

/// Unread count state notifier
class UnreadCountNotifier extends StateNotifier<UnreadCountState> {
  final GetUnreadCountUseCase _getUnreadCountUseCase;

  UnreadCountNotifier(this._getUnreadCountUseCase)
    : super(const UnreadCountState());

  /// Refresh unread count for specific folder
  Future<void> refreshUnreadCount({
    required String userEmail,
    required MailFolder folder,
    bool force = false,
  }) async {
    // Check if refresh is needed
    if (!force && !state.needsRefresh(folder)) {
      AppLogger.debug('🔢 Unread count for $folder is fresh, skipping refresh');
      return;
    }

    AppLogger.info('🔢 Refreshing unread count for folder: $folder');

    // Set loading state
    state = state.setLoading(folder, true);

    try {
      // Get labels for folder
      final labels = MailFolderConfig.getLabelsForFolder(folder);

      // Execute use case
      final result = await _getUnreadCountUseCase.execute(
        userEmail: userEmail,
        labels: labels,
      );

      result.when(
        success: (unreadResult) {
          // Update count in state
          state = state.updateCount(folder, unreadResult.unreadCount);

          AppLogger.info(
            '✅ Unread count updated for $folder: ${unreadResult.unreadCount}',
          );
        },
        failure: (failure) {
          // Set error state
          final errorMessage = failure.message;
          state = state.setError(folder, errorMessage);

          AppLogger.error(
            '❌ Failed to get unread count for $folder: $errorMessage',
          );
        },
      );
    } catch (e) {
      // Handle unexpected errors
      final errorMessage = 'Beklenmeyen hata: ${e.toString()}';
      state = state.setError(folder, errorMessage);

      AppLogger.error(
        '❌ Unexpected error getting unread count for $folder: $e',
      );
    }
  }

  /// Refresh multiple folders at once
  Future<void> refreshMultipleFolders({
    required String userEmail,
    required List<MailFolder> folders,
    bool force = false,
  }) async {
    final futures = folders.map(
      (folder) => refreshUnreadCount(
        userEmail: userEmail,
        folder: folder,
        force: force,
      ),
    );

    await Future.wait(futures);
  }

  /// Clear all counts (e.g., when user logs out)
  void clearAllCounts() {
    state = const UnreadCountState();
    AppLogger.info('🧹 Cleared all unread counts');
  }

  /// Clear count for specific folder
  void clearCount(MailFolder folder) {
    state = state.updateCount(folder, 0);
    AppLogger.debug('🧹 Cleared unread count for $folder');
  }
}

/// Unread count provider
final unreadCountProvider =
    StateNotifierProvider<UnreadCountNotifier, UnreadCountState>((ref) {
      final useCase = ref.read(getUnreadCountUseCaseProvider);
      return UnreadCountNotifier(useCase);
    });

/// Helper providers for specific folders
final inboxUnreadCountProvider = Provider<int>((ref) {
  return ref.watch(unreadCountProvider).getCount(MailFolder.inbox);
});

final sentUnreadCountProvider = Provider<int>((ref) {
  return ref.watch(unreadCountProvider).getCount(MailFolder.sent);
});

final draftsUnreadCountProvider = Provider<int>((ref) {
  return ref.watch(unreadCountProvider).getCount(MailFolder.drafts);
});

final spamUnreadCountProvider = Provider<int>((ref) {
  return ref.watch(unreadCountProvider).getCount(MailFolder.spam);
});

final starredUnreadCountProvider = Provider<int>((ref) {
  return ref.watch(unreadCountProvider).getCount(MailFolder.starred);
});

final importantUnreadCountProvider = Provider<int>((ref) {
  return ref.watch(unreadCountProvider).getCount(MailFolder.important);
});

/// Generic provider for any folder
final folderUnreadCountProvider = Provider.family<int, MailFolder>((
  ref,
  folder,
) {
  return ref.watch(unreadCountProvider).getCount(folder);
});

/// Display text provider for any folder
final folderUnreadDisplayProvider = Provider.family<String, MailFolder>((
  ref,
  folder,
) {
  return ref.watch(unreadCountProvider).getDisplayText(folder);
});

/// Badge visibility provider for any folder
final folderBadgeVisibleProvider = Provider.family<bool, MailFolder>((
  ref,
  folder,
) {
  return ref.watch(unreadCountProvider).shouldShowBadge(folder);
});
