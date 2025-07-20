// lib/src/features/mail/presentation/pages/mobile/mail_detail_mobile.dart
// 🎯 Stack Layout Integration - Bottom Bar ile InAppWebView gesture conflict önleme
// ✅ Header ve Attachments section kaldırıldı - Full-screen UnifiedHtmlRenderer

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
//import 'package:korgan/src/features/mail/presentation/widgets/mobile/unified_html_render/unified_html_renderer.dart';
//import 'package:korgan/src/features/mail/presentation/pages/test/yandex_unified_mail_editor.dart';
import '../../../domain/entities/mail_detail.dart';
import '../../providers/mail_providers.dart';
import '../../widgets/mobile/mail_detail_actions/mail_detail_bottom_bar.dart';
import '../../widgets/mobile/mail_detail_actions/mail_detail_action_sheet.dart';
import '../../widgets/mobile/htmlrender/html_mail_renderer.dart';
import '../../widgets/mobile/htmlrender/models/render_mode.dart';
//import '../../widgets/mail_item/platform/mobile/mail_detail_attachments_section_mobile.dart';
import '../../widgets/mobile/attachments/attachments_widget_mobile.dart';

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

    // Load mail detail when page opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMailDetail();
    });
  }

  /// Load mail detail
  void _loadMailDetail() {
    ref
        .read(mailDetailProvider.notifier)
        .loadMailDetail(mailId: widget.mailId, email: widget.userEmail);
  }

  @override
  Widget build(BuildContext context) {
    // Watch mail detail state
    final mailDetail = ref.watch(currentMailDetailProvider);
    final isLoading = ref.watch(mailDetailLoadingProvider);
    final error = ref.watch(mailDetailErrorProvider);

    // 🎯 STACK LAYOUT: Scaffold with Stack body to prevent gesture conflicts
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(context, mailDetail),
      body: _buildStackLayoutBody(context, mailDetail, isLoading, error),
      // 🚫 FloatingActionButton kaldırıldı - artık bottom bar'da reply butonu var
    );
  }

  /// 🎯 STACK LAYOUT: Ana body - WebView ve Bottom Bar ayrı layer'larda
  Widget _buildStackLayoutBody(
    BuildContext context,
    MailDetail? mailDetail,
    bool isLoading,
    String? error,
  ) {
    // Bottom bar height hesapla - safe area dahil
    final mediaQuery = MediaQuery.of(context);
    final bottomBarTotalHeight =
        MailDetailBottomBar.height +
        mediaQuery.padding.bottom +
        MailDetailBottomBar.safeAreaPadding;

    return Stack(
      children: [
        
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          bottom: bottomBarTotalHeight, // Bottom bar için alan bırak
          child: _buildContentArea(context, mailDetail, isLoading, error),
        ),

        
        if (mailDetail != null) // Sadece mail yüklendiğinde göster
          Positioned(
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
              isEnabled: !isLoading, // Loading durumunda disable
            ),
          ),
      ],
    );
  }

  /// ✅ Content area
Widget _buildContentArea(
    BuildContext context,
    MailDetail? mailDetail,
    bool isLoading,
    String? error,
  ) {
    if (isLoading) {
      return _buildLoadingWidget();
    }

    if (error != null) {
      return _buildErrorWidget(error);
    }

    if (mailDetail == null) {
      return _buildNotFoundWidget();
    }

    // 🎯 SINGLE SCROLL: Gesture conflicts önlendi
    return SingleChildScrollView(
      // 🔧 Taşma önleme (araştırmada önerilen)
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: [
          // 🆕 WebView - Dinamik yükseklik + gesture recognizer
SizedBox(
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

          // 🆕 Attachments - WebView altında
          if (mailDetail.hasAttachments && mailDetail.attachmentsList.isNotEmpty)
 AttachmentsWidgetMobile(mailDetail: mailDetail),
        ],
      ),
    );
  }
  /// Build AppBar - Basitleştirilmiş versiyon, bottom bar'da actions var
  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    MailDetail? mailDetail,
  ) {
    return AppBar(
      title: Text(mailDetail?.senderName ?? 'Mail Detail'),
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        // Sadece star butonu kaldı - diğerleri bottom bar'da
        if (mailDetail != null)
          IconButton(
            icon: Icon(
              mailDetail.isStarred ? Icons.star : Icons.star_border,
              color: mailDetail.isStarred ? Colors.amber : Colors.white,
            ),
            onPressed: () => _toggleStar(mailDetail),
          ),
      ],
    );
  }


  // ========== ACTION HANDLERS ==========

  /// Reply to mail action
  void _replyToMail(MailDetail mailDetail) {
    debugPrint('🚀 Opening reply editor for: ${mailDetail.subject}');

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text('Yanıtla: ${mailDetail.senderName}'),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          body: HtmlMailRenderer(
            mode: RenderMode.editor,
            mailDetail: mailDetail,
            currentUserEmail: widget.userEmail,
            onSend: () {
              // TODO: Send logic
              Navigator.pop(context);
            },
            onContentChanged: (content) {
              // TODO: Content change logic
            },
          ),
        ),
      ),
    );
  }

  /// Toggle star status
  void _toggleStar(MailDetail mailDetail) {
    debugPrint('⭐ Toggle star for: ${mailDetail.subject}');
    // TODO: Implement star toggle logic
  }

  /// Handle forward action
  void _handleForward(MailDetail mailDetail) {
    debugPrint('📤 Forward mail: ${mailDetail.subject}');
    // TODO: Implement forward logic
  }

  /// Handle mark important action
  void _handleMarkImportant(MailDetail mailDetail) {
    debugPrint('❗ Mark important: ${mailDetail.subject}');
    // TODO: Implement mark important logic
  }

  /// Handle delete action
  void _handleDelete(MailDetail mailDetail) {
    debugPrint('🗑️ Delete mail: ${mailDetail.subject}');
    // TODO: Implement delete logic
  }

  /// Handle more actions
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

  // ========== UI STATE WIDGETS ==========

  /// Loading widget
  Widget _buildLoadingWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Mail yükleniyor...'),
        ],
      ),
    );
  }

  /// Error widget
  Widget _buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Hata: $error',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadMailDetail,
            child: const Text('Tekrar Dene'),
          ),
        ],
      ),
    );
  }

  /// Not found widget
  Widget _buildNotFoundWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.mail_outline, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Mail bulunamadı',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}