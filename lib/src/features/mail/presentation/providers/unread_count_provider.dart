// lib/src/features/mail/presentation/providers/unread_count_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../utils/app_logger.dart';
import '../../domain/usecases/get_unread_count_usecase.dart';
import '../providers/mail_providers.dart';
import '../../presentation/providers/mail_context_provider.dart';

import 'state/mail_constants.dart';
import 'state/mail_state.dart';

/// State class for unread count management - Context-aware version
class UnreadCountState {
  /// Map of folder -> user email -> unread count
  final Map<MailFolder, Map<String, int>> counts;

  /// Loading states for each folder and user
  final Map<MailFolder, Map<String, bool>> loading;

  /// Error states for each folder and user
  final Map<MailFolder, Map<String, String?>> errors;

  /// Last refresh time for each folder and user
  final Map<MailFolder, Map<String, DateTime>> lastRefresh;

  const UnreadCountState({
    this.counts = const {},
    this.loading = const {},
    this.errors = const {},
    this.lastRefresh = const {},
  });

  /// Get count for specific folder and user
  int getCount(MailFolder folder, String userEmail) {
    return counts[folder]?[userEmail] ?? 0;
  }

  /// Check if folder is loading for specific user
  bool isLoading(MailFolder folder, String userEmail) {
    return loading[folder]?[userEmail] ?? false;
  }

  /// Get error for folder and user
  String? getError(MailFolder folder, String userEmail) {
    return errors[folder]?[userEmail];
  }

  /// Check if folder needs refresh for specific user (older than 1 minute OR different user)
  bool needsRefresh(MailFolder folder, String userEmail) {
    final folderLastRefresh = lastRefresh[folder];
    if (folderLastRefresh == null) return true;

    final lastTime = folderLastRefresh[userEmail];
    if (lastTime == null) return true; // Never refreshed for this user

    final now = DateTime.now();
    final difference = now.difference(lastTime);
    return difference.inMinutes >= 1;
  }

  /// Get display text for folder count
  String getDisplayText(MailFolder folder, String userEmail) {
    final count = getCount(folder, userEmail);
    if (count == 0) {
      return '';
    } else if (count <= 99) {
      return count.toString();
    } else {
      return '>99';
    }
  }

  /// Check if should show badge for folder
  bool shouldShowBadge(MailFolder folder, String userEmail) {
    return getCount(folder, userEmail) > 0;
  }

  /// Copy with updates
  UnreadCountState copyWith({
    Map<MailFolder, Map<String, int>>? counts,
    Map<MailFolder, Map<String, bool>>? loading,
    Map<MailFolder, Map<String, String?>>? errors,
    Map<MailFolder, Map<String, DateTime>>? lastRefresh,
  }) {
    return UnreadCountState(
      counts: counts ?? this.counts,
      loading: loading ?? this.loading,
      errors: errors ?? this.errors,
      lastRefresh: lastRefresh ?? this.lastRefresh,
    );
  }

  /// Update count for specific folder and user
  UnreadCountState updateCount(MailFolder folder, String userEmail, int count) {
    final newCounts = Map<MailFolder, Map<String, int>>.from(counts);
    newCounts[folder] = {...(newCounts[folder] ?? {}), userEmail: count};

    final newLoading = Map<MailFolder, Map<String, bool>>.from(loading);
    newLoading[folder] = {...(newLoading[folder] ?? {}), userEmail: false};

    final newErrors = Map<MailFolder, Map<String, String?>>.from(errors);
    newErrors[folder] = {...(newErrors[folder] ?? {}), userEmail: null};

    final newLastRefresh = Map<MailFolder, Map<String, DateTime>>.from(
      lastRefresh,
    );
    newLastRefresh[folder] = {
      ...(newLastRefresh[folder] ?? {}),
      userEmail: DateTime.now(),
    };

    return copyWith(
      counts: newCounts,
      loading: newLoading,
      errors: newErrors,
      lastRefresh: newLastRefresh,
    );
  }

  /// Set loading state for folder and user
  UnreadCountState setLoading(
    MailFolder folder,
    String userEmail,
    bool isLoading,
  ) {
    final newLoading = Map<MailFolder, Map<String, bool>>.from(loading);
    newLoading[folder] = {...(newLoading[folder] ?? {}), userEmail: isLoading};

    final newErrors = Map<MailFolder, Map<String, String?>>.from(errors);
    if (isLoading) {
      newErrors[folder] = {...(newErrors[folder] ?? {}), userEmail: null};
    }

    return copyWith(
      loading: newLoading,
      errors: isLoading ? newErrors : errors,
    );
  }

  /// Set error for folder and user
  UnreadCountState setError(MailFolder folder, String userEmail, String error) {
    final newLoading = Map<MailFolder, Map<String, bool>>.from(loading);
    newLoading[folder] = {...(newLoading[folder] ?? {}), userEmail: false};

    final newErrors = Map<MailFolder, Map<String, String?>>.from(errors);
    newErrors[folder] = {...(newErrors[folder] ?? {}), userEmail: error};

    return copyWith(loading: newLoading, errors: newErrors);
  }
}

/// Unread count state notifier - Context-aware version
class UnreadCountNotifier extends StateNotifier<UnreadCountState> {
  final GetUnreadCountUseCase _getUnreadCountUseCase;

  UnreadCountNotifier(this._getUnreadCountUseCase)
    : super(const UnreadCountState());

  /// Refresh unread count for specific folder and user
  Future<void> refreshUnreadCount({
    required String userEmail,
    required MailFolder folder,
    bool force = false,
  }) async {
    // Check if refresh is needed for this specific user
    if (!force && !state.needsRefresh(folder, userEmail)) {
      AppLogger.debug(
        '🔢 Unread count for $folder/$userEmail is fresh, skipping refresh',
      );
      return;
    }

    AppLogger.info(
      '🔢 Refreshing unread count for folder: $folder, user: $userEmail',
    );

    // Set loading state for this user
    state = state.setLoading(folder, userEmail, true);

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
          // Update count in state for this user
          state = state.updateCount(
            folder,
            userEmail,
            unreadResult.unreadCount,
          );

          AppLogger.info(
            '✅ Unread count updated for $folder/$userEmail: ${unreadResult.unreadCount}',
          );
        },
        failure: (failure) {
          // Set error state for this user
          final errorMessage = failure.message;
          state = state.setError(folder, userEmail, errorMessage);

          AppLogger.error(
            '❌ Failed to get unread count for $folder/$userEmail: $errorMessage',
          );
        },
      );
    } catch (e) {
      // Handle unexpected errors
      final errorMessage = 'Beklenmeyen hata: ${e.toString()}';
      state = state.setError(folder, userEmail, errorMessage);

      AppLogger.error(
        '❌ Unexpected error getting unread count for $folder/$userEmail: $e',
      );
    }
  }

  /// Refresh multiple folders for specific user
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

  /// Clear count for specific folder and user
  void clearCount(MailFolder folder, String userEmail) {
    state = state.updateCount(folder, userEmail, 0);
    AppLogger.debug('🧹 Cleared unread count for $folder/$userEmail');
  }

  /// Force refresh all folders for new user context
  Future<void> refreshAllFoldersForUser(String userEmail) async {
    AppLogger.info('🔄 Force refreshing all folders for user: $userEmail');

    final allFolders = [
      MailFolder.inbox,
      MailFolder.sent,
      MailFolder.drafts,
      MailFolder.spam,
      MailFolder.starred,
      MailFolder.important,
      MailFolder.trash,
    ];

    await refreshMultipleFolders(
      userEmail: userEmail,
      folders: allFolders,
      force: true, // Force refresh for context switch
    );
  }
}

/// Unread count provider
final unreadCountProvider =
    StateNotifierProvider<UnreadCountNotifier, UnreadCountState>((ref) {
      final useCase = ref.read(getUnreadCountUseCaseProvider);
      return UnreadCountNotifier(useCase);
    });

/// Helper providers for specific folders - now context-aware
final inboxUnreadCountProvider = Provider<int>((ref) {
  final selectedContext = ref.watch(selectedMailContextProvider);
  final userEmail = selectedContext?.emailAddress ?? '';
  if (userEmail.isEmpty) return 0;

  return ref.watch(unreadCountProvider).getCount(MailFolder.inbox, userEmail);
});

final sentUnreadCountProvider = Provider<int>((ref) {
  final selectedContext = ref.watch(selectedMailContextProvider);
  final userEmail = selectedContext?.emailAddress ?? '';
  if (userEmail.isEmpty) return 0;

  return ref.watch(unreadCountProvider).getCount(MailFolder.sent, userEmail);
});

final draftsUnreadCountProvider = Provider<int>((ref) {
  final selectedContext = ref.watch(selectedMailContextProvider);
  final userEmail = selectedContext?.emailAddress ?? '';
  if (userEmail.isEmpty) return 0;

  return ref.watch(unreadCountProvider).getCount(MailFolder.drafts, userEmail);
});

final spamUnreadCountProvider = Provider<int>((ref) {
  final selectedContext = ref.watch(selectedMailContextProvider);
  final userEmail = selectedContext?.emailAddress ?? '';
  if (userEmail.isEmpty) return 0;

  return ref.watch(unreadCountProvider).getCount(MailFolder.spam, userEmail);
});

final starredUnreadCountProvider = Provider<int>((ref) {
  final selectedContext = ref.watch(selectedMailContextProvider);
  final userEmail = selectedContext?.emailAddress ?? '';
  if (userEmail.isEmpty) return 0;

  return ref.watch(unreadCountProvider).getCount(MailFolder.starred, userEmail);
});

final importantUnreadCountProvider = Provider<int>((ref) {
  final selectedContext = ref.watch(selectedMailContextProvider);
  final userEmail = selectedContext?.emailAddress ?? '';
  if (userEmail.isEmpty) return 0;

  return ref
      .watch(unreadCountProvider)
      .getCount(MailFolder.important, userEmail);
});

/// Generic provider for any folder - now context-aware
final folderUnreadCountProvider = Provider.family<int, MailFolder>((
  ref,
  folder,
) {
  final selectedContext = ref.watch(selectedMailContextProvider);
  final userEmail = selectedContext?.emailAddress ?? '';
  if (userEmail.isEmpty) return 0;

  return ref.watch(unreadCountProvider).getCount(folder, userEmail);
});

/// Display text provider for any folder - now context-aware
final folderUnreadDisplayProvider = Provider.family<String, MailFolder>((
  ref,
  folder,
) {
  final selectedContext = ref.watch(selectedMailContextProvider);
  final userEmail = selectedContext?.emailAddress ?? '';
  if (userEmail.isEmpty) return '';

  return ref.watch(unreadCountProvider).getDisplayText(folder, userEmail);
});

/// Badge visibility provider for any folder - now context-aware
final folderBadgeVisibleProvider = Provider.family<bool, MailFolder>((
  ref,
  folder,
) {
  final selectedContext = ref.watch(selectedMailContextProvider);
  final userEmail = selectedContext?.emailAddress ?? '';
  if (userEmail.isEmpty) return false;

  return ref.watch(unreadCountProvider).shouldShowBadge(folder, userEmail);
});
