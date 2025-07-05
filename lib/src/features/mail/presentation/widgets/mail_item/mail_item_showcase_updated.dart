// lib/src/features/mail/presentation/widgets/mail_item/mail_item_showcase_updated.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/mail.dart';
import '../../providers/mail_provider.dart';
import '../../providers/mail_providers.dart';
import '../../../../../utils/platform_helper.dart';
import 'mail_item.dart';

void main() {
  runApp(ProviderScope(child: MailItemShowcaseApp()));
}

/// Showcase app for demonstrating mail item widget with state management
class MailItemShowcaseApp extends StatelessWidget {
  const MailItemShowcaseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gmail Mobile - ${PlatformHelper.platformName}',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        checkboxTheme: CheckboxThemeData(
          fillColor: WidgetStateProperty.resolveWith<Color>((states) {
            if (states.contains(WidgetState.selected)) {
              return const Color(0xFF1A73E8);
            }
            return Colors.transparent;
          }),
          checkColor: WidgetStateProperty.all(Colors.white),
        ),
      ),
      home: const MailItemShowcase(),
      debugShowCheckedModeBanner: false,
    );
  }
}

/// Main showcase widget with Gmail mobile pagination
class MailItemShowcase extends ConsumerStatefulWidget {
  const MailItemShowcase({super.key});

  @override
  ConsumerState<MailItemShowcase> createState() => _MailItemShowcaseState();
}

class _MailItemShowcaseState extends ConsumerState<MailItemShowcase> {
  final String userEmail = 'berk@argenteknoloji.com';
  Set<int> selectedMailIndices = {};
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    // Initial load when widget initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(mailProvider.notifier).initialLoadMails(userEmail);
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  /// Handle scroll for infinite loading (Gmail mobile style)
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      // When near bottom, load more
      _loadMoreMails();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch mail state
    final mailState = ref.watch(mailProvider);
    final isLoading = mailState.isLoading;
    final isLoadingMore = mailState.isLoadingMore;
    final error = mailState.error;
    final unreadCount = mailState.unreadCount;
    final hasMore = mailState.hasMore;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Gmail Mobile'),
            Text(
              'Mails: ${mailState.mails.length} | Unread: $unreadCount${hasMore ? ' | +' : ''}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        actions: [
          // Refresh button
          IconButton(
            icon: isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.refresh),
            onPressed: isLoading ? null : () => _refreshMails(),
            tooltip: 'Pull to Refresh',
          ),

          if (selectedMailIndices.isNotEmpty) ...[
            // Selected count
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${selectedMailIndices.length} seçili',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // Bulk actions
            IconButton(
              icon: const Icon(Icons.select_all),
              onPressed: () => _selectAllMails(),
              tooltip: 'Tümünü Seç',
            ),
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () => _clearSelection(),
              tooltip: 'Seçimi Temizle',
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _moveSelectedToTrash(),
              tooltip: 'Seçilenleri Çöp Kutusuna Taşı',
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          // Error banner
          if (error != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.red.withOpacity(0.1),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      error,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        ref.read(mailProvider.notifier).clearError(),
                    child: const Text('Kapat'),
                  ),
                ],
              ),
            ),

          // Selection info
          if (selectedMailIndices.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: const Color(0xFF1A73E8).withOpacity(0.1),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: Color(0xFF1A73E8),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${selectedMailIndices.length} mail seçildi',
                    style: const TextStyle(
                      color: Color(0xFF1A73E8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _clearSelection,
                    child: const Text('Temizle'),
                  ),
                ],
              ),
            ),

          // Pagination info (Debug)
          if (mailState.mails.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.grey.withOpacity(0.1),
              child: Text(
                'Pagination: ${hasMore ? 'Has More' : 'End'} | '
                'Loading: ${isLoadingMore ? 'Yes' : 'No'} | '
                'Total Est: ${mailState.totalEstimate}',
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ),

          // Mail list
          Expanded(child: _buildMailList(mailState)),
        ],
      ),
    );
  }

  /// Build mail list with Gmail mobile pagination
  Widget _buildMailList(MailState mailState) {
    final isLoading = mailState.isLoading;
    final isLoadingMore = mailState.isLoadingMore;
    // Initial loading state
    if (isLoading && mailState.mails.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('E-postalar yükleniyor...'),
          ],
        ),
      );
    }

    // Empty state
    if (mailState.mails.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.mail_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Henüz e-posta yok',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _refreshMails(),
              child: const Text('Yenile'),
            ),
          ],
        ),
      );
    }

    // Mail list with RefreshIndicator
    return RefreshIndicator(
      onRefresh: _refreshMails,
      child: ListView.separated(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount:
            mailState.mails.length +
            (isLoadingMore ? 1 : 0) +
            (!mailState.hasMore ? 1 : 0),
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          // Load more indicator at the bottom
          if (index == mailState.mails.length && isLoadingMore) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 12),
                    Text('Daha fazla yükleniyor...'),
                  ],
                ),
              ),
            );
          }

          // End of list indicator
          if (index == mailState.mails.length + (isLoadingMore ? 1 : 0) &&
              !mailState.hasMore) {
            return Container(
              padding: const EdgeInsets.all(16),
              child: const Center(
                child: Text(
                  'Tüm e-postalar yüklendi',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
            );
          }

          // Regular mail item
          if (index < mailState.mails.length) {
            final mail = mailState.mails[index];
            final isSelected = selectedMailIndices.contains(index);

            return Dismissible(
              key: Key(mail.id),
              direction: DismissDirection.endToStart,
              background: Container(
                color: Colors.orange,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(Icons.delete_outline, color: Colors.white, size: 24),
                    SizedBox(width: 8),
                    Text(
                      'Çöp Kutusu',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              onDismissed: (direction) {
                _moveToTrash(mail, index);
              },
              child: MailItem(
                mail: mail,
                isSelected: isSelected,
                onTap: () => _onMailTap(mail, index),
                onToggleSelection: () => _toggleSelection(index),
                onArchive: () => _archiveMail(mail, index),
                onDelete: () => _moveToTrash(mail, index),
                onToggleStar: () => _toggleStar(mail),
                onToggleRead: () => _toggleRead(mail),
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  /// Refresh mails (Pull to refresh - Gmail mobile style)
  Future<void> _refreshMails() async {
    await ref.read(mailProvider.notifier).refreshMails(userEmail);
  }

  /// Load more mails (Infinite scroll - Gmail mobile style)
  Future<void> _loadMoreMails() async {
    await ref.read(mailProvider.notifier).loadMoreMails(userEmail);
  }

  /// Handle mail tap
  void _onMailTap(Mail mail, int index) {
    if (!mail.isRead) {
      _toggleRead(mail);
    }
    _showSnackBar('${mail.senderName} mail\'i açıldı');
  }

  /// Toggle mail selection
  void _toggleSelection(int index) {
    setState(() {
      if (selectedMailIndices.contains(index)) {
        selectedMailIndices.remove(index);
      } else {
        selectedMailIndices.add(index);
      }
    });
  }

  /// Select all mails
  void _selectAllMails() {
    setState(() {
      selectedMailIndices = Set.from(
        List.generate(ref.read(mailProvider).mails.length, (index) => index),
      );
    });
    _showSnackBar('Tüm mailler seçildi');
  }

  /// Clear selection
  void _clearSelection() {
    setState(() {
      selectedMailIndices.clear();
    });
    _showSnackBar('Seçim temizlendi');
  }

  /// Archive mail
  void _archiveMail(Mail mail, int index) async {
    await ref.read(mailProvider.notifier).archiveMail(mail.id, userEmail);

    // Update selection indices
    _updateSelectionAfterRemoval(index);
    _showSnackBar('${mail.senderName} mail\'i arşivlendi', color: Colors.green);
  }

  /// Move mail to trash
  void _moveToTrash(Mail mail, int index) async {
    await ref.read(mailProvider.notifier).moveToTrash(mail.id, userEmail);

    // Update selection indices
    _updateSelectionAfterRemoval(index);
    _showSnackBar(
      '${mail.senderName} çöp kutusuna taşındı',
      color: Colors.orange,
    );
  }

  /// Toggle star status
  void _toggleStar(Mail mail) async {
    if (mail.isStarred) {
      await ref.read(mailProvider.notifier).unstarMail(mail.id, userEmail);
      _showSnackBar('${mail.senderName} yıldızı kaldırıldı');
    } else {
      await ref.read(mailProvider.notifier).starMail(mail.id, userEmail);
      _showSnackBar('${mail.senderName} yıldızlandı ⭐');
    }
  }

  /// Toggle read status
  void _toggleRead(Mail mail) async {
    if (mail.isRead) {
      await ref.read(mailProvider.notifier).markAsUnread(mail.id, userEmail);
      _showSnackBar('${mail.senderName} okunmadı olarak işaretlendi');
    } else {
      await ref.read(mailProvider.notifier).markAsRead(mail.id, userEmail);
      _showSnackBar('${mail.senderName} okundu olarak işaretlendi');
    }
  }

  /// Move selected mails to trash
  void _moveSelectedToTrash() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seçili Mailleri Çöp Kutusuna Taşı'),
        content: Text(
          '${selectedMailIndices.length} mail\'i çöp kutusuna taşımak istediğinizden emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _performBulkMoveToTrash();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: const Text('Çöp Kutusuna Taşı'),
          ),
        ],
      ),
    );
  }

  /// Perform bulk move to trash
  void _performBulkMoveToTrash() async {
    final selectedCount = selectedMailIndices.length;
    final mailsToTrash = selectedMailIndices
        .map((index) => ref.read(mailProvider).mails[index])
        .toList();

    // Move each mail to trash
    for (final mail in mailsToTrash) {
      await ref.read(mailProvider.notifier).moveToTrash(mail.id, userEmail);
    }

    setState(() {
      selectedMailIndices.clear();
    });

    _showSnackBar(
      '$selectedCount mail çöp kutusuna taşındı',
      color: Colors.orange,
    );
  }

  /// Update selection after removal
  void _updateSelectionAfterRemoval(int removedIndex) {
    final newSelection = <int>{};
    for (final selectedIndex in selectedMailIndices) {
      if (selectedIndex < removedIndex) {
        newSelection.add(selectedIndex);
      } else if (selectedIndex > removedIndex) {
        newSelection.add(selectedIndex - 1);
      }
    }
    setState(() {
      selectedMailIndices = newSelection;
    });
  }

  /// Show snack bar
  void _showSnackBar(String message, {Color? color}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
