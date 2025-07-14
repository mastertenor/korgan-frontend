// lib/src/features/mail/presentation/pages/mobile/mail_detail_mobile.dart
// Fixed version with proper scrolling for long content

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:korgan/src/features/mail/presentation/widgets/mobile/unified_html_render/unified_html_renderer.dart';
import 'package:korgan/src/features/mail/presentation/pages/test/yandex_unified_mail_editor.dart';
import '../../../domain/entities/mail_detail.dart';
import '../../providers/mail_providers.dart';

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

    return Scaffold(
      appBar: _buildAppBar(context, mailDetail),
      body: _buildBody(context, mailDetail, isLoading, error),
      floatingActionButton: mailDetail != null
          ? _buildFAB(context, mailDetail)
          : null,
    );
  }

  /// Build AppBar
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
        if (mailDetail != null) ...[
          IconButton(
            icon: Icon(
              mailDetail.isStarred ? Icons.star : Icons.star_border,
              color: mailDetail.isStarred ? Colors.amber : Colors.white,
            ),
            onPressed: () => _toggleStar(mailDetail),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) => _onMenuSelected(value, mailDetail),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'mark_read',
                child: Row(
                  children: [
                    Icon(
                      mailDetail.isRead
                          ? Icons.mark_email_unread
                          : Icons.mark_email_read,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      mailDetail.isRead
                          ? 'Okunmadı olarak işaretle'
                          : 'Okundu olarak işaretle',
                    ),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 20),
                    SizedBox(width: 12),
                    Text('Sil'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'archive',
                child: Row(
                  children: [
                    Icon(Icons.archive, size: 20),
                    SizedBox(width: 12),
                    Text('Arşivle'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  /// Build main body - 🔧 SCROLL FIX: Removed SingleChildScrollView to let WebView handle scrolling
  Widget _buildBody(
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

    // 🔧 SCROLL FIX: Use Column with Expanded for proper WebView sizing
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

        // 🔧 SCROLL FIX: Expanded content area for WebView
        Expanded(child: _buildMailContent(context, mailDetail)),
      ],
    );
  }

  /// 🔧 SCROLL FIX: Build mail content with full screen WebView
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
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                if (mailDetail.hasHtmlContent)
                  Chip(
                    label: const Text('Rich'),
                    backgroundColor: Colors.green.withOpacity(0.1),
                    labelStyle: const TextStyle(
                      fontSize: 10,
                      color: Colors.green,
                    ),
                  ),
              ],
            ),
          ),

          // 🔧 SCROLL FIX: Expanded UnifiedHtmlRenderer to fill available space
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              child: UnifiedHtmlRenderer(
                htmlContent: contentToRender,
                mailDetail: mailDetail,
                isReplyMode: false, // Normal view mode
                onReplyTextChanged: (text) {
                  // Handle reply text changes (future feature)
                  debugPrint('Reply text changed: $text');
                },
                onReply: () {
                  // Handle reply action (future feature)
                  _replyToMail(mailDetail);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Convert plain text to basic HTML
  String _convertTextToHtml(String text) {
    if (text.isEmpty) return '<p>İçerik bulunamadı.</p>';

    return '''
    <div style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; line-height: 1.6; color: #333; padding: 16px;">
      <p>${text.replaceAll('\n\n', '</p><p>').replaceAll('\n', '<br>').replaceAll(RegExp(r'(https?://[^\s]+)'), '<a href="\$1" target="_blank">\$1</a>')}</p>
    </div>
    ''';
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
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      mailDetail.senderEmail ?? '',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                mailDetail.time,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
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
              const Icon(Icons.attach_file, size: 20),
              const SizedBox(width: 8),
              Text(
                'Ekler (${mailDetail.attachmentCount})',
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

  /// FAB for reply
  Widget _buildFAB(BuildContext context, MailDetail mailDetail) {
    return FloatingActionButton.extended(
      onPressed: () => _replyToMail(mailDetail),
      icon: const Icon(Icons.reply),
      label: const Text('Yanıtla'),
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
    );
  }

  /// Reply to mail action
  void _replyToMail(MailDetail mailDetail) {
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

  // ========== MENU ACTIONS ==========

  void _onMenuSelected(String value, MailDetail mailDetail) {
    switch (value) {
      case 'mark_read':
        _toggleRead(mailDetail);
        break;
      case 'delete':
        _deleteMail(mailDetail);
        break;
      case 'archive':
        _archiveMail(mailDetail);
        break;
    }
  }

  void _toggleStar(MailDetail mailDetail) {
    // TODO: Implement star toggle
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          mailDetail.isStarred ? 'Yıldız kaldırıldı' : 'Yıldızlandı ⭐',
        ),
      ),
    );
  }

  void _toggleRead(MailDetail mailDetail) {
    // TODO: Implement read toggle
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          mailDetail.isRead
              ? 'Okunmadı olarak işaretlendi'
              : 'Okundu olarak işaretlendi',
        ),
      ),
    );
  }

  void _deleteMail(MailDetail mailDetail) {
    // TODO: Implement delete
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Mail silindi')));
    Navigator.of(context).pop();
  }

  void _archiveMail(MailDetail mailDetail) {
    // TODO: Implement archive
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Mail arşivlendi')));
    Navigator.of(context).pop();
  }

  // ========== UTILITY METHODS ==========

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
          Text('Hata: $error'),
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
          Text('Mail bulunamadı'),
        ],
      ),
    );
  }

  /// Get avatar color based on name
  Color _getAvatarColor(String name) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
    ];
    return colors[name.hashCode % colors.length];
  }

  /// Get avatar initial
  String _getAvatarInitial(String name) {
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}
