// lib/src/features/mail/presentation/widgets/mobile/compose/reply_recipients_subject_input_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/entities/mail_recipient.dart';
import '../../../../domain/enums/reply_type.dart';
import '../../../providers/mail_providers.dart';
import '../../../providers/mail_reply_provider.dart';

/// Reply recipients input widget with reply type selection
///
/// Features:
/// - Non-editable "From" field 
/// - Reply type selection (Reply vs Reply All)
/// - Pre-filled TO/CC recipients based on original mail
/// - Collapsible CC/BCC fields with arrow indicator
/// - Full-width layout following original design
/// - Theme-based colors and equal height for all fields
class ReplyRecipientsSubjectInputWidget extends ConsumerStatefulWidget {
  final String fromEmail;
  final String fromName;

  const ReplyRecipientsSubjectInputWidget({
    super.key,
    required this.fromEmail,
    required this.fromName,
  });

  @override
  ConsumerState<ReplyRecipientsSubjectInputWidget> createState() => 
      _ReplyRecipientsSubjectInputWidgetState();
}

class _ReplyRecipientsSubjectInputWidgetState 
    extends ConsumerState<ReplyRecipientsSubjectInputWidget> {
  late TextEditingController _toController;
  late TextEditingController _ccController;
  late TextEditingController _bccController;
  late TextEditingController _subjectController;
  
  late FocusNode _toFocusNode;
  late FocusNode _ccFocusNode;
  late FocusNode _bccFocusNode;
  late FocusNode _subjectFocusNode;

  bool _isExpanded = false; // CC/BCC alanlarının görünürlüğü

  @override
  void initState() {
    super.initState();
    _toController = TextEditingController();
    _ccController = TextEditingController();
    _bccController = TextEditingController();
    _subjectController = TextEditingController();
    
    _toFocusNode = FocusNode();
    _ccFocusNode = FocusNode();
    _bccFocusNode = FocusNode();
    _subjectFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _toController.dispose();
    _ccController.dispose();
    _bccController.dispose();
    _subjectController.dispose();
    
    _toFocusNode.dispose();
    _ccFocusNode.dispose();
    _bccFocusNode.dispose();
    _subjectFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final replyState = ref.watch(mailReplyProvider);
    
    return Container(
      width: double.infinity,
      color: theme.scaffoldBackgroundColor,
      child: Column(
        children: [
          // Reply Type Selection - UNIQUE TO REPLY
          _buildReplyTypeSelection(theme, replyState),
          
          const Divider(height: 1),
          
          // Kimden alanı (non-editable, no arrow)
          _buildFromField(theme),
          
          const Divider(height: 1),
          
          // Alıcı alanı
          _buildToField(theme, replyState),
          
          // CC/BCC alanları (collapsible)
          if (_isExpanded || replyState.showCc || replyState.showBcc) ...[
            if (replyState.showCc || _isExpanded) ...[
              const Divider(height: 1),
              _buildCcField(theme, replyState),
            ],
            
            if (replyState.showBcc || _isExpanded) ...[
              const Divider(height: 1),
              _buildBccField(theme, replyState),
            ],
          ],
          
          const Divider(height: 1),
          
          // Konu alanı
          _buildSubjectField(theme, replyState),
          const Divider(height: 1),
        ],
      ),
    );
  }

  /// Build reply type selection - UNIQUE FEATURE
  Widget _buildReplyTypeSelection(ThemeData theme, MailReplyState state) {
    // Don't show if can't switch to reply all
    if (!state.canSwitchToReplyAll) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              'Tür',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                // Reply button
                _buildReplyTypeButton(
                  theme: theme,
                  replyType: ReplyType.reply,
                  currentType: state.replyType,
                  text: 'Yanıtla',
                  icon: Icons.reply,
                ),
                
                const SizedBox(width: 12),
                
                // Reply All button
                _buildReplyTypeButton(
                  theme: theme,
                  replyType: ReplyType.replyAll,
                  currentType: state.replyType,
                  text: 'Tümünü Yanıtla',
                  icon: Icons.reply_all,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build reply type button
  Widget _buildReplyTypeButton({
    required ThemeData theme,
    required ReplyType replyType,
    required ReplyType currentType,
    required String text,
    required IconData icon,
  }) {
    final isSelected = replyType == currentType;
    
    return GestureDetector(
      onTap: () {
        if (!isSelected) {
          ref.read(mailReplyProvider.notifier).switchReplyType(replyType);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected 
              ? theme.colorScheme.primary
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected 
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withOpacity(0.5),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected 
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSurface,
            ),
            const SizedBox(width: 6),
            Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isSelected 
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build non-editable from field
  Widget _buildFromField(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              'Kimden',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              '${widget.fromName} <${widget.fromEmail}>',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          // No arrow icon for "From" field as specified
        ],
      ),
    );
  }

  /// Build to field
  Widget _buildToField(ThemeData theme, MailReplyState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              'Alıcı',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Existing TO recipients - ✅ DÜZELTME: readOnly: false
                if (state.to.isNotEmpty) ...[
                  _buildRecipientChips(state.to, RecipientType.to, theme, readOnly: false),
                  const SizedBox(height: 8),
                ],
                
                // TO input field - for additional recipients
                TextField(
                  controller: _toController,
                  focusNode: _toFocusNode,
                  decoration: InputDecoration(
                    hintText: state.to.isEmpty ? 'Email adresi' : 'Başka alıcı ekle',
                    hintStyle: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: theme.textTheme.bodyMedium,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (value) => _addRecipient(value, RecipientType.to),
                  onChanged: (value) => setState(() {}),
                ),
              ],
            ),
          ),
          // Collapsible arrow for CC/BCC
          SizedBox(
            height: 16,
            width: 16,
            child: IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: Icon(
                _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              onPressed: () => setState(() => _isExpanded = !_isExpanded),
            ),
          ),
        ],
      ),
    );
  }

  /// Build cc field
  Widget _buildCcField(ThemeData theme, MailReplyState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              'Cc',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Existing CC recipients - ✅ DÜZELTME: readOnly: false
                if (state.cc.isNotEmpty) ...[
                  _buildRecipientChips(state.cc, RecipientType.cc, theme, readOnly: false),
                  const SizedBox(height: 8),
                ],
                
                // CC input field
                TextField(
                  controller: _ccController,
                  focusNode: _ccFocusNode,
                  decoration: InputDecoration(
                    hintText: state.cc.isEmpty ? 'Email adresi' : 'Başka alıcı ekle',
                    hintStyle: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: theme.textTheme.bodyMedium,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (value) => _addRecipient(value, RecipientType.cc),
                  onChanged: (value) => setState(() {}),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build bcc field
  Widget _buildBccField(ThemeData theme, MailReplyState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              'Bcc',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Existing BCC recipients
                if (state.bcc.isNotEmpty) ...[
                  _buildRecipientChips(state.bcc, RecipientType.bcc, theme),
                  const SizedBox(height: 8),
                ],
                
                // BCC input field
                TextField(
                  controller: _bccController,
                  focusNode: _bccFocusNode,
                  decoration: InputDecoration(
                    hintText: state.bcc.isEmpty ? 'Email adresi' : 'Başka alıcı ekle',
                    hintStyle: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: theme.textTheme.bodyMedium,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (value) => _addRecipient(value, RecipientType.bcc),
                  onChanged: (value) => setState(() {}),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build subject field
  Widget _buildSubjectField(ThemeData theme, MailReplyState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              'Konu',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: TextField(
              controller: _subjectController,
              focusNode: _subjectFocusNode,
              decoration: InputDecoration(
                hintText: 'Konu başlığı',
                hintStyle: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              style: theme.textTheme.bodyMedium,
              textInputAction: TextInputAction.next,
              onChanged: (value) {
                ref.read(mailReplyProvider.notifier).updateSubject(value);
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Build recipient chips
  Widget _buildRecipientChips(
    List<MailRecipient> recipients, 
    RecipientType type, 
    ThemeData theme, {
    bool readOnly = false,
  }) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: recipients.asMap().entries.map((entry) {
        final index = entry.key;
        final recipient = entry.value;
        return _buildRecipientChip(recipient, index, type, theme, readOnly: readOnly);
      }).toList(),
    );
  }

  /// Build individual recipient chip
  Widget _buildRecipientChip(
    MailRecipient recipient, 
    int index, 
    RecipientType type, 
    ThemeData theme, {
    bool readOnly = false,
  }) {
    final isValidEmail = _isValidEmail(recipient.email);
    
    return Container(
      decoration: BoxDecoration(
        color: isValidEmail 
            ? (readOnly ? theme.colorScheme.surfaceVariant : theme.colorScheme.primaryContainer)
            : theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isValidEmail 
              ? (readOnly ? theme.colorScheme.outline.withOpacity(0.3) : theme.colorScheme.primary.withOpacity(0.3))
              : theme.colorScheme.error.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Padding(
              padding: const EdgeInsets.only(left: 12, top: 6, bottom: 6),
              child: Text(
                _getDisplayText(recipient),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isValidEmail 
                      ? (readOnly ? theme.colorScheme.onSurfaceVariant : theme.colorScheme.onPrimaryContainer)
                      : theme.colorScheme.onErrorContainer,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          
          const SizedBox(width: 4),
          
          // Remove button (only for non-read-only chips)
          if (!readOnly) ...[
            InkWell(
              onTap: () => _removeRecipient(index, type),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  Icons.close,
                  size: 16,
                  color: isValidEmail 
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onErrorContainer,
                ),
              ),
            ),
            
            const SizedBox(width: 4),
          ],
        ],
      ),
    );
  }

  // ========== HELPER METHODS ==========

  /// Add recipient
  void _addRecipient(String emailInput, RecipientType type) {
    final trimmedInput = emailInput.trim();
    if (trimmedInput.isEmpty) return;
    
    // Parse multiple emails separated by comma or semicolon
    final emailAddresses = trimmedInput
        .split(RegExp(r'[,;]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    
    final notifier = ref.read(mailReplyProvider.notifier);
    
    for (final emailAddress in emailAddresses) {
      final recipient = MailRecipient.fromDisplayString(emailAddress);
      
      switch (type) {
        case RecipientType.to:
          if (!_isDuplicateRecipient(recipient.email, ref.read(mailReplyProvider).to)) {
            notifier.addToRecipient(recipient);
          }
          break;
        case RecipientType.cc:
          if (!_isDuplicateRecipient(recipient.email, ref.read(mailReplyProvider).cc)) {
            notifier.addCcRecipient(recipient);
          }
          break;
        case RecipientType.bcc:
          if (!_isDuplicateRecipient(recipient.email, ref.read(mailReplyProvider).bcc)) {
            notifier.addBccRecipient(recipient);
          }
          break;
      }
    }
    
    // Clear the appropriate controller
    switch (type) {
      case RecipientType.to:
        _toController.clear();
        break;
      case RecipientType.cc:
        _ccController.clear();
        break;
      case RecipientType.bcc:
        _bccController.clear();
        break;
    }
    
    setState(() {});
  }

  /// Remove recipient
  void _removeRecipient(int index, RecipientType type) {
    final notifier = ref.read(mailReplyProvider.notifier);
    
    switch (type) {
      case RecipientType.to:
        notifier.removeToRecipient(index);
        break;
      case RecipientType.cc:
        notifier.removeCcRecipient(index);
        break;
      case RecipientType.bcc:
        notifier.removeBccRecipient(index);
        break;
    }
  }

  /// Validate email format
  bool _isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email);
  }

  /// Check for duplicate recipient
  bool _isDuplicateRecipient(String email, List<MailRecipient> existingRecipients) {
    return existingRecipients.any((recipient) => 
        recipient.email.toLowerCase() == email.toLowerCase());
  }

  /// Get display text for recipient
  String _getDisplayText(MailRecipient recipient) {
    if (recipient.name == recipient.email || recipient.name.isEmpty) {
      return recipient.email;
    }
    
    // Show name if it's different from email and not too long
    if (recipient.name.length <= 20) {
      return recipient.name;
    }
    
    // If name is too long, show email
    return recipient.email;
  }


}

/// Recipient type enumeration
enum RecipientType {
  to,
  cc,
  bcc,
}