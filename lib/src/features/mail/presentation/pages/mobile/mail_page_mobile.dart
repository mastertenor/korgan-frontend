// lib/src/features/mail/presentation/pages/mobile/mail_page_mobile.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/mail.dart';
import '../../../domain/entities/mail_detail.dart'; // 🆕 Added for MailDetail type
import '../../providers/mail_providers.dart';
import '../../providers/mail_provider.dart';
import '../../widgets/mail_item/mail_item.dart';
import 'mail_search_mobile.dart';
import 'mail_detail_mobile.dart';

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
    MailContext? mailContext,
    bool isSearchMode,
  ) {
    final unreadCount = mailContext?.unreadCount ?? 0;
    final folderName = _getFolderDisplayName(currentFolder);

    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(isSearchMode ? 'Arama Sonuçları' : folderName),
          if (unreadCount > 0 && !isSearchMode)
            Text(
              '$unreadCount okunmamış',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white.withOpacity(0.9),
              ),
            ),
        ],
      ),
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
      elevation: 2,
      actions: _buildAppBarActions(context, isSearchMode),
    );
  }

  /// AppBar actions
  List<Widget> _buildAppBarActions(BuildContext context, bool isSearchMode) {
    final currentContext = ref.watch(currentContextProvider);

    if (isSearchMode) {
      return [
        IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _exitSearch,
          tooltip: 'Aramadan Çık',
        ),
      ];
    }

    return [
      IconButton(
        icon: const Icon(Icons.search),
        onPressed: _navigateToSearchPage,
        tooltip: 'Ara',
      ),
      IconButton(
        icon: (currentContext?.isLoading ?? false)
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.refresh),
        onPressed: (currentContext?.isLoading ?? false)
            ? null
            : _refreshCurrentFolder,
        tooltip: 'Yenile',
      ),
      _buildFolderSwitchButton(),
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
    MailContext? currentContext,
    bool isSearchMode,
  ) {
    // Error state
    if (error != null) {
      return _buildErrorWidget(error, isSearchMode);
    }

    // Loading state (first load)
    if (isLoading && currentMails.isEmpty) {
      return _buildLoadingWidget();
    }

    // Empty state
    if (currentMails.isEmpty && !isLoading) {
      return _buildEmptyWidget(isSearchMode);
    }

    // Mail list
    return RefreshIndicator(
      onRefresh: _refreshCurrentFolder,
      child: ListView.builder(
        controller: _scrollController,
        itemCount:
            currentMails.length +
            (currentContext?.isLoadingMore == true ? 1 : 0),
        itemBuilder: (context, index) {
          // Loading more indicator
          if (index == currentMails.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final mail = currentMails[index];
          return MailItem(
            mail: mail,
            isSelected: false, // 🆕 Fixed: Added required parameter
            onTap: () => _onMailTap(mail),
            onArchive: () => _optimisticMoveToTrash(mail),
            onToggleStar: () => _toggleStar(mail),
            onToggleSelection:
                () {}, // 🆕 Fixed: Added required parameter (empty for now)
            onToggleRead: () => _toggleRead(mail),
          );
        },
      ),
    );
  }

  /// Loading widget
  Widget _buildLoadingWidget() {
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

  /// Error widget
  Widget _buildErrorWidget(String error, bool isSearchMode) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: Colors.red[400]),
            const SizedBox(height: 16),
            Text(
              'Hata',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: isSearchMode ? _exitSearch : _refreshCurrentFolder,
              icon: Icon(isSearchMode ? Icons.arrow_back : Icons.refresh),
              label: Text(isSearchMode ? 'Geri Dön' : 'Tekrar Dene'),
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

  /// Empty widget
  Widget _buildEmptyWidget(bool isSearchMode) {
    final currentFolder = ref.watch(currentFolderProvider);

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

  /// Exit search mode
  void _exitSearch() {
    ref.read(mailProvider.notifier).exitSearch();
  }

  void _navigateToSearchPage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MailSearchMobile(userEmail: widget.userEmail),
      ),
    );
  }

  // ========== MAIL ACTIONS ==========

  /// Mail tıklama - Navigation to Mail Detail
  void _onMailTap(Mail mail) {
    // Mark as read if unread
    if (!mail.isRead) {
      _toggleRead(mail);
    }

    // Navigate to mail detail page
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            MailDetailMobile(mailId: mail.id, userEmail: widget.userEmail),
      ),
    );
  }

  /// Optimistic move to trash
  void _optimisticMoveToTrash(Mail mail) {
    // 1. Immediately remove from UI
    ref.read(mailProvider.notifier).optimisticRemoveFromCurrentContext(mail.id);
    _showSnackBar('${mail.senderName} çöp kutusuna taşındı');

    // 2. Background API call
    ref
        .read(mailProvider.notifier)
        .moveToTrashApiOnly(mail.id, widget.userEmail)
        .catchError((error) {
          _showSnackBar('Çöp kutusuna taşıma başarısız', color: Colors.red);
        });
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

  /// Toggle read
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

// ========== COMPOSE TYPE ENUM ==========
// 🆕 ComposeType enum moved to separate file to avoid conflicts

// Import ComposeType from mail_compose_mobile.dart instead of defining here
