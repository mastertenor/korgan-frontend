// lib/src/features/mail/presentation/widgets/mobile/compose/subject_input_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/mail_providers.dart';

/// Subject input widget for compose form
class SubjectInputWidget extends ConsumerStatefulWidget {
  const SubjectInputWidget({super.key});

  @override
  ConsumerState<SubjectInputWidget> createState() => _SubjectInputWidgetState();
}

class _SubjectInputWidgetState extends ConsumerState<SubjectInputWidget> {
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
    if (_controller.text != composeState.subject) {
      _controller.text = composeState.subject;
    }
    
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      decoration: InputDecoration(
        hintText: 'Konu başlığı...',
        hintStyle: TextStyle(color: Colors.grey.shade400),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.blue, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        suffixIcon: composeState.subject.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _controller.clear();
                  ref.read(mailComposeProvider.notifier).updateSubject('');
                },
              )
            : null,
      ),
      style: const TextStyle(fontSize: 16),
      textInputAction: TextInputAction.next,
      onChanged: (value) {
        ref.read(mailComposeProvider.notifier).updateSubject(value);
      },
    );
  }
}