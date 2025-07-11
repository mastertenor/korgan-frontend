// lib/src/features/mail/presentation/pages/mobile/mail_page_mobile.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/mail.dart';
import '../../providers/mail_providers.dart';
import '../../providers/mail_provider.dart';
import '../../widgets/mail_item/mail_item.dart';

class MailPageMobile extends ConsumerStatefulWidget {
  final String userEmail;

  const MailPageMobile({super.key, required this.userEmail});

  @override
  ConsumerState<MailPageMobile> createState() => _MailPageMobileState();
}

class _MailPageMobileState extends ConsumerState<MailPageMobile> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    // Set user email and load initial folder
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeMailPage();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  /// Initialize mail page with user context
  Future<void> _initializeMailPage() async {
    // Set current user email
    ref.read(mailProvider.notifier).setCurrentUserEmail(widget.userEmail);

    // Load inbox folder (smart caching - won't reload if already cached)
    await ref
        .read(mailProvider.notifier)
        .loadFolder(MailFolder.inbox, userEmail: widget.userEmail);
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
    // Watch current context state
    final currentFolder = ref.watch(currentFolderProvider);
    final currentMails = ref.watch(currentMailsProvider);
    final isLoading = ref.watch(currentLoadingProvider);
    final error = ref.watch(currentErrorProvider);
    final isSearchMode = ref.watch(isSearchModeProvider);
    final currentContext = ref.watch(currentContextProvider);

    final theme = Theme.of(context);

    return Scaffold(
      appBar: _buildAppBar(theme, currentFolder, currentContext, isSearchMode),
      body: _buildBody(
        currentMails,
        isLoading,
        error,
        currentContext,
        isSearchMode,
      ),
    );
  }

  /// AppBar widget'ı - Context-aware
  PreferredSizeWidget _buildAppBar(
    ThemeData theme,
    MailFolder currentFolder,
    MailContext? context,
    bool isSearchMode,
  ) {
    final unreadCount = context?.unreadCount ?? 0;
    final folderName = _getFolderDisplayName(currentFolder);

    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(isSearchMode ? 'Arama Sonuçları' : folderName),
          if (unreadCount > 0)
            Text(
              '$unreadCount okunmamış',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.appBarTheme.foregroundColor?.withOpacity(0.8),
              ),
            ),
        ],
      ),
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
      leading: isSearchMode
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: _exitSearch,
            )
          : null,
      actions: _buildAppBarActions(context, isSearchMode),
    );
  }

  /// AppBar action butonları - Context-aware
  List<Widget> _buildAppBarActions(MailContext? context, bool isSearchMode) {
    if (isSearchMode) {
      return [
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: _exitSearch,
          tooltip: 'Aramayı Kapat',
        ),
      ];
    }

    return [
      _buildFolderSwitchButton(),
      IconButton(
        icon: const Icon(Icons.search),
        onPressed: _showSearchDialog,
        tooltip: 'Ara',
      ),
      IconButton(
        icon: (context?.isLoading ?? false)
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.refresh),
        onPressed: (context?.isLoading ?? false) ? null : _refreshCurrentFolder,
        tooltip: 'Yenile',
      ),
    ];
  }

  /// Folder switch button
  Widget _buildFolderSwitchButton() {
    return PopupMenuButton<MailFolder>(
      icon: const Icon(Icons.folder, color: Colors.white),
      tooltip: 'Klasör Değiştir',
      onSelected: _onFolderSelected,
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: MailFolder.inbox,
          child: ListTile(
            leading: Icon(Icons.inbox),
            title: Text('Gelen Kutusu'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem(
          value: MailFolder.starred,
          child: ListTile(
            leading: Icon(Icons.star, color: Colors.amber),
            title: Text('Yıldızlı'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem(
          value: MailFolder.sent,
          child: ListTile(
            leading: Icon(Icons.send),
            title: Text('Gönderilmiş'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem(
          value: MailFolder.drafts,
          child: ListTile(
            leading: Icon(Icons.drafts),
            title: Text('Taslaklar'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem(
          value: MailFolder.spam,
          child: ListTile(
            leading: Icon(Icons.report, color: Colors.orange),
            title: Text('Spam'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem(
          value: MailFolder.trash,
          child: ListTile(
            leading: Icon(Icons.delete, color: Colors.red),
            title: Text('Çöp Kutusu'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }

  /// Ana içerik alanı
  Widget _buildBody(
    List<Mail> currentMails,
    bool isLoading,
    String? error,
    MailContext? context,
    bool isSearchMode,
  ) {
    return Column(
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
                    style: const TextStyle(color: Colors.red, fontSize: 14),
                  ),
                ),
                TextButton(
                  onPressed: () => ref.read(mailProvider.notifier).clearError(),
                  child: const Text('Kapat', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),

        // Search mode indicator
        if (isSearchMode && context?.currentQuery != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.blue.withOpacity(0.1),
            child: Row(
              children: [
                const Icon(Icons.search, color: Colors.blue, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Arama: "${context!.currentQuery}"',
                    style: const TextStyle(color: Colors.blue, fontSize: 12),
                  ),
                ),
                TextButton(
                  onPressed: _exitSearch,
                  child: const Text('Temizle', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),

        // Ana içerik
        Expanded(child: _buildMainContent(currentMails, isLoading, context)),
      ],
    );
  }

  /// Ana içerik (error state, empty state, veya mail listesi)
  Widget _buildMainContent(
    List<Mail> mails,
    bool isLoading,
    MailContext? context,
  ) {
    // İlk yükleme loading state
    if (isLoading && mails.isEmpty) {
      return _buildLoadingIndicator();
    }

    // Empty state
    if (!isLoading && mails.isEmpty) {
      return _buildEmptyState();
    }

    // Mail listesi - Context-aware
    return RefreshIndicator(
      onRefresh: _refreshCurrentFolder,
      child: ListView.separated(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: mails.length + ((context?.isLoadingMore ?? false) ? 1 : 0),
        separatorBuilder: (context, index) =>
            const Divider(height: 1, indent: 72),
        itemBuilder: (context, index) {
          // Loading indicator
          if (index == mails.length) {
            return _buildLoadingIndicator();
          }

          final mail = mails[index];

          // Optimistic UI: Swipe to delete with confirmation
          return Dismissible(
            key: Key(mail.id),
            direction: DismissDirection.endToStart,
            background: Container(
              color: Colors.orange,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.delete_outline, color: Colors.white, size: 28),
                  SizedBox(height: 4),
                  Text(
                    'Çöpe Taşı',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            onDismissed: (direction) {
              _optimisticMoveToTrash(mail);
            },
            child: MailItem(
              mail: mail,
              isSelected: false,
              onTap: () => _onMailTap(mail),
              onToggleSelection: null,
              onArchive: () => _archiveMail(mail),
              onToggleStar: () => _toggleStar(mail),
              onToggleRead: () => _toggleRead(mail),
            ),
          );
        },
      ),
    );
  }

  /// Loading indicator widget
  Widget _buildLoadingIndicator() {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Center(child: CircularProgressIndicator()),
    );
  }

  /// Empty state widget - Context-aware
  Widget _buildEmptyState() {
    final currentFolder = ref.watch(currentFolderProvider);
    final isSearchMode = ref.watch(isSearchModeProvider);

    final title = isSearchMode
        ? 'Arama sonucu bulunamadı'
        : '${_getFolderDisplayName(currentFolder)} boş';

    final subtitle = isSearchMode
        ? 'Farklı arama terimleri deneyin'
        : 'Yeni e-postalar burada görünecek';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSearchMode ? Icons.search_off : Icons.mail_outline,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: isSearchMode ? _exitSearch : _refreshCurrentFolder,
              icon: Icon(isSearchMode ? Icons.arrow_back : Icons.refresh),
              label: Text(isSearchMode ? 'Geri Dön' : 'Yenile'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========== CONTEXT-AWARE ACTIONS ==========

  /// Refresh current folder
  Future<void> _refreshCurrentFolder() async {
    await ref
        .read(mailProvider.notifier)
        .refreshCurrentFolder(userEmail: widget.userEmail);
  }

  /// Load more mails in current folder
  Future<void> _loadMoreMails() async {
    await ref
        .read(mailProvider.notifier)
        .loadMoreInCurrentFolder(userEmail: widget.userEmail);
  }

  /// Switch to selected folder
  Future<void> _onFolderSelected(MailFolder folder) async {
    await ref
        .read(mailProvider.notifier)
        .loadFolder(folder, userEmail: widget.userEmail);
  }

  /// Search in current folder
  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) return;

    await ref
        .read(mailProvider.notifier)
        .searchInCurrentFolder(
          query: query.trim(),
          userEmail: widget.userEmail,
        );
  }

  /// Exit search mode
  void _exitSearch() {
    ref.read(mailProvider.notifier).exitSearch();
  }

  /// Show search dialog
  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ara'),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Arama terimi girin...',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (query) {
            Navigator.of(context).pop();
            _performSearch(query);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
        ],
      ),
    );
  }

  // ========== MAIL ACTIONS ==========

  /// Mail tıklama
  void _onMailTap(Mail mail) {
    // TODO: Mail detay sayfasına git
    if (!mail.isRead) {
      _toggleRead(mail);
    }
    _showSnackBar('${mail.senderName} maili açıldı');
  }

  /// Optimistic move to trash
  void _optimisticMoveToTrash(Mail mail) {
    // 1. ✅ Immediately remove from UI (optimistic)
    ref.read(mailProvider.notifier).optimisticRemoveFromCurrentContext(mail.id);

    // 2. Show success feedback
    _showSnackBar('${mail.senderName} çöpe taşındı', color: Colors.orange);

    // 3. API call in background
    _performTrashOperation(mail);
  }

  /// Background API operation for trash
  Future<void> _performTrashOperation(Mail mail) async {
    try {
      // API-only call (no state change)
      await ref
          .read(mailProvider.notifier)
          .moveToTrashApiOnly(mail.id, widget.userEmail);

      // ✅ Success - nothing to do (already removed from UI)
    } catch (error) {
      // ❌ API failed - show UNDO option
      _showUndoSnackBar(mail, error.toString());
    }
  }

  /// Show UNDO snackbar for failed operations
  void _showUndoSnackBar(Mail mail, String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            const Expanded(child: Text('Silme başarısız: Bağlantı hatası')),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'GERİ AL',
          textColor: Colors.white,
          onPressed: () => _undoTrashOperation(mail),
        ),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// UNDO trash operation
  void _undoTrashOperation(Mail mail) {
    // Restore mail to current context
    ref.read(mailProvider.notifier).restoreMailToCurrentContext(mail);
    _showSnackBar('${mail.senderName} geri getirildi', color: Colors.green);
  }

  /// Archive mail with optimistic UI
  void _archiveMail(Mail mail) {
    // 1. ✅ Immediately remove from UI (optimistic)
    ref.read(mailProvider.notifier).optimisticRemoveFromCurrentContext(mail.id);

    // 2. Show success feedback
    _showSnackBar('${mail.senderName} arşivlendi', color: Colors.green);

    // 3. API call in background
    _performArchiveOperation(mail);
  }

  /// Background API operation for archive
  Future<void> _performArchiveOperation(Mail mail) async {
    try {
      // API-only call (no state change)
      await ref
          .read(mailProvider.notifier)
          .archiveMailApiOnly(mail.id, widget.userEmail);

      // ✅ Success - nothing to do (already removed from UI)
    } catch (error) {
      // ❌ API failed - show UNDO option
      _showArchiveUndoSnackBar(mail, error.toString());
    }
  }

  /// Show UNDO snackbar for failed archive
  void _showArchiveUndoSnackBar(Mail mail, String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            const Expanded(child: Text('Arşivleme başarısız: Bağlantı hatası')),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'GERİ AL',
          textColor: Colors.white,
          onPressed: () => _undoArchiveOperation(mail),
        ),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// UNDO archive operation
  void _undoArchiveOperation(Mail mail) {
    // Restore mail to current context
    ref.read(mailProvider.notifier).restoreMailToCurrentContext(mail);
    _showSnackBar('${mail.senderName} geri getirildi', color: Colors.green);
  }

  /// Toggle star
  void _toggleStar(Mail mail) {
    if (mail.isStarred) {
      ref.read(mailProvider.notifier).unstarMail(mail.id, widget.userEmail);
      _showSnackBar('${mail.senderName} yıldızı kaldırıldı');
    } else {
      ref.read(mailProvider.notifier).starMail(mail.id, widget.userEmail);
      _showSnackBar('${mail.senderName} yıldızlandı ⭐');
    }
  }

  /// Toggle read status
  void _toggleRead(Mail mail) {
    if (mail.isRead) {
      ref.read(mailProvider.notifier).markAsUnread(mail.id, widget.userEmail);
      _showSnackBar('${mail.senderName} okunmadı olarak işaretlendi');
    } else {
      ref.read(mailProvider.notifier).markAsRead(mail.id, widget.userEmail);
      _showSnackBar('${mail.senderName} okundu olarak işaretlendi');
    }
  }

  // ========== UTILITY METHODS ==========

  /// Get folder display name
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

  /// Show snackbar
  void _showSnackBar(String message, {Color? color}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
