// lib/src/features/mail/presentation/widgets/web/compose/components/compose_recipients_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../domain/enums/reply_type.dart';
import '../../../../providers/mail_compose_provider.dart';
import '../../../../../domain/entities/mail_recipient.dart';
import '../../../../providers/mail_providers.dart';
import '../../../../utils/subject_prefix_utils.dart';
import '../../common/chips/selectable_recipient_chip.dart'; // ✅ YENİ IMPORT
import '../../common/chips/chip_theme.dart'; // ✅ YENİ IMPORT
import '../../common/recipient_tooltip_widget.dart'; // ✅ YENİ IMPORT
/// Gmail benzeri recipients widget
/// 
/// Features:
/// - From field (non-editable)
/// - To field (always visible)
/// - Cc/Bcc fields (collapsible)
/// - Subject field (YENİ EKLENDİ)
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
  late final TextEditingController _subjectController; // 🎯 YENİ EKLENDİ
  
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
    _subjectController = TextEditingController(); // 🎯 YENİ EKLENDİ
    
    // Initialize focus nodes
    _toFocusNode = FocusNode();
    _ccFocusNode = FocusNode();
    _bccFocusNode = FocusNode();
    
    // Listen to text changes
    _toController.addListener(_onToTextChanged);
    _ccController.addListener(_onCcTextChanged);
    _bccController.addListener(_onBccTextChanged);
    _subjectController.addListener(_onSubjectTextChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
    final replyState = ref.read(mailReplyProvider);
    if (replyState.replyType == ReplyType.replyAll) {
      setState(() {
        _showCc = true;
      });
    }
  });
  }

  @override
  void dispose() {
    _toController.dispose();
    _ccController.dispose();
    _bccController.dispose();
    _subjectController.dispose(); // 🎯 YENİ EKLENDİ
    
    _toFocusNode.dispose();
    _ccFocusNode.dispose();
    _bccFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
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
              
              // To field
              _buildToField(composeState),
              
              // Cc field (conditional)
              if (_showCc)
                _buildCcField(composeState),
              
              // Bcc field (conditional)
              if (_showBcc)
                _buildBccField(composeState),

              // Subject field
              _buildSubjectField(),
            ],
          ),
        );
      },
    );
  }

  /// Build From field
  Widget _buildFromField() {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            SizedBox(
              width: 60,
              child: Text(
                'Kimden',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ),
            
            const SizedBox(width: 12),
            
            Expanded(
              child: Text(
                '${widget.fromName} <${widget.fromEmail}>',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build To field
  Widget _buildToField(MailComposeState composeState) {
    return InkWell(
      onTap: () => _toFocusNode.requestFocus(),
      mouseCursor: SystemMouseCursors.text, // Mouse cursor'u text olarak değiştir
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade300, width: 1),
          ),
        ),
        constraints: const BoxConstraints(minHeight: 42), // Minimum yükseklik chip yüksekliğine uygun
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 60,
                child: Text(
                  'Kime',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              Expanded(
                child: _buildRecipientField(
                  controller: _toController,
                  focusNode: _toFocusNode,
                  recipients: composeState.to,
                  hintText: '',
                  onRecipientAdded: (recipient) {
                    ref.read(mailComposeProvider.notifier).addToRecipient(recipient);
                  },
                  onRecipientRemoved: (recipient) {
                    ref.read(mailComposeProvider.notifier).removeToRecipient(recipient);
                  },
                ),
              ),
              
              _buildCcBccLinks(),
            ],
          ),
        ),
      ),
    );
  }

  /// Build Cc field
  Widget _buildCcField(MailComposeState composeState) {
    return InkWell(
      onTap: () => _ccFocusNode.requestFocus(),
      mouseCursor: SystemMouseCursors.text, // Mouse cursor'u text olarak değiştir
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade300, width: 1),
          ),
        ),
        constraints: const BoxConstraints(minHeight: 42), // Minimum yükseklik chip yüksekliğine uygun
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 60,
                child: Text(
                  'Cc',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              Expanded(
                child: _buildRecipientField(
                  controller: _ccController,
                  focusNode: _ccFocusNode,
                  recipients: composeState.cc,
                  hintText: '',
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
        ),
      ),
    );
  }

  /// Build Bcc field
  Widget _buildBccField(MailComposeState composeState) {
    return InkWell(
      onTap: () => _bccFocusNode.requestFocus(),
      mouseCursor: SystemMouseCursors.text,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade300, width: 1),
          ),
        ),
        constraints: const BoxConstraints(minHeight: 42), 
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 60,
                child: Text(
                  'Bcc',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              Expanded(
                child: _buildRecipientField(
                  controller: _bccController,
                  focusNode: _bccFocusNode,
                  recipients: composeState.bcc,
                  hintText: '',
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
        ),
      ),
    );
  }

  /// Build Cc/Bcc toggle links - sağ tarafa yerleştirildi
  Widget _buildCcBccLinks() {
    // Eğer her ikisi de görünürse, boş widget döndür
    if (_showCc && _showBcc) {
      return const SizedBox.shrink();
    }
    
    return Padding(
      padding: const EdgeInsets.only(left: 8), // 🎯 DÜZELTME: top padding kaldırıldı
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!_showCc)
            InkWell(
              onTap: () => setState(() => _showCc = true),
              child: const Text(
                'Cc',
                style: TextStyle(
                  color: Colors.blue,
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          
          if (!_showCc && !_showBcc) const SizedBox(width: 8),
          
          if (!_showBcc)
            InkWell(
              onTap: () => setState(() => _showBcc = true),
              child: const Text(
                'Bcc',
                style: TextStyle(
                  color: Colors.blue,
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Build subject field
  Widget _buildSubjectField() {
    return Consumer(
      builder: (context, ref, child) {
        final composeState = ref.watch(mailComposeProvider);
        final replyState = ref.watch(mailReplyProvider);
        final isReplyMode = replyState.originalMail != null;
        
        if (isReplyMode && _subjectController.text.isEmpty && composeState.subject.isEmpty) {
          final originalSubject = replyState.originalMail?.subject ?? '';
          final generatedSubject = SubjectPrefixUtils.generateSubjectForReply(
            originalSubject: originalSubject,
            replyType: replyState.replyType,
          );
          
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_subjectController.text.isEmpty) {
              _subjectController.text = generatedSubject;
              ref.read(mailComposeProvider.notifier).updateSubject(generatedSubject);
            }
          });
        }
        
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              SizedBox(
                width: 60,
                child: Text(
                  'Konu',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _subjectController,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    fontWeight: FontWeight.normal,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Build recipient input field
  Widget _buildRecipientField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required List<MailRecipient> recipients,
    required String hintText,
    required Function(MailRecipient) onRecipientAdded,
    required Function(int) onRecipientRemoved,
  }) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // Recipient chips
        ...recipients.asMap().entries.map((entry) => _buildRecipientChip(
          entry.value,
          onRemoved: () => onRecipientRemoved(entry.key),
        )).toList(),
        
        // Text input - her zaman chip'lerin yanında
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 100),
          child: IntrinsicWidth(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                fontWeight: FontWeight.normal,
              ),
              decoration: const InputDecoration(
                // 🎯 Hint text kaldırıldı
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 4),
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
          ),
        ),
      ],
    );
  }

  /// Build recipient chip
Widget _buildRecipientChip(MailRecipient recipient, {required VoidCallback onRemoved}) {
  return SelectableRecipientChip(
    name: recipient.name.isNotEmpty == true 
        ? recipient.name
        : recipient.email,
    chipTheme: RecipientChipTheme.compose(),
    textStyle: const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.normal,
    ),
    onRemoved: onRemoved,
    tooltipBuilder: (name) => RecipientTooltipWidget(
      name: name,
      email: recipient.email, // ✅ Compose'da email'i de geçiriyoruz
    ),
  );
}
  // Event handlers
  void _onToTextChanged() {
    // Handle real-time validation if needed
  }

  void _onCcTextChanged() {
    // Handle real-time validation if needed
  }

  void _onBccTextChanged() {
    // Handle real-time validation if needed
  }

  // 🎯 YENİ EKLENDİ: Subject text değişikliği için handler
  void _onSubjectTextChanged() {
    ref.read(mailComposeProvider.notifier).updateSubject(_subjectController.text);
  }

  /// Add recipient from text input
  void _addRecipientFromText(String text, Function(MailRecipient) onRecipientAdded) {
    if (text.isEmpty) return;
    
    // Basic email validation
    if (!_isValidEmail(text)) {
      // Show error or ignore
      return;
    }
    
    final recipient = MailRecipient(
      email: text,
      name: text, // Use email as name for now
    );
    
    onRecipientAdded(recipient);
  }

  /// Basic email validation
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
}