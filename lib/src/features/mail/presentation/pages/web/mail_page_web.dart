// lib/src/features/mail/presentation/pages/web/mail_page_web.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../common_widgets/mail/resizable_split_view.dart';
import '../../../../../utils/app_logger.dart';
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
class MailPageWeb extends ConsumerStatefulWidget {
  final String userEmail;

  const MailPageWeb({super.key, required this.userEmail});

  @override
  ConsumerState<MailPageWeb> createState() => _MailPageWebState();
}

class _MailPageWebState extends ConsumerState<MailPageWeb> {
  // Web-specific state
  String? _selectedMailId;
  final Set<String> _selectedMails = {}; // 🔄 MEVCUT - provider ile sync edilecek
  final bool _isPreviewPanelVisible = true;

  @override
  void initState() {
    super.initState();
    AppLogger.info('🌐 MailPageWeb initialized for: ${widget.userEmail}');
    
    // Mail loading - sadece inbox
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeMailPage();
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  /// Initialize mail page - provider initialization eklendi
  Future<void> _initializeMailPage() async {
    AppLogger.info('🌐 Initializing mail page for: ${widget.userEmail}');
    
    // Set user email
    ref.read(mailProvider.notifier).setCurrentUserEmail(widget.userEmail);
    
    // Load inbox folder
    await ref
        .read(mailProvider.notifier)
        .loadFolder(MailFolder.inbox, userEmail: widget.userEmail);
    
    // 🆕 Initialize selection provider with current mails
    final currentMails = ref.read(currentMailsProvider);
    ref.read(mailSelectionProvider.notifier).updateWithMailList(currentMails);
        
    AppLogger.info('🌐 Mail page initialization completed');
  }

  @override
  Widget build(BuildContext context) {
    // 🆕 Watch layout state
    final currentLayout = ref.watch(currentLayoutProvider);
    final isLayoutChanging = ref.watch(isLayoutChangingProvider);
    
    // 🆕 Listen to selection provider changes and sync with local state
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

    // 🆕 Listen to mail list changes and update selection provider
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
            onFolderSelected: _handleFolderSelected,
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
                
                // 🆕 SELECTION INFO BAR - Toolbar'ın hemen altında
                const MailSelectionInfoBar(),
                
                // 🆕 UPDATED: CONTENT AREA (Layout-dependent)
                Expanded(
                  child: _buildContentArea(currentLayout, isLayoutChanging),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 🆕 ADDED: Build content area based on layout type
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

  /// 🔄 UPDATED: No split layout (only mail list, no preview)
  Widget _buildNoSplitLayout() {
    return MailListSectionWeb(
      userEmail: widget.userEmail,
      selectedMailId: _selectedMailId,
      selectedMails: _selectedMails,
      isPreviewPanelVisible: false, // No preview in noSplit mode
      onMailSelected: _handleMailSelected,
      onMailCheckboxChanged: _handleMailCheckboxChanged,
    );
  }

  /// 🆕 ADDED: Vertical split layout with ResizableSplitView
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
        onMailSelected: _handleMailSelected,
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

  /// 🆕 ADDED: Horizontal split layout with ResizableSplitView
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
        onMailSelected: _handleMailSelected,
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

  // ========== UPDATED CALLBACK METHODS ==========

  /// Handle folder selection from left sidebar - UPGRADED
  Future<void> _handleFolderSelected(MailFolder folder) async {
    AppLogger.info('📁 Folder selected: $folder');
    
    try {
      // Clear current selection when switching folders
      setState(() {
        _selectedMailId = null;
        _selectedMails.clear(); // 🔄 Local state clear
      });
      
      // 🆕 Clear selection provider
      ref.read(mailSelectionProvider.notifier).clearAllSelections();
      
      // Load the selected folder
      await ref
          .read(mailProvider.notifier)
          .loadFolder(folder, userEmail: widget.userEmail);
          
      AppLogger.info('✅ Folder loaded successfully: $folder');
      
    } catch (error) {
      AppLogger.error('❌ Error loading folder $folder: $error');
      
      // Show error snackbar - MEVCUT
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Folder yüklenemedi: ${_getFolderDisplayName(folder)}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Handle mail selection from mail list - MEVCUT
  void _handleMailSelected(String mailId) {
    setState(() {
      _selectedMailId = mailId;
    });
    
    // Load mail detail for preview
    ref.read(mailDetailProvider.notifier).loadMailDetail(
      mailId: mailId,
      email: widget.userEmail,
    );
    
    AppLogger.info('📧 Mail selected: $mailId');
  }

  /// Handle mail checkbox changes - UPGRADED
  void _handleMailCheckboxChanged(String mailId, bool isSelected) {
    // 🔄 Update local state (MEVCUT)
    setState(() {
      if (isSelected) {
        _selectedMails.add(mailId);
      } else {
        _selectedMails.remove(mailId);
      }
    });
    
    // 🆕 Update selection provider
    if (isSelected) {
      ref.read(mailSelectionProvider.notifier).selectMail(mailId);
    } else {
      ref.read(mailSelectionProvider.notifier).deselectMail(mailId);
    }
    
    AppLogger.info('☑️ Mail checkbox changed: $mailId -> $isSelected (synced with provider)');
  }

  // ========== UTILITY METHODS ==========

  /// 🆕 Helper to compare two sets
  bool _setsEqual<T>(Set<T> set1, Set<T> set2) {
    return set1.length == set2.length && set1.containsAll(set2);
  }

  /// Get folder display name for error messages - MEVCUT
  String _getFolderDisplayName(MailFolder folder) {
    switch (folder) {
      case MailFolder.inbox:
        return 'Gelen Kutusu';
      case MailFolder.sent:
        return 'Gönderilmiş';
      case MailFolder.drafts:
        return 'Taslaklar';
      case MailFolder.spam:
        return 'Spam';
      case MailFolder.trash:
        return 'Çöp Kutusu';
      case MailFolder.starred:
        return 'Yıldızlı';
      case MailFolder.important:
        return 'Önemli';
      default:
        return folder.name;
    }
  }
}