// lib/src/features/mail/presentation/widgets/web/toolbar/mail_toolbar_web.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../utils/app_logger.dart';
import '../../../providers/mail_providers.dart';
import 'components/no_selection_toolbar.dart';
import 'components/selection_toolbar.dart';

/// Gmail-style web mail toolbar
/// 
/// This widget displays different toolbar content based on mail selection state:
/// - No selection: SelectAll checkbox + Refresh button
/// - Has selection: Delete button + selection info
/// 
/// The toolbar automatically adapts its content based on the current selection state.
class MailToolbarWeb extends ConsumerWidget {
  final String userEmail;
  final EdgeInsetsGeometry? padding;
  final double height;
  final Color? backgroundColor;

  const MailToolbarWeb({
    super.key,
    required this.userEmail,
    this.padding,
    this.height = 56.0,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch selection and mail state
    final hasSelection = ref.watch(hasSelectionProvider);
    final selectedCount = ref.watch(selectedMailCountProvider);
    final currentMails = ref.watch(currentMailsProvider);
    final isLoading = ref.watch(currentLoadingProvider);
    final currentFolder = ref.watch(currentFolderProvider);

    AppLogger.info('🔧 MailToolbarWeb: hasSelection=$hasSelection, '
                  'selectedCount=$selectedCount, mailCount=${currentMails.length}');

    return Container(
      height: height,
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.grey[50],
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade300,
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        children: [
          // Selection state-based content
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.0, -0.2),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: hasSelection
                  ? SelectionToolbar(
                      key: const ValueKey('selection_toolbar'),
                      userEmail: userEmail,
                      selectedCount: selectedCount,
                      isLoading: isLoading,
                    )
                  : NoSelectionToolbar(
                      key: const ValueKey('no_selection_toolbar'),
                      userEmail: userEmail,
                      totalMailCount: currentMails.length,
                      currentFolder: currentFolder,
                      isLoading: isLoading,
                    ),
            ),
          ),
        ],
      ),
    );
  }



}