// lib/src/features/mail/presentation/widgets/web/sections/mail_preview_section_web.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

import '../common/mail_header_widget.dart';
import '../../../../../../utils/app_logger.dart';
import '../../../../domain/entities/mail_detail.dart';
import '../../../../domain/entities/mail.dart'; // ✅ ADD: Import Mail entity
import '../../../providers/mail_providers.dart';
import '../preview/mail_renderer_platform.dart';
// ✅ ADD: Import the toolbar widget
import '../toolbar/components/mail_detail_toolbar.dart';


class MailPreviewSectionWeb extends ConsumerStatefulWidget {
  final String userEmail;
  /// ✅ ADD: Navigation callbacks - parent component'e navigation isteklerini ileten callback'ler
  final Function(String)? onMailSelected; // Mail seçim callback'i (next/previous navigation için)
  final VoidCallback? onPreviewClosed;    // Preview kapatma callback'i (clear selection için)
  
  const MailPreviewSectionWeb({
    super.key,
    required this.userEmail,
    this.onMailSelected,      // ✅ ADD: Optional navigation callback
    this.onPreviewClosed,     // ✅ ADD: Optional close callback
  });

  @override
  ConsumerState<MailPreviewSectionWeb> createState() => _MailPreviewSectionWebState();
}

class _MailPreviewSectionWebState extends ConsumerState<MailPreviewSectionWeb> {
  // ScrollController - preview panel'in kendi controller'ı
  final ScrollController _scrollController = ScrollController();

  // Web renderer instance - preview panel'in kendi renderer'ı
  late final MailWebRenderer _webRenderer;

  @override
  void initState() {
    super.initState();
    AppLogger.info('🖥️ MailPreviewSectionWeb initialized for: ${widget.userEmail}');
    
    // Initialize web renderer
    // Mevcut renderer pattern'ını takip et
    _webRenderer = MailWebRenderer(
      scrollController: _scrollController,
      repository: ref.read(mailRepositoryProvider),  // Inject repository
      userEmail: widget.userEmail,                   // Pass user email
      onHeightChanged: (height) {
        setState(() {});
      },
      ref: ref,
    );
    
    // Initialize web renderer
    if (kIsWeb) {
      _webRenderer.initialize();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _webRenderer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Provider watches
    final mailDetail = ref.watch(currentMailDetailProvider);
    final mailDetailLoading = ref.watch(mailDetailLoadingProvider);

    return _buildPreviewPanel(context, mailDetail, mailDetailLoading);
  }

  // Preview panel - buildRenderedHtmlSection ile mail içeriği gösterimi
  Widget _buildPreviewPanel(BuildContext context, MailDetail? mailDetail, bool isLoading) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // ✅ UPDATED: Toolbar with navigation callbacks
          if (mailDetail != null) 
            MailDetailToolbar(
              mailDetail: mailDetail,
              userEmail: widget.userEmail,
              onBack: _handlePreviewClose,                    // ✅ Preview kapatma
              isLoading: isLoading,
              mode: ToolbarMode.preview,
              // ✅ ADD: Navigation callbacks
              onPreviousMail: _handlePreviousMail,           // ✅ Önceki mail
              onNextMail: _handleNextMail,                   // ✅ Sonraki mail
              hasPreviousMail: _hasPreviousMail(mailDetail), // ✅ Önceki mail var mı?
              hasNextMail: _hasNextMail(mailDetail),         // ✅ Sonraki mail var mı?
            ),
          
          // Content below toolbar
          Expanded(
            child: _buildPreviewContent(context, mailDetail, isLoading),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewContent(BuildContext context, MailDetail? mailDetail, bool isLoading) {
    // Loading state
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // No mail selected
    if (mailDetail == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.mail_outline, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Önizlemek için bir mail seçin',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    // ✅ UPDATED: Mail selected - show content with unified scroll and header
    return SingleChildScrollView(
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
        ],
      ),
    );
  }

  Widget _buildMailHeaderNew(MailDetail mailDetail) {
    return MailHeaderWidget(mailDetail: mailDetail);
  }

  // ========== ✅ NEW: NAVIGATION HANDLERS ==========
  
  /// Handle preview close - clear selection
  void _handlePreviewClose() {
    AppLogger.info('🔙 Preview close requested');
    
    if (widget.onPreviewClosed != null) {
      widget.onPreviewClosed!();
    } else {
      // Fallback: Clear selection directly
      ref.read(mailSelectionProvider.notifier).clearAllSelections();
    }
  }

  /// Handle previous mail navigation
void _handlePreviousMail() {
  final currentMailId = ref.read(currentMailDetailProvider)?.id;
  if (currentMailId == null) return;

  AppLogger.info('⬅️ Previous mail navigation requested from: $currentMailId');
  
  final previousMail = _getPreviousMail(currentMailId);
  AppLogger.info('🔍 Found previous mail: ${previousMail?.id}'); // DEBUG LOG
  
  if (previousMail != null && widget.onMailSelected != null) {
    AppLogger.info('📞 Calling onMailSelected with: ${previousMail.id}'); // DEBUG LOG
    widget.onMailSelected!(previousMail.id);
  } else {
    AppLogger.info('❌ Cannot navigate - previousMail: ${previousMail != null}, callback: ${widget.onMailSelected != null}'); // DEBUG LOG
  }
}

  /// Handle next mail navigation  
void _handleNextMail() {
  final currentMailId = ref.read(currentMailDetailProvider)?.id;
  if (currentMailId == null) return;

  AppLogger.info('➡️ Next mail navigation requested from: $currentMailId');
  
  final nextMail = _getNextMail(currentMailId);
  AppLogger.info('🔍 Found next mail: ${nextMail?.id}'); // DEBUG LOG
  
  if (nextMail != null && widget.onMailSelected != null) {
    AppLogger.info('📞 Calling onMailSelected with: ${nextMail.id}'); // DEBUG LOG
    widget.onMailSelected!(nextMail.id);
  } else {
    AppLogger.info('❌ Cannot navigate - nextMail: ${nextMail != null}, callback: ${widget.onMailSelected != null}'); // DEBUG LOG
  }
}

  // ========== ✅ NEW: NAVIGATION HELPERS ==========

  /// Check if previous mail exists
  bool _hasPreviousMail(MailDetail currentMailDetail) {
    return _getPreviousMail(currentMailDetail.id) != null;
  }

  /// Check if next mail exists
  bool _hasNextMail(MailDetail currentMailDetail) {
    return _getNextMail(currentMailDetail.id) != null;
  }

  /// Get previous mail from current mails list
  Mail? _getPreviousMail(String currentMailId) {
  final currentMails = ref.read(currentMailsProvider);
  final currentIndex = currentMails.indexWhere((mail) => mail.id == currentMailId);
  
  AppLogger.info('🔍 Getting previous mail - currentIndex: $currentIndex, totalMails: ${currentMails.length}'); // DEBUG LOG
  
  if (currentIndex > 0) {
    return currentMails[currentIndex - 1];
  }
  
  return null;
}

/// Get next mail from current mails list
Mail? _getNextMail(String currentMailId) {
  final currentMails = ref.read(currentMailsProvider);
  final currentIndex = currentMails.indexWhere((mail) => mail.id == currentMailId);
  
  AppLogger.info('🔍 Getting next mail - currentIndex: $currentIndex, totalMails: ${currentMails.length}'); // DEBUG LOG
  
  if (currentIndex >= 0 && currentIndex < currentMails.length - 1) {
    return currentMails[currentIndex + 1];
  }
  
  return null;
}
}