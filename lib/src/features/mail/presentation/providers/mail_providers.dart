// lib/src/features/mail/presentation/providers/mail_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../data/datasources/mail_remote_datasource.dart';
import '../../domain/repositories/mail_repository.dart';
import '../../data/repositories/mail_repository_impl.dart';
import '../../domain/usecases/get_mails_usecase.dart';
import '../../domain/usecases/get_trash_mails_usecase.dart';
import '../../domain/usecases/mail_actions_usecase.dart';
import '../../domain/usecases/get_mail_detail_usecase.dart';
import '../../domain/entities/mail.dart';
import '../../domain/entities/mail_detail.dart'; // 🔧 EmailPriority için gerekli
import '../../domain/usecases/download_attachment_usecase.dart';
import 'mail_provider.dart';
import 'mail_detail_provider.dart' show MailDetailState, MailDetailNotifier;

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

/// Get Mail Detail UseCase Provider
final getMailDetailUseCaseProvider = Provider<GetMailDetailUseCase>((ref) {
  final repository = ref.read(mailRepositoryProvider);
  return GetMailDetailUseCase(repository);
});

/// 🆕 Download Attachment UseCase Provider
final downloadAttachmentUseCaseProvider = Provider<DownloadAttachmentUseCase>((
  ref,
) {
  final repository = ref.read(mailRepositoryProvider);
  return DownloadAttachmentUseCase(repository);
});

// ========== MAIN MAIL PROVIDER ==========

/// Main Mail State Provider
final mailProvider = StateNotifierProvider<MailNotifier, MailState>((ref) {
  final getMailsUseCase = ref.read(getMailsUseCaseProvider);
  final mailActionsUseCase = ref.read(mailActionsUseCaseProvider);

  return MailNotifier(getMailsUseCase, mailActionsUseCase); // ✅ Doğru
});

// ========== CURRENT STATE PROVIDERS ==========

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

/// Current mails provider
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

// ========== 🆕 MAIL DETAIL PROVIDERS ==========

/// Mail Detail State Provider
final mailDetailProvider =
    StateNotifierProvider<MailDetailNotifier, MailDetailState>((ref) {
      final getMailDetailUseCase = ref.read(getMailDetailUseCaseProvider);
      return MailDetailNotifier(getMailDetailUseCase);
    });

/// Current mail detail provider
final currentMailDetailProvider = Provider<MailDetail?>((ref) {
  final state = ref.watch(mailDetailProvider);
  return state.mailDetail;
});

/// Mail detail loading provider
final mailDetailLoadingProvider = Provider<bool>((ref) {
  final state = ref.watch(mailDetailProvider);
  return state.isLoading;
});

/// Mail detail error provider
final mailDetailErrorProvider = Provider<String?>((ref) {
  final state = ref.watch(mailDetailProvider);
  return state.error;
});

/// Current mail detail ID provider
final currentMailDetailIdProvider = Provider<String?>((ref) {
  final state = ref.watch(mailDetailProvider);
  return state.currentMailId;
});

/// Mail detail last updated provider
final mailDetailLastUpdatedProvider = Provider<DateTime?>((ref) {
  final state = ref.watch(mailDetailProvider);
  return state.lastUpdated;
});

/// 🆕 Specific mail loading provider factory
Provider<bool> mailLoadingProvider(String mailId) {
  return Provider<bool>((ref) {
    final state = ref.watch(mailDetailProvider);
    return state.isLoadingMail(mailId);
  });
}

/// 🆕 Specific mail loaded provider factory
Provider<bool> mailLoadedProvider(String mailId) {
  return Provider<bool>((ref) {
    final state = ref.watch(mailDetailProvider);
    return state.isMailLoaded(mailId);
  });
}

// ========== 🔧 MAIL DETAIL STATISTICS ==========

/// Mail detail statistics provider - FIXED VERSION
final mailDetailStatsProvider = Provider<MailDetailStats?>((ref) {
  final mailDetail = ref.watch(currentMailDetailProvider);
  if (mailDetail == null) return null;

  return MailDetailStats(
    id: mailDetail.id,
    senderName: mailDetail.senderName,
    subject: mailDetail.subject,
    // 🔧 MailDetail'e özgü property'ler - safe getters ile
    hasHtmlContent: mailDetail.htmlContent.isNotEmpty,
    isTextOnly:
        mailDetail.htmlContent.isEmpty && mailDetail.textContent.isNotEmpty,
    // ✅ Mail entity'den gelen attachment property'ler
    hasAttachments: mailDetail.hasAttachments,
    attachmentCount: mailDetail.attachmentCount,
    // 🔧 MailDetail'e özgü - sizeBytes
    sizeBytes: mailDetail.sizeBytes,
    // 🔧 MailDetail'e özgü - formattedSize hesaplama
    formattedSize: _formatSize(mailDetail.sizeBytes),
    // 🔧 MailDetail'e özgü - isLargeEmail hesaplama
    isLargeEmail: (mailDetail.sizeBytes ?? 0) > (1024 * 1024), // > 1MB
    // ✅ MailDetail'e özgü - priority
    priority: mailDetail.priority,
    // ✅ MailDetail'e özgü - labels
    labelCount: mailDetail.labels.length,
    // 🔧 MailDetail'e özgü - recipients toplam sayısı
    recipientCount:
        mailDetail.recipients.length +
        mailDetail.ccRecipients.length +
        mailDetail.bccRecipients.length,
    // 🔧 MailDetail'e özgü - thread kontrol
    isPartOfThread:
        mailDetail.threadId != null && mailDetail.threadId!.isNotEmpty,
  );
});

// 🔧 Helper function - size formatting
String _formatSize(int? sizeBytes) {
  if (sizeBytes == null || sizeBytes == 0) return '0B';

  if (sizeBytes < 1024) return '${sizeBytes}B';
  if (sizeBytes < 1024 * 1024)
    return '${(sizeBytes / 1024).toStringAsFixed(1)}KB';
  return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)}MB';
}

// ========== FOLDER-SPECIFIC PROVIDERS ==========
// ... diğer provider'lar aynı kalacak

// ========== DATA CLASSES ==========

/// 🔧 Mail detail statistics - Updated class
class MailDetailStats {
  final String id;
  final String senderName;
  final String subject;
  final bool hasHtmlContent;
  final bool isTextOnly;
  final bool hasAttachments;
  final int attachmentCount;
  final int? sizeBytes;
  final String formattedSize;
  final bool isLargeEmail;
  final EmailPriority priority;
  final int labelCount;
  final int recipientCount;
  final bool isPartOfThread;

  const MailDetailStats({
    required this.id,
    required this.senderName,
    required this.subject,
    required this.hasHtmlContent,
    required this.isTextOnly,
    required this.hasAttachments,
    required this.attachmentCount,
    this.sizeBytes,
    required this.formattedSize,
    required this.isLargeEmail,
    required this.priority,
    required this.labelCount,
    required this.recipientCount,
    required this.isPartOfThread,
  });

  @override
  String toString() {
    return 'MailDetailStats($id: $subject, hasHtml=$hasHtmlContent, size=$formattedSize)';
  }
}
