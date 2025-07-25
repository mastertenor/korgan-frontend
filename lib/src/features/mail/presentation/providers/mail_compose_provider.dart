// lib/src/features/mail/presentation/providers/mail_compose_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/mail_compose_request.dart';
import '../../domain/entities/mail_recipient.dart';
import '../../domain/entities/attachment_upload.dart';
import '../../domain/entities/compose_result.dart';
import '../../domain/usecases/send_mail_usecase.dart';

/// State class for mail compose functionality
class MailComposeState {
  /// Loading states
  final bool isLoading;
  final bool isSending;

  /// Form data
  final MailRecipient? from;
  final List<MailRecipient> to;
  final List<MailRecipient> cc;
  final List<MailRecipient> bcc;
  final String subject;
  final String textContent;
  final String? htmlContent;
  final List<AttachmentUpload> attachments;

  /// UI states
  final bool showCc;
  final bool showBcc;
  final bool isHtmlMode;

  /// Result states
  final ComposeResult? lastResult;
  final String? error;
  final List<String> validationErrors;

  /// Draft support
  final bool isDraft;
  final String? draftId;
  final DateTime? lastSaved;

  const MailComposeState({
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
    this.showCc = false,
    this.showBcc = false,
    this.isHtmlMode = false,
    this.lastResult,
    this.error,
    this.validationErrors = const [],
    this.isDraft = false,
    this.draftId,
    this.lastSaved,
  });

  /// Create initial state
  factory MailComposeState.initial() {
    return const MailComposeState();
  }

  /// Create state for reply
  factory MailComposeState.forReply({
    required MailRecipient from,
    required MailRecipient replyTo,
    required String originalSubject,
  }) {
    return MailComposeState(
      from: from,
      to: [replyTo],
      subject: originalSubject.startsWith('Re: ') 
          ? originalSubject 
          : 'Re: $originalSubject',
    );
  }

  /// Create state for forward
  factory MailComposeState.forForward({
    required MailRecipient from,
    required String originalSubject,
    required String originalContent,
  }) {
    return MailComposeState(
      from: from,
      subject: originalSubject.startsWith('Fwd: ') 
          ? originalSubject 
          : 'Fwd: $originalSubject',
      textContent: '\n\n--- Forwarded Message ---\n$originalContent',
    );
  }

  /// Copy with updated values
  MailComposeState copyWith({
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
    bool? showCc,
    bool? showBcc,
    bool? isHtmlMode,
    ComposeResult? lastResult,
    String? error,
    List<String>? validationErrors,
    bool? isDraft,
    String? draftId,
    DateTime? lastSaved,
  }) {
    return MailComposeState(
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
      showCc: showCc ?? this.showCc,
      showBcc: showBcc ?? this.showBcc,
      isHtmlMode: isHtmlMode ?? this.isHtmlMode,
      lastResult: lastResult ?? this.lastResult,
      error: error,
      validationErrors: validationErrors ?? this.validationErrors,
      isDraft: isDraft ?? this.isDraft,
      draftId: draftId ?? this.draftId,
      lastSaved: lastSaved ?? this.lastSaved,
    );
  }

  /// Check if compose form is valid
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
  bool get canSend => isValid && !isSending && !isLoading;

  /// Get total recipient count
  int get recipientCount => to.length + cc.length + bcc.length;

  /// Check if has attachments
  bool get hasAttachments => attachments.isNotEmpty;

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
    return 'MailComposeState('
           'isLoading: $isLoading, '
           'isSending: $isSending, '
           'from: ${from?.email}, '
           'to: ${to.length}, '
           'subject: "$subject", '
           'isValid: $isValid'
           ')';
  }
}

/// Mail compose state notifier
class MailComposeNotifier extends StateNotifier<MailComposeState> {
  final SendMailUseCase _sendMailUseCase;

  MailComposeNotifier(this._sendMailUseCase) : super(MailComposeState.initial());

  // ========== INITIALIZATION ==========

/// Clear all state (reset to initial)
void clearAll() {
  state = MailComposeState.initial();
}

  /// Initialize with sender
  void initializeWithSender(MailRecipient sender) {
    state = state.copyWith(from: sender);
  }

  /// Initialize for reply
  void initializeForReply({
    required MailRecipient from,
    required MailRecipient replyTo,
    required String originalSubject,
  }) {
    state = MailComposeState.forReply(
      from: from,
      replyTo: replyTo,
      originalSubject: originalSubject,
    );
  }

  /// Initialize for forward
  void initializeForForward({
    required MailRecipient from,
    required String originalSubject,
    required String originalContent,
  }) {
    state = MailComposeState.forForward(
      from: from,
      originalSubject: originalSubject,
      originalContent: originalContent,
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
  void updateHtmlContent(String? htmlContent) {
    state = state.copyWith(
      htmlContent: htmlContent,
      error: null,
      validationErrors: [],
    );
  }

  /// Toggle HTML mode
  void toggleHtmlMode() {
    state = state.copyWith(isHtmlMode: !state.isHtmlMode);
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

  /// Update TO recipient
  void updateToRecipient(int index, MailRecipient recipient) {
    if (index >= 0 && index < state.to.length) {
      final updatedTo = [...state.to];
      updatedTo[index] = recipient;
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

  /// Send mail
  Future<bool> sendMail() async {
    if (!state.canSend) {
      return false;
    }

    state = state.copyWith(
      isSending: true,
      error: null,
      validationErrors: [],
    );

    try {
      final composeRequest = state.toComposeRequest();
      final params = SendMailParams(request: composeRequest);
      
      final result = await _sendMailUseCase.call(params);

      return result.when(
        success: (composeResult) {
          state = state.copyWith(
            isSending: false,
            lastResult: composeResult,
          );
          return true;
        },
        failure: (failure) {
          state = state.copyWith(
            isSending: false,
            error: failure.message,
            validationErrors: _extractValidationErrors(failure),
          );
          return false;
        },
      );
    } catch (e) {
      state = state.copyWith(
        isSending: false,
        error: 'Beklenmeyen hata: ${e.toString()}',
      );
      return false;
    }
  }

  /// Get validation summary
  String getValidationSummary() {
    if (!state.isValid) {
      try {
        final composeRequest = state.toComposeRequest();
        return _sendMailUseCase.getValidationSummary(composeRequest);
      } catch (e) {
        return '⚠️ Form eksik: ${e.toString()}';
      }
    }
    return '✅ Mail gönderilmeye hazır';
  }

  /// Save as draft (placeholder for future implementation)
  Future<void> saveDraft() async {
    // TODO: Implement draft saving
    state = state.copyWith(
      isDraft: true,
      lastSaved: DateTime.now(),
    );
  }

  /// Clear all data
  void clear() {
    state = MailComposeState.initial();
  }

  // ========== HELPER METHODS ==========

  /// Extract validation errors from failure
  List<String> _extractValidationErrors(Object failure) {
    // This would extract specific validation errors from the failure
    // For now, return empty list
    return [];
  }
}