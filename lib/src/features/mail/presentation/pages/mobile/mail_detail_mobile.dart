// lib/src/features/mail/presentation/pages/mobile/mail_detail_mobile.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
                          ? 'Okunmadı İşaretle'
                          : 'Okundu İşaretle',
                    ),
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
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 20, color: Colors.red),
                    SizedBox(width: 12),
                    Text('Sil', style: TextStyle(color: Colors.red)),
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
    // Error state
    if (error != null) {
      return _buildErrorState(context, error);
    }

    // Loading state
    if (isLoading) {
      return _buildLoadingState(context);
    }

    // No data state
    if (mailDetail == null) {
      return _buildNoDataState(context);
    }

    // Success state
    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMailHeader(context, mailDetail),
            const SizedBox(height: 24),
            _buildMailContent(context, mailDetail),
          ],
        ),
      ),
    );
  }

  /// Build error state
  Widget _buildErrorState(BuildContext context, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Hata Oluştu',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadMailDetail,
              icon: const Icon(Icons.refresh),
              label: const Text('Yeniden Dene'),
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

  /// Build loading state
  Widget _buildLoadingState(BuildContext context) {
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

  /// Build no data state
  Widget _buildNoDataState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.mail_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Mail Bulunamadı',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Bu mail artık mevcut olmayabilir.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
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

  /// Build mail content section
  Widget _buildMailContent(BuildContext context, MailDetail mailDetail) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Content type indicator
          Row(
            children: [
              Icon(
                mailDetail.hasHtmlContent ? Icons.web : Icons.text_fields,
                size: 16,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 8),
              Text(
                mailDetail.hasHtmlContent ? 'HTML İçerik' : 'Metin İçerik',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              if (mailDetail.sizeBytes != null)
                Text(
                  mailDetail.formattedSize,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Content
          SelectableText(
            mailDetail.displayContent,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
          ),
        ],
      ),
    );
  }

  /// Build floating action button
  Widget _buildFAB(BuildContext context, MailDetail mailDetail) {
    return FloatingActionButton(
      onPressed: () => _onReply(mailDetail),
      backgroundColor: Colors.blue,
      child: const Icon(Icons.reply, color: Colors.white),
    );
  }

  // ========== ACTION METHODS ==========

  /// Refresh mail detail
  Future<void> _onRefresh() async {
    ref
        .read(mailDetailProvider.notifier)
        .refreshCurrentMail(email: widget.userEmail);
  }

  /// Handle menu selection
  void _onMenuSelected(String value, MailDetail mailDetail) {
    switch (value) {
      case 'mark_read':
        _toggleReadStatus(mailDetail);
        break;
      case 'archive':
        _archiveMail(mailDetail);
        break;
      case 'delete':
        _deleteMail(mailDetail);
        break;
    }
  }

  /// Toggle star status
  void _toggleStar(MailDetail mailDetail) {
    // TODO: Implement star toggle
    _showSnackBar(mailDetail.isStarred ? 'Yıldız kaldırıldı' : 'Yıldızlandı ⭐');
  }

  /// Toggle read status
  void _toggleReadStatus(MailDetail mailDetail) {
    // TODO: Implement read status toggle
    _showSnackBar(
      mailDetail.isRead
          ? 'Okunmadı olarak işaretlendi'
          : 'Okundu olarak işaretlendi',
    );
  }

  /// Archive mail
  void _archiveMail(MailDetail mailDetail) {
    // TODO: Implement archive
    _showSnackBar('${mailDetail.senderName} arşivlendi');
    Navigator.of(context).pop();
  }

  /// Delete mail
  void _deleteMail(MailDetail mailDetail) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mail\'i Sil'),
        content: Text(
          '${mailDetail.senderName} mail\'ini silmek istediğinizden emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Implement delete
              _showSnackBar('${mailDetail.senderName} silindi');
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  /// Reply to mail
  void _onReply(MailDetail mailDetail) {
    // TODO: Implement reply
    _showSnackBar('Yanıtla özelliği yakında eklenecek');
  }

  // ========== UTILITY METHODS ==========

  /// Get avatar color based on sender name
  Color _getAvatarColor(String senderName) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.red,
      Colors.indigo,
      Colors.pink,
    ];

    final index = senderName.hashCode % colors.length;
    return colors[index.abs()];
  }

  /// Get avatar initial
  String _getAvatarInitial(String senderName) {
    if (senderName.isEmpty) return '?';
    return senderName[0].toUpperCase();
  }

  /// Get label color
  Color _getLabelColor(String label) {
    switch (label.toUpperCase()) {
      case 'IMPORTANT':
        return Colors.red;
      case 'STARRED':
        return Colors.amber;
      case 'INBOX':
        return Colors.blue;
      case 'SENT':
        return Colors.green;
      case 'DRAFT':
        return Colors.orange;
      case 'SPAM':
        return Colors.red;
      case 'TRASH':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  /// Get label display name
  String _getLabelDisplayName(String label) {
    switch (label.toUpperCase()) {
      case 'IMPORTANT':
        return 'Önemli';
      case 'STARRED':
        return 'Yıldızlı';
      case 'INBOX':
        return 'Gelen';
      case 'SENT':
        return 'Gönderilen';
      case 'DRAFT':
        return 'Taslak';
      case 'SPAM':
        return 'Spam';
      case 'TRASH':
        return 'Çöp';
      case 'CATEGORY_PERSONAL':
        return 'Kişisel';
      case 'CATEGORY_SOCIAL':
        return 'Sosyal';
      case 'CATEGORY_PROMOTIONS':
        return 'Promosyon';
      case 'CATEGORY_UPDATES':
        return 'Güncelleme';
      case 'CATEGORY_FORUMS':
        return 'Forum';
      default:
        return label;
    }
  }

  /// Show snackbar message
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
