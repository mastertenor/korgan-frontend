// lib/src/features/mail/presentation/widgets/web/toolbar/pagination/mail_pagination_web.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../providers/mail_providers.dart';

/// Simple web mail pagination component
/// Displays format: "< 1-50 arası >"
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

    // Don't show if no data
    if (pageRange.start == 1 && pageRange.end == 0) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Left arrow
        IconButton(
          onPressed: (canGoPrevious && !isLoading) ? () => _goToPreviousPage(ref) : null,
          icon: const Icon(Icons.chevron_left),
          iconSize: 20,
          splashRadius: 16,
        ),
        
        const SizedBox(width: 8),
        
        // Page info
        Text(
          isLoading 
              ? 'Yükleniyor...'
              : (pageRange.start == pageRange.end 
                  ? '${pageRange.start}'
                  : '${pageRange.start}-${pageRange.end} arası'),
          style: const TextStyle(fontSize: 13),
        ),
        
        const SizedBox(width: 8),
        
        // Right arrow
        IconButton(
          onPressed: (canGoNext && !isLoading) ? () => _goToNextPage(ref) : null,
          icon: const Icon(Icons.chevron_right),
          iconSize: 20,
          splashRadius: 16,
        ),
      ],
    );
  }

  void _goToPreviousPage(WidgetRef ref) async {
    try {
      await ref.read(mailProvider.notifier).goToPreviousPage(
        userEmail: userEmail,
      );
    } catch (e) {
      debugPrint('❌ Previous page failed: $e');
    }
  }

  void _goToNextPage(WidgetRef ref) async {
    try {
      await ref.read(mailProvider.notifier).goToNextPage(
        userEmail: userEmail,
      );
    } catch (e) {
      debugPrint('❌ Next page failed: $e');
    }
  }
}