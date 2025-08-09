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
import '../../domain/usecases/send_mail_usecase.dart';
import '../../domain/entities/mail.dart';
import '../../domain/entities/mail_detail.dart';
import '../../domain/entities/compose_result.dart';
import '../../domain/enums/reply_type.dart';
import '../../domain/usecases/download_attachment_usecase.dart';
import 'mail_provider.dart';
import 'mail_detail_provider.dart' show MailDetailState, MailDetailNotifier;
import 'mail_compose_provider.dart';
import 'mail_reply_provider.dart';
import 'mail_selection_provider.dart';

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

/// Download Attachment UseCase Provider
final downloadAttachmentUseCaseProvider = Provider<DownloadAttachmentUseCase>((
  ref,
) {
  final repository = ref.read(mailRepositoryProvider);
  return DownloadAttachmentUseCase(repository);
});

// ========== 🆕 MAIL COMPOSE PROVIDERS ==========

/// Send Mail UseCase Provider
final sendMailUseCaseProvider = Provider<SendMailUseCase>((ref) {
  final repository = ref.read(mailRepositoryProvider);
  return SendMailUseCase(repository);
});

/// Mail Compose State Provider
final mailComposeProvider = StateNotifierProvider<MailComposeNotifier, MailComposeState>((ref) {
  final sendMailUseCase = ref.read(sendMailUseCaseProvider);
  return MailComposeNotifier(sendMailUseCase);
});

// ========== 🆕 MAIL REPLY PROVIDERS ==========

/// Mail Reply State Provider
final mailReplyProvider = StateNotifierProvider<MailReplyNotifier, MailReplyState>((ref) {
  final sendMailUseCase = ref.read(sendMailUseCaseProvider);
  return MailReplyNotifier(sendMailUseCase);
});

// ========== COMPOSE UTILITY PROVIDERS ==========

/// Current compose form validity provider
final composeFormValidityProvider = Provider<bool>((ref) {
  final composeState = ref.watch(mailComposeProvider);
  return composeState.isValid;
});

/// Can send mail provider
final canSendMailProvider = Provider<bool>((ref) {
  final composeState = ref.watch(mailComposeProvider);
  return composeState.canSend;
});

/// Compose validation summary provider
final composeValidationSummaryProvider = Provider<String>((ref) {
  final composeNotifier = ref.read(mailComposeProvider.notifier);
  return composeNotifier.getValidationSummary();
});

/// Compose loading state provider
final composeLoadingProvider = Provider<bool>((ref) {
  final composeState = ref.watch(mailComposeProvider);
  return composeState.isSending;
});

/// Compose error provider
final composeErrorProvider = Provider<String?>((ref) {
  final composeState = ref.watch(mailComposeProvider);
  return composeState.error;
});

/// Compose last result provider
final composeLastResultProvider = Provider<ComposeResult?>((ref) {
  final composeState = ref.watch(mailComposeProvider);
  return composeState.lastResult;
});

/// Recipient count provider
final recipientCountProvider = Provider<int>((ref) {
  final composeState = ref.watch(mailComposeProvider);
  return composeState.recipientCount;
});

/// Attachment count provider
final attachmentCountProvider = Provider<int>((ref) {
  final composeState = ref.watch(mailComposeProvider);
  return composeState.attachments.length;
});

/// Total attachment size provider
final totalAttachmentSizeProvider = Provider<String>((ref) {
  final composeState = ref.watch(mailComposeProvider);
  return composeState.totalAttachmentSizeFormatted;
});

/// Has attachments provider
final hasAttachmentsProvider = Provider<bool>((ref) {
  final composeState = ref.watch(mailComposeProvider);
  return composeState.hasAttachments;
});

// ========== REPLY UTILITY PROVIDERS ==========

/// Current reply form validity provider
final replyFormValidityProvider = Provider<bool>((ref) {
  final replyState = ref.watch(mailReplyProvider);
  return replyState.isValid;
});

/// Can send reply provider
final canSendReplyProvider = Provider<bool>((ref) {
  final replyState = ref.watch(mailReplyProvider);
  return replyState.canSend;
});

/// Reply validation summary provider
final replyValidationSummaryProvider = Provider<String>((ref) {
  final replyNotifier = ref.read(mailReplyProvider.notifier);
  return replyNotifier.getValidationSummary();
});

/// Reply loading state provider
final replyLoadingProvider = Provider<bool>((ref) {
  final replyState = ref.watch(mailReplyProvider);
  return replyState.isSending;
});

/// Reply error provider
final replyErrorProvider = Provider<String?>((ref) {
  final replyState = ref.watch(mailReplyProvider);
  return replyState.error;
});

/// Reply last result provider
final replyLastResultProvider = Provider<ComposeResult?>((ref) {
  final replyState = ref.watch(mailReplyProvider);
  return replyState.lastResult;
});

/// Reply recipient count provider
final replyRecipientCountProvider = Provider<int>((ref) {
  final replyState = ref.watch(mailReplyProvider);
  return replyState.recipientCount;
});

/// Reply attachment count provider
final replyAttachmentCountProvider = Provider<int>((ref) {
  final replyState = ref.watch(mailReplyProvider);
  return replyState.attachments.length;
});

/// Reply total attachment size provider
final replyTotalAttachmentSizeProvider = Provider<String>((ref) {
  final replyState = ref.watch(mailReplyProvider);
  return replyState.totalAttachmentSizeFormatted;
});

/// Reply has attachments provider
final replyHasAttachmentsProvider = Provider<bool>((ref) {
  final replyState = ref.watch(mailReplyProvider);
  return replyState.hasAttachments;
});

/// Can switch to reply all provider
final canSwitchToReplyAllProvider = Provider<bool>((ref) {
  final replyState = ref.watch(mailReplyProvider);
  return replyState.canSwitchToReplyAll;
});

/// Current reply type provider
final currentReplyTypeProvider = Provider<ReplyType>((ref) {
  final replyState = ref.watch(mailReplyProvider);
  return replyState.replyType;
});

/// Original mail provider
final originalMailProvider = Provider<MailDetail?>((ref) {
  final replyState = ref.watch(mailReplyProvider);
  return replyState.originalMail;
});

// ========== MAIN MAIL PROVIDER (UNCHANGED) ==========

/// Main Mail State Provider
final mailProvider = StateNotifierProvider<MailNotifier, MailState>((ref) {
  final getMailsUseCase = ref.read(getMailsUseCaseProvider);
  final mailActionsUseCase = ref.read(mailActionsUseCaseProvider);

  return MailNotifier(getMailsUseCase, mailActionsUseCase);
});

// ========== CURRENT STATE PROVIDERS (UNCHANGED) ==========

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

// ========== MAIL DETAIL PROVIDERS (UNCHANGED) ==========

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

/// Specific mail loading provider factory
Provider<bool> mailLoadingProvider(String mailId) {
  return Provider<bool>((ref) {
    final state = ref.watch(mailDetailProvider);
    return state.isLoadingMail(mailId);
  });
}

/// Specific mail loaded provider factory
Provider<bool> mailLoadedProvider(String mailId) {
  return Provider<bool>((ref) {
    final state = ref.watch(mailDetailProvider);
    return state.isMailLoaded(mailId);
  });
}

// ========== 🆕 MAIL SELECTION PROVIDERS ==========

/// Mail Selection State Provider
final mailSelectionProvider = StateNotifierProvider<MailSelectionNotifier, MailSelectionState>((ref) {
  return MailSelectionNotifier();
});

// ========== SELECTION UTILITY PROVIDERS ==========

/// Selected mail count provider
final selectedMailCountProvider = Provider<int>((ref) {
  final selectionState = ref.watch(mailSelectionProvider);
  return selectionState.selectedCount;
});

/// Has selection provider
final hasSelectionProvider = Provider<bool>((ref) {
  final selectionState = ref.watch(mailSelectionProvider);
  return selectionState.hasSelection;
});

/// Is all selected provider
final isAllSelectedProvider = Provider<bool>((ref) {
  final selectionState = ref.watch(mailSelectionProvider);
  return selectionState.isAllSelected;
});

/// Is partially selected provider
final isPartiallySelectedProvider = Provider<bool>((ref) {
  final selectionState = ref.watch(mailSelectionProvider);
  return selectionState.isPartiallySelected;
});

/// Selection percentage provider
final selectionPercentageProvider = Provider<double>((ref) {
  final selectionState = ref.watch(mailSelectionProvider);
  return selectionState.selectionPercentage;
});

/// Selected mail IDs provider
final selectedMailIdsProvider = Provider<List<String>>((ref) {
  final selectionState = ref.watch(mailSelectionProvider);
  return selectionState.selectedMailIdsList;
});

/// Is select all active provider
final isSelectAllActiveProvider = Provider<bool>((ref) {
  final selectionState = ref.watch(mailSelectionProvider);
  return selectionState.isSelectAllActive;
});

/// Selection summary provider (for debugging/UI)
final selectionSummaryProvider = Provider<String>((ref) {
  final selectionNotifier = ref.read(mailSelectionProvider.notifier);
  return selectionNotifier.getSelectionSummary();
});

/// Specific mail selection provider factory
/// Usage: ref.watch(mailSelectedProvider('mail_id_123'))
Provider<bool> mailSelectedProvider(String mailId) {
  return Provider<bool>((ref) {
    final selectionState = ref.watch(mailSelectionProvider);
    return selectionState.isMailSelected(mailId);
  });
}




// ========== MAIL DETAIL STATISTICS (UNCHANGED) ==========

/// Mail detail statistics provider - FIXED VERSION
final mailDetailStatsProvider = Provider<MailDetailStats?>((ref) {
  final mailDetail = ref.watch(currentMailDetailProvider);
  if (mailDetail == null) return null;

  return MailDetailStats(
    id: mailDetail.id,
    senderName: mailDetail.senderName,
    subject: mailDetail.subject,
    hasHtmlContent: mailDetail.htmlContent.isNotEmpty,
    isTextOnly:
        mailDetail.htmlContent.isEmpty && mailDetail.textContent.isNotEmpty,
    hasAttachments: mailDetail.hasAttachments,
    attachmentCount: mailDetail.attachmentCount,
    sizeBytes: mailDetail.sizeBytes,
    formattedSize: _formatSize(mailDetail.sizeBytes),
    isLargeEmail: (mailDetail.sizeBytes ?? 0) > (1024 * 1024),
    priority: mailDetail.priority,
    labelCount: mailDetail.labels.length,
    recipientCount:
        mailDetail.recipients.length +
        mailDetail.ccRecipients.length +
        mailDetail.bccRecipients.length,
    isPartOfThread:
        mailDetail.threadId != null && mailDetail.threadId!.isNotEmpty,
  );
});

// Helper function - size formatting
String _formatSize(int? sizeBytes) {
  if (sizeBytes == null || sizeBytes == 0) return '0B';

  if (sizeBytes < 1024) return '${sizeBytes}B';
  if (sizeBytes < 1024 * 1024)
    return '${(sizeBytes / 1024).toStringAsFixed(1)}KB';
  return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)}MB';
}

// ========== DATA CLASSES (UNCHANGED) ==========

/// Mail detail statistics - Updated class
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
    required this.sizeBytes,
    required this.formattedSize,
    required this.isLargeEmail,
    required this.priority,
    required this.labelCount,
    required this.recipientCount,
    required this.isPartOfThread,
  });

  @override
  String toString() {
    return 'MailDetailStats(id: $id, hasAttachments: $hasAttachments, attachmentCount: $attachmentCount, isLargeEmail: $isLargeEmail)';
  }
}