// lib/src/features/mail/presentation/pages/mobile/mail_reply_mobile.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/mail_detail.dart';
import '../../../domain/entities/mail_recipient.dart';
import '../../../domain/enums/reply_type.dart';
import '../../providers/mail_providers.dart';
import '../../widgets/mobile/htmlrender/html_mail_renderer.dart';
import '../../widgets/mobile/htmlrender/models/render_mode.dart';

class MailReplyMobile extends ConsumerStatefulWidget {
  final MailDetail originalMail;
  final String currentUserEmail;
  final String? currentUserName; // Opsiyonel ekleme
  final ReplyType? initialReplyType; // Opsiyonel ekleme

  const MailReplyMobile({
    super.key,
    required this.originalMail,
    required this.currentUserEmail,
    this.currentUserName, // Opsiyonel
    this.initialReplyType, // Opsiyonel
  });

  @override
  ConsumerState<MailReplyMobile> createState() => _MailReplyMobileState();
}

class _MailReplyMobileState extends ConsumerState<MailReplyMobile> {
  double _contentHeight = 1.0;
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Provider initialize - ADIM 1 EKLEME
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeReplyProvider();
    });
  }

  /// Provider'ı initialize et - SADECE BU EKLENDİ
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

  /// User name çıkart - SADECE BU EKLENDİ  
  String _extractUserName(String email) {
    if (email.contains('@')) {
      final namePart = email.split('@').first;
      if (namePart.isNotEmpty) {
        return namePart[0].toUpperCase() + namePart.substring(1);
      }
    }
    return email;
  }

  /// Attachment options modal - ADIM 2 EKLEME
  void _showAttachmentOptions() {
    if (!mounted) return;
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 20),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Options
            ListTile(
              leading: const Icon(Icons.photo, color: Colors.blue),
              title: const Text('Galeri'),
              subtitle: const Text('Fotoğraf ve videolar'),
              onTap: () {
                Navigator.pop(context);
                _showPlaceholderMessage('Galeri özelliği yakında!');
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.green),
              title: const Text('Kamera'),
              subtitle: const Text('Fotoğraf çek'),
              onTap: () {
                Navigator.pop(context);
                _showPlaceholderMessage('Kamera özelliği yakında!');
              },
            ),
            ListTile(
              leading: const Icon(Icons.folder, color: Colors.orange),
              title: const Text('Dosyalar'),
              subtitle: const Text('Belgeler ve diğer dosyalar'),
              onTap: () {
                Navigator.pop(context);
                _showPlaceholderMessage('Dosya seçme özelliği yakında!');
              },
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// Placeholder message - ADIM 2 EKLEME
  void _showPlaceholderMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Provider state'lerini izle - ADIM 2 EKLEME
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
          // Attachment button - ADIM 2 EKLEME
          if (hasAttachments) 
            Stack(
              alignment: Alignment.topRight,
              children: [
                IconButton(
                  icon: const Icon(Icons.attach_file),
                  onPressed: _showAttachmentOptions,
                  tooltip: 'Dosya Ekle',
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.orange,
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
            )
          else
            IconButton(
              icon: const Icon(Icons.attach_file_outlined),
              onPressed: _showAttachmentOptions,
              tooltip: 'Dosya Ekle',
            ),
          
          // Send button - Loading state eklendi
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
            onPressed: isLoading ? null : _handleSend,
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
          _buildReplyHeader(widget.originalMail),
          _buildReplyTextField(),
          //const SizedBox(height: 16),
          _buildRenderedHtmlSection(widget.originalMail),
        ],
      ),
    );
  }

  Widget _buildReplyHeader(MailDetail mailDetail) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kime: ${mailDetail.senderEmail}',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Konu: ${mailDetail.subject}',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

Widget _buildReplyTextField() {
  return Padding(
    padding: const EdgeInsets.all(16),
    child: TextField(
      controller: _controller,
      maxLines: null, // Sınırsız yükseklik
      decoration: const InputDecoration(
        hintText: 'Yanıtınızı buraya yazın...',
        border: InputBorder.none, // Tamamen sade
        isCollapsed: true, // Ekstra paddingleri de kaldırır, opsiyonel
      ),
      style: const TextStyle(), // Renk/boyut ayarı verilmedi, tamamen varsayılan
    ),
  );
}

Widget _buildRenderedHtmlSection(MailDetail mailDetail) {
    return SizedBox(
      // 🔥 Padding tamamen kaldırıldı
      width: double.infinity, // 🔥 Tam genişlik
      child: SizedBox(
        height: _contentHeight,
        width: double.infinity, // 🔥 Tam genişlik
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
    );
  }


  void _handleSend() async { // async eklendi
    final replyText = _controller.text.trim();

    if (replyText.isEmpty) {
      if (mounted) { // mounted kontrolü eklendi
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