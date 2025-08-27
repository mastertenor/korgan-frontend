// lib/src/features/mail/presentation/providers/mail_reply_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/mail_recipient.dart';
import '../../domain/entities/attachment_upload.dart';
import '../../domain/entities/compose_result.dart';
import '../../domain/entities/mail_compose_request.dart';
import '../../domain/entities/mail_detail.dart';
import '../../domain/enums/reply_type.dart';
import '../../domain/usecases/send_mail_usecase.dart';
import '../utils/reply_html_builder.dart';
import '../utils/subject_prefix_utils.dart';


/// Mail reply state
class MailReplyState {
  // ========== CORE REPLY FIELDS ==========
  final bool isLoading;
  final bool isSending;
  final MailRecipient? from;
  final List<MailRecipient> to;
  final List<MailRecipient> cc;
  final List<MailRecipient> bcc;
  final String subject;
  final String textContent;
  final String? htmlContent;
  final List<AttachmentUpload> attachments;

  // ========== REPLY-SPECIFIC FIELDS ==========
  final MailDetail? originalMail;
  final ReplyType replyType;
  final bool showCc;
  final bool showBcc;
  final bool isHtmlMode;

  // ========== UI STATE ==========
  final ComposeResult? lastResult;
  final String? error;
  final List<String> validationErrors;

  // ========== DRAFT FIELDS ==========
  final bool isDraft;
  final String? draftId;
  final DateTime? lastSaved;

  // 🆕 FORWARD LOADING STATE
  final bool isDownloadingAttachments;
  final double attachmentDownloadProgress;

  const MailReplyState({
    this.isLoading = false,
    this.isSending = false,
    this.from,
    this.to = const [],
    this.cc = const [],
    this.bcc = const [],
    this.subject = '',
    this.textContent = '',
    this.htmlContent,
    this.attachments = const [],
    this.originalMail,
    this.replyType = ReplyType.reply,
    this.showCc = false,
    this.showBcc = false,
    this.isHtmlMode = false,
    this.lastResult,
    this.error,
    this.validationErrors = const [],
    this.isDraft = false,
    this.draftId,
    this.lastSaved,
    // 🆕 NEW FIELDS
    this.isDownloadingAttachments = false,
    this.attachmentDownloadProgress = 0.0,
  });

  // ========== FACTORY CONSTRUCTORS ==========

  /// Initial empty state
  factory MailReplyState.initial() {
    return const MailReplyState();
  }

  /// Initialize for reply
  factory MailReplyState.forReply({
    required MailRecipient from,
    required MailDetail originalMail,
    required ReplyType replyType,
    List<AttachmentUpload>? preDownloadedAttachments, // 🆕 NEW PARAMETER
  }) {
    // Determine recipients based on reply type
    final List<MailRecipient> toRecipients;
    final List<MailRecipient> ccRecipients;
    final List<AttachmentUpload> replyAttachments;
    
    switch (replyType) {
      case ReplyType.reply:
        // Only reply to sender
        toRecipients = [
          MailRecipient(
            email: originalMail.senderEmail,
            name: originalMail.senderName,
          )
        ];
        ccRecipients = [];
        replyAttachments = [];
        break;
        
      case ReplyType.replyAll:
        // Reply to sender + all recipients (except current user)
        toRecipients = [
          MailRecipient(
            email: originalMail.senderEmail,
            name: originalMail.senderName,
          )
        ];
        
        // Add original TO recipients (exclude current user)
        final originalToRecipients = originalMail.recipients
            .where((email) => email != from.email)
            .map((email) => MailRecipient.fromEmail(email))
            .toList();
            
        // Add original CC recipients (exclude current user)  
        final originalCcRecipients = originalMail.ccRecipients
            .where((email) => email != from.email)
            .map((email) => MailRecipient.fromEmail(email))
            .toList();
            
        ccRecipients = [...originalToRecipients, ...originalCcRecipients];
        replyAttachments = [];
        break;
        
      case ReplyType.forward:
        // Forward has empty recipients initially
        toRecipients = [];
        ccRecipients = [];
        // 🆕 Use pre-downloaded attachments if available, otherwise placeholder
        replyAttachments = preDownloadedAttachments ?? 
                          _createPlaceholderAttachments(originalMail);
        break;
    }

    // ========== UPDATED SUBJECT GENERATION ==========
    // Generate subject with appropriate prefix - RFC 5322 compliant
    final String replySubject = SubjectPrefixUtils.generateSubjectForReply(
      originalSubject: originalMail.subject,
      replyType: replyType,
    );

    return MailReplyState(
      from: from,
      to: toRecipients,
      cc: ccRecipients,
      subject: replySubject,
      originalMail: originalMail,
      replyType: replyType,
      showCc: ccRecipients.isNotEmpty,
      textContent: _generateReplyContent(originalMail, replyType),
      attachments: replyAttachments,
    );
  }

  /// Generate reply content based on original mail and reply type
  static String _generateReplyContent(MailDetail originalMail, ReplyType replyType) {
    final String prefix;
    switch (replyType) {
      case ReplyType.reply:
      case ReplyType.replyAll:
        prefix = '\n\n--- Orijinal Mesaj ---';
        break;
      case ReplyType.forward:
        prefix = '\n\n--- İletilen Mesaj ---';
        break;
    }
    
    final originalContent = originalMail.safeTextContent;
    return '$prefix\nGönderen: ${originalMail.senderName} <${originalMail.senderEmail}>\nKonu: ${originalMail.subject}\nTarih: ${originalMail.receivedDate}\n\n$originalContent';
  }

  /// 🆕 Create placeholder attachments for forward (when content not yet downloaded)
  static List<AttachmentUpload> _createPlaceholderAttachments(MailDetail originalMail) {
    print('=== CREATING PLACEHOLDER ATTACHMENTS ===');
    print('Original mail has ${originalMail.attachments.length} attachments');
    
    if (!originalMail.hasAttachments) return [];
    
    return originalMail.attachments.map((mailAttachment) {
      print('Creating placeholder for: ${mailAttachment.filename}');
      return AttachmentUpload.fromMailAttachment(
        attachmentId: mailAttachment.id,
        filename: mailAttachment.filename,
        mimeType: mailAttachment.mimeType,
        content: '', // 🆕 Empty content - will be downloaded later
        disposition: mailAttachment.isInline ? 'inline' : 'attachment',
        contentId: mailAttachment.contentId,
        isPlaceholder: true, // 🆕 Mark as placeholder
      );
    }).toList();
  }

  // ========== GETTERS ==========

  /// Check if reply form is valid
  bool get isValid {
    return from != null &&
           to.isNotEmpty &&
           subject.isNotEmpty &&
           (textContent.isNotEmpty || (htmlContent != null && htmlContent!.isNotEmpty)) &&
           !hasValidationErrors;
  }

  /// Check if there are validation errors
  bool get hasValidationErrors => validationErrors.isNotEmpty;

  /// Check if ready to send (valid and not loading)
  bool get canSend => isValid && !isSending && !isLoading && !isDownloadingAttachments;

  /// Get total recipient count
  int get recipientCount => to.length + cc.length + bcc.length;

  /// Check if has attachments
  bool get hasAttachments => attachments.isNotEmpty;

  /// 🆕 Check if has placeholder attachments (not yet downloaded)
  bool get hasPlaceholderAttachments {
    return attachments.any((att) => att.isPlaceholder);
  }

  /// Get total attachment size in bytes
  int get totalAttachmentSize {
    return attachments
        .map((attachment) => attachment.estimatedSizeBytes)
        .fold(0, (a, b) => a + b);
  }

  /// Get formatted attachment size
  String get totalAttachmentSizeFormatted {
    final size = totalAttachmentSize;
    if (size < 1024) return '${size}B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)}KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  /// Can switch to reply all (only if original mail has multiple recipients)
  bool get canSwitchToReplyAll {
    if (originalMail == null) return false;
    
    final totalOriginalRecipients = originalMail!.recipients.length +
                                   originalMail!.ccRecipients.length;
    return totalOriginalRecipients > 1;
  }

  // ========== COPY WITH ==========

  /// Copy with updated values
  MailReplyState copyWith({
    bool? isLoading,
    bool? isSending,
    MailRecipient? from,
    List<MailRecipient>? to,
    List<MailRecipient>? cc,
    List<MailRecipient>? bcc,
    String? subject,
    String? textContent,
    String? htmlContent,
    List<AttachmentUpload>? attachments,
    MailDetail? originalMail,
    ReplyType? replyType,
    bool? showCc,
    bool? showBcc,
    bool? isHtmlMode,
    ComposeResult? lastResult,
    String? error,
    List<String>? validationErrors,
    bool? isDraft,
    String? draftId,
    DateTime? lastSaved,
    // 🆕 NEW PARAMETERS
    bool? isDownloadingAttachments,
    double? attachmentDownloadProgress,
  }) {
    return MailReplyState(
      isLoading: isLoading ?? this.isLoading,
      isSending: isSending ?? this.isSending,
      from: from ?? this.from,
      to: to ?? this.to,
      cc: cc ?? this.cc,
      bcc: bcc ?? this.bcc,
      subject: subject ?? this.subject,
      textContent: textContent ?? this.textContent,
      htmlContent: htmlContent ?? this.htmlContent,
      attachments: attachments ?? this.attachments,
      originalMail: originalMail ?? this.originalMail,
      replyType: replyType ?? this.replyType,
      showCc: showCc ?? this.showCc,
      showBcc: showBcc ?? this.showBcc,
      isHtmlMode: isHtmlMode ?? this.isHtmlMode,
      lastResult: lastResult ?? this.lastResult,
      error: error,
      validationErrors: validationErrors ?? this.validationErrors,
      isDraft: isDraft ?? this.isDraft,
      draftId: draftId ?? this.draftId,
      lastSaved: lastSaved ?? this.lastSaved,
      // 🆕 NEW FIELDS
      isDownloadingAttachments: isDownloadingAttachments ?? this.isDownloadingAttachments,
      attachmentDownloadProgress: attachmentDownloadProgress ?? this.attachmentDownloadProgress,
    );
  }

  /// Create MailComposeRequest from current state
  MailComposeRequest toComposeRequest() {
    if (from == null) {
      throw StateError('From recipient is required');
    }

    return MailComposeRequest(
      from: from!,
      to: to,
      cc: cc.isNotEmpty ? cc : null,
      bcc: bcc.isNotEmpty ? bcc : null,
      subject: subject,
      text: textContent,
      html: htmlContent,
      attachments: attachments.isNotEmpty ? attachments : null,
      isDraft: isDraft,
      draftId: draftId,
      lastSaved: lastSaved,
    );
  }

  @override
  String toString() {
    return 'MailReplyState('
           'isLoading: $isLoading, '
           'isSending: $isSending, '
           'replyType: $replyType, '
           'from: ${from?.email}, '
           'to: ${to.length}, '
           'subject: "$subject", '
           'isValid: $isValid, '
           'isDownloadingAttachments: $isDownloadingAttachments'
           ')';
  }
}

/// Mail reply state notifier
class MailReplyNotifier extends StateNotifier<MailReplyState> {
  final SendMailUseCase _sendMailUseCase;

  MailReplyNotifier(this._sendMailUseCase) : super(MailReplyState.initial());

  // ========== INITIALIZATION ==========

  /// Clear all state (reset to initial)
  void clearAll() {
    state = MailReplyState.initial();
  }

  /// Initialize for reply
  void initializeForReply({
    required MailRecipient from,
    required MailDetail originalMail,
    required ReplyType replyType,
    List<AttachmentUpload>? preDownloadedAttachments, // 🆕 NEW PARAMETER
  }) {
    state = MailReplyState.forReply(
      from: from,
      originalMail: originalMail,
      replyType: replyType,
      preDownloadedAttachments: preDownloadedAttachments, // 🆕 PASS PARAMETER
    );
  }

  /// 🆕 Initialize for forward with attachment downloading
  void initializeForForward({
    required MailRecipient from,
    required MailDetail originalMail,
    List<AttachmentUpload>? preDownloadedAttachments,
  }) {
    // Use the enhanced initializeForReply method
    initializeForReply(
      from: from,
      originalMail: originalMail,
      replyType: ReplyType.forward,
      preDownloadedAttachments: preDownloadedAttachments,
    );
  }

  /// Switch reply type (reply <-> replyAll)
  void switchReplyType(ReplyType newReplyType) {
    if (state.originalMail == null || state.from == null) return;
    
    // Re-initialize with new reply type
    initializeForReply(
      from: state.from!,
      originalMail: state.originalMail!,
      replyType: newReplyType,
    );
  }

  // 🆕 ATTACHMENT DOWNLOAD METHODS

  /// Set attachment download progress
  void setAttachmentDownloadProgress(double progress) {
    state = state.copyWith(
      attachmentDownloadProgress: progress,
    );
  }

  /// Start attachment download
  void startAttachmentDownload() {
    state = state.copyWith(
      isDownloadingAttachments: true,
      attachmentDownloadProgress: 0.0,
      error: null,
    );
  }

  /// Complete attachment download
  void completeAttachmentDownload(List<AttachmentUpload> downloadedAttachments) {
    state = state.copyWith(
      isDownloadingAttachments: false,
      attachmentDownloadProgress: 1.0,
      attachments: downloadedAttachments,
      error: null,
    );
  }

  /// Handle attachment download error
  void setAttachmentDownloadError(String error) {
    state = state.copyWith(
      isDownloadingAttachments: false,
      attachmentDownloadProgress: 0.0,
      error: error,
    );
  }

  // ========== FORM UPDATES ==========

  /// Update subject
  void updateSubject(String subject) {
    state = state.copyWith(
      subject: subject,
      error: null,
      validationErrors: [],
    );
  }

  /// Update text content
  void updateTextContent(String content) {
    state = state.copyWith(
      textContent: content,
      error: null,
      validationErrors: [],
    );
  }

  /// Update HTML content
  void updateHtmlContent(String? content) {
    state = state.copyWith(
      htmlContent: content,
      error: null,
      validationErrors: [],
    );
  }

  // ========== RECIPIENTS MANAGEMENT ==========

  /// Add TO recipient
  void addToRecipient(MailRecipient recipient) {
    final updatedTo = [...state.to, recipient];
    state = state.copyWith(
      to: updatedTo,
      error: null,
      validationErrors: [],
    );
  }

  /// Remove TO recipient
  void removeToRecipient(int index) {
    if (index >= 0 && index < state.to.length) {
      final updatedTo = [...state.to];
      updatedTo.removeAt(index);
      state = state.copyWith(to: updatedTo);
    }
  }

  /// Show/hide CC field
  void toggleCcVisibility() {
    state = state.copyWith(showCc: !state.showCc);
  }

  /// Add CC recipient
  void addCcRecipient(MailRecipient recipient) {
    final updatedCc = [...state.cc, recipient];
    state = state.copyWith(
      cc: updatedCc,
      showCc: true,
      error: null,
      validationErrors: [],
    );
  }

  /// Remove CC recipient
  void removeCcRecipient(int index) {
    if (index >= 0 && index < state.cc.length) {
      final updatedCc = [...state.cc];
      updatedCc.removeAt(index);
      state = state.copyWith(cc: updatedCc);
    }
  }

  /// Show/hide BCC field
  void toggleBccVisibility() {
    state = state.copyWith(showBcc: !state.showBcc);
  }

  /// Add BCC recipient
  void addBccRecipient(MailRecipient recipient) {
    final updatedBcc = [...state.bcc, recipient];
    state = state.copyWith(
      bcc: updatedBcc,
      showBcc: true,
      error: null,
      validationErrors: [],
    );
  }

  /// Remove BCC recipient
  void removeBccRecipient(int index) {
    if (index >= 0 && index < state.bcc.length) {
      final updatedBcc = [...state.bcc];
      updatedBcc.removeAt(index);
      state = state.copyWith(bcc: updatedBcc);
    }
  }

  // ========== ATTACHMENTS MANAGEMENT ==========

  /// Add attachment
  void addAttachment(AttachmentUpload attachment) {
    final updatedAttachments = [...state.attachments, attachment];
    state = state.copyWith(
      attachments: updatedAttachments,
      error: null,
      validationErrors: [],
    );
  }

  /// Remove attachment
  void removeAttachment(int index) {
    if (index >= 0 && index < state.attachments.length) {
      final updatedAttachments = [...state.attachments];
      updatedAttachments.removeAt(index);
      state = state.copyWith(attachments: updatedAttachments);
    }
  }

  // ========== MAIL OPERATIONS ==========

  /// Send reply
  Future<bool> sendReply() async {
    if (!state.canSend) {
      return false;
    }

    state = state.copyWith(
      isSending: true,
      error: null,
      validationErrors: [],
    );

    try {
      final combinedHtml = buildCombinedHtmlContent();

      final composeRequest = state.toComposeRequest();
      final updatedRequest = composeRequest.copyWith(html: combinedHtml);

      final params = SendMailParams(request: updatedRequest);
      
      final result = await _sendMailUseCase.call(params);
      
      result.when(
        success: (composeResult) {
          state = state.copyWith(
            isSending: false,
            lastResult: composeResult,
          );
        },
        failure: (failure) {
          state = state.copyWith(
            isSending: false,
            error: failure.message,
          );
        },
      );
      
      return result.isSuccess;
    } catch (e) {
      state = state.copyWith(
        isSending: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Get validation summary
  String getValidationSummary() {
    final errors = <String>[];
    
    if (state.from == null) {
      errors.add('Gönderen gerekli');
    }
    
    if (state.to.isEmpty) {
      errors.add('En az bir alıcı gerekli');
    }
    
    if (state.subject.isEmpty) {
      errors.add('Konu gerekli');
    }
    
    if (state.textContent.isEmpty && (state.htmlContent?.isEmpty ?? true)) {
      errors.add('İçerik gerekli');
    }

    // 🆕 Check for placeholder attachments
    if (state.hasPlaceholderAttachments) {
      errors.add('Ekler henüz indirilmedi');
    }
    
    return errors.isEmpty ? 'Form geçerli' : errors.join(', ');
  }

/// Build combined HTML content (DEBUG VERSION)
String? buildCombinedHtmlContent() {
  // Check if we have required data
  if (state.originalMail == null) {
    return null;
  }

  // User must have written something
  if (state.textContent.trim().isEmpty) {
    return null;
  }

  // Validate using HTML builder
  if (!ReplyHtmlBuilder.canBuildReply(
    userReplyText: state.textContent,
    originalMail: state.originalMail!,
  )) {
    return null;
  }

  // Build combined HTML
  return ReplyHtmlBuilder.buildReplyHtml(
    userReplyText: state.textContent,
    originalMail: state.originalMail!,
  );
}  /// Build plain text fallback
  String buildCombinedPlainText() {
    // If no original mail, return user text only
    if (state.originalMail == null) {
      return state.textContent;
    }

    // Build combined plain text
    return ReplyHtmlBuilder.buildReplyPlainText(
      userReplyText: state.textContent,
      originalMail: state.originalMail!,
    );
  }

  /// Get estimated email size
  int getEstimatedEmailSize() {
    if (state.originalMail == null) {
      return state.textContent.length;
    }

    return ReplyHtmlBuilder.getEstimatedHtmlSize(
      userReplyText: state.textContent,
      originalMail: state.originalMail!,
    );
  }

}