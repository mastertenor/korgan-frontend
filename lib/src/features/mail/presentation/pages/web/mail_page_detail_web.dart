// lib/src/features/mail/presentation/pages/web/mail_page_detail_web.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../../../../../common_widgets/mail/mail_header_widget.dart';
import '../../../../../utils/app_logger.dart';
import '../../providers/mail_providers.dart';
import '../../widgets/web/preview/mail_renderer_platform.dart';
import '../../widgets/web/sections/mail_leftbar_section.dart';
import '../../widgets/web/toolbar/components/mail_detail_toolbar.dart';
import '../../widgets/web/compose/mail_compose_modal_platform.dart'; // NEW IMPORT
import '../../../domain/entities/mail_detail.dart';
import '../../widgets/web/attachments/attachments_widget_web.dart';

/// Web-optimized full-screen mail detail page
/// 
/// Mevcut MailWebRenderer'ı kullanarak mail detail gösterir.
/// Preview panel kapalıyken veya direct URL erişiminde kullanılır.
/// 
/// Features:
/// - Full-screen mail detail view using existing MailWebRenderer
/// - Left sidebar for folder navigation
/// - Professional toolbar with Gmail-style action buttons
/// - Back navigation to folder
/// - Mail actions (reply, forward, star, delete, etc.)
/// - Previous/Next mail navigation
/// - URL-based navigation support
/// - Compose modal integration
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
    AppLogger.info('MailPageDetailWeb initialized for: ${widget.userEmail}/${widget.folder}/${widget.mailId}');
    
    // Mevcut renderer pattern'ını takip et
    _webRenderer = MailWebRenderer(
      scrollController: _scrollController,
      repository: ref.read(mailRepositoryProvider),  // Inject repository
      userEmail: widget.userEmail,                   // Pass user email
      onHeightChanged: (height) {
        setState(() {});
      },
      ref:ref,
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
  void didUpdateWidget(MailPageDetailWeb oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Handle URL mailId changes for Previous/Next navigation
    if (oldWidget.mailId != widget.mailId) {
      AppLogger.info('Mail ID changed: ${oldWidget.mailId} → ${widget.mailId}');
      
      // Delay provider modification to avoid widget tree building conflict
      Future(() {
        if (mounted) {
          _initializeMailDetail();
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _webRenderer.dispose();
    super.dispose();
  }

  /// Initialize mail detail - load specific mail using existing provider pattern
  Future<void> _initializeMailDetail() async {
    AppLogger.info('Loading mail detail: ${widget.mailId}');
    
    try {
      // Load mail detail first
      ref.read(mailDetailProvider.notifier).loadMailDetail(
        mailId: widget.mailId,
        email: widget.userEmail,
      );
      
      // Mark as read automatically (same as mobile pattern)
      await ref.read(mailProvider.notifier).markAsRead(widget.mailId, widget.userEmail);
      AppLogger.info('Mail marked as read via detail page: ${widget.mailId}');
      
      AppLogger.info('Mail detail load initiated via provider');
      
    } catch (error) {
      AppLogger.error('Error loading mail detail: $error');
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
      // UPDATED: Stack layout for compose modal overlay (like mail_page_web.dart)
      body: Stack(
        children: [
          // Main page content (original layout)
          Row(
            children: [
              // LEFT SIDEBAR
              MailLeftBarSection(
                userEmail: widget.userEmail,
              ),
              
              // MAIN CONTENT AREA
              Expanded(
                child: Column(
                  children: [
                    // Mail Detail Toolbar
                    if (mailDetail != null)
                      MailDetailToolbar(
                        mailDetail: mailDetail,
                        userEmail: widget.userEmail,
                        onBack: _handleBackNavigation,
                        isLoading: mailDetailLoading,
                        onPreviousMail: _handlePreviousMail,
                        onNextMail: _handleNextMail,
                        hasPreviousMail: _hasPreviousMail(),
                        hasNextMail: _hasNextMail(),
                      ),
                      
                    // Content area
                    Expanded(
                      child: _buildContent(context, mailDetail, mailDetailLoading, mailDetailError),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          // COMPOSE MODAL OVERLAY (like mail_page_web.dart)
          MailComposeModalWeb(
            userEmail: widget.userEmail,
            userName: _extractUserNameFromEmail(widget.userEmail),
          ),
        ],
      ),
    );
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
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.white,
      child: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMailHeaderNew(mailDetail),
            const SizedBox(height: 16),
            SizedBox(
              height: _webRenderer.iframeHeight,
              child: _webRenderer.buildRenderedHtmlSection(mailDetail),
            ),
            
            // Attachments section - web version
            _buildAttachmentsSection(mailDetail),
            
            // Bottom padding for better scroll experience
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

Widget _buildMailHeaderNew(MailDetail mailDetail) {
  return MailHeaderWidget(mailDetail: mailDetail);
}

  // EVENT HANDLERS

  /// Handle back navigation to folder
  void _handleBackNavigation() {
    AppLogger.info('Navigating back to folder: ${widget.folder}');
    
    // Build correct folder URL pattern
    // From: /mail/email/folder/mailId 
    // To:   /mail/email/folder/
    final folderPath = '/mail/${widget.userEmail}/${widget.folder}/';
    
    AppLogger.info('Navigating to: $folderPath');
    context.go(folderPath);
  }

  /// Handle previous mail navigation
  void _handlePreviousMail() {
    AppLogger.info('Navigate to previous mail');
    
    final currentMails = ref.read(currentMailsProvider);
    final currentIndex = currentMails.indexWhere((mail) => mail.id == widget.mailId);
    
    if (currentIndex > 0) {
      final previousMail = currentMails[currentIndex - 1];
      final previousMailPath = '/mail/${widget.userEmail}/${widget.folder}/${previousMail.id}';
      
      AppLogger.info('Navigating to previous mail: $previousMailPath');
      context.go(previousMailPath);
    }
  }

  /// Handle next mail navigation
  void _handleNextMail() {
    AppLogger.info('Navigate to next mail');
    
    final currentMails = ref.read(currentMailsProvider);
    final currentIndex = currentMails.indexWhere((mail) => mail.id == widget.mailId);
    
    if (currentIndex >= 0 && currentIndex < currentMails.length - 1) {
      final nextMail = currentMails[currentIndex + 1];
      final nextMailPath = '/mail/${widget.userEmail}/${widget.folder}/${nextMail.id}';
      
      AppLogger.info('Navigating to next mail: $nextMailPath');
      context.go(nextMailPath);
    }
  }

  /// Check if there is a previous mail
  bool _hasPreviousMail() {
    final currentMails = ref.watch(currentMailsProvider);
    final currentIndex = currentMails.indexWhere((mail) => mail.id == widget.mailId);
    return currentIndex > 0;
  }

  /// Check if there is a next mail
  bool _hasNextMail() {
    final currentMails = ref.watch(currentMailsProvider);
    final currentIndex = currentMails.indexWhere((mail) => mail.id == widget.mailId);
    return currentIndex >= 0 && currentMails.length > 1 && currentIndex < currentMails.length - 1;
  }

  // Web mail detail sayfasında
  Widget _buildAttachmentsSection(MailDetail mailDetail) {
    if (!mailDetail.hasAttachments) return SizedBox.shrink();
    
    return AttachmentsWidgetWeb(mailDetail: mailDetail);
  }

  // HELPER METHODS

  /// Extract user name from email (simple fallback)
  String _extractUserNameFromEmail(String email) {
    if (email.contains('@')) {
      return email.split('@')[0];
    }
    return email;
  }
}