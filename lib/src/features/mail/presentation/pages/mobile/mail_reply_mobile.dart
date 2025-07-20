// lib/src/features/mail/presentation/pages/mobile/mail_reply_mobile.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/mail_detail.dart';
import '../../../domain/enums/reply_type.dart';
import '../../widgets/mobile/htmlrender/html_mail_renderer.dart';
import '../../widgets/mobile/htmlrender/models/render_mode.dart';

/// Mail Reply Mobile Page
class MailReplyMobile extends ConsumerStatefulWidget {
  final MailDetail originalMail;
  final String currentUserEmail;
  final ReplyType replyType;

  const MailReplyMobile({
    super.key,
    required this.originalMail,
    required this.currentUserEmail,
    this.replyType = ReplyType.reply,
  });

  @override
  ConsumerState<MailReplyMobile> createState() => _MailReplyMobileState();
}

class _MailReplyMobileState extends ConsumerState<MailReplyMobile> {
   
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildReplyAppBar(context),
      body: _buildReplyBody(context),
    );
  }

  // ==================== APP BAR SECTION ====================
  
  PreferredSizeWidget _buildReplyAppBar(BuildContext context) {
    return AppBar(
      title: Text(_getAppBarTitle()),
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
      elevation: 1,
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: _handleClose,
      ),
    );
  }

  String _getAppBarTitle() {
    switch (widget.replyType) {
      case ReplyType.reply:
        return 'Yanıtla';
      case ReplyType.replyAll:
        return 'Tümüne Yanıtla';
      case ReplyType.forward:
        return 'İlet';
    }
  }

  // ==================== BODY SECTION ====================
  
  Widget _buildReplyBody(BuildContext context) {
    return Stack(
      children: [
        // Main content area with HTML renderer
        _buildMainContent(context),
      
        
      ],
    );
  }

  Widget _buildMainContent(BuildContext context) {
    const bottomBarHeight = 80.0; // Fixed height for bottom bar

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      bottom: bottomBarHeight,
      child: HtmlMailRenderer(
        mode: RenderMode.editor,
        mailDetail: widget.originalMail,
        currentUserEmail: widget.currentUserEmail,
        onHeightChanged: (height) {
          // Height changes are handled by the renderer itself
        },
      ),
    );
  }

  
  // ==================== ACTION HANDLERS ====================
  
  void _handleClose() {
  
      Navigator.of(context).pop();
    
  }

 }