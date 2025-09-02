// lib/src/features/mail/presentation/widgets/web/toolbar/pagination/mail_pagination_web.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../providers/mail_providers.dart';
import '../../../../providers/global_search_provider.dart'; // 🆕 SEARCH STATE IMPORT

/// Simple web mail pagination component
/// Displays format: "2408 satırdan 1-50 arası < >"
class MailPaginationWeb extends ConsumerWidget {
  final String userEmail;
  final EdgeInsetsGeometry? padding;
  final double height;
  final Color? backgroundColor;

  const MailPaginationWeb({
    super.key,
    required this.userEmail,
    this.padding,
    this.height = 32.0,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canGoNext = ref.watch(canGoNextPageProvider);
    final canGoPrevious = ref.watch(canGoPreviousPageProvider);
    final isLoading = ref.watch(paginationLoadingProvider);
    final pageRange = ref.watch(pageRangeInfoProvider);

    // 🆕 Get total estimate from current context
    //final totalEstimate = ref.watch(currentContextProvider)?.totalEstimate ?? 0;

    // Don't show if no data
    if (pageRange.start == 1 && pageRange.end == 0) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 🆕 Page info - moved to left, outside of chevrons
        Text(
          isLoading
              ? 'Yükleniyor...'
              : _buildRangeDisplayText(pageRange),
          style: const TextStyle(fontSize: 13),
        ),

        const SizedBox(width: 8),

        // Left arrow
        IconButton(
          onPressed: (canGoPrevious && !isLoading)
              ? () => _goToPreviousPage(ref)
              : null,
          icon: const Icon(Icons.chevron_left),
          iconSize: 20,
          splashRadius: 16,
        ),

        // Right arrow - moved next to left arrow
        IconButton(
          onPressed: (canGoNext && !isLoading)
              ? () => _goToNextPage(ref)
              : null,
          icon: const Icon(Icons.chevron_right),
          iconSize: 20,
          splashRadius: 16,
        ),
      ],
    );
  }

  /// 🆕 Build range display text with total estimate
  /// Format: "2408 satırdan 1-50 arası" or just "2408 satırdan 15" for single item
  String _buildRangeDisplayText(
    ({int start, int end}) pageRange,
  ) {
    final totalText = ' Çok sayıda e-posta / ';

    if (pageRange.start == pageRange.end) {
      return '$totalText${pageRange.start}';
    }

    return '$totalText${pageRange.start}-${pageRange.end} arası';
  }

  void _goToPreviousPage(WidgetRef ref) async {
    try {
      // 🆕 CHECK IF IN SEARCH MODE
      final isSearchMode = ref.read(globalSearchModeProvider);

      if (isSearchMode) {
        // Use search-aware pagination with highlight
        await ref
            .read(mailProvider.notifier)
            .goToPreviousPageWithHighlight(userEmail: userEmail);
      } else {
        // Use normal pagination
        await ref
            .read(mailProvider.notifier)
            .goToPreviousPage(userEmail: userEmail);
      }
    } catch (e) {
      debugPrint('❌ Previous page failed: $e');
    }
  }

  void _goToNextPage(WidgetRef ref) async {
    try {
      // 🆕 CHECK IF IN SEARCH MODE
      final isSearchMode = ref.read(globalSearchModeProvider);

      if (isSearchMode) {
        // Use search-aware pagination with highlight
        await ref
            .read(mailProvider.notifier)
            .goToNextPageWithHighlight(userEmail: userEmail);
      } else {
        // Use normal pagination
        await ref
            .read(mailProvider.notifier)
            .goToNextPage(userEmail: userEmail);
      }
    } catch (e) {
      debugPrint('❌ Next page failed: $e');
    }
  }
}
