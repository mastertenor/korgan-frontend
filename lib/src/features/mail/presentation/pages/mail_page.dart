// lib/src/features/mail/presentation/pages/mail_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/mail.dart';
import '../providers/mail_providers.dart';
import '../providers/mail_provider.dart';
import '../widgets/mail_item/mail_item.dart';
import '../../../../core/network/api_endpoints.dart';

/// Ana mail uygulaması sayfası
///
/// Bu sayfa mail uygulamasının production-ready versiyonudur.
/// Optimistic UI pattern ile hızlı kullanıcı deneyimi sağlar.
class MailPage extends ConsumerStatefulWidget {
  final String userEmail;

  const MailPage({super.key, required this.userEmail});

  @override
  ConsumerState<MailPage> createState() => _MailPageState();
}

class _MailPageState extends ConsumerState<MailPage> {
  late ScrollController _scrollController;
  Set<int> selectedMailIndices = {};

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    // İlk yükleme - INBOX mailleri
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInboxMails(refresh: true);
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  /// Scroll dinleyicisi - infinite loading için
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreMails();
    }
  }

  @override
  Widget build(BuildContext context) {
    final mailState = ref.watch(mailProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: _buildAppBar(theme, mailState),
      body: _buildBody(mailState),
      floatingActionButton: _buildFAB(),
    );
  }

  /// AppBar widget'ı
  PreferredSizeWidget _buildAppBar(ThemeData theme, MailState mailState) {
    final hasSelection = selectedMailIndices.isNotEmpty;

    return AppBar(
      title: hasSelection
          ? Text('${selectedMailIndices.length} seçili')
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Gelen Kutusu'),
                if (mailState.unreadCount > 0)
                  Text(
                    '${mailState.unreadCount} okunmamış',
                    style: theme.textTheme.bodySmall,
                  ),
              ],
            ),
      actions: _buildAppBarActions(mailState, hasSelection),
    );
  }

  /// AppBar action butonları
  List<Widget> _buildAppBarActions(MailState mailState, bool hasSelection) {
    if (hasSelection) {
      return [
        // Toplu işlem butonları
        IconButton(
          icon: const Icon(Icons.mark_email_read),
          onPressed: _markSelectedAsRead,
          tooltip: 'Okundu olarak işaretle',
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: _moveSelectedToTrash,
          tooltip: 'Çöpe taşı',
        ),
        IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: _showMoreActions,
        ),
      ];
    }

    return [
      // Normal durum butonları
      _buildFilterButton(mailState),
      IconButton(
        icon: mailState.isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.refresh),
        onPressed: mailState.isLoading ? null : _refreshMails,
        tooltip: 'Yenile',
      ),
    ];
  }

  /// Filter butonu
  Widget _buildFilterButton(MailState mailState) {
    return PopupMenuButton<String>(
      icon: Icon(
        mailState.isFiltered ? Icons.filter_alt : Icons.filter_alt_outlined,
      ),
      tooltip: 'Filtrele',
      onSelected: _onFilterSelected,
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'all',
          child: ListTile(
            leading: Icon(Icons.all_inbox),
            title: Text('Tüm mailler'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem(
          value: 'unread',
          child: ListTile(
            leading: Icon(Icons.mark_email_unread),
            title: Text('Okunmamış'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem(
          value: 'starred',
          child: ListTile(
            leading: Icon(Icons.star, color: Colors.amber),
            title: Text('Yıldızlı'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem(
          value: 'important',
          child: ListTile(
            leading: Icon(Icons.label_important, color: Colors.orange),
            title: Text('Önemli'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }

  /// Ana içerik alanı
  Widget _buildBody(MailState mailState) {
    return Column(
      children: [
        // ✅ ERROR BANNER - Showcase'deki gibi
        if (mailState.error != null)
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
                    mailState.error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
                TextButton(
                  onPressed: () => ref.read(mailProvider.notifier).clearError(),
                  child: const Text('Kapat'),
                ),
              ],
            ),
          ),

        // Ana içerik
        Expanded(child: _buildMainContent(mailState)),
      ],
    );
  }

  /// Loading indicator widget
  Widget _buildLoadingIndicator() {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Center(child: CircularProgressIndicator()),
    );
  }

  /// Ana içerik (error state, empty state, veya mail listesi)
  Widget _buildMainContent(MailState mailState) {
    // Error state (sadece mail listesi boşsa)
    if (mailState.error != null && mailState.mails.isEmpty) {
      return _buildErrorState(mailState.error!);
    }

    // Empty state
    if (!mailState.isLoading && mailState.mails.isEmpty) {
      return _buildEmptyState();
    }

    // Mail listesi (error olsa bile mevcut mailleri göster)
    return RefreshIndicator(
      onRefresh: _refreshMails,
      child: ListView.separated(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: mailState.mails.length + (mailState.isLoadingMore ? 1 : 0),
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          // Loading indicator
          if (index == mailState.mails.length) {
            return _buildLoadingIndicator();
          }

          final mail = mailState.mails[index];
          final isSelected = selectedMailIndices.contains(index);

          // ✅ OPTIMISTIC UI: Hemen dismiss, background'da API
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
                    'Çöpe Taşı',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            onDismissed: (direction) {
              _optimisticMoveToTrash(mail, index);
            },
            child: MailItem(
              mail: mail,
              isSelected: isSelected,
              onTap: () => _onMailTap(mail, index),
              onToggleSelection: () => _toggleSelection(index),
              onArchive: () => _archiveMail(mail, index),
              onToggleStar: () => _toggleStar(mail),
              onToggleRead: () => _toggleRead(mail),
            ),
          );
        },
      ),
    );
  }

  /// Empty state widget
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.mail_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Gelen kutunuz boş',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Yeni e-postalar burada görünecek',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  /// Error state widget
  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Bir hata oluştu',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _refreshMails,
              icon: const Icon(Icons.refresh),
              label: const Text('Tekrar dene'),
            ),
          ],
        ),
      ),
    );
  }

  /// Floating Action Button
  Widget? _buildFAB() {
    if (selectedMailIndices.isNotEmpty) {
      return FloatingActionButton(
        onPressed: _clearSelection,
        tooltip: 'Seçimi temizle',
        child: const Icon(Icons.close),
      );
    }
    return null;
  }

  // ========== MAIL LOADING METHODS ==========

  /// INBOX maillerini yükle
  Future<void> _loadInboxMails({bool refresh = true}) async {
    await ref
        .read(mailProvider.notifier)
        .loadInboxMails(
          userEmail: widget.userEmail,
          maxResults: 20,
          refresh: refresh,
        );
  }

  /// Daha fazla mail yükle
  Future<void> _loadMoreMails() async {
    await ref
        .read(mailProvider.notifier)
        .loadMoreMailsWithFilters(userEmail: widget.userEmail, maxResults: 20);
  }

  /// Mailleri yenile
  Future<void> _refreshMails() async {
    await _loadInboxMails(refresh: true);
  }

  /// Filter seçimi
  void _onFilterSelected(String filter) {
    switch (filter) {
      case 'all':
        ref
            .read(mailProvider.notifier)
            .clearFiltersAndRefresh(userEmail: widget.userEmail);
        break;
      case 'unread':
        ref
            .read(mailProvider.notifier)
            .loadUnreadInboxMails(userEmail: widget.userEmail, refresh: true);
        break;
      case 'starred':
        ref
            .read(mailProvider.notifier)
            .loadStarredMails(userEmail: widget.userEmail, refresh: true);
        break;
      case 'important':
        ref
            .read(mailProvider.notifier)
            .searchMails(
              query: GmailQueries.important,
              userEmail: widget.userEmail,
              refresh: true,
            );
        break;
    }
  }

  // ========== OPTIMISTIC UI METHODS ==========

  /// ✅ OPTIMISTIC: Çöpe taşı - Hemen UI'dan kaldır, sonra API
  void _optimisticMoveToTrash(Mail mail, int index) {
    // ❌ MANUAL STATE UPDATE'İ KALDIR
    // _updateSelectionAfterRemoval(index);

    // ✅ PROVIDER'IN STATE'İNİ GÜNCELLE
    ref.read(mailProvider.notifier).optimisticRemoveMail(mail.id);

    // 2. Hemen success feedback
    _showSnackBar('${mail.senderName} çöpe taşındı', color: Colors.orange);

    // 3. API çağrısını background'da yap
    _performTrashOperation(mail);
  }

  /// ✅ Background API operation
  Future<void> _performTrashOperation(Mail mail) async {
    try {
      // Provider'dan state update etmeden sadece API çağrısı yap
      await ref
          .read(mailProvider.notifier)
          .moveToTrashApiOnly(mail.id, widget.userEmail);

      // Başarılı - hiçbir şey yapma (zaten UI'da silinmiş)
    } catch (error) {
      // ✅ Hata durumunda UNDO seçeneği sun
      _showUndoSnackBar(mail, error.toString());
    }
  }

  /// ✅ UNDO functionality ile error handling
  void _showUndoSnackBar(Mail mail, String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Expanded(child: Text('Silme başarısız: Bağlantı hatası')),
          ],
        ),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 5),
        action: SnackBarAction(
          label: 'GERİ AL',
          textColor: Colors.white,
          onPressed: () => _undoTrashOperation(mail),
        ),
      ),
    );
  }

  /// ✅ UNDO operation
  void _undoTrashOperation(Mail mail) {
    // Mail'i tekrar listeye ekle
    ref.read(mailProvider.notifier).restoreMailToList(mail);

    _showSnackBar('${mail.senderName} geri getirildi', color: Colors.green);
  }

  // ========== MAIL INTERACTION METHODS ==========

  /// Mail tıklama
  void _onMailTap(Mail mail, int index) {
    if (selectedMailIndices.isNotEmpty) {
      _toggleSelection(index);
    } else {
      // TODO: Mail detay sayfasına git
      if (!mail.isRead) {
        _toggleRead(mail);
      }
      _showSnackBar('${mail.senderName} maili açıldı');
    }
  }

  /// Seçim toggle
  void _toggleSelection(int index) {
    setState(() {
      if (selectedMailIndices.contains(index)) {
        selectedMailIndices.remove(index);
      } else {
        selectedMailIndices.add(index);
      }
    });
  }

  /// Seçimi temizle
  void _clearSelection() {
    setState(() {
      selectedMailIndices.clear();
    });
  }

  /// Mail arşivle
  void _archiveMail(Mail mail, int index) {
    // 1. UI'dan hemen kaldır
    _updateSelectionAfterRemoval(index);

    // 2. API çağrısını background'da yap
    ref
        .read(mailProvider.notifier)
        .archiveMail(mail.id, widget.userEmail)
        .then((_) {
          _showSnackBar('${mail.senderName} arşivlendi', color: Colors.green);
        })
        .catchError((error) {
          _showSnackBar(
            'Arşivleme başarısız: ${error.toString()}',
            color: Colors.red,
          );
        });
  }

  /// Yıldız toggle
  void _toggleStar(Mail mail) {
    if (mail.isStarred) {
      ref.read(mailProvider.notifier).unstarMail(mail.id, widget.userEmail);
      _showSnackBar('${mail.senderName} yıldızı kaldırıldı');
    } else {
      ref.read(mailProvider.notifier).starMail(mail.id, widget.userEmail);
      _showSnackBar('${mail.senderName} yıldızlandı ⭐');
    }
  }

  /// Okundu/Okunmadı toggle
  void _toggleRead(Mail mail) {
    if (mail.isRead) {
      ref.read(mailProvider.notifier).markAsUnread(mail.id, widget.userEmail);
      _showSnackBar('${mail.senderName} okunmadı olarak işaretlendi');
    } else {
      ref.read(mailProvider.notifier).markAsRead(mail.id, widget.userEmail);
      _showSnackBar('${mail.senderName} okundu olarak işaretlendi');
    }
  }

  // ========== BULK OPERATIONS ==========

  /// Seçili mailleri okundu işaretle
  void _markSelectedAsRead() {
    final mails = ref.read(mailProvider).mails;
    for (final index in selectedMailIndices) {
      if (index < mails.length && !mails[index].isRead) {
        ref
            .read(mailProvider.notifier)
            .markAsRead(mails[index].id, widget.userEmail);
      }
    }
    _clearSelection();
    _showSnackBar('Seçili mailler okundu olarak işaretlendi');
  }

  /// Seçili mailleri çöpe taşı
  void _moveSelectedToTrash() {
    final mails = ref.read(mailProvider).mails;
    final mailsToTrash = selectedMailIndices
        .where((index) => index < mails.length)
        .map((index) => mails[index])
        .toList();

    for (final mail in mailsToTrash) {
      ref
          .read(mailProvider.notifier)
          .moveToTrashApiOnly(mail.id, widget.userEmail);
    }
    _clearSelection();
    _showSnackBar(
      '${mailsToTrash.length} e-posta çöpe taşındı',
      color: Colors.orange,
    );
  }

  /// Daha fazla işlem göster
  void _showMoreActions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.select_all),
            title: const Text('Tümünü seç'),
            onTap: () {
              Navigator.pop(context);
              setState(() {
                selectedMailIndices = Set.from(
                  List.generate(
                    ref.read(mailProvider).mails.length,
                    (index) => index,
                  ),
                );
              });
            },
          ),
          ListTile(
            leading: const Icon(Icons.star_outline),
            title: const Text('Yıldızla'),
            onTap: () {
              Navigator.pop(context);
              _starSelected();
            },
          ),
          ListTile(
            leading: const Icon(Icons.archive_outlined),
            title: const Text('Arşivle'),
            onTap: () {
              Navigator.pop(context);
              _archiveSelected();
            },
          ),
        ],
      ),
    );
  }

  /// Seçili mailleri yıldızla
  void _starSelected() {
    final mails = ref.read(mailProvider).mails;
    for (final index in selectedMailIndices) {
      if (index < mails.length && !mails[index].isStarred) {
        ref
            .read(mailProvider.notifier)
            .starMail(mails[index].id, widget.userEmail);
      }
    }
    _clearSelection();
    _showSnackBar('Seçili mailler yıldızlandı');
  }

  /// Seçili mailleri arşivle
  void _archiveSelected() {
    final mails = ref.read(mailProvider).mails;
    for (final index in selectedMailIndices) {
      if (index < mails.length) {
        ref
            .read(mailProvider.notifier)
            .archiveMail(mails[index].id, widget.userEmail);
      }
    }
    _clearSelection();
    _showSnackBar('Seçili mailler arşivlendi');
  }

  // ========== UTILITY METHODS ==========

  /// Seçim indekslerini güncelle (mail silindikten sonra)
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

  /// SnackBar göster
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
