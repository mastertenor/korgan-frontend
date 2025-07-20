import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/mail_detail.dart';
import '../../widgets/mobile/htmlrender/html_mail_renderer.dart';
import '../../widgets/mobile/htmlrender/models/render_mode.dart';

class MailReplyMobile extends ConsumerStatefulWidget {
  final MailDetail originalMail;
  final String currentUserEmail;

  const MailReplyMobile({
    super.key,
    required this.originalMail,
    required this.currentUserEmail,
  });

  @override
  ConsumerState<MailReplyMobile> createState() => _MailReplyMobileState();
}

class _MailReplyMobileState extends ConsumerState<MailReplyMobile> {
    double _contentHeight = 1.0;

  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: _handleSend,
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
          const SizedBox(height: 16),
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
        maxLines: 10,
        minLines: 5,
        decoration: InputDecoration(
          hintText: 'Yanıtınızı buraya yazın...',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          filled: true,
          fillColor: Colors.grey.shade100,
        ),
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


  void _handleSend() {
    final replyText = _controller.text.trim();

    if (replyText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Yanıt boş olamaz!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Burada gönderme işlemini başlatabilirsin (API, provider, vs)

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Yanıt gönderildi!'),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.of(context).pop(true); // Yanıttan başarılı dönüş
  }
}
