// lib/src/features/mail/presentation/pages/mobile/mail_detail_mobile.dart
// Updated with UnifiedHtmlRenderer integration

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:korgan/src/features/mail/presentation/widgets/mail_content/unified_html_renderer.dart';
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

  /// Build main body
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mail header section
          _buildMailHeader(context, mailDetail),
          const SizedBox(height: 16),

          // 🆕 NEW: HTML Content with UnifiedHtmlRenderer
          _buildMailContent(context, mailDetail),

          // Attachments section (if any)
          if (mailDetail.hasAttachments) ...[
            const SizedBox(height: 16),
            _buildAttachmentsSection(context, mailDetail),
          ],

          // Extra spacing for FAB
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  /// 🆕 NEW: Build mail content with UnifiedHtmlRenderer
  Widget _buildMailContent(BuildContext context, MailDetail mailDetail) {
    // Determine which content to show
    final String contentToRender = mailDetail.hasHtmlContent
        ? mailDetail.htmlContent
        : mailDetail.textContent.isNotEmpty
        ? _convertTextToHtml(mailDetail.textContent)
        : _convertTextToHtml(mailDetail.displayContent);

    return Container(
      width: double.infinity,
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

          // 🚀 UnifiedHtmlRenderer Integration
          UnifiedHtmlRenderer(
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
        ],
      ),
    );
  }

  /// Convert plain text to basic HTML
  String _convertTextToHtml(String text) {
    if (text.isEmpty) return '<p>İçerik bulunamadı.</p>';

    return '''
    <div style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; line-height: 1.6; color: #333;">
      ${text.replaceAll('\n\n', '</p><p>').replaceAll('\n', '<br>').replaceAll(RegExp(r'(https?://[^\s]+)'), '<a href="\$1" target="_blank">\$1</a>')}
    </div>
    ''';
  }

  /// Build mail header section (EXISTING CODE - UNCHANGED)
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
                      mailDetail.senderEmail,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    mailDetail.time,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  if (mailDetail.hasAttachments)
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Icon(
                        Icons.attach_file,
                        size: 16,
                        color: Colors.grey,
                      ),
                    ),
                ],
              ),
            ],
          ),

          // Recipients (if multiple)
          if (mailDetail.recipients.length > 1) ...[
            const SizedBox(height: 12),
            Text(
              'To: ${mailDetail.recipients.join(', ')}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],

          // Labels
          if (mailDetail.labels.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: mailDetail.labels.map((label) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getLabelColor(label).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getLabelColor(label).withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    _getLabelDisplayName(label),
                    style: TextStyle(
                      fontSize: 11,
                      color: _getLabelColor(label),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  /// Build attachments section (EXISTING CODE - UNCHANGED)
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

  /// 🆕 NEW: FAB for reply
  Widget _buildFAB(BuildContext context, MailDetail mailDetail) {
    return FloatingActionButton.extended(
      onPressed: () => _replyToMail(mailDetail),
      icon: const Icon(Icons.reply),
      label: const Text('Yanıtla'),
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
    );
  }

  /// 🆕 NEW: Reply to mail action
  void _replyToMail(MailDetail mailDetail) {
    // TODO: Navigate to reply page or show reply interface
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yanıtla'),
        content: Text('${mailDetail.senderName} adresine yanıt gönderilecek.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Implement reply functionality
            },
            child: const Text('Yanıtla'),
          ),
        ],
      ),
    );
  }

  // ========== EXISTING HELPER METHODS (UNCHANGED) ==========

  /// Build loading widget
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

  /// Build error widget
  Widget _buildErrorWidget(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Hata Oluştu',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Colors.red[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _loadMailDetail(),
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

  /// Build not found widget
  Widget _buildNotFoundWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.mail_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Mail Bulunamadı',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Bu mail artık mevcut değil veya silinmiş olabilir.',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Geri Dön'),
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

  // ========== ACTION HANDLERS (EXISTING) ==========

  void _toggleStar(MailDetail mailDetail) {
    // TODO: Implement star toggle
    debugPrint('Toggle star for: ${mailDetail.id}');
  }

  void _onMenuSelected(String value, MailDetail mailDetail) {
    switch (value) {
      case 'mark_read':
        // TODO: Toggle read status
        debugPrint('Toggle read status: ${mailDetail.id}');
        break;
      case 'delete':
        // TODO: Delete mail
        debugPrint('Delete mail: ${mailDetail.id}');
        break;
      case 'archive':
        // TODO: Archive mail
        debugPrint('Archive mail: ${mailDetail.id}');
        break;
    }
  }

  // ========== UTILITY METHODS (EXISTING) ==========

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

  String _getAvatarInitial(String name) {
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  Color _getLabelColor(String label) {
    switch (label.toUpperCase()) {
      case 'INBOX':
        return Colors.blue;
      case 'IMPORTANT':
        return Colors.red;
      case 'STARRED':
        return Colors.amber;
      case 'SENT':
        return Colors.green;
      case 'DRAFTS':
        return Colors.orange;
      case 'SPAM':
        return Colors.red.shade800;
      case 'TRASH':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _getLabelDisplayName(String label) {
    switch (label.toUpperCase()) {
      case 'INBOX':
        return 'Gelen Kutusu';
      case 'IMPORTANT':
        return 'Önemli';
      case 'STARRED':
        return 'Yıldızlı';
      case 'SENT':
        return 'Gönderilmiş';
      case 'DRAFTS':
        return 'Taslaklar';
      case 'SPAM':
        return 'Spam';
      case 'TRASH':
        return 'Çöp Kutusu';
      default:
        return label;
    }
  }
}
