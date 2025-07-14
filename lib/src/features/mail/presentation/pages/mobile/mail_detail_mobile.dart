// lib/src/features/mail/presentation/pages/mobile/mail_detail_mobile.dart
// 🎯 Stack Layout Integration - Bottom Bar ile InAppWebView gesture conflict önleme

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:korgan/src/features/mail/presentation/widgets/mobile/unified_html_render/unified_html_renderer.dart';
import 'package:korgan/src/features/mail/presentation/pages/test/yandex_unified_mail_editor.dart';
import '../../../domain/entities/mail_detail.dart';
import '../../providers/mail_providers.dart';
import '../../widgets/mobile/mail_detail_actions/mail_detail_bottom_bar.dart';
import '../../widgets/mobile/mail_detail_actions/mail_detail_action_sheet.dart';
import '../../widgets/mobile/mail_detail_actions/mail_detail_actions_models.dart';

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
        // 🎯 WebView Area - bottom bar yüksekliği kadar yukarıda
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          bottom: bottomBarTotalHeight, // Bottom bar için alan bırak
          child: _buildContentArea(context, mailDetail, isLoading, error),
        ),

        // 🎯 Bottom Bar - Stack'in en üstünde, gesture conflict yok
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

  /// Content area - WebView veya loading/error states
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

    // Mail content - WebView ile render
    return Column(
      children: [
        // Header section - Fixed height
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildMailHeader(context, mailDetail),
              if (mailDetail.hasAttachments) ...[
                const SizedBox(height: 16),
                _buildAttachmentsSection(context, mailDetail),
              ],
            ],
          ),
        ),

        // Content area - WebView için expanded
        Expanded(child: _buildMailContent(context, mailDetail)),
      ],
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

  /// Build mail content with WebView
  Widget _buildMailContent(BuildContext context, MailDetail mailDetail) {
    // Determine which content to show
    final String contentToRender = mailDetail.hasHtmlContent
        ? mailDetail.htmlContent
        : mailDetail.textContent.isNotEmpty
        ? _convertTextToHtml(mailDetail.textContent)
        : _convertTextToHtml(mailDetail.displayContent);

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Content type indicator
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(
                  mailDetail.hasHtmlContent ? Icons.web : Icons.text_fields,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 8),
                Text(
                  mailDetail.hasHtmlContent ? 'HTML İçerik' : 'Metin İçerik',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
          ),

          // 🎯 WebView content - Stack layout ile conflict yok
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              child: UnifiedHtmlRenderer(
                htmlContent: contentToRender,
                mailDetail: mailDetail,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build mail header section
  Widget _buildMailHeader(BuildContext context, MailDetail mailDetail) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subject
          Text(
            mailDetail.subject,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          // Sender info
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: _getAvatarColor(mailDetail.senderName),
                child: Text(
                  _getAvatarInitial(mailDetail.senderName),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mailDetail.senderName,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      mailDetail.senderEmail,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build attachments section
  Widget _buildAttachmentsSection(BuildContext context, MailDetail mailDetail) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.attach_file,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Ek Dosyalar',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Ek dosyalar: ${mailDetail.attachmentCount} adet',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  // ========== BOTTOM BAR ACTION HANDLERS ==========

  /// Reply to mail action - mevcut implementation
  void _replyToMail(MailDetail mailDetail) {
    debugPrint('📧 Reply action triggered from bottom bar');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => YandexUnifiedMailEditor(
          mailDetail: mailDetail,
          currentUserEmail: widget.userEmail,
        ),
      ),
    );
  }

  /// Forward mail action - placeholder
  void _handleForward(MailDetail mailDetail) {
    debugPrint('📤 Forward action - placeholder implementation');

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📤 İletme özelliği yakında!'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  /// Mark important action - placeholder
  void _handleMarkImportant(MailDetail mailDetail) {
    debugPrint('⭐ Mark important action - placeholder implementation');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          mailDetail.isImportant
              ? '⭐ Önemli işareti kaldırıldı!'
              : '⭐ Önemli olarak işaretlendi!',
        ),
        backgroundColor: Colors.amber,
      ),
    );
  }

  /*
  /// Archive action (artık action sheet'te)
  void _handleArchive(MailDetail mailDetail) {
    debugPrint('📁 Archive action - placeholder implementation');

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📁 Arşivleme özelliği yakında!'),
        backgroundColor: Colors.green,
      ),
    );
  }
*/
  /// Delete mail action - placeholder with confirmation
  void _handleDelete(MailDetail mailDetail) {
    debugPrint('🗑️ Delete action - placeholder implementation');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🗑️ Maili Sil'),
        content: const Text(
          'Bu maili çöp kutusuna taşımak istediğinizden emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('🗑️ Silme özelliği yakında!'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  /// More actions - action sheet göster
  void _handleMoreActions(MailDetail mailDetail) {
    debugPrint('⋮ More actions - opening action sheet');

    MailDetailActionSheet.show(
      context: context,
      mailDetail: mailDetail,
      currentUserEmail: widget.userEmail,
      onActionSelected: (action) =>
          _handleActionSheetSelection(action, mailDetail),
    );
  }

  /// Action sheet selection handler
  void _handleActionSheetSelection(MailAction action, MailDetail mailDetail) {
    debugPrint('🎯 Action sheet selection: ${action.name}');

    switch (action) {
      case MailAction.markRead:
        _toggleRead(mailDetail);
        break;
      case MailAction.markUnread:
        _toggleRead(mailDetail);
        break;
      case MailAction.markImportant:
        _handleMarkImportant(mailDetail);
        break;
      case MailAction.addLabel:
        _handleAddLabel(mailDetail);
        break;
      case MailAction.spam:
        _handleSpam(mailDetail);
        break;
      case MailAction.permanent:
        _handlePermanent(mailDetail);
        break;
      case MailAction.createRule:
        _handleCreateRule(mailDetail);
        break;
      case MailAction.translate:
        _handleTranslate(mailDetail);
        break;
      case MailAction.print:
        _handlePrint(mailDetail);
        break;
      default:
        _handleUnknownAction(action);
        break;
    }
  }

  // ========== ACTION SHEET ACTION HANDLERS ==========

  /// Toggle read/unread status
  void _toggleRead(MailDetail mailDetail) {
    debugPrint('📧 Toggle read status - placeholder implementation');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          mailDetail.isRead
              ? '📧 Okunmadı olarak işaretlendi!'
              : '✅ Okundu olarak işaretlendi!',
        ),
        backgroundColor: Colors.blue,
      ),
    );
  }

  /// Add label / Move to folder
  void _handleAddLabel(MailDetail mailDetail) {
    debugPrint('📁 Add label action - placeholder implementation');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('📁 Klasör Seç'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.inbox),
              title: const Text('Gelen Kutusu'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('📁 Klasör taşıma özelliği yakında!'),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.archive),
              title: const Text('Arşiv'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('📁 Arşivleme özelliği yakında!'),
                  ),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
        ],
      ),
    );
  }

  /// Spam action
  void _handleSpam(MailDetail mailDetail) {
    debugPrint('🚫 Spam action - placeholder implementation');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🚫 Spam Olarak İşaretle'),
        content: const Text(
          'Bu maili spam olarak işaretlemek istediğinizden emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('🚫 Spam işaretleme özelliği yakında!'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Spam Olarak İşaretle'),
          ),
        ],
      ),
    );
  }

  /// Permanent action
  void _handlePermanent(MailDetail mailDetail) {
    debugPrint('📌 Permanent action - placeholder implementation');

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📌 Sabitleme özelliği yakında!'),
        backgroundColor: Colors.purple,
      ),
    );
  }

  /// Create rule action
  void _handleCreateRule(MailDetail mailDetail) {
    debugPrint('⚙️ Create rule action - placeholder implementation');

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('⚙️ Kural oluşturma özelliği yakında!'),
        backgroundColor: Colors.indigo,
      ),
    );
  }

  /// Translate action
  void _handleTranslate(MailDetail mailDetail) {
    debugPrint('🌐 Translate action - placeholder implementation');

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🌐 Çeviri özelliği yakında!'),
        backgroundColor: Colors.teal,
      ),
    );
  }

  /// Print action
  void _handlePrint(MailDetail mailDetail) {
    debugPrint('🖨️ Print action - placeholder implementation');

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🖨️ Yazdırma özelliği yakında!'),
        backgroundColor: Colors.brown,
      ),
    );
  }

  /// Unknown action fallback
  void _handleUnknownAction(MailAction action) {
    debugPrint('❓ Unknown action: ${action.name}');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('❓ Bilinmeyen işlem: ${action.name}'),
        backgroundColor: Colors.grey,
      ),
    );
  }

  // ========== EXISTING METHODS - Star toggle ==========

  /// Toggle star status
  void _toggleStar(MailDetail mailDetail) {
    debugPrint('⭐ Toggle star status - placeholder implementation');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          mailDetail.isStarred ? 'Yıldız kaldırıldı' : 'Yıldızlandı ⭐',
        ),
      ),
    );
  }

  // ========== UTILITY METHODS ==========

  /// Convert text content to HTML
  String _convertTextToHtml(String textContent) {
    if (textContent.isEmpty) {
      return '<p>Bu mailde içerik bulunmuyor.</p>';
    }

    return '''
    <div style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; 
                font-size: 16px; line-height: 1.5; color: #333; padding: 16px;">
      <p>${textContent.replaceAll('\n', '<br>').replaceAll(RegExp(r'(https?://[^\s]+)'), '<a href="\$1" target="_blank">\$1</a>')}</p>
    </div>
    ''';
  }

  /// Get avatar color for sender
  Color _getAvatarColor(String senderName) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
    ];

    final index = senderName.hashCode % colors.length;
    return colors[index.abs()];
  }

  /// Get avatar initial for sender
  String _getAvatarInitial(String senderName) {
    if (senderName.isEmpty) return '?';

    final words = senderName.split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    } else {
      return senderName[0].toUpperCase();
    }
  }

  // ========== LOADING/ERROR WIDGETS ==========

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
          const Text(
            'Mail yüklenirken hata oluştu',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
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
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Bu mail silinmiş veya taşınmış olabilir.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
