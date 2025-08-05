// lib/src/features/mail/presentation/pages/web/mail_page_web.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../utils/app_logger.dart';

/// Web-optimized mail page with Gmail-style interface - MINIMAL VERSION
///
/// Bu minimal version'da:
/// ✅ 3-panel layout (sidebar + list + preview placeholder)
/// ✅ Mevcut mobile provider'ları kullanım
/// ✅ Basit hover effects
/// ✅ Dense mail list view
/// ❌ Advanced features (gelecek fazlarda)
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
  bool _isPreviewPanelVisible = true;

  @override
  void initState() {
    super.initState();
    AppLogger.info('🌐 MailPageWeb initialized for: ${widget.userEmail}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // Header Section
          //_buildHeader(),
          
          // Main Content
          Expanded(
            child: Row(
              children: [
                // Sidebar
                _buildSidebar(),
                
                // Mail List
                Expanded(
                  flex: _isPreviewPanelVisible ? 2 : 3,
                  child: _buildMailList(),
                ),
                
                // Preview Panel (Optional)
                if (_isPreviewPanelVisible)
                  Expanded(
                    flex: 2,
                    child: _buildPreviewPanel(),
                  ),
              ],
            ),
          ),
        ],
      ),
      
      // Floating Compose Button
      floatingActionButton: _buildComposeButton(),
    );
  }

 

  // ========== SIDEBAR ==========
  
  Widget _buildSidebar() {
    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        children: [
          // Compose Button (In Sidebar)
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // TODO: Navigate to compose
                  AppLogger.info('✍️ Compose button clicked');
                },
                icon: const Icon(Icons.edit, size: 20),
                label: const Text('Yeni E-posta'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
          
          // Folder List
          Expanded(
            child: ListView(
              children: [
                _buildFolderItem(Icons.inbox, 'Gelen Kutusu', true, 12),
                _buildFolderItem(Icons.star, 'Yıldızlı', false, 3),
                _buildFolderItem(Icons.send, 'Gönderilmiş', false, 0),
                _buildFolderItem(Icons.drafts, 'Taslaklar', false, 2),
                const Divider(),
                _buildFolderItem(Icons.archive, 'Arşiv', false, 0),
                _buildFolderItem(Icons.report, 'Spam', false, 0),
                _buildFolderItem(Icons.delete, 'Çöp Kutusu', false, 5),
              ],
            ),
          ),
          
          // User Info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.blue[100],
                  child: Text(
                    widget.userEmail[0].toUpperCase(),
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.userEmail,
                    style: const TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFolderItem(IconData icon, String title, bool isSelected, int count) {
    return Material(
      color: isSelected ? Colors.blue[50] : Colors.transparent,
      child: InkWell(
        onTap: () {
          AppLogger.info('📁 Folder selected: $title');
          // TODO: Handle folder selection
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? Colors.blue[600] : Colors.grey[600],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected ? Colors.blue[700] : Colors.grey[800],
                  ),
                ),
              ),
              if (count > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue[600],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ========== MAIL LIST ==========
  
  Widget _buildMailList() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          right: _isPreviewPanelVisible 
            ? BorderSide(color: Colors.grey[300]!) 
            : BorderSide.none,
        ),
      ),
      child: Column(
        children: [
          // Toolbar
          _buildMailToolbar(),
          
          // Mail List
          Expanded(
            child: _buildMailListContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildMailToolbar() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Select All Checkbox
          Transform.scale(
            scale: 0.9,
            child: Checkbox(
              value: _selectedMails.isNotEmpty,
              onChanged: (value) {
                setState(() {
                  if (value == true) {
                    // TODO: Select all mails
                  } else {
                    _selectedMails.clear();
                  }
                });
              },
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Bulk Actions (Show when items selected)
          if (_selectedMails.isNotEmpty) ...[
            IconButton(
              onPressed: () {
                // TODO: Archive selected
              },
              icon: const Icon(Icons.archive, size: 20),
              tooltip: 'Arşivle',
            ),
            IconButton(
              onPressed: () {
                // TODO: Delete selected
              },
              icon: const Icon(Icons.delete, size: 20),
              tooltip: 'Sil',
            ),
            IconButton(
              onPressed: () {
                // TODO: Mark as read
              },
              icon: const Icon(Icons.mark_email_read, size: 20),
              tooltip: 'Okundu İşaretle',
            ),
          ] else ...[
            // Default toolbar
            Text(
              'Gelen Kutusu',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
          ],
          
          const Spacer(),
          
          // Pagination info
          Text(
            '1-50 / 150',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMailListContent() {
    // TODO: Bu kısımda gerçek mail provider'ı kullanılacak
    // Şimdilik mock data ile çalışalım
    return ListView.builder(
      itemCount: 10, // Mock count
      itemBuilder: (context, index) {
        return _buildMailListItem(index);
      },
    );
  }

  Widget _buildMailListItem(int index) {
    final isSelected = _selectedMails.contains('mail_$index');
    final isCurrentlySelected = _selectedMailId == 'mail_$index';
    
    return Material(
      color: isCurrentlySelected ? Colors.blue[50] : Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedMailId = 'mail_$index';
          });
          AppLogger.info('📧 Mail selected: mail_$index');
        },
        onHover: (isHovering) {
          // TODO: Hover state handling
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
          ),
          child: Row(
            children: [
              // Checkbox
              Transform.scale(
                scale: 0.8,
                child: Checkbox(
                  value: isSelected,
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        _selectedMails.add('mail_$index');
                      } else {
                        _selectedMails.remove('mail_$index');
                      }
                    });
                  },
                ),
              ),
              
              const SizedBox(width: 8),
              
              // Star
              IconButton(
                onPressed: () {
                  // TODO: Toggle star
                },
                icon: Icon(
                  index % 3 == 0 ? Icons.star : Icons.star_border,
                  color: index % 3 == 0 ? Colors.amber : Colors.grey[400],
                  size: 18,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
              ),
              
              const SizedBox(width: 12),
              
              // Avatar
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.blue[100],
                child: Text(
                  'A',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Mail Content
              Expanded(
                child: Row(
                  children: [
                    // Sender (Fixed width)
                    SizedBox(
                      width: 160,
                      child: Text(
                        'Sender Name $index',
                        style: TextStyle(
                          fontWeight: index % 2 == 0 ? FontWeight.bold : FontWeight.normal,
                          fontSize: 14,
                          color: Colors.grey[800],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // Subject & Preview
                    Expanded(
                      child: Text(
                        'Bu bir örnek mail konusu - Mail içeriğinin önizlemesi burada görünecek...',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Time
              Text(
                '12:34',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ========== PREVIEW PANEL ==========
  
  Widget _buildPreviewPanel() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: _selectedMailId != null
          ? _buildMailPreview()
          : _buildEmptyPreview(),
    );
  }

  Widget _buildMailPreview() {
    return Column(
      children: [
        // Preview Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Örnek Mail Konusu',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.blue[100],
                    child: Text(
                      'A',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sender Name',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[800],
                          ),
                        ),
                        Text(
                          'sender@example.com',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '2 saat önce',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Preview Content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Bu bir örnek mail içeriğidir. Gerçek mail içeriği burada görünecek...\n\nLorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
          ),
        ),
        
        // Preview Actions
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: Colors.grey[300]!)),
          ),
          child: Row(
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  // TODO: Reply
                },
                icon: const Icon(Icons.reply, size: 18),
                label: const Text('Yanıtla'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () {
                  // TODO: Forward
                },
                icon: const Icon(Icons.forward, size: 18),
                label: const Text('İlet'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyPreview() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.mail_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Mail seçin',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Önizlemek için sol taraftan bir mail seçin',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  // ========== FLOATING ACTIONS ==========
  
  Widget _buildComposeButton() {
    return FloatingActionButton.extended(
      onPressed: () {
        // TODO: Navigate to compose
        AppLogger.info('✍️ Compose FAB clicked');
      },
      icon: const Icon(Icons.edit),
      label: const Text('Yeni'),
      backgroundColor: Colors.blue[600],
      foregroundColor: Colors.white,
    );
  }
}