// lib/src/features/mail/presentation/providers/mail_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../data/datasources/mail_remote_datasource.dart';
import '../../domain/repositories/mail_repository.dart';
import '../../data/repositories/mail_repository_impl.dart';
import '../../domain/usecases/get_mails_usecase.dart';
import '../../domain/usecases/get_trash_mails_usecase.dart';
import '../../domain/usecases/mail_actions_usecase.dart';
import '../../domain/entities/mail.dart';
import 'mail_provider.dart';

// ========== DEPENDENCY INJECTION PROVIDERS ==========

/// API Client Provider
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

/// Mail Remote DataSource Provider
final mailRemoteDataSourceProvider = Provider<MailRemoteDataSource>((ref) {
  final apiClient = ref.read(apiClientProvider);
  return MailRemoteDataSourceImpl(apiClient);
});

/// Mail Repository Provider
final mailRepositoryProvider = Provider<MailRepository>((ref) {
  final remoteDataSource = ref.read(mailRemoteDataSourceProvider);
  return MailRepositoryImpl(remoteDataSource);
});

/// Get Mails UseCase Provider
final getMailsUseCaseProvider = Provider<GetMailsUseCase>((ref) {
  final repository = ref.read(mailRepositoryProvider);
  return GetMailsUseCase(repository);
});

/// Get Trash Mails UseCase Provider
final getTrashMailsUseCaseProvider = Provider<GetTrashMailsUseCase>((ref) {
  final repository = ref.read(mailRepositoryProvider);
  return GetTrashMailsUseCase(repository);
});

/// Mail Actions UseCase Provider
final mailActionsUseCaseProvider = Provider<MailActionsUseCase>((ref) {
  final repository = ref.read(mailRepositoryProvider);
  return MailActionsUseCase(repository);
});

/// Mail State Provider - Context-Aware
final mailProvider = StateNotifierProvider<MailNotifier, MailState>((ref) {
  final getMailsUseCase = ref.read(getMailsUseCaseProvider);
  final mailActionsUseCase = ref.read(mailActionsUseCaseProvider);

  return MailNotifier(getMailsUseCase, mailActionsUseCase);
});

// ========== CURRENT CONTEXT PROVIDERS ==========

/// Current folder provider
final currentFolderProvider = Provider<MailFolder>((ref) {
  final mailState = ref.watch(mailProvider);
  return mailState.currentFolder;
});

/// Current context provider
final currentContextProvider = Provider<MailContext?>((ref) {
  final mailState = ref.watch(mailProvider);
  return mailState.currentContext;
});

/// Current mails provider (from current context)
final currentMailsProvider = Provider<List<Mail>>((ref) {
  final mailState = ref.watch(mailProvider);
  return mailState.currentMails;
});

/// Current loading state provider
final currentLoadingProvider = Provider<bool>((ref) {
  final mailState = ref.watch(mailProvider);
  return mailState.isCurrentLoading;
});

/// Current error provider
final currentErrorProvider = Provider<String?>((ref) {
  final mailState = ref.watch(mailProvider);
  return mailState.currentError;
});

/// Is search mode active
final isSearchModeProvider = Provider<bool>((ref) {
  final mailState = ref.watch(mailProvider);
  return mailState.isSearchMode;
});

// ========== FOLDER-SPECIFIC PROVIDERS ==========

/// Get specific folder context
Provider<MailContext?> folderContextProvider(MailFolder folder) {
  return Provider<MailContext?>((ref) {
    final mailState = ref.watch(mailProvider);
    return mailState.contexts[folder];
  });
}

/// Get specific folder mails
Provider<List<Mail>> folderMailsProvider(MailFolder folder) {
  return Provider<List<Mail>>((ref) {
    final context = ref.watch(folderContextProvider(folder));
    return context?.mails ?? [];
  });
}

/// Get specific folder loading state
Provider<bool> folderLoadingProvider(MailFolder folder) {
  return Provider<bool>((ref) {
    final context = ref.watch(folderContextProvider(folder));
    return context?.isLoading ?? false;
  });
}

/// Get specific folder error
Provider<String?> folderErrorProvider(MailFolder folder) {
  return Provider<String?>((ref) {
    final context = ref.watch(folderContextProvider(folder));
    return context?.error;
  });
}

/// Get specific folder unread count
Provider<int> folderUnreadCountProvider(MailFolder folder) {
  return Provider<int>((ref) {
    final context = ref.watch(folderContextProvider(folder));
    return context?.unreadCount ?? 0;
  });
}

// ========== CONVENIENCE FOLDER PROVIDERS ==========

/// Inbox providers
final inboxContextProvider = folderContextProvider(MailFolder.inbox);
final inboxMailsProvider = folderMailsProvider(MailFolder.inbox);
final inboxLoadingProvider = folderLoadingProvider(MailFolder.inbox);
final inboxErrorProvider = folderErrorProvider(MailFolder.inbox);
final inboxUnreadCountProvider = folderUnreadCountProvider(MailFolder.inbox);

/// Sent providers
final sentContextProvider = folderContextProvider(MailFolder.sent);
final sentMailsProvider = folderMailsProvider(MailFolder.sent);
final sentLoadingProvider = folderLoadingProvider(MailFolder.sent);
final sentErrorProvider = folderErrorProvider(MailFolder.sent);
final sentUnreadCountProvider = folderUnreadCountProvider(MailFolder.sent);

/// Drafts providers
final draftsContextProvider = folderContextProvider(MailFolder.drafts);
final draftsMailsProvider = folderMailsProvider(MailFolder.drafts);
final draftsLoadingProvider = folderLoadingProvider(MailFolder.drafts);
final draftsErrorProvider = folderErrorProvider(MailFolder.drafts);
final draftsUnreadCountProvider = folderUnreadCountProvider(MailFolder.drafts);

/// Spam providers
final spamContextProvider = folderContextProvider(MailFolder.spam);
final spamMailsProvider = folderMailsProvider(MailFolder.spam);
final spamLoadingProvider = folderLoadingProvider(MailFolder.spam);
final spamErrorProvider = folderErrorProvider(MailFolder.spam);
final spamUnreadCountProvider = folderUnreadCountProvider(MailFolder.spam);

/// Trash providers
final trashContextProvider = folderContextProvider(MailFolder.trash);
final trashMailsProvider = folderMailsProvider(MailFolder.trash);
final trashLoadingProvider = folderLoadingProvider(MailFolder.trash);
final trashErrorProvider = folderErrorProvider(MailFolder.trash);
final trashUnreadCountProvider = folderUnreadCountProvider(MailFolder.trash);

/// Starred providers
final starredContextProvider = folderContextProvider(MailFolder.starred);
final starredMailsProvider = folderMailsProvider(MailFolder.starred);
final starredLoadingProvider = folderLoadingProvider(MailFolder.starred);
final starredErrorProvider = folderErrorProvider(MailFolder.starred);
final starredUnreadCountProvider = folderUnreadCountProvider(
  MailFolder.starred,
);

/// Important providers
final importantContextProvider = folderContextProvider(MailFolder.important);
final importantMailsProvider = folderMailsProvider(MailFolder.important);
final importantLoadingProvider = folderLoadingProvider(MailFolder.important);
final importantErrorProvider = folderErrorProvider(MailFolder.important);
final importantUnreadCountProvider = folderUnreadCountProvider(
  MailFolder.important,
);

// ========== GLOBAL STATE PROVIDERS ==========

/// Total unread count across all folders
final totalUnreadCountProvider = Provider<int>((ref) {
  final mailState = ref.watch(mailProvider);
  return mailState.totalUnreadCount;
});

/// Any loading state active
final anyLoadingProvider = Provider<bool>((ref) {
  final mailState = ref.watch(mailProvider);
  return mailState.isAnyLoading;
});

/// Any error state active
final anyErrorProvider = Provider<String?>((ref) {
  final mailState = ref.watch(mailProvider);

  // Return first error found across all contexts
  for (final context in mailState.contexts.values) {
    if (context.error != null) {
      return context.error;
    }
  }
  return null;
});

// ========== MAIL STATISTICS PROVIDERS ==========

/// Mail statistics for current folder
final currentFolderStatsProvider = Provider<MailStats>((ref) {
  final context = ref.watch(currentContextProvider);
  final mails = context?.mails ?? [];

  return MailStats(
    totalMails: mails.length,
    unreadMails: mails.where((mail) => !mail.isRead).length,
    starredMails: mails.where((mail) => mail.isStarred).length,
    readMails: mails.where((mail) => mail.isRead).length,
    folderName: ref.watch(currentFolderProvider).name,
  );
});

/// Global mail statistics across all folders
final globalMailStatsProvider = Provider<GlobalMailStats>((ref) {
  final mailState = ref.watch(mailProvider);

  final allMails = mailState.contexts.values
      .expand((context) => context.mails)
      .toList();

  return GlobalMailStats(
    totalMails: allMails.length,
    totalUnreadMails: allMails.where((mail) => !mail.isRead).length,
    totalStarredMails: allMails.where((mail) => mail.isStarred).length,
    totalReadMails: allMails.where((mail) => mail.isRead).length,
    loadedFolders: mailState.contexts.length,
    folderStats: mailState.contexts.map((folder, context) {
      return MapEntry(
        folder,
        FolderStats(
          folder: folder,
          totalMails: context.mails.length,
          unreadMails: context.unreadCount,
          starredMails: context.mails.where((mail) => mail.isStarred).length,
          lastUpdated: context.lastUpdated,
        ),
      );
    }),
  );
});

// ========== FOLDER NAVIGATION PROVIDERS ==========

/// Available folders with data
final availableFoldersProvider = Provider<List<MailFolder>>((ref) {
  final mailState = ref.watch(mailProvider);
  return mailState.contexts.keys.toList();
});

/// Folders with unread mails
final foldersWithUnreadProvider = Provider<List<MailFolder>>((ref) {
  final mailState = ref.watch(mailProvider);

  return mailState.contexts.entries
      .where((entry) => entry.value.unreadCount > 0)
      .map((entry) => entry.key)
      .toList();
});

/// Folder navigation info
final folderNavigationProvider = Provider<List<FolderNavInfo>>((ref) {
  final mailState = ref.watch(mailProvider);

  return MailFolder.values.where((folder) => !_isSearchFolder(folder)).map((
    folder,
  ) {
    final context = mailState.contexts[folder];
    return FolderNavInfo(
      folder: folder,
      isLoaded: context != null,
      unreadCount: context?.unreadCount ?? 0,
      totalCount: context?.mails.length ?? 0,
      isStale: context?.isStale ?? true,
      hasError: context?.error != null,
    );
  }).toList();
});

// ========== HELPER FUNCTIONS ==========

bool _isSearchFolder(MailFolder folder) {
  return [
    MailFolder.inboxSearch,
    MailFolder.sentSearch,
    MailFolder.draftsSearch,
    MailFolder.spamSearch,
    MailFolder.starredSearch,
    MailFolder.importantSearch,
  ].contains(folder);
}

// ========== DATA CLASSES ==========

/// Mail statistics for a single folder
class MailStats {
  final int totalMails;
  final int unreadMails;
  final int starredMails;
  final int readMails;
  final String folderName;

  const MailStats({
    required this.totalMails,
    required this.unreadMails,
    required this.starredMails,
    required this.readMails,
    required this.folderName,
  });

  @override
  String toString() {
    return 'MailStats($folderName: total=$totalMails, unread=$unreadMails, starred=$starredMails, read=$readMails)';
  }
}

/// Global mail statistics across all folders
class GlobalMailStats {
  final int totalMails;
  final int totalUnreadMails;
  final int totalStarredMails;
  final int totalReadMails;
  final int loadedFolders;
  final Map<MailFolder, FolderStats> folderStats;

  const GlobalMailStats({
    required this.totalMails,
    required this.totalUnreadMails,
    required this.totalStarredMails,
    required this.totalReadMails,
    required this.loadedFolders,
    required this.folderStats,
  });

  @override
  String toString() {
    return 'GlobalMailStats(total=$totalMails, unread=$totalUnreadMails, folders=$loadedFolders)';
  }
}

/// Statistics for a specific folder
class FolderStats {
  final MailFolder folder;
  final int totalMails;
  final int unreadMails;
  final int starredMails;
  final DateTime? lastUpdated;

  const FolderStats({
    required this.folder,
    required this.totalMails,
    required this.unreadMails,
    required this.starredMails,
    this.lastUpdated,
  });

  @override
  String toString() {
    return 'FolderStats(${folder.name}: total=$totalMails, unread=$unreadMails)';
  }
}

/// Folder navigation information
class FolderNavInfo {
  final MailFolder folder;
  final bool isLoaded;
  final int unreadCount;
  final int totalCount;
  final bool isStale;
  final bool hasError;

  const FolderNavInfo({
    required this.folder,
    required this.isLoaded,
    required this.unreadCount,
    required this.totalCount,
    required this.isStale,
    required this.hasError,
  });

  String get displayName {
    switch (folder) {
      case MailFolder.inbox:
        return 'Gelen Kutusu';
      case MailFolder.sent:
        return 'Gönderilmiş';
      case MailFolder.drafts:
        return 'Taslaklar';
      case MailFolder.spam:
        return 'Spam';
      case MailFolder.trash:
        return 'Çöp Kutusu';
      case MailFolder.starred:
        return 'Yıldızlı';
      case MailFolder.important:
        return 'Önemli';
      default:
        return folder.name;
    }
  }

  @override
  String toString() {
    return 'FolderNavInfo($displayName: loaded=$isLoaded, unread=$unreadCount, stale=$isStale)';
  }
}
