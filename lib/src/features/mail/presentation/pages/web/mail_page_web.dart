// lib/src/features/mail/presentation/pages/web/mail_page_web.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
//import '../../../../../common_widgets/mail/resizable_split_view.dart';
import '../../widgets/web/resizable-split/resizable_split_view_platform.dart';
import '../../../../../utils/app_logger.dart';
import '../../../../../routing/route_constants.dart';
import '../../providers/mail_providers.dart';
import '../../providers/mail_layout_provider.dart';
import '../../providers/state/mail_state.dart';
import '../../providers/state/mail_layout_state.dart';
import '../../widgets/web/sections/mail_list_section_web.dart';
import '../../widgets/web/sections/mail_leftbar_section.dart';
import '../../widgets/web/sections/mail_preview_section_web.dart';
import '../../widgets/web/toolbar/mail_toolbar_web.dart';
import '../../widgets/web/toolbar/components/mail_selection_info_bar.dart';

/// Web-optimized mail page with Gmail-style toolbar and resizable layout
/// 
/// ✅ UPDATED: URL-based folder support added
/// - Reads initialFolder from URL parameters
/// - Syncs provider state with URL
/// - Handles folder changes via URL navigation
class MailPageWeb extends ConsumerStatefulWidget {
  final String userEmail;
  
  /// 🆕 Initial folder from URL (optional, defaults to inbox)
  final String? initialFolder;

  const MailPageWeb({
    super.key, 
    required this.userEmail,
    this.initialFolder,
  });

  @override
  ConsumerState<MailPageWeb> createState() => _MailPageWebState();
}

class _MailPageWebState extends ConsumerState<MailPageWeb> {
  // Web-specific state
  String? _selectedMailId;
  final Set<String> _selectedMails = {}; // MEVCUT - provider ile sync edilecek

  @override
  void initState() {
    super.initState();
    AppLogger.info('🌐 MailPageWeb initialized for: ${widget.userEmail}');
    AppLogger.info('🗂️ Initial folder from URL: ${widget.initialFolder}');
    
    // Mail loading with URL-based folder
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeMailPage();
    });
  }

  @override
  void didUpdateWidget(MailPageWeb oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // 🆕 Handle URL folder changes
    if (oldWidget.initialFolder != widget.initialFolder) {
      AppLogger.info('🔄 URL folder changed: ${oldWidget.initialFolder} → ${widget.initialFolder}');
      _handleUrlFolderChange();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  /// Initialize mail page with URL-based folder - UPDATED
  Future<void> _initializeMailPage() async {
    AppLogger.info('🌐 Initializing mail page for: ${widget.userEmail}');
    
    // Set user email
    ref.read(mailProvider.notifier).setCurrentUserEmail(widget.userEmail);
    
    // 🆕 Load folder based on URL parameter
    final targetFolder = _getTargetFolder();
    AppLogger.info('🗂️ Loading target folder: $targetFolder');
    
    await ref
        .read(mailProvider.notifier)
        .loadFolder(targetFolder, userEmail: widget.userEmail);
    
    // Initialize selection provider with current mails
    final currentMails = ref.read(currentMailsProvider);
    ref.read(mailSelectionProvider.notifier).updateWithMailList(currentMails);
        
    AppLogger.info('🌐 Mail page initialization completed');
  }

  /// 🆕 Handle URL folder changes
  Future<void> _handleUrlFolderChange() async {
    if (!mounted) return;
    
    final targetFolder = _getTargetFolder();
    final currentFolder = ref.read(currentFolderProvider);
    
    // Only load if different from current
    if (targetFolder != currentFolder) {
      AppLogger.info('🔄 Syncing provider with URL folder: $targetFolder');
      
      // 🔧 FIX: Delay provider modification using Future.microtask
      Future.microtask(() async {
        if (!mounted) return;
        
        // Clear selections when switching folders
        setState(() {
          _selectedMailId = null;
          _selectedMails.clear();
        });
        ref.read(mailSelectionProvider.notifier).clearAllSelections();
        
        // Load new folder
        await ref
            .read(mailProvider.notifier)
            .loadFolder(targetFolder, userEmail: widget.userEmail);
      });
    }
  }

  /// 🆕 Get target folder from URL or default to inbox
  MailFolder _getTargetFolder() {
    final folderName = widget.initialFolder ?? 'inbox';
    
    // Convert URL string to MailFolder enum
    switch (folderName.toLowerCase()) {
      case 'inbox':
        return MailFolder.inbox;
      case 'sent':
        return MailFolder.sent;
      case 'drafts':
        return MailFolder.drafts;
      case 'spam':
        return MailFolder.spam;
      case 'trash':
        return MailFolder.trash;
      case 'starred':
        return MailFolder.starred;
      case 'important':
        return MailFolder.important;
      default:
        AppLogger.warning('❌ Invalid folder name: $folderName, defaulting to inbox');
        return MailFolder.inbox;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch layout state
    final currentLayout = ref.watch(currentLayoutProvider);
    final isLayoutChanging = ref.watch(isLayoutChangingProvider);
    
    // Listen to selection provider changes and sync with local state
    ref.listen(mailSelectionProvider, (previous, next) {
      final newSelectedIds = next.selectedMailIds;
      if (!_setsEqual(_selectedMails, newSelectedIds)) {
        setState(() {
          _selectedMails.clear();
          _selectedMails.addAll(newSelectedIds);
        });
        AppLogger.info('🔄 Local state synced with selection provider: ${newSelectedIds.length} selected');
      }
    });

    // Listen to mail list changes and update selection provider
    ref.listen(currentMailsProvider, (previous, next) {
      ref.read(mailSelectionProvider.notifier).updateWithMailList(next);
      AppLogger.info('🔄 Selection provider updated with new mail list: ${next.length} mails');
    });

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Row(  // ← Ana layout: ROW
        children: [
          // LEFT SIDEBAR (Sabit genişlik)
          MailLeftBarSection(
            userEmail: widget.userEmail,
            onFolderSelected: _handleFolderSelectedFromSidebar, // 🆕 URL-based navigation
          ),
          
          // MAIN CONTENT AREA (Toolbar + Info Bar + Mail List + Preview)
          Expanded(
            child: Column(  // ← Main content: COLUMN
              children: [
                // TOOLBAR - Mail list hizasında
                MailToolbarWeb(
                  userEmail: widget.userEmail,
                  backgroundColor: Colors.white,
                ),
                
                // SELECTION INFO BAR - Toolbar'ın hemen altında
                const MailSelectionInfoBar(),
                
                // CONTENT AREA (Layout-dependent)
                Expanded(
                  child: _buildContentArea(currentLayout, isLayoutChanging),
                ),

                // Bottom bar
                _buildMailBottomBar(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build content area based on layout type
  Widget _buildContentArea(MailLayoutType layoutType, bool isLayoutChanging) {
    // Show loading indicator during layout changes
    if (isLayoutChanging) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // Build layout-specific content
    switch (layoutType) {
      case MailLayoutType.noSplit:
        return _buildNoSplitLayout();
        
      case MailLayoutType.verticalSplit:
        return _buildVerticalSplitLayout();
        
      case MailLayoutType.horizontalSplit:
        return _buildHorizontalSplitLayout();
    }
  }

  /// No split layout (only mail list, no preview) - UPDATED for URL navigation
  Widget _buildNoSplitLayout() {
    return MailListSectionWeb(
      userEmail: widget.userEmail,
      selectedMailId: _selectedMailId,
      selectedMails: _selectedMails,
      isPreviewPanelVisible: false, // No preview in noSplit mode
      onMailSelected: _handleMailSelectedInListOnly, // 🆕 URL navigation for detail
      onMailCheckboxChanged: _handleMailCheckboxChanged,
    );
  }

  /// Vertical split layout with ResizableSplitView
  Widget _buildVerticalSplitLayout() {
    final splitRatio = ref.watch(currentSplitRatioProvider);
    
    return ResizableSplitView(
      isVertical: true,
      initialRatio: splitRatio,
      minRatio: 0.25, // 25% minimum for mail list
      maxRatio: 0.75, // 75% maximum for mail list
      splitterThickness: 6.0,
      leftChild: MailListSectionWeb(
        userEmail: widget.userEmail,
        selectedMailId: _selectedMailId,
        selectedMails: _selectedMails,
        isPreviewPanelVisible: true, // Preview is visible in split mode
        onMailSelected: _handleMailSelected, // Preview mode
        onMailCheckboxChanged: _handleMailCheckboxChanged,
      ),
      rightChild: MailPreviewSectionWeb(
        userEmail: widget.userEmail,
      ),
      onRatioChanged: (ratio) {
        // Update state in layout notifier
        ref.read(mailLayoutProvider.notifier).updateSplitRatio(ratio);
        AppLogger.debug('🎨 Vertical split ratio updated: ${ratio.toStringAsFixed(2)}');
      },
    );
  }

  /// Horizontal split layout with ResizableSplitView
  Widget _buildHorizontalSplitLayout() {
    final splitRatio = ref.watch(currentSplitRatioProvider);
    
    return ResizableSplitView(
      isVertical: false, // Horizontal split (top-bottom)
      initialRatio: splitRatio,
      minRatio: 0.3, // 30% minimum for mail list
      maxRatio: 0.7, // 70% maximum for mail list  
      splitterThickness: 6.0,
      leftChild: MailListSectionWeb(
        userEmail: widget.userEmail,
        selectedMailId: _selectedMailId,
        selectedMails: _selectedMails,
        isPreviewPanelVisible: true, // Preview is visible in split mode
        onMailSelected: _handleMailSelected, // Preview mode
        onMailCheckboxChanged: _handleMailCheckboxChanged,
      ),
      rightChild: MailPreviewSectionWeb(
        userEmail: widget.userEmail,
      ),
      onRatioChanged: (ratio) {
        // Update state in layout notifier
        ref.read(mailLayoutProvider.notifier).updateSplitRatio(ratio);
        AppLogger.debug('🎨 Horizontal split ratio updated: ${ratio.toStringAsFixed(2)}');
      },
    );
  }

  /// Build mail bottom bar
  Widget _buildMailBottomBar() {
    return SizedBox(
      height: 16, // Ufak yükseklik
      child: Container(
        color: Colors.white, // Beyaz arka plan
        child: const SizedBox.expand(), // İçerik yok, sadece boş alan
      ),
    );
  }

  // ========== UPDATED CALLBACK METHODS ==========

  /// 🆕 Handle folder selection from left sidebar - URL-based navigation
  void _handleFolderSelectedFromSidebar(MailFolder folder) {
    AppLogger.info('📁 Folder selected from sidebar: $folder');
    
    // Convert MailFolder enum to URL string
    final folderName = _mailFolderToUrlString(folder);
    
    // Navigate to folder URL
    final folderPath = MailRoutes.folderPath(widget.userEmail, folderName);
    context.go(folderPath);
    
    AppLogger.info('🔗 Navigating to: $folderPath');
  }

/// Handle mail selection from mail list - UPDATED (for preview mode)
void _handleMailSelected(String mailId) {
  setState(() {
    _selectedMailId = mailId;
  });
  
    // 🆕 Mark as read if unread (same logic as mobile)
    final currentMails = ref.read(currentMailsProvider);
    final selectedMail = currentMails.where((m) => m.id == mailId).firstOrNull;
    
    if (selectedMail != null && !selectedMail.isRead) {
      ref.read(mailProvider.notifier).markAsRead(mailId, widget.userEmail);
      AppLogger.info('📖 Mail marked as read via preview: $mailId');
    }
    
    // Load mail detail for preview
    ref.read(mailDetailProvider.notifier).loadMailDetail(
      mailId: mailId,
      email: widget.userEmail,
    );
    
    AppLogger.info('📧 Mail selected for preview: $mailId');
  }

  /// 🆕 Handle mail selection in list-only mode - navigate to detail page
  void _handleMailSelectedInListOnly(String mailId) {
    AppLogger.info('📧 Mail selected in list-only mode: $mailId');
    
    // Get current folder for URL
    final currentFolder = ref.read(currentFolderProvider);
    final folderName = _mailFolderToUrlString(currentFolder);
    
    // Navigate to mail detail page
    final detailPath = MailRoutes.mailDetailPath(widget.userEmail, folderName, mailId);
    context.go(detailPath);
    
    AppLogger.info('🔗 Navigating to mail detail: $detailPath');
  }

  /// Handle mail checkbox changes - UPGRADED
  void _handleMailCheckboxChanged(String mailId, bool isSelected) {
    // Update local state (MEVCUT)
    setState(() {
      if (isSelected) {
        _selectedMails.add(mailId);
      } else {
        _selectedMails.remove(mailId);
      }
    });
    
    // Update selection provider
    if (isSelected) {
      ref.read(mailSelectionProvider.notifier).selectMail(mailId);
    } else {
      ref.read(mailSelectionProvider.notifier).deselectMail(mailId);
    }
    
    AppLogger.info('☑️ Mail checkbox changed: $mailId -> $isSelected (synced with provider)');
  }

  // ========== UTILITY METHODS ==========

  /// 🆕 Convert MailFolder enum to URL string
  String _mailFolderToUrlString(MailFolder folder) {
    switch (folder) {
      case MailFolder.inbox:
        return 'inbox';
      case MailFolder.sent:
        return 'sent';
      case MailFolder.drafts:
        return 'drafts';
      case MailFolder.spam:
        return 'spam';
      case MailFolder.trash:
        return 'trash';
      case MailFolder.starred:
        return 'starred';
      case MailFolder.important:
        return 'important';
      default:
        return 'inbox';
    }
  }

  /// Helper to compare two sets
  bool _setsEqual<T>(Set<T> set1, Set<T> set2) {
    return set1.length == set2.length && set1.containsAll(set2);
  }

}