// lib/src/features/mail/presentation/pages/mobile/mail_search_mobile.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/mail.dart';
import '../../providers/mail_providers.dart';
import '../../providers/mail_provider.dart';
import '../../widgets/mail_item/mail_item.dart';
import 'mail_detail_mobile.dart'; // 🆕 Import for navigation

class MailSearchMobile extends ConsumerStatefulWidget {
  final String userEmail;

  const MailSearchMobile({super.key, required this.userEmail});

  @override
  ConsumerState<MailSearchMobile> createState() => _MailSearchMobileState();
}

class _MailSearchMobileState extends ConsumerState<MailSearchMobile> {
  late TextEditingController _searchController;
  late FocusNode _searchFocusNode;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    // Auto-focus search field when page opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  /// Scroll dinleyicisi - infinite loading için
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreSearchResults();
    }
  }

  /// Load more search results
  Future<void> _loadMoreSearchResults() async {
    await ref
        .read(mailProvider.notifier)
        .loadMoreInCurrentFolder(userEmail: widget.userEmail);
  }

  /// Search sayfasından çıkarken state'i temizle
  void _exitSearchAndNavigateBack() {
    // Search state'ini temizle
    ref.read(mailProvider.notifier).exitSearch();
    // Sayfayı kapat
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    // Watch search state
    final isSearchMode = ref.watch(isSearchModeProvider);
    final currentMails = ref.watch(currentMailsProvider);
    final isLoading = ref.watch(currentLoadingProvider);
    final error = ref.watch(currentErrorProvider);
    final currentContext = ref.watch(currentContextProvider);
    final currentFolder = ref.watch(currentFolderProvider);

    // 🐛 DEBUG: State durumlarını konsola yazdır
    print('=== MAIL SEARCH DEBUG ===');
    print('isSearchMode: $isSearchMode');
    print('currentFolder: $currentFolder');
    print('currentMails.length: ${currentMails.length}');
    print('isLoading (provider): $isLoading');
    print('error: $error');
    print('currentContext: $currentContext');
    print('========================');

    // Hardware back button'ı da yakalayalım
    return WillPopScope(
      onWillPop: () async {
        // Hardware back button'a basıldığında da search state'ini temizle
        ref.read(mailProvider.notifier).exitSearch();
        return true; // Normal back navigation'a izin ver
      },
      child: Scaffold(
        appBar: _buildSearchAppBar(),
        body: Column(
          children: [
            if (error != null) _buildErrorBanner(error),
            Expanded(
              child: _buildSearchContent(
                currentMails,
                isLoading, // ✅ Sadece provider loading kullanıyoruz
                isSearchMode,
                currentContext,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Search AppBar with search field
  PreferredSizeWidget _buildSearchAppBar() {
    return AppBar(
      title: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        decoration: const InputDecoration(
          hintText: 'E-postalarda ara...',
          border: InputBorder.none,
          hintStyle: TextStyle(color: Colors.white70),
        ),
        style: const TextStyle(color: Colors.white, fontSize: 18),
        onSubmitted: _performSearch,
        textInputAction: TextInputAction.search,
      ),
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: _exitSearchAndNavigateBack,
      ),
      actions: [
        if (_searchController.text.isNotEmpty)
          IconButton(icon: const Icon(Icons.clear), onPressed: _clearSearch),
      ],
    );
  }

  /// Error banner
  Widget _buildErrorBanner(String error) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: Colors.red.withOpacity(0.1),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(error, style: const TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () => ref.read(mailProvider.notifier).clearError(),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  /// Main search content - SIMPLIFIED (no local loading)
  Widget _buildSearchContent(
    List<Mail> mails,
    bool isLoading, // Sadece provider loading
    bool isSearchMode,
    MailContext? context,
  ) {
    print('📱 _buildSearchContent çağrıldı:');
    print('   isSearchMode: $isSearchMode');
    print('   isLoading: $isLoading');
    print('   mails.length: ${mails.length}');

    // ✅ Loading state - önce kontrol edilir (searchMode'dan bağımsız)
    if (isLoading) {
      print('👉 Showing LOADING STATE');
      return _buildLoadingState();
    }

    // Initial state - no search performed yet
    if (!isSearchMode) {
      print('👉 Showing INITIAL STATE');
      return _buildInitialState();
    }

    // Empty search results
    if (mails.isEmpty) {
      print('👉 Showing EMPTY STATE');
      return _buildEmptySearchState();
    }

    // Search results
    print('👉 Showing SEARCH RESULTS (${mails.length} mails)');
    return _buildSearchResults(mails, context);
  }

  /// Initial state before search
  Widget _buildInitialState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'E-postalarda arama yapın',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text(
            'Arama terimi girin veya hızlı filtrelerden birini seçin',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  /// Loading state
  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Aranıyor...'),
        ],
      ),
    );
  }

  /// Empty search results
  Widget _buildEmptySearchState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('Arama sonucu bulunamadı', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 8),
          Text(
            '"${_searchController.text}" için sonuç yok',
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _clearSearch,
            child: const Text('Aramayı Temizle'),
          ),
        ],
      ),
    );
  }

  /// Build search results list
  Widget _buildSearchResults(List<Mail> mails, MailContext? context) {
    return RefreshIndicator(
      onRefresh: _refreshSearch,
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: mails.length + (context?.hasMore == true ? 1 : 0),
        itemBuilder: (context, index) {
          // Show loading indicator at bottom if loading more
          if (index >= mails.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final mail = mails[index];
          return MailItem(
            mail: mail,
            isSelected: false, // 🆕 Added required parameter
            onTap: () => _onMailTap(mail), // 🆕 Updated with navigation
            onArchive: () => _archiveMail(mail),
            onToggleStar: () => _toggleStar(mail),
            onToggleSelection: () =>
                {}, // 🆕 Added required parameter (empty for search)
            onToggleRead: () => _toggleRead(mail),
          );
        },
      ),
    );
  }

  // ========== SEARCH ACTIONS ==========

  /// Refresh search results
  Future<void> _refreshSearch() async {
    final currentQuery = _searchController.text.trim();
    if (currentQuery.isNotEmpty) {
      await ref
          .read(mailProvider.notifier)
          .refreshCurrentFolder(userEmail: widget.userEmail);
      // Re-perform search with current query
      _performSearch(currentQuery);
    }
  }

  /// ✅ SIMPLIFIED: Perform search (no local loading)
  void _performSearch(String query) {
    if (query.trim().isEmpty) return;

    print('🚀 LOCAL: _performSearch başladı: "$query"');

    // ✅ Sadece provider method'unu çağır (provider hemen loading set edecek)
    ref
        .read(mailProvider.notifier)
        .searchInCurrentFolder(
          query: query.trim(),
          userEmail: widget.userEmail,
        );

    print('✅ LOCAL: _performSearch çağrısı yapıldı');
  }

  /// ✅ SIMPLIFIED: Clear search (no local loading)
  void _clearSearch() {
    print('🧹 _clearSearch başladı');

    // Search'i temizle
    _searchController.clear();
    ref.read(mailProvider.notifier).exitSearch();
    _searchFocusNode.requestFocus();

    print('✅ _clearSearch bitti');
  }

  // ========== MAIL ACTIONS ==========

  /// 🆕 Mail tıklama - Navigation to Mail Detail (adapted from mail_page_mobile.dart)
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

  /// Archive mail
  void _archiveMail(Mail mail) {
    ref.read(mailProvider.notifier).optimisticRemoveFromCurrentContext(mail.id);
    _showSnackBar('${mail.senderName} arşivlendi', color: Colors.green);

    // Background API call
    ref
        .read(mailProvider.notifier)
        .archiveMailApiOnly(mail.id, widget.userEmail)
        .catchError((error) {
          _showSnackBar('Arşivleme başarısız', color: Colors.red);
        });
  }

  /// Toggle star
  void _toggleStar(Mail mail) {
    if (mail.isStarred) {
      ref.read(mailProvider.notifier).unstarMail(mail.id, widget.userEmail);
      _showSnackBar('Yıldız kaldırıldı');
    } else {
      ref.read(mailProvider.notifier).starMail(mail.id, widget.userEmail);
      _showSnackBar('Yıldızlandı ⭐');
    }
  }

  /// Toggle read
  void _toggleRead(Mail mail) {
    if (mail.isRead) {
      ref.read(mailProvider.notifier).markAsUnread(mail.id, widget.userEmail);
      _showSnackBar('Okunmadı olarak işaretlendi');
    } else {
      ref.read(mailProvider.notifier).markAsRead(mail.id, widget.userEmail);
      _showSnackBar('Okundu olarak işaretlendi');
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
