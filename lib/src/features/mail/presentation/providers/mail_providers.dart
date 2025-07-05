// lib/src/features/mail/presentation/providers/mail_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:korgan/src/features/mail/domain/entities/mail.dart';
import '../../../../core/network/api_client.dart';
import '../../data/datasources/mail_remote_datasource.dart';
import '../../domain/repositories/mail_repository.dart';
import '../../data/repositories/mail_repository_impl.dart';
import '../../domain/usecases/get_mails_usecase.dart';
import '../../domain/usecases/get_trash_mails_usecase.dart';
import '../../domain/usecases/mail_actions_usecase.dart';
import 'mail_provider.dart';

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

/// Mail State Provider
final mailProvider = StateNotifierProvider<MailNotifier, MailState>((ref) {
  final getMailsUseCase = ref.read(getMailsUseCaseProvider);
  final getTrashMailsUseCase = ref.read(getTrashMailsUseCaseProvider);
  final mailActionsUseCase = ref.read(mailActionsUseCaseProvider);

  return MailNotifier(
    getMailsUseCase,
    getTrashMailsUseCase,
    mailActionsUseCase,
  );
});

/// Computed providers for common use cases

/// Unread mails only
final unreadMailsProvider = Provider<List<Mail>>((ref) {
  final mailState = ref.watch(mailProvider);
  return mailState.mails.where((mail) => !mail.isRead).toList();
});

/// Starred mails only
final starredMailsProvider = Provider<List<Mail>>((ref) {
  final mailState = ref.watch(mailProvider);
  return mailState.mails.where((mail) => mail.isStarred).toList();
});

/// Trash mails only
final trashMailsProvider = Provider<List<Mail>>((ref) {
  final mailState = ref.watch(mailProvider);
  return mailState.trashMails;
});

/// Active (non-deleted) mails only
final activeMailsProvider = Provider<List<Mail>>((ref) {
  final mailState = ref.watch(mailProvider);
  return mailState.mails.where((mail) => !mail.isDeleted).toList();
});

/// Loading state only
final mailLoadingProvider = Provider<bool>((ref) {
  final mailState = ref.watch(mailProvider);
  return mailState.isLoading;
});

/// Trash loading state only
final trashLoadingProvider = Provider<bool>((ref) {
  final mailState = ref.watch(mailProvider);
  return mailState.isLoadingTrash;
});

/// Error state only
final mailErrorProvider = Provider<String?>((ref) {
  final mailState = ref.watch(mailProvider);
  return mailState.error;
});

/// Trash error state only
final trashErrorProvider = Provider<String?>((ref) {
  final mailState = ref.watch(mailProvider);
  return mailState.trashError;
});

/// Unread count only
final unreadCountProvider = Provider<int>((ref) {
  final mailState = ref.watch(mailProvider);
  return mailState.unreadCount;
});

/// Trash count only
final trashCountProvider = Provider<int>((ref) {
  final mailState = ref.watch(mailProvider);
  return mailState.trashCount;
});

/// Has more mails to load
final hasMoreMailsProvider = Provider<bool>((ref) {
  final mailState = ref.watch(mailProvider);
  return mailState.hasMore;
});

/// Has more trash mails to load
final hasMoreTrashMailsProvider = Provider<bool>((ref) {
  final mailState = ref.watch(mailProvider);
  return mailState.trashHasMore;
});

/// Combined loading state (any loading)
final anyLoadingProvider = Provider<bool>((ref) {
  final mailState = ref.watch(mailProvider);
  return mailState.isLoading || mailState.isLoadingTrash;
});

/// Combined error state (any error)
final anyErrorProvider = Provider<String?>((ref) {
  final mailState = ref.watch(mailProvider);
  return mailState.error ?? mailState.trashError;
});

/// Mail statistics provider
final mailStatsProvider = Provider<MailStats>((ref) {
  final mailState = ref.watch(mailProvider);

  return MailStats(
    totalMails: mailState.mails.length,
    unreadMails: mailState.unreadCount,
    starredMails: mailState.mails.where((mail) => mail.isStarred).length,
    trashMails: mailState.trashCount,
    readMails: mailState.mails.where((mail) => mail.isRead).length,
  );
});

/// Mail statistics data class
class MailStats {
  final int totalMails;
  final int unreadMails;
  final int starredMails;
  final int trashMails;
  final int readMails;

  const MailStats({
    required this.totalMails,
    required this.unreadMails,
    required this.starredMails,
    required this.trashMails,
    required this.readMails,
  });

  @override
  String toString() {
    return 'MailStats(total: $totalMails, unread: $unreadMails, starred: $starredMails, trash: $trashMails, read: $readMails)';
  }
}
