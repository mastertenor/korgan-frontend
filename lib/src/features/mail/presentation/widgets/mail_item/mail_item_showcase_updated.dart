// lib/src/features/mail/presentation/widgets/mail_item/mail_item_showcase_updated.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/mail.dart';
import '../../providers/mail_provider.dart';
import '../../providers/mail_providers.dart';
import '../../../../../utils/platform_helper.dart';
import '../../../../../core/network/api_endpoints.dart';
import 'mail_item.dart';

void main() {
  runApp(ProviderScope(child: MailItemShowcaseApp()));
}

/// Showcase app for demonstrating mail item widget with state management
/// 🆕 Enhanced with Gmail API filtering support - INBOX filtering enabled
class MailItemShowcaseApp extends StatelessWidget {
  const MailItemShowcaseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gmail Mobile with INBOX Filter - ${PlatformHelper.platformName}',
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

/// Main showcase widget with Gmail mobile pagination and INBOX filtering
/// 🆕 Now using INBOX label filtering instead of email-based filtering
class MailItemShowcase extends ConsumerStatefulWidget {
  const MailItemShowcase({super.key});

  @override
  ConsumerState<MailItemShowcase> createState() => _MailItemShowcaseState();
}

class _MailItemShowcaseState extends ConsumerState<MailItemShowcase> {
  // 🆕 Using userEmail for queue tracking instead of specific email filtering
  final String userEmail = 'berk@argenteknoloji.com';
  Set<int> selectedMailIndices = {};
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    // 🆕 Initial load with INBOX filtering when widget initializes
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

  /// Handle scroll for infinite loading (Gmail mobile style)
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      // When near bottom, load more with current filters
      _loadMoreInboxMails();
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
            // 🆕 Updated title to show INBOX filtering
            const Text('Gmail Mobile - INBOX'),
            Text(
              'Mails: ${mailState.mails.length} | Unread: $unreadCount${hasMore ? ' | +' : ''} | ${mailState.filterDescription}',
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
          // 🆕 Filter toggle button
          PopupMenuButton<String>(
            icon: Icon(
              mailState.isFiltered ? Icons.filter_alt : Icons.filter_alt_off,
              color: mailState.isFiltered ? Colors.yellow : Colors.white,
            ),
            tooltip: 'Filter Options',
            onSelected: (value) => _onFilterSelected(value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'inbox',
                child: Row(
                  children: [
                    Icon(Icons.inbox, size: 20),
                    SizedBox(width: 8),
                    Text('INBOX Only'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'unread_inbox',
                child: Row(
                  children: [
                    Icon(Icons.mark_email_unread, size: 20),
                    SizedBox(width: 8),
                    Text('Unread in INBOX'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'starred',
                child: Row(
                  children: [
                    Icon(Icons.star, size: 20, color: Colors.amber),
                    SizedBox(width: 8),
                    Text('Starred'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'important',
                child: Row(
                  children: [
                    Icon(Icons.label_important, size: 20, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('Important'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'attachments',
                child: Row(
                  children: [
                    Icon(Icons.attach_file, size: 20),
                    SizedBox(width: 8),
                    Text('With Attachments'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.clear_all, size: 20),
                    SizedBox(width: 8),
                    Text('Clear Filters'),
                  ],
                ),
              ),
            ],
          ),

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
            onPressed: isLoading ? null : () => _refreshCurrentFilter(),
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

          // 🆕 Filter info banner
          if (mailState.isFiltered)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.blue.withOpacity(0.1),
              child: Row(
                children: [
                  const Icon(Icons.filter_alt, color: Colors.blue, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Active Filter: ${mailState.filterDescription}',
                      style: const TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => _clearFilters(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: const Text('Clear', style: TextStyle(fontSize: 12)),
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

      // 🆕 Floating Action Button for quick filters
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showQuickFilterDialog(),
        tooltip: 'Quick Filters',
        child: const Icon(Icons.tune),
      ),
    );
  }

  /// 🆕 Handle filter selection from popup menu
  void _onFilterSelected(String filterType) {
    switch (filterType) {
      case 'inbox':
        _loadInboxMails(refresh: true);
        break;
      case 'unread_inbox':
        _loadUnreadInboxMails(refresh: true);
        break;
      case 'starred':
        _loadStarredMails(refresh: true);
        break;
      case 'important':
        _loadImportantMails(refresh: true);
        break;
      case 'attachments':
        _searchMailsWithAttachments(refresh: true);
        break;
      case 'clear':
        _clearFilters();
        break;
    }
  }

  /// 🆕 Show quick filter dialog with more options
  void _showQuickFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gmail Filters'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Quick Gmail Query Examples:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildFilterOption(
              'Recent unread with attachments',
              'is:unread has:attachment newer:7d',
            ),
            _buildFilterOption('Large emails (>5MB)', 'larger:5M'),
            _buildFilterOption(
              'From GitHub notifications',
              'from:notifications@github.com',
            ),
            _buildFilterOption(
              'Important and starred',
              'is:important is:starred',
            ),
            _buildFilterOption(
              'Last 30 days, not spam/trash',
              'newer:30d -in:spam -in:trash',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// 🆕 Build filter option widget for dialog
  Widget _buildFilterOption(String title, String query) {
    return ListTile(
      title: Text(title, style: const TextStyle(fontSize: 14)),
      subtitle: Text(
        query,
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
      onTap: () {
        Navigator.of(context).pop();
        _searchMailsWithQuery(query, refresh: true);
      },
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
            Text('Loading INBOX emails...'), // 🆕 Updated loading message
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
            Text(
              // 🆕 Dynamic empty message based on filter
              mailState.isFiltered
                  ? 'No emails found for current filter'
                  : 'No emails in INBOX',
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              'Filter: ${mailState.filterDescription}',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _refreshCurrentFilter(),
              child: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    // Mail list with RefreshIndicator
    return RefreshIndicator(
      onRefresh: _refreshCurrentFilter,
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
                    Text(
                      'Loading more emails...',
                    ), // 🆕 Updated loading message
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
              child: Center(
                child: Text(
                  // 🆕 Dynamic end message based on filter
                  mailState.isFiltered
                      ? 'All filtered emails loaded'
                      : 'All INBOX emails loaded',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
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
                      'Move to Trash',
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

  // ========== 🆕 ENHANCED FILTERING METHODS ==========

  /// Load INBOX mails only (using new filtering API)
  Future<void> _loadInboxMails({bool refresh = true}) async {
    if (refresh) {
      await ref
          .read(mailProvider.notifier)
          .loadInboxMails(userEmail: userEmail, maxResults: 20, refresh: true);
    } else {
      await ref
          .read(mailProvider.notifier)
          .loadInboxMails(userEmail: userEmail, maxResults: 20, refresh: false);
    }
  }

  /// Load more INBOX mails with current filters
  Future<void> _loadMoreInboxMails() async {
    await ref
        .read(mailProvider.notifier)
        .loadMoreMailsWithFilters(userEmail: userEmail, maxResults: 20);
  }

  /// Load unread mails in INBOX
  Future<void> _loadUnreadInboxMails({bool refresh = true}) async {
    await ref
        .read(mailProvider.notifier)
        .loadUnreadInboxMails(
          userEmail: userEmail,
          maxResults: 20,
          refresh: refresh,
        );
  }

  /// Load starred mails
  Future<void> _loadStarredMails({bool refresh = true}) async {
    await ref
        .read(mailProvider.notifier)
        .loadStarredMails(
          userEmail: userEmail,
          maxResults: 20,
          refresh: refresh,
        );
  }

  /// Load important mails using custom query
  Future<void> _loadImportantMails({bool refresh = true}) async {
    await ref
        .read(mailProvider.notifier)
        .searchMails(
          query: GmailQueries.important,
          userEmail: userEmail,
          maxResults: 20,
          refresh: refresh,
        );
  }

  /// Search mails with attachments
  Future<void> _searchMailsWithAttachments({bool refresh = true}) async {
    await ref
        .read(mailProvider.notifier)
        .searchMails(
          query: GmailQueries.hasAttachment,
          userEmail: userEmail,
          maxResults: 20,
          refresh: refresh,
        );
  }

  /// Search mails with custom query
  Future<void> _searchMailsWithQuery(
    String query, {
    bool refresh = true,
  }) async {
    await ref
        .read(mailProvider.notifier)
        .searchMails(
          query: query,
          userEmail: userEmail,
          maxResults: 20,
          refresh: refresh,
        );
  }

  /// Clear all filters and show all mails
  Future<void> _clearFilters() async {
    await ref
        .read(mailProvider.notifier)
        .clearFiltersAndRefresh(userEmail: userEmail, maxResults: 20);
  }

  /// Refresh with current filter
  Future<void> _refreshCurrentFilter() async {
    final currentState = ref.read(mailProvider);

    if (currentState.currentQuery != null) {
      await _searchMailsWithQuery(currentState.currentQuery!, refresh: true);
    } else if (currentState.currentLabels != null) {
      if (currentState.currentLabels!.contains(ApiEndpoints.labelInbox) &&
          currentState.currentLabels!.contains(ApiEndpoints.labelUnread)) {
        await _loadUnreadInboxMails(refresh: true);
      } else if (currentState.currentLabels!.contains(
        ApiEndpoints.labelStarred,
      )) {
        await _loadStarredMails(refresh: true);
      } else if (currentState.currentLabels!.contains(
        ApiEndpoints.labelInbox,
      )) {
        await _loadInboxMails(refresh: true);
      } else {
        await _loadInboxMails(refresh: true); // Default fallback
      }
    } else {
      await _loadInboxMails(refresh: true); // Default to INBOX
    }
  }

  // ========== ORIGINAL MAIL INTERACTION METHODS (UNCHANGED) ==========

  /// Handle mail tap
  void _onMailTap(Mail mail, int index) {
    if (!mail.isRead) {
      _toggleRead(mail);
    }
    _showSnackBar('${mail.senderName} mail opened');
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
    _showSnackBar('All emails selected');
  }

  /// Clear selection
  void _clearSelection() {
    setState(() {
      selectedMailIndices.clear();
    });
    _showSnackBar('Selection cleared');
  }

  /// Archive mail
  void _archiveMail(Mail mail, int index) async {
    await ref.read(mailProvider.notifier).archiveMail(mail.id, userEmail);

    // Update selection indices
    _updateSelectionAfterRemoval(index);
    _showSnackBar('${mail.senderName} archived', color: Colors.green);
  }

  /// Move mail to trash
  void _moveToTrash(Mail mail, int index) async {
    await ref.read(mailProvider.notifier).moveToTrash(mail.id, userEmail);

    // Update selection indices
    _updateSelectionAfterRemoval(index);
    _showSnackBar('${mail.senderName} moved to trash', color: Colors.orange);
  }

  /// Toggle star status
  void _toggleStar(Mail mail) async {
    if (mail.isStarred) {
      await ref.read(mailProvider.notifier).unstarMail(mail.id, userEmail);
      _showSnackBar('${mail.senderName} unstarred');
    } else {
      await ref.read(mailProvider.notifier).starMail(mail.id, userEmail);
      _showSnackBar('${mail.senderName} starred ⭐');
    }
  }

  /// Toggle read status
  void _toggleRead(Mail mail) async {
    if (mail.isRead) {
      await ref.read(mailProvider.notifier).markAsUnread(mail.id, userEmail);
      _showSnackBar('${mail.senderName} marked as unread');
    } else {
      await ref.read(mailProvider.notifier).markAsRead(mail.id, userEmail);
      _showSnackBar('${mail.senderName} marked as read');
    }
  }

  /// Move selected mails to trash
  void _moveSelectedToTrash() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Move Selected Emails to Trash'),
        content: Text(
          'Are you sure you want to move ${selectedMailIndices.length} emails to trash?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _performBulkMoveToTrash();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: const Text('Move to Trash'),
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

    _showSnackBar('$selectedCount emails moved to trash', color: Colors.orange);
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

/*
🆕 Gmail API Filtering Usage Examples

1. INBOX Label Filtering:
   - labels: ['INBOX'] 
   - Fetches only emails in INBOX folder

2. Unread INBOX Filtering:
   - labels: ['INBOX', 'UNREAD']
   - Fetches only unread emails in INBOX

3. Starred Emails:
   - labels: ['STARRED']
   - Fetches only starred emails

4. Custom Gmail Queries:
   - query: 'is:unread has:attachment'
   - query: 'from:notifications@github.com'
   - query: 'subject:Invoice'
   - query: 'newer:7d larger:5M'
   - query: 'label:INBOX is:unread has:attachment'

5. Combined Filtering Examples:
   - query: 'label:INBOX is:unread from:amazon.com'
   - query: 'is:important is:starred newer:30d'
   - query: 'has:attachment larger:10M -in:spam'

6. Date-based Filtering:
   - query: 'newer:7d' (last 7 days)
   - query: 'older:1w' (older than 1 week)
   - query: 'after:2024/1/1 before:2024/12/31'

7. Size-based Filtering:
   - query: 'larger:10M' (larger than 10MB)
   - query: 'smaller:1M' (smaller than 1MB)

8. Content-based Filtering:
   - query: 'has:attachment' (emails with attachments)
   - query: 'has:drive' (emails with Google Drive links)
   - query: 'filename:pdf' (emails with PDF attachments)

9. Sender/Recipient Filtering:
   - query: 'from:boss@company.com'
   - query: 'to:me@example.com'
   - query: 'from:(-notifications)'

10. Advanced Combinations:
    - query: 'label:INBOX is:unread has:attachment larger:5M newer:7d'
    - query: 'from:github.com OR from:gitlab.com'
    - query: '(subject:Invoice OR subject:Receipt) has:attachment'

Note: When using query parameter, it overrides other filters like labels.
The backend API handles all Gmail query syntax as documented in Gmail search operators.
*/
