// lib/src/features/mail/presentation/pages/web/mail_page_web.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../utils/app_logger.dart';
import '../../providers/mail_providers.dart';
import '../../providers/mail_provider.dart';

import '../../widgets/web/sections/mail_list_section_web.dart'; // YENİ IMPORT
import '../../widgets/web/sections/mail_preview_section_web.dart'; // YENİ IMPORT

/// Web-optimized mail page - SADECE Provider Integration ve Mail Listesi
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
                // Sidebar - basit
                _buildSidebar(),
                
                // Mail List - YENİ WIDGET KULLANIMI
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
                
                // Preview Panel - YENİ WIDGET KULLANIMI
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

  // YENİ CALLBACK METHODLARI
  void _handleMailSelected(String mailId) {
    setState(() {
      _selectedMailId = mailId;
    });
    // Mail detail yükle
    ref.read(mailDetailProvider.notifier).loadMailDetail(
      mailId: mailId,
      email: widget.userEmail,
    );
  }

  void _handleMailCheckboxChanged(String mailId, bool isSelected) {
    setState(() {
      if (isSelected) {
        _selectedMails.add(mailId);
      } else {
        _selectedMails.remove(mailId);
      }
    });
  }

  // SIDEBAR - basit (değişiklik yok)
  Widget _buildSidebar() {
    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        children: [
          // Compose Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // TODO: Compose
                },
                icon: const Icon(Icons.edit),
                label: const Text('Oluştur'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ),
          ),
          
          // Navigation - sadece inbox
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: [
                ListTile(
                  leading: const Icon(Icons.inbox, size: 20),
                  title: const Text('Gelen Kutusu', style: TextStyle(fontSize: 14)),
                  selected: true,
                  onTap: () {},
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}