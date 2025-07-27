// lib/src/features/mail/presentation/pages/mobile/mail_reply_mobile.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:korgan/src/features/mail/presentation/widgets/mobile/compose/reply_recipients_subject_input_widget.dart';
import '../../widgets/mobile/compose/reply_attachments_manager_widget.dart';
import '../../../domain/entities/mail_detail.dart';
import '../../../domain/entities/mail_recipient.dart';
import '../../../domain/enums/reply_type.dart';
import '../../providers/mail_providers.dart';
import '../../widgets/mobile/htmlrender/html_mail_renderer.dart';
import '../../widgets/mobile/htmlrender/models/render_mode.dart';


class MailReplyMobile extends ConsumerStatefulWidget {
  final MailDetail originalMail;
  final String currentUserEmail;
  final String? currentUserName;
  final ReplyType? initialReplyType;

  const MailReplyMobile({
    super.key,
    required this.originalMail,
    required this.currentUserEmail,
    this.currentUserName,
    this.initialReplyType,
  });

  @override
  ConsumerState<MailReplyMobile> createState() => _MailReplyMobileState();
}

class _MailReplyMobileState extends ConsumerState<MailReplyMobile> {
  double _contentHeight = 1.0;
  late TextEditingController _contentController;

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController();
    
    // Provider initialize
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeReplyProvider();
      
      // ✅ YENİ: Controller listener eklendi
      _contentController.addListener(() {
        ref.read(mailReplyProvider.notifier).updateTextContent(_contentController.text);
      });

      // ✅ İlk değerle provider'ı senkronize et
  ref.read(mailReplyProvider.notifier).updateTextContent(_contentController.text);
    });
  }

  /// Provider'ı initialize et
  void _initializeReplyProvider() {
    final replyNotifier = ref.read(mailReplyProvider.notifier);
    replyNotifier.clearAll();
    
    final sender = MailRecipient(
      email: widget.currentUserEmail,
      name: widget.currentUserName ?? _extractUserName(widget.currentUserEmail),
    );

    replyNotifier.initializeForReply(
      from: sender,
      originalMail: widget.originalMail,
      replyType: widget.initialReplyType ?? ReplyType.reply,
    );
  }

  /// User name çıkart
  String _extractUserName(String email) {
    if (email.contains('@')) {
      final namePart = email.split('@').first;
      if (namePart.isNotEmpty) {
        return namePart[0].toUpperCase() + namePart.substring(1);
      }
    }
    return email;
  }

  /// Attachment options modal
  void _showAttachmentOptions() {
    if (!mounted) return;
    
    const ReplyAttachmentsManagerWidget().showAttachmentOptions(context, ref);
  }

  
  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Provider state'lerini izle
    final isLoading = ref.watch(replyLoadingProvider);
    final replyState = ref.watch(mailReplyProvider);
    final hasAttachments = replyState.attachments.isNotEmpty;
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Yanıtla'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // Attachment button
          Stack(
            alignment: Alignment.topRight,
            children: [
              IconButton(
                icon: Icon(
                  hasAttachments ? Icons.attach_file : Icons.attach_file_outlined,
                  color: hasAttachments ? Colors.amber : Colors.white,
                ),
                onPressed: _showAttachmentOptions,
                tooltip: 'Dosya Ekle',
              ),
              
              // Attachment count badge
              if (hasAttachments)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${replyState.attachments.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          
          // ✅ YENİ: Send button - compose ile aynı enable/disable logic
          IconButton(
            icon: isLoading 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.send),
            onPressed: replyState.canSend && !isLoading
                ? _handleSend
                : null,
            tooltip: 'Gönder',
          ),
        ],
      ),
      body: _buildReplyContent(context),
    );
  }

Widget _buildReplyContent(BuildContext context) {
  return SingleChildScrollView(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ReplyRecipientsSubjectInputWidget(
          fromEmail: widget.currentUserEmail,
          fromName: widget.currentUserName ?? _extractUserName(widget.currentUserEmail),
        ),
        _buildReplyTextField(),
        const ReplyAttachmentsManagerWidget(),
        _buildRenderedHtmlSection(widget.originalMail),
      ],
    ),
  );
}

Widget _buildReplyTextField() {
  return Padding(
    padding: const EdgeInsets.all(16),
    child: TextField(
      controller: _contentController,
      maxLines: null,
      decoration: const InputDecoration(
        hintText: 'Yanıtınızı buraya yazın...',
        border: InputBorder.none,
        isCollapsed: true,
      ),
      style: const TextStyle(),
      // ✅ YENİ: onChanged callback eklendi
      onChanged: (value) {
        ref.read(mailReplyProvider.notifier).updateTextContent(value);
      },
    ),
  );
}

Widget _buildRenderedHtmlSection(MailDetail mailDetail) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // 🆕 Quote Header - Gmail tarzı
      _buildQuoteHeader(mailDetail),
      
      const SizedBox(height: 8),
      
      // Mevcut HTML Renderer - Değişmedi
      SizedBox(
        width: double.infinity,
        child: SizedBox(
          height: _contentHeight,
          width: double.infinity,
          child: HtmlMailRenderer(
            mode: RenderMode.editor,
            currentUserEmail: widget.currentUserEmail,
            mailDetail: mailDetail,
            onHeightChanged: (height) {
              if (mounted) {
                setState(() {
                  _contentHeight = height;
                });
              }
            },
          ),
        ),
      ),
    ],
  );
}


Widget _buildQuoteHeader(MailDetail mailDetail) {
  final dateText = mailDetail.formattedReceivedUtcLocalDateTime;
  
  final senderText = '${mailDetail.senderName} <${mailDetail.senderEmail}>';
  
  return Padding(
    padding: const EdgeInsets.only(left: 16.0),
    child: Text(
      '$dateText tarihinde $senderText şunu yazdı:',
      style: TextStyle(
        fontSize: 13,
        color: Colors.grey.shade700,
        fontStyle: FontStyle.italic,
      ),
    ),
  );
}

  void _handleSend() async {
    // ✅ DÜZELTME: Provider'dan content al (controller'dan değil)
    final replyText = ref.read(mailReplyProvider).textContent.trim();

    if (replyText.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Yanıt boş olamaz!'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Provider ile gönderme
    final success = await ref.read(mailReplyProvider.notifier).sendReply();
    
    // mounted kontrolü ile async gap koruması
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Yanıt gönderildi!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      } else {
        final errorMessage = ref.read(replyErrorProvider) ?? 'Yanıt gönderilemedi';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
}