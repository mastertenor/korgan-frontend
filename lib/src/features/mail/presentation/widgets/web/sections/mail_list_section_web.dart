// lib/src/features/mail/presentation/widgets/web/mail_list_section_web.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/entities/mail.dart';
import '../../../providers/mail_providers.dart';

class MailListSectionWeb extends ConsumerWidget {
  final String userEmail;
  final String? selectedMailId;
  final Set<String> selectedMails;
  final bool isPreviewPanelVisible;
  final Function(String) onMailSelected;
  final Function(String, bool) onMailCheckboxChanged;
  
  const MailListSectionWeb({
    super.key,
    required this.userEmail,
    required this.selectedMailId,
    required this.selectedMails,
    required this.isPreviewPanelVisible,
    required this.onMailSelected,
    required this.onMailCheckboxChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Provider watches
    final currentMails = ref.watch(currentMailsProvider);
    final isLoading = ref.watch(currentLoadingProvider);
    final error = ref.watch(currentErrorProvider);

    return _buildMailList(
      currentMails: currentMails,
      isLoading: isLoading,
      error: error,
    );
  }

  // MAIL LIST - ana sayfadan taşınan method
  Widget _buildMailList({
    required List<Mail> currentMails,
    required bool isLoading,
    required String? error,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: isPreviewPanelVisible 
            ? Border(right: BorderSide(color: Colors.grey[300]!))
            : null,
      ),
      child: Column(
        children: [
          // Toolbar
          _buildMailToolbar(currentMails: currentMails),
          
          // Mail List Content
          Expanded(
            child: _buildMailListContent(
              currentMails: currentMails,
              isLoading: isLoading,
              error: error,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMailToolbar({required List<Mail> currentMails}) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Title
          Text(
            'Gelen Kutusu',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          
          const Spacer(),
          
          // Mail count
          Text(
            '${currentMails.length} mail',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMailListContent({
    required List<Mail> currentMails,
    required bool isLoading,
    required String? error,
  }) {
    // Loading state
    if (isLoading && currentMails.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // Error state  
    if (error != null && currentMails.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Mailler yüklenemedi',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Empty state
    if (currentMails.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Gelen kutunuz boş',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    // Mail list
    return ListView.builder(
      itemCount: currentMails.length,
      itemBuilder: (context, index) {
        final mail = currentMails[index];
        return _buildMailListItem(mail, index);
      },
    );
  }

  // Mail item - ana sayfadan taşınan method
  Widget _buildMailListItem(Mail mail, int index) {
    final isSelected = selectedMails.contains(mail.id);
    final isCurrentlySelected = selectedMailId == mail.id;
    
    return Material(
      color: isCurrentlySelected 
          ? Colors.blue.withOpacity(0.1)
          : Colors.transparent,
      child: InkWell(
        onTap: () {
          onMailSelected(mail.id);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.grey[200]!),
            ),
          ),
          child: Row(
            children: [
              // Checkbox
              Transform.scale(
                scale: 0.8,
                child: Checkbox(
                  value: isSelected,
                  onChanged: (value) {
                    onMailCheckboxChanged(mail.id, value == true);
                  },
                ),
              ),
              
              const SizedBox(width: 8),
              
              // Star
              Icon(
                mail.isStarred ? Icons.star : Icons.star_border,
                color: mail.isStarred ? Colors.amber : Colors.grey[400],
                size: 18,
              ),
              
              const SizedBox(width: 16),
              
              // Mail content
              Expanded(
                child: Row(
                  children: [
                    // Sender name
                    SizedBox(
                      width: 180,
                      child: Text(
                        mail.senderName,
                        style: TextStyle(
                          fontWeight: mail.isRead ? FontWeight.normal : FontWeight.bold,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // Subject
                    Expanded(
                      child: Text(
                        mail.subject,
                        style: TextStyle(
                          fontSize: 14,
                          color: mail.isRead ? Colors.grey[700] : Colors.black,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    
                    const SizedBox(width: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}