// lib/src/features/mail/presentation/widgets/web/compose/components/compose_recipients_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../providers/mail_compose_provider.dart';
import '../../../../../domain/entities/mail_recipient.dart';
import '../../../../providers/mail_providers.dart';

/// Gmail benzeri recipients widget
/// 
/// Features:
/// - From field (non-editable)
/// - To field (always visible)
/// - Cc/Bcc fields (collapsible)
/// - Email chips with remove functionality
/// - Real-time validation
/// - Auto-complete support (future)
class ComposeRecipientsWidget extends ConsumerStatefulWidget {
  /// Current user email (from field)
  final String fromEmail;
  
  /// Current user name (from field)
  final String fromName;

  const ComposeRecipientsWidget({
    super.key,
    required this.fromEmail,
    required this.fromName,
  });

  @override
  ConsumerState<ComposeRecipientsWidget> createState() => _ComposeRecipientsWidgetState();
}

class _ComposeRecipientsWidgetState extends ConsumerState<ComposeRecipientsWidget> {
  // Text controllers
  late final TextEditingController _toController;
  late final TextEditingController _ccController;
  late final TextEditingController _bccController;
  
  // Focus nodes
  late final FocusNode _toFocusNode;
  late final FocusNode _ccFocusNode;
  late final FocusNode _bccFocusNode;
  
  // Cc/Bcc visibility
  bool _showCc = false;
  bool _showBcc = false;

  @override
  void initState() {
    super.initState();
    
    // Initialize controllers
    _toController = TextEditingController();
    _ccController = TextEditingController();
    _bccController = TextEditingController();
    
    // Initialize focus nodes
    _toFocusNode = FocusNode();
    _ccFocusNode = FocusNode();
    _bccFocusNode = FocusNode();
    
    // Listen to text changes
    _toController.addListener(_onToTextChanged);
    _ccController.addListener(_onCcTextChanged);
    _bccController.addListener(_onBccTextChanged);
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
    
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          // From field
          _buildFromField(),
          
          _buildDivider(),
          
          // To field
          _buildToField(composeState),
          
          // Cc field (if visible)
          if (_showCc) ...[
            _buildDivider(),
            _buildCcField(composeState),
          ],
          
          // Bcc field (if visible)
          if (_showBcc) ...[
            _buildDivider(),
            _buildBccField(composeState),
          ],
          
          // Cc/Bcc toggle buttons (if not all visible)
          if (!_showCc || !_showBcc) ...[
            _buildDivider(),
            _buildToggleButtons(),
          ],
        ],
      ),
    );
  }

  /// Build from field (non-editable)
  Widget _buildFromField() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(
              'Kimden',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Text(
                '${widget.fromName} <${widget.fromEmail}>',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build To field
  Widget _buildToField(MailComposeState composeState) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Kime',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          Expanded(
            child: _buildRecipientField(
              controller: _toController,
              focusNode: _toFocusNode,
              recipients: composeState.to,
              hintText: 'Alıcı e-posta adresi',
              onRecipientAdded: (recipient) {
                ref.read(mailComposeProvider.notifier).addToRecipient(recipient);
              },
              onRecipientRemoved: (recipient) {
                ref.read(mailComposeProvider.notifier).removeToRecipient(recipient);
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Build Cc field
  Widget _buildCcField(MailComposeState composeState) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Cc',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          Expanded(
            child: _buildRecipientField(
              controller: _ccController,
              focusNode: _ccFocusNode,
              recipients: composeState.cc,
              hintText: 'Cc alıcı e-posta adresi',
              onRecipientAdded: (recipient) {
                ref.read(mailComposeProvider.notifier).addCcRecipient(recipient);
              },
              onRecipientRemoved: (recipient) {
                ref.read(mailComposeProvider.notifier).removeCcRecipient(recipient);
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Build Bcc field
  Widget _buildBccField(MailComposeState composeState) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Bcc',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          Expanded(
            child: _buildRecipientField(
              controller: _bccController,
              focusNode: _bccFocusNode,
              recipients: composeState.bcc,
              hintText: 'Bcc alıcı e-posta adresi',
              onRecipientAdded: (recipient) {
                ref.read(mailComposeProvider.notifier).addBccRecipient(recipient);
              },
              onRecipientRemoved: (recipient) {
                ref.read(mailComposeProvider.notifier).removeBccRecipient(recipient);
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Build recipient field with chips
  Widget _buildRecipientField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required List<MailRecipient> recipients,
    required String hintText,
    required Function(MailRecipient) onRecipientAdded,
    required Function(int) onRecipientRemoved,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Recipient chips
        if (recipients.isNotEmpty)
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: recipients.asMap().entries.map((entry) => _buildRecipientChip(
              entry.value,
              onRemoved: () => onRecipientRemoved(entry.key),
            )).toList(),
          ),
        
        if (recipients.isNotEmpty) const SizedBox(height: 8),
        
        // Text input
        TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: Colors.grey.shade500),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
            isDense: true,
          ),
          onSubmitted: (value) {
            _addRecipientFromText(value.trim(), onRecipientAdded);
            controller.clear();
          },
          onEditingComplete: () {
            final text = controller.text.trim();
            if (text.isNotEmpty) {
              _addRecipientFromText(text, onRecipientAdded);
              controller.clear();
            }
          },
        ),
      ],
    );
  }

  /// Build recipient chip
  Widget _buildRecipientChip(MailRecipient recipient, {required VoidCallback onRemoved}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            recipient.name.isNotEmpty == true 
                ? '${recipient.name} <${recipient.email}>'
                : recipient.email,
            style: TextStyle(
              fontSize: 13,
              color: Colors.blue.shade800,
            ),
          ),
          
          const SizedBox(width: 4),
          
          GestureDetector(
            onTap: onRemoved,
            child: Icon(
              Icons.close,
              size: 16,
              color: Colors.blue.shade600,
            ),
          ),
        ],
      ),
    );
  }

  /// Build Cc/Bcc toggle buttons
  Widget _buildToggleButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          const SizedBox(width: 72), // Align with other fields
          
          if (!_showCc)
            _buildToggleButton(
              'Cc',
              onTap: () => setState(() => _showCc = true),
            ),
          
          if (!_showCc && !_showBcc) const SizedBox(width: 12),
          
          if (!_showBcc)
            _buildToggleButton(
              'Bcc',
              onTap: () => setState(() => _showBcc = true),
            ),
        ],
      ),
    );
  }

  /// Build toggle button
  Widget _buildToggleButton(String label, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  /// Build divider
  Widget _buildDivider() {
    return Divider(
      height: 1,
      color: Colors.grey.shade300,
      indent: 12,
      endIndent: 12,
    );
  }

  // ========== EVENT HANDLERS ==========

  void _onToTextChanged() {
    // Handle comma-separated emails
    final text = _toController.text;
    if (text.contains(',') || text.contains(';')) {
      final emails = text.split(RegExp(r'[,;]')).map((e) => e.trim()).where((e) => e.isNotEmpty);
      for (final email in emails) {
        _addRecipientFromText(email, (recipient) {
          ref.read(mailComposeProvider.notifier).addToRecipient(recipient);
        });
      }
      _toController.clear();
    }
  }

  void _onCcTextChanged() {
    final text = _ccController.text;
    if (text.contains(',') || text.contains(';')) {
      final emails = text.split(RegExp(r'[,;]')).map((e) => e.trim()).where((e) => e.isNotEmpty);
      for (final email in emails) {
        _addRecipientFromText(email, (recipient) {
          ref.read(mailComposeProvider.notifier).addCcRecipient(recipient);
        });
      }
      _ccController.clear();
    }
  }

  void _onBccTextChanged() {
    final text = _bccController.text;
    if (text.contains(',') || text.contains(';')) {
      final emails = text.split(RegExp(r'[,;]')).map((e) => e.trim()).where((e) => e.isNotEmpty);
      for (final email in emails) {
        _addRecipientFromText(email, (recipient) {
          ref.read(mailComposeProvider.notifier).addBccRecipient(recipient);
        });
      }
      _bccController.clear();
    }
  }

  /// Add recipient from text input
  void _addRecipientFromText(String text, Function(MailRecipient) onAdd) {
    if (text.isEmpty) return;
    
    // Basic email validation
    if (_isValidEmail(text)) {
      final recipient = MailRecipient(
        email: text,
        name: text, // Use email as name when no name provided
      );
      onAdd(recipient);
    } else {
      // Show error (could be improved with better UI feedback)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Geçersiz e-posta adresi: $text'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Basic email validation
  bool _isValidEmail(String email) {
    return RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email);
  }
}