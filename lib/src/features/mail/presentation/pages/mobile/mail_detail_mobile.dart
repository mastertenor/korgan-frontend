// lib/src/features/mail/presentation/pages/mobile/mail_detail_mobile.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/mail_detail.dart';
import '../../../domain/enums/reply_type.dart';
import '../../providers/mail_providers.dart';
import '../../widgets/mobile/mail_detail_actions/mail_detail_bottom_bar.dart';
import '../../widgets/mobile/mail_detail_actions/mail_detail_action_sheet.dart';
import '../../widgets/mobile/htmlrender/html_mail_renderer.dart';
import '../../widgets/mobile/htmlrender/models/render_mode.dart';
import '../../widgets/mobile/attachments/attachments_widget_mobile.dart';
import 'mail_reply_mobile.dart';

class MailDetailMobile extends ConsumerStatefulWidget {
  final String mailId;
  final String userEmail;

  const MailDetailMobile({
    super.key,
    required this.mailId,
    required this.userEmail,
  });

  @override
  ConsumerState<MailDetailMobile> createState() => _MailDetailMobileState();
}

class _MailDetailMobileState extends ConsumerState<MailDetailMobile> {
  double _contentHeight = 1.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMailDetail();
    });
  }

  void _loadMailDetail() {
    ref
        .read(mailDetailProvider.notifier)
        .loadMailDetail(mailId: widget.mailId, email: widget.userEmail);
  }

  @override
  Widget build(BuildContext context) {
    final mailDetail = ref.watch(currentMailDetailProvider);
    final isLoading = ref.watch(mailDetailLoadingProvider);
    final error = ref.watch(mailDetailErrorProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildMailAppBar(context, mailDetail),
      body: _buildMailBody(context, mailDetail, isLoading, error),
    );
  }

  // ==================== APP BAR SECTION ====================
  
  PreferredSizeWidget _buildMailAppBar(
    BuildContext context, 
    MailDetail? mailDetail,
  ) {
    return AppBar(
      title: Text(
        mailDetail?.senderName ?? 'Mail Detail',
        overflow: TextOverflow.ellipsis,
      ),
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
      elevation: 1,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: _buildAppBarActions(mailDetail),
    );
  }

  List<Widget> _buildAppBarActions(MailDetail? mailDetail) {
    if (mailDetail == null) return [];

    return [
      // Star action
      IconButton(
        icon: Icon(
          mailDetail.isStarred ? Icons.star : Icons.star_border,
          color: mailDetail.isStarred ? Colors.amber : Colors.white,
        ),
        onPressed: () => _toggleStar(mailDetail),
        tooltip: mailDetail.isStarred ? 'Yıldızı kaldır' : 'Yıldızla',
      ),
    ];
  }

  // ==================== BODY SECTION ====================
  
  Widget _buildMailBody(
    BuildContext context,
    MailDetail? mailDetail,
    bool isLoading,
    String? error,
  ) {
    return Stack(
      children: [
        // Main content area
        _buildMainContent(context, mailDetail, isLoading, error),
        
        // Bottom action bar
        if (mailDetail != null && !isLoading)
          _buildBottomActionBar(context, mailDetail),
      ],
    );
  }

  Widget _buildMainContent(
    BuildContext context,
    MailDetail? mailDetail,
    bool isLoading,
    String? error,
  ) {
    final bottomBarHeight = _calculateBottomBarHeight(context);

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      bottom: bottomBarHeight,
      child: _buildContentArea(context, mailDetail, isLoading, error),
    );
  }

  double _calculateBottomBarHeight(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return MailDetailBottomBar.height +
           mediaQuery.padding.bottom +
           MailDetailBottomBar.safeAreaPadding;
  }

  // ==================== CONTENT AREA SECTION ====================
  
  Widget _buildContentArea(
    BuildContext context,
    MailDetail? mailDetail,
    bool isLoading,
    String? error,
  ) {
    // Loading state
    if (isLoading) {
      return _buildLoadingState();
    }

    // Error state
    if (error != null) {
      return _buildErrorState(error);
    }

    // Empty state
    if (mailDetail == null) {
      return _buildEmptyState();
    }

    // Success state - Show mail content
    return _buildMailContent(context, mailDetail);
  }

  Widget _buildMailContent(BuildContext context, MailDetail mailDetail) {
    return SingleChildScrollView(
      clipBehavior: Clip.hardEdge,
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mail header info
          _buildMailHeader(mailDetail),
          
          // Rendered HTML content
          _buildRenderedHtmlSection(mailDetail),
          
          // Attachments section
          _buildAttachmentsSection(mailDetail),
          
          // Extra bottom padding to prevent content hiding behind bottom bar
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ==================== MAIL HEADER SECTION ====================
  
  Widget _buildMailHeader(MailDetail mailDetail) {
    return Container(
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
          // Subject
          Text(
            mailDetail.subject,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          // From section
          _buildEmailField('Gönderen', mailDetail.senderName, mailDetail.senderEmail),
          
          // To section
          if (mailDetail.recipients.isNotEmpty)
            _buildEmailField('Alıcı', '', mailDetail.recipients.join(', ')),
          
          // CC section
          if (mailDetail.ccRecipients.isNotEmpty)
            _buildEmailField('CC', '', mailDetail.ccRecipients.join(', ')),
          
          const SizedBox(height: 8),
          
          // Date
          Row(
            children: [
              Icon(
                Icons.schedule,
                size: 16,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 8),
              Text(
                mailDetail.formattedReceivedDate,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmailField(String label, String name, String email) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (name.isNotEmpty) ...[
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                ],
                Text(
                  email,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== RENDERED HTML SECTION ====================
  
  Widget _buildRenderedHtmlSection(MailDetail mailDetail) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SizedBox(
        height: _contentHeight,
        child: ClipRect(
          child: HtmlMailRenderer(
            mode: RenderMode.preview,
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
    );
  }

  // ==================== ATTACHMENTS SECTION ====================
  
  Widget _buildAttachmentsSection(MailDetail mailDetail) {
    if (!mailDetail.hasAttachments || mailDetail.attachmentsList.isEmpty) {
      return const SizedBox.shrink();
    }

    return AttachmentsWidgetMobile(mailDetail: mailDetail);
  }

  // ==================== BOTTOM ACTION BAR SECTION ====================
  
  Widget _buildBottomActionBar(BuildContext context, MailDetail mailDetail) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: MailDetailBottomBar(
        mailDetail: mailDetail,
        currentUserEmail: widget.userEmail,
        onReply: () => _replyToMail(mailDetail),
        onForward: () => _handleForward(mailDetail),
        onMarkImportant: () => _handleMarkImportant(mailDetail),
        onDelete: () => _handleDelete(mailDetail),
        onMoreActions: () => _handleMoreActions(mailDetail),
        isEnabled: true,
      ),
    );
  }

  // ==================== STATE WIDGETS ====================
  
  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Mail yükleniyor...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'Mail yüklenirken hata oluştu',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadMailDetail,
              icon: const Icon(Icons.refresh),
              label: const Text('Tekrar Dene'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.mail_outline,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Mail bulunamadı',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Bu mail artık mevcut değil veya silinmiş olabilir',
            style: TextStyle(
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ==================== ACTION HANDLERS ====================

void _replyToMail(MailDetail mailDetail) {
  debugPrint('🚀 Opening reply editor for: ${mailDetail.subject}');

  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => MailReplyMobile(
        originalMail: mailDetail,
        currentUserEmail: widget.userEmail,
        replyType: ReplyType.reply,
      ),
    ),
  ).then((result) {
    // Handle result from reply page
    if (result == true) {
      debugPrint('✅ Reply sent successfully');
      // You can refresh mail list or show confirmation here
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mail başarıyla gönderildi!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  });
}

  void _toggleStar(MailDetail mailDetail) {
    debugPrint('⭐ Toggle star for: ${mailDetail.subject}');
    // TODO: Implement star toggle logic
  }

  void _handleForward(MailDetail mailDetail) {
    debugPrint('📤 Forward mail: ${mailDetail.subject}');
    // TODO: Implement forward logic
  }

  void _handleMarkImportant(MailDetail mailDetail) {
    debugPrint('❗ Mark important: ${mailDetail.subject}');
    // TODO: Implement mark important logic
  }

  void _handleDelete(MailDetail mailDetail) {
    debugPrint('🗑️ Delete mail: ${mailDetail.subject}');
    // TODO: Implement delete logic
  }

  void _handleMoreActions(MailDetail mailDetail) {
    debugPrint('⋯ More actions for: ${mailDetail.subject}');

    MailDetailActionSheet.show(
      context: context,
      mailDetail: mailDetail,
      currentUserEmail: widget.userEmail,
      onActionSelected: (action) {
        debugPrint('🎯 Action selected: $action');
        // TODO: Handle selected action
      },
    );
  }
}