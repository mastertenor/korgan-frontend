// lib/src/features/mail/presentation/widgets/mobile/compose/recipients_input_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/entities/mail_recipient.dart';
import '../../../providers/mail_compose_provider.dart';
import '../../../providers/mail_providers.dart';

/// Recipients input widget with collapsible design
///
/// Features:
/// - Non-editable "From" field without arrow
/// - Collapsible CC/BCC fields with arrow indicator
/// - Full-width layout without margins
/// - Theme-based colors
/// - Equal height for all fields
class RecipientsInputWidget extends ConsumerStatefulWidget {
  final String fromEmail; // From alanı için email

  const RecipientsInputWidget({
    super.key,
    this.fromEmail = 'berk@argenteknoloji.com',
  });

  @override
  ConsumerState<RecipientsInputWidget> createState() => _RecipientsInputWidgetState();
}

class _RecipientsInputWidgetState extends ConsumerState<RecipientsInputWidget> {
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
    final composeState = ref.watch(mailComposeProvider);
    
    return Container(
      width: double.infinity,
      color: theme.scaffoldBackgroundColor,
      child: Column(
        children: [
          // Kimden alanı (non-editable, no arrow)
          _buildFromField(theme),
          
          const Divider(height: 1),
          
          // Alıcı alanı
          _buildToField(theme, composeState),
          
          // CC/BCC alanları (collapsible)
          if (_isExpanded) ...[
            const Divider(height: 1),
            _buildCcField(theme, composeState),
            
            const Divider(height: 1),
            _buildBccField(theme, composeState),
          ],
          
          const Divider(height: 1),
          
          // Konu alanı
          _buildSubjectField(theme, composeState),
          const Divider(height: 1),
        ],
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
              widget.fromEmail,
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
  Widget _buildToField(ThemeData theme, MailComposeState state) {
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
                // Existing TO recipients
                if (state.to.isNotEmpty) ...[
                  _buildRecipientChips(state.to, RecipientType.to, theme),
                  const SizedBox(height: 8),
                ],
                
                // TO input field
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
            height: 16, // Yüksekliği düşür
            width: 16,
            child: IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(), // Minimum kısıtlama
              icon: Icon(
                _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                size: 20,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              onPressed: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              tooltip: _isExpanded ? 'CC/BCC Gizle' : 'CC/BCC Göster',
            ),
          ),
        ],
      ),
    );
  }

  /// Build CC field
  Widget _buildCcField(ThemeData theme, MailComposeState state) {
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
                // Existing CC recipients
                if (state.cc.isNotEmpty) ...[
                  _buildRecipientChips(state.cc, RecipientType.cc, theme),
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

  /// Build BCC field
  Widget _buildBccField(ThemeData theme, MailComposeState state) {
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
  Widget _buildSubjectField(ThemeData theme, MailComposeState state) {
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
                ref.read(mailComposeProvider.notifier).updateSubject(value);
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Build recipient chips
  Widget _buildRecipientChips(List<MailRecipient> recipients, RecipientType type, ThemeData theme) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: recipients.asMap().entries.map((entry) {
        final index = entry.key;
        final recipient = entry.value;
        return _buildRecipientChip(recipient, index, type, theme);
      }).toList(),
    );
  }

  /// Build individual recipient chip
  Widget _buildRecipientChip(MailRecipient recipient, int index, RecipientType type, ThemeData theme) {
    final isValidEmail = _isValidEmail(recipient.email);
    
    return Container(
      decoration: BoxDecoration(
        color: isValidEmail 
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isValidEmail 
              ? theme.colorScheme.primary.withOpacity(0.3)
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
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onErrorContainer,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          
          const SizedBox(width: 4),
          
          // Remove button
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
      ),
    );
  }

  // ========== EVENT HANDLERS ==========

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
    
    final notifier = ref.read(mailComposeProvider.notifier);
    
    for (final emailAddress in emailAddresses) {
      final recipient = MailRecipient.fromDisplayString(emailAddress);
      
      switch (type) {
        case RecipientType.to:
          if (!_isDuplicateRecipient(recipient.email, ref.read(mailComposeProvider).to)) {
            notifier.addToRecipient(recipient);
          }
          break;
        case RecipientType.cc:
          if (!_isDuplicateRecipient(recipient.email, ref.read(mailComposeProvider).cc)) {
            notifier.addCcRecipient(recipient);
          }
          break;
        case RecipientType.bcc:
          if (!_isDuplicateRecipient(recipient.email, ref.read(mailComposeProvider).bcc)) {
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
    final notifier = ref.read(mailComposeProvider.notifier);
    
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

  // ========== HELPER METHODS ==========

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