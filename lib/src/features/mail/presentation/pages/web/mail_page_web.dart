// lib/src/features/mail/presentation/pages/web/mail_page_web.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../utils/app_logger.dart';
import '../../providers/mail_providers.dart';
import '../../providers/mail_provider.dart';

import '../../widgets/web/sections/mail_list_section_web.dart';
import '../../widgets/web/sections/mail_preview_section_web.dart';
import '../../widgets/web/sections/mail_leftbar_section.dart'; // 🆕 YENİ IMPORT

/// Web-optimized mail page with full folder navigation
class MailPageWeb extends ConsumerStatefulWidget {
  final String userEmail;

  const MailPageWeb({super.key, required this.userEmail});

  @override
  ConsumerState<MailPageWeb> createState() => _MailPageWebState();
}

class _MailPageWebState extends ConsumerState<MailPageWeb> {
  // Web-specific state
  String? _selectedMailId;
  final Set<String> _selectedMails = {};
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

  /// Initialize mail page - SADECE inbox yükle
  Future<void> _initializeMailPage() async {
    AppLogger.info('🌐 Initializing mail page for: ${widget.userEmail}');
    
    // Set user email
    ref.read(mailProvider.notifier).setCurrentUserEmail(widget.userEmail);
    
    // Load inbox folder
    await ref
        .read(mailProvider.notifier)
        .loadFolder(MailFolder.inbox, userEmail: widget.userEmail);
        
    AppLogger.info('🌐 Mail page initialization completed');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // Main Content
          Expanded(
            child: Row(
              children: [
                // 🆕 LEFT SIDEBAR - YENİ WIDGET KULLANIMI
                MailLeftBarSection(
                  userEmail: widget.userEmail,
                  onFolderSelected: _handleFolderSelected,
                ),
                
                // Mail List
                Expanded(
                  flex: _isPreviewPanelVisible ? 2 : 3,
                  child: MailListSectionWeb(
                    userEmail: widget.userEmail,
                    selectedMailId: _selectedMailId,
                    selectedMails: _selectedMails,
                    isPreviewPanelVisible: _isPreviewPanelVisible,
                    onMailSelected: _handleMailSelected,
                    onMailCheckboxChanged: _handleMailCheckboxChanged,
                  ),
                ),
                
                // Preview Panel
                if (_isPreviewPanelVisible)
                  Expanded(
                    flex: 2,
                    child: MailPreviewSectionWeb(
                      userEmail: widget.userEmail,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ========== 🆕 YENİ CALLBACK METHODS ==========

  /// Handle folder selection from left sidebar
  Future<void> _handleFolderSelected(MailFolder folder) async {
    AppLogger.info('📁 Folder selected: $folder');
    
    try {
      // Clear current selection when switching folders
      setState(() {
        _selectedMailId = null;
        _selectedMails.clear();
      });
      
      // Load the selected folder
      await ref
          .read(mailProvider.notifier)
          .loadFolder(folder, userEmail: widget.userEmail);
          
      AppLogger.info('✅ Folder loaded successfully: $folder');
      
    } catch (error) {
      AppLogger.error('❌ Error loading folder $folder: $error');
      
      // Show error snackbar
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

  /// Handle mail selection from mail list
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

  /// Handle mail checkbox changes
  void _handleMailCheckboxChanged(String mailId, bool isSelected) {
    setState(() {
      if (isSelected) {
        _selectedMails.add(mailId);
      } else {
        _selectedMails.remove(mailId);
      }
    });
    
    AppLogger.info('☑️ Mail checkbox changed: $mailId -> $isSelected');
  }

  // ========== UTILITY METHODS ==========

  /// Get folder display name for error messages
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