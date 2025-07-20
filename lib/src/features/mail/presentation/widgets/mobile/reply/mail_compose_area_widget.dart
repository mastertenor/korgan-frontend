// lib/src/features/mail/presentation/widgets/mobile/reply/mail_compose_area_widget.dart

import 'package:flutter/material.dart';

/// Mail Compose Area Widget - Ultra Simple Version
///
/// En basit hali - sadece TextFormField, background white, border gray
class MailComposeAreaWidget extends StatefulWidget {
  final TextEditingController controller;
  final String placeholder;
  final Function(String)? onChanged;

  const MailComposeAreaWidget({
    super.key,
    required this.controller,
    this.placeholder = 'Mesajınızı yazın...',
    this.onChanged,
  });

  @override
  State<MailComposeAreaWidget> createState() => _MailComposeAreaWidgetState();
}

class _MailComposeAreaWidgetState extends State<MailComposeAreaWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextFormField(
        controller: widget.controller,
        onChanged: widget.onChanged,
        maxLines: null,
        minLines: 4,
        keyboardType: TextInputType.multiline,
        textInputAction: TextInputAction.newline,
        style: const TextStyle(
          fontSize: 16,
          color: Colors.black87,
        ),
        decoration: InputDecoration(
          hintText: widget.placeholder,
          hintStyle: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 16,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          isDense: true,
        ),
      ),
    );
  }
}