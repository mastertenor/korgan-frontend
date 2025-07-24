// lib/src/features/mail/presentation/widgets/mobile/compose/recipients_input_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/entities/mail_recipient.dart';
import '../../../providers/mail_compose_provider.dart';
import '../../../providers/mail_providers.dart';

/// Recipients input widget for compose form
///
/// Features:
/// - TO recipients (required)
/// - CC/BCC fields (expandable)
/// - Email validation
/// - Recipient chips with remove functionality
/// - Auto-complete suggestions (future ready)
class RecipientsInputWidget extends ConsumerStatefulWidget {
  const RecipientsInputWidget({super.key});

  @override
  ConsumerState<RecipientsInputWidget> createState() => _RecipientsInputWidgetState();
}

class _RecipientsInputWidgetState extends ConsumerState<RecipientsInputWidget> {
  late TextEditingController _toController;
  late TextEditingController _ccController;
  late TextEditingController _bccController;
  
  late FocusNode _toFocusNode;
  late FocusNode _ccFocusNode;
  late FocusNode _bccFocusNode;

  @override
  void initState() {
    super.initState();
    _toController = TextEditingController();
    _ccController = TextEditingController();
    _bccController = TextEditingController();
    
    _toFocusNode = FocusNode();
    _ccFocusNode = FocusNode();
    _bccFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _toController.dispose();
    _ccController.dispose();
    _bccController.dispose();
    
    _toFocusNode.dispose();
    _ccFocusNode.dispose();
    _bccFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final composeState = ref.watch(mailComposeProvider);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // TO Field (always visible)
        _buildToField(composeState),
        
        const SizedBox(height: 8),
        
        // CC/BCC Toggle buttons
        _buildToggleButtons(composeState),
        
        // CC Field (conditional)
        if (composeState.showCc) ...[
          const SizedBox(height: 12),
          _buildCcField(composeState),
        ],
        
        // BCC Field (conditional)
        if (composeState.showBcc) ...[
          const SizedBox(height: 12),
          _buildBccField(composeState),
        ],
      ],
    );
  }

  /// Build TO field
  Widget _buildToField(MailComposeState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // TO label and recipients
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 50,
              child: Text(
                'Kime:',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade700,
                  fontSize: 14,
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Existing TO recipients
                  if (state.to.isNotEmpty) ...[
                    _buildRecipientChips(state.to, RecipientType.to),
                    const SizedBox(height: 8),
                  ],
                  
                  // TO input field
                  TextField(
                    controller: _toController,
                    focusNode: _toFocusNode,
                    decoration: InputDecoration(
                      hintText: state.to.isEmpty ? 'Email adresi ekleyin...' : 'Başka alıcı ekle...',
                      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: const BorderSide(color: Colors.blue, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      isDense: true,
                      suffixIcon: _toController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.add_circle, color: Colors.blue),
                              onPressed: () => _addRecipient(_toController.text, RecipientType.to),
                              visualDensity: VisualDensity.compact,
                            )
                          : null,
                    ),
                    style: const TextStyle(fontSize: 14),
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (value) => _addRecipient(value, RecipientType.to),
                    onChanged: (value) => setState(() {}), // Trigger rebuild for suffix icon
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Build CC field
  Widget _buildCcField(MailComposeState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 50,
              child: Row(
                children: [
                  Text(
                    'Cc:',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade700,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: () => ref.read(mailComposeProvider.notifier).toggleCcVisibility(),
                    child: Icon(
                      Icons.close,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Existing CC recipients
                  if (state.cc.isNotEmpty) ...[
                    _buildRecipientChips(state.cc, RecipientType.cc),
                    const SizedBox(height: 8),
                  ],
                  
                  // CC input field
                  TextField(
                    controller: _ccController,
                    focusNode: _ccFocusNode,
                    decoration: InputDecoration(
                      hintText: state.cc.isEmpty ? 'Cc ekleyin...' : 'Başka Cc ekle...',
                      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: const BorderSide(color: Colors.blue, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      isDense: true,
                      suffixIcon: _ccController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.add_circle, color: Colors.blue),
                              onPressed: () => _addRecipient(_ccController.text, RecipientType.cc),
                              visualDensity: VisualDensity.compact,
                            )
                          : null,
                    ),
                    style: const TextStyle(fontSize: 14),
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (value) => _addRecipient(value, RecipientType.cc),
                    onChanged: (value) => setState(() {}), // Trigger rebuild for suffix icon
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Build BCC field
  Widget _buildBccField(MailComposeState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 50,
              child: Row(
                children: [
                  Text(
                    'Bcc:',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade700,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: () => ref.read(mailComposeProvider.notifier).toggleBccVisibility(),
                    child: Icon(
                      Icons.close,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Existing BCC recipients
                  if (state.bcc.isNotEmpty) ...[
                    _buildRecipientChips(state.bcc, RecipientType.bcc),
                    const SizedBox(height: 8),
                  ],
                  
                  // BCC input field
                  TextField(
                    controller: _bccController,
                    focusNode: _bccFocusNode,
                    decoration: InputDecoration(
                      hintText: state.bcc.isEmpty ? 'Bcc ekleyin...' : 'Başka Bcc ekle...',
                      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: const BorderSide(color: Colors.blue, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      isDense: true,
                      suffixIcon: _bccController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.add_circle, color: Colors.blue),
                              onPressed: () => _addRecipient(_bccController.text, RecipientType.bcc),
                              visualDensity: VisualDensity.compact,
                            )
                          : null,
                    ),
                    style: const TextStyle(fontSize: 14),
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (value) => _addRecipient(value, RecipientType.bcc),
                    onChanged: (value) => setState(() {}), // Trigger rebuild for suffix icon
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Build CC/BCC toggle buttons
  Widget _buildToggleButtons(MailComposeState state) {
    return Row(
      children: [
        const SizedBox(width: 50), // Align with field labels
        
        if (!state.showCc)
          InkWell(
            onTap: () => ref.read(mailComposeProvider.notifier).toggleCcVisibility(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Text(
                '+ Cc',
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        
        if (!state.showCc && !state.showBcc) const SizedBox(width: 8),
        
        if (!state.showBcc)
          InkWell(
            onTap: () => ref.read(mailComposeProvider.notifier).toggleBccVisibility(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Text(
                '+ Bcc',
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// Build recipient chips
  Widget _buildRecipientChips(List<MailRecipient> recipients, RecipientType type) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: recipients.asMap().entries.map((entry) {
        final index = entry.key;
        final recipient = entry.value;
        
        return _buildRecipientChip(recipient, index, type);
      }).toList(),
    );
  }

  /// Build individual recipient chip
  Widget _buildRecipientChip(MailRecipient recipient, int index, RecipientType type) {
    final isValidEmail = _isValidEmail(recipient.email);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isValidEmail ? Colors.blue.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isValidEmail ? Colors.blue.shade200 : Colors.red.shade200,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Email icon
          Icon(
            isValidEmail ? Icons.email : Icons.error_outline,
            size: 14,
            color: isValidEmail ? Colors.blue.shade600 : Colors.red.shade600,
          ),
          
          const SizedBox(width: 6),
          
          // Recipient text
          Flexible(
            child: Text(
              _getDisplayText(recipient),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isValidEmail ? Colors.blue.shade800 : Colors.red.shade800,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          
          const SizedBox(width: 6),
          
          // Remove button
          InkWell(
            onTap: () => _removeRecipient(index, type),
            child: Icon(
              Icons.close,
              size: 16,
              color: isValidEmail ? Colors.blue.shade600 : Colors.red.shade600,
            ),
          ),
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
          // Check for duplicates
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
    
    // Rebuild to hide suffix icon
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