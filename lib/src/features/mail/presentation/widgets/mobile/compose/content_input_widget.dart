// lib/src/features/mail/presentation/widgets/mobile/compose/content_input_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/mail_compose_provider.dart';
import '../../../providers/mail_providers.dart';

/// Content input widget for compose form
class ContentInputWidget extends ConsumerStatefulWidget {
  const ContentInputWidget({super.key});

  @override
  ConsumerState<ContentInputWidget> createState() => _ContentInputWidgetState();
}

class _ContentInputWidgetState extends ConsumerState<ContentInputWidget> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final composeState = ref.watch(mailComposeProvider);
    
    // Update controller if state changed externally
    if (_controller.text != composeState.textContent) {
      _controller.text = composeState.textContent;
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // HTML/Text mode toggle (future ready)
        _buildModeToggle(composeState),
        
        const SizedBox(height: 8),
        
        // Content input field
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          maxLines: 12,
          minLines: 8,
          decoration: InputDecoration(
            hintText: 'Mesajınızı yazın...',
            hintStyle: TextStyle(color: Colors.grey.shade400),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.blue, width: 2),
            ),
            contentPadding: const EdgeInsets.all(12),
            alignLabelWithHint: true,
          ),
          style: const TextStyle(fontSize: 16),
          keyboardType: TextInputType.multiline,
          textInputAction: TextInputAction.newline,
          onChanged: (value) {
            ref.read(mailComposeProvider.notifier).updateTextContent(value);
          },
        ),
        
        // Character count (optional)
        if (composeState.textContent.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            '${composeState.textContent.length} karakter',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ],
    );
  }

  /// Build mode toggle (HTML/Text)
  Widget _buildModeToggle(MailComposeState state) {
    return Row(
      children: [
        Text(
          'Metin Modu',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        const Spacer(),
        Switch(
          value: state.isHtmlMode,
          onChanged: (value) {
            ref.read(mailComposeProvider.notifier).toggleHtmlMode();
            if (value) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('HTML modu yakında eklenecek!'),
                  duration: Duration(seconds: 2),
                ),
              );
            }
          },
          activeColor: Colors.blue,
        ),
        Text(
          'HTML',
          style: TextStyle(
            fontSize: 14,
            color: state.isHtmlMode ? Colors.blue : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}