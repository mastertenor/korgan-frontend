// lib/src/features/mail/presentation/widgets/mobile/reply/mail_reply_fields_widget.dart

import 'package:flutter/material.dart';

/// En Basit Mail Reply Fields Widget
///
/// Sadece To ve CC alanları - minimal design
class MailReplyFieldsWidget extends StatelessWidget {
  final TextEditingController toController;
  final TextEditingController ccController;

  const MailReplyFieldsWidget({
    super.key,
    required this.toController,
    required this.ccController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          // To field
          Row(
            children: [
              const SizedBox(width: 40, child: Text('To:')),
              Expanded(
                child: TextFormField(
                  controller: toController,
                  decoration: const InputDecoration(
                    hintText: 'Email adresi',
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
              ),
            ],
          ),
          
          const Divider(height: 16),
          
          // CC field
          Row(
            children: [
              const SizedBox(width: 40, child: Text('CC:')),
              Expanded(
                child: TextFormField(
                  controller: ccController,
                  decoration: const InputDecoration(
                    hintText: 'CC email adresi',
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}