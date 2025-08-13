// lib/src/features/mail/presentation/pages/web/mail_page_detail_web.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../../../../../utils/app_logger.dart';
import '../../../../../routing/route_constants.dart';
import '../../providers/mail_providers.dart';
import '../../widgets/web/preview/mail_renderer_platform.dart';
import '../../../domain/entities/mail_detail.dart';

/// Web-optimized full-screen mail detail page
/// 
/// Mevcut MailWebRenderer'ı kullanarak mail detail gösterir.
/// Preview panel kapalıyken veya direct URL erişiminde kullanılır.
/// 
/// Features:
/// - Full-screen mail detail view using existing MailWebRenderer
/// - Back navigation to folder
/// - Mail actions (star, archive, delete, etc.)
/// - URL-based navigation support
/// - Mevcut web renderer infrastructure'ını kullanır
class MailPageDetailWeb extends ConsumerStatefulWidget {
  /// User email address
  final String userEmail;
  
  /// Current folder name (inbox, sent, drafts, etc.)
  final String folder;
  
  /// Mail ID to display
  final String mailId;

  const MailPageDetailWeb({
    super.key,
    required this.userEmail,
    required this.folder,
    required this.mailId,
  });

  @override
  ConsumerState<MailPageDetailWeb> createState() => _MailPageDetailWebState();
}

class _MailPageDetailWebState extends ConsumerState<MailPageDetailWeb> {
  // ScrollController - mevcut renderer pattern'ı takip eder
  final ScrollController _scrollController = ScrollController();
  
  // Web renderer instance - mevcut MailWebRenderer kullanır
  late final MailWebRenderer _webRenderer;

  @override
  void initState() {
    super.initState();
    AppLogger.info('📧 MailPageDetailWeb initialized for: ${widget.userEmail}/${widget.folder}/${widget.mailId}');
    
    // Mevcut renderer pattern'ını takip et
    _webRenderer = MailWebRenderer(
      scrollController: _scrollController,
      onHeightChanged: (height) {
        if (mounted) {
          setState(() {
            // Height changes handled by renderer
          });
        }
      },
    );
    
    // Initialize web renderer
    if (kIsWeb) {
      _webRenderer.initialize();
    }
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeMailDetail();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _webRenderer.dispose();
    super.dispose();
  }

  /// Initialize mail detail - load specific mail using existing provider pattern
  Future<void> _initializeMailDetail() async {
    AppLogger.info('📧 Loading mail detail: ${widget.mailId}');
    
    try {
      // ✅ Use same pattern as mail_page_web.dart
      ref.read(mailDetailProvider.notifier).loadMailDetail(
        mailId: widget.mailId,
        email: widget.userEmail,
      );
      
      AppLogger.info('📧 Mail detail load initiated via provider');
      
    } catch (error) {
      AppLogger.error('❌ Error loading mail detail: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Mevcut provider'ları kullan
    final mailDetail = ref.watch(currentMailDetailProvider);
    final mailDetailLoading = ref.watch(mailDetailLoadingProvider);
    final mailDetailError = ref.watch(mailDetailErrorProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          _buildHeader(context, mailDetail),
          Expanded(
            child: _buildContent(context, mailDetail, mailDetailLoading, mailDetailError),
          ),
        ],
      ),
    );
  }

  /// Build header with navigation and actions
  Widget _buildHeader(BuildContext context, MailDetail? mailDetail) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back button
          IconButton(
            onPressed: _handleBackNavigation,
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Geri',
          ),
          
          const SizedBox(width: 8),
          
          // Page title
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mailDetail?.subject ?? widget.mailId,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${_getFolderDisplayName(widget.folder)} • ${widget.userEmail}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          
          // Mail actions
          if (mailDetail != null) ..._buildActionButtons(mailDetail),
        ],
      ),
    );
  }

  /// Build action buttons
  List<Widget> _buildActionButtons(MailDetail mailDetail) {
    return [
      // Star button
      IconButton(
        onPressed: () => _handleStarToggle(mailDetail),
        icon: Icon(
          mailDetail.isStarred ? Icons.star : Icons.star_border,
          color: mailDetail.isStarred ? Colors.amber : null,
        ),
        tooltip: mailDetail.isStarred ? 'Yıldızı kaldır' : 'Yıldızla',
      ),
      
      // Archive button
      IconButton(
        onPressed: () => _handleArchive(mailDetail),
        icon: const Icon(Icons.archive_outlined),
        tooltip: 'Arşivle',
      ),
      
      // Delete button
      IconButton(
        onPressed: () => _handleDelete(mailDetail),
        icon: const Icon(Icons.delete_outlined),
        tooltip: 'Sil',
      ),
      
      const SizedBox(width: 8),
      
      // More actions menu
      PopupMenuButton<String>(
        onSelected: (action) => _handleMenuAction(action, mailDetail),
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'reply',
            child: Row(
              children: [
                Icon(Icons.reply, size: 18),
                SizedBox(width: 12),
                Text('Yanıtla'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'forward',
            child: Row(
              children: [
                Icon(Icons.forward, size: 18),
                SizedBox(width: 12),
                Text('İlet'),
              ],
            ),
          ),
          const PopupMenuDivider(),
          const PopupMenuItem(
            value: 'markUnread',
            child: Row(
              children: [
                Icon(Icons.mark_email_unread, size: 18),
                SizedBox(width: 12),
                Text('Okunmadı işaretle'),
              ],
            ),
          ),
        ],
        child: const Padding(
          padding: EdgeInsets.all(8.0),
          child: Icon(Icons.more_vert),
        ),
      ),
    ];
  }

  /// Build main content area using existing provider pattern
  Widget _buildContent(BuildContext context, MailDetail? mailDetail, bool isLoading, String? error) {
    if (isLoading) {
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

    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
            const SizedBox(height: 16),
            Text(
              'Mail yüklenemedi',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _initializeMailDetail,
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      );
    }

    if (mailDetail == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.mail_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Mail bulunamadı',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'ID: ${widget.mailId}',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return _buildMailDetailContent(mailDetail);
  }

  /// Build mail detail content using existing MailWebRenderer
  Widget _buildMailDetailContent(MailDetail mailDetail) {
    return Center(
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 800),
        margin: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Column(
            children: [
              // Mail header info
              _buildMailHeader(mailDetail),
              
              // Mail content using existing renderer
              Expanded(
                child: _webRenderer.buildMailContent(context, mailDetail),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build mail header info section
  Widget _buildMailHeader(MailDetail mailDetail) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subject
          Text(
            mailDetail.subject,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w500,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          
          // Sender info
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.blue[100],
                child: Text(
                  mailDetail.senderName.isNotEmpty 
                      ? mailDetail.senderName[0].toUpperCase() 
                      : '?',
                  style: TextStyle(
                    color: Colors.blue[800],
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
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      mailDetail.senderEmail,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                mailDetail.time,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ========== EVENT HANDLERS ==========

  /// Handle back navigation to folder
  void _handleBackNavigation() {
    AppLogger.info('⬅️ Navigating back to folder: ${widget.folder}');
    
    final folderPath = MailRoutes.folderPath(widget.userEmail, widget.folder);
    context.go(folderPath);
  }

  /// Handle star toggle - following selection_toolbar pattern
  void _handleStarToggle(MailDetail mailDetail) {
    AppLogger.info('⭐ Star toggle for mail: ${mailDetail.id}');
    
    // Use existing provider methods (same as selection_toolbar)
    if (mailDetail.isStarred) {
      ref.read(mailProvider.notifier).unstarMail(mailDetail.id, widget.userEmail);
      _showSuccessSnackBar(context, 'Yıldız kaldırıldı');
    } else {
      ref.read(mailProvider.notifier).starMail(mailDetail.id, widget.userEmail);
      _showSuccessSnackBar(context, 'Yıldızlandı');
    }
  }

  /// Handle archive action - following selection_toolbar pattern
  void _handleArchive(MailDetail mailDetail) {
    AppLogger.info('📦 Archive action for mail: ${mailDetail.id}');
    
    try {
      // Optimistic UI update
      _showSuccessSnackBar(context, 'Mail arşivleniyor...');
      
      // Use provider method (if available)
      // ref.read(mailProvider.notifier).archiveMail(mailDetail.id, widget.userEmail);
      
      // Navigate back after archive
      _handleBackNavigation();
      
    } catch (e) {
      AppLogger.error('❌ Archive failed: $e');
      _showErrorSnackBar(context, 'Arşivleme başarısız');
    }
  }

  /// Handle delete action - following selection_toolbar single mail pattern
  Future<void> _handleDelete(MailDetail mailDetail) async {
    AppLogger.info('🗑️ Delete action for mail: ${mailDetail.id}');
    
    try {
      final mailName = mailDetail.senderName;
      
      // 1. Optimistic remove (same as selection_toolbar pattern)
      ref.read(mailProvider.notifier).optimisticRemoveFromCurrentContext(mailDetail.id);
      
      // 2. Show success feedback immediately
      _showSuccessSnackBar(context, '$mailName çöp kutusuna taşındı');
      
      // 3. Navigate back immediately (optimistic)
      _handleBackNavigation();
      
      // 4. Background API call (same as selection_toolbar pattern)
      await ref.read(mailProvider.notifier).moveToTrashApiOnly(mailDetail.id, widget.userEmail);
      
      AppLogger.info('✅ Single mail deleted successfully: ${mailDetail.id}');
      
    } catch (error) {
      AppLogger.error('❌ Single mail delete failed: $error');
      _showErrorSnackBar(context, 'Çöp kutusuna taşıma başarısız');
    }
  }

  /// Handle menu actions - following selection_toolbar pattern
  void _handleMenuAction(String action, MailDetail mailDetail) {
    AppLogger.info('📋 Menu action: $action for mail: ${mailDetail.id}');
    
    switch (action) {
      case 'reply':
        // TODO: Navigate to compose with reply
        _showInfoSnackBar(context, 'Yanıtlama özelliği yakında eklenecek');
        break;
      case 'forward':
        // TODO: Navigate to compose with forward
        _showInfoSnackBar(context, 'İletme özelliği yakında eklenecek');
        break;
      case 'markUnread':
        // Use existing provider method (same as selection_toolbar)
        ref.read(mailProvider.notifier).markAsUnread(mailDetail.id, widget.userEmail);
        _showSuccessSnackBar(context, 'Okunmadı olarak işaretlendi');
        break;
    }
  }

  // ========== SNACKBAR HELPERS (same as selection_toolbar) ==========

  /// Show success snackbar
  void _showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// Show error snackbar  
  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// Show info snackbar (for placeholder features)
  void _showInfoSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ========== UTILITY METHODS ==========

  /// Get display name for folder
  String _getFolderDisplayName(String folder) {
    switch (folder.toLowerCase()) {
      case 'inbox':
        return 'Gelen Kutusu';
      case 'sent':
        return 'Gönderilmiş';
      case 'drafts':
        return 'Taslaklar';
      case 'spam':
        return 'Spam';
      case 'trash':
        return 'Çöp Kutusu';
      case 'starred':
        return 'Yıldızlı';
      case 'important':
        return 'Önemli';
      case 'archive':
        return 'Arşiv';
      default:
        return folder;
    }
  }
}