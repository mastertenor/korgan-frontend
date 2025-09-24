// lib/src/common_widgets/shell/components/header/widgets/global_search_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../features/mail/presentation/providers/global_search_provider.dart';
import '../../../../../features/mail/presentation/providers/mail_tree_provider.dart';
import '../../../../../features/mail/presentation/providers/mail_context_provider.dart';
import '../../../../../utils/app_logger.dart';

/// Global search widget for web header - TreeNode aware
///
/// Simplified version that avoids state management conflicts.
/// The widget only reads providers when needed, not in build method.
class GlobalSearchWidget extends ConsumerStatefulWidget {
  final Function(String)? onSearch;
  final VoidCallback? onClear;

  const GlobalSearchWidget({super.key, this.onSearch, this.onClear});

  @override
  ConsumerState<GlobalSearchWidget> createState() => _GlobalSearchWidgetState();
}

class _GlobalSearchWidgetState extends ConsumerState<GlobalSearchWidget> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _isHovered = false;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();

    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 600,
      height: 48,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: Container(
          decoration: _buildSearchBoxDecoration(),
          child: Row(
            children: [
              _buildSearchIcon(),
              Expanded(child: _buildTextField()),
              if (_controller.text.isNotEmpty) _buildClearIcon(),
            ],
          ),
        ),
      ),
    );
  }

  BoxDecoration _buildSearchBoxDecoration() {
    Color borderColor;
    Color backgroundColor;

    if (_isFocused) {
      borderColor = Colors.blue[400]!;
      backgroundColor = Colors.white;
    } else if (_isHovered) {
      borderColor = Colors.grey[400]!;
      backgroundColor = Colors.grey[50]!;
    } else {
      borderColor = Colors.grey[300]!;
      backgroundColor = Colors.grey[50]!;
    }

    return BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: borderColor, width: 1),
      boxShadow: _isFocused
          ? [
              BoxShadow(
                color: Colors.blue.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ]
          : null,
    );
  }

  Widget _buildSearchIcon() {
    return GestureDetector(
      onTap: _performSearch,
      child: SizedBox(
        width: 40,
        height: 40,
        child: Icon(
          Icons.search,
          color: _isFocused ? Colors.blue[600] : Colors.grey[600],
          size: 20,
        ),
      ),
    );
  }

  Widget _buildTextField() {
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      decoration: InputDecoration(
        hintText: _getHintText(),
        hintStyle: TextStyle(color: Colors.grey[500], fontSize: 16),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
      ),
      style: const TextStyle(fontSize: 16, color: Colors.black87),
      onSubmitted: _onSubmitted,
      onChanged: (value) {
        setState(() {}); // Only rebuild to show/hide clear icon
      },
      textInputAction: TextInputAction.search,
    );
  }

  Widget _buildClearIcon() {
    return GestureDetector(
      onTap: _clearSearch,
      child: Container(
        width: 32,
        height: 32,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(Icons.close, color: Colors.grey[600], size: 18),
      ),
    );
  }

  // ========== HELPER METHODS ==========

  String _getHintText() {
    // Only read provider when needed, not in build
    final currentNode = ref.read(currentTreeNodeProvider);

    if (currentNode == null) {
      return 'Select a folder to search';
    } else {
      return 'Search in ${currentNode.title}';
    }
  }

  bool _canPerformSearch() {
    final currentNode = ref.read(currentTreeNodeProvider);
    final isLoading = ref.read(globalSearchLoadingProvider);
    return currentNode != null && !isLoading;
  }

  String? _getUserEmail() {
    final selectedContext = ref.read(selectedMailContextProvider);
    return selectedContext?.emailAddress;
  }

  // ========== EVENT HANDLERS ==========

  void _performSearch() {
    final query = _controller.text.trim();
    if (query.isEmpty) return;

    if (!_canPerformSearch()) {
      AppLogger.warning(
        'Cannot perform search - no TreeNode selected or loading',
      );
      return;
    }

    final currentNode = ref.read(currentTreeNodeProvider);
    final userEmail = _getUserEmail();

    if (currentNode == null) {
      AppLogger.error('No TreeNode selected for search');
      return;
    }

    if (userEmail == null || userEmail.isEmpty) {
      AppLogger.error('No user email available for search');
      return;
    }

    AppLogger.info('Performing search: "$query" in ${currentNode.title}');

    // Call TreeNode search through GlobalSearchController
    ref
        .read(globalSearchControllerProvider)
        .performNodeSearch(
          node: currentNode,
          query: query,
          userEmail: userEmail,
        );

    // Optional callback
    widget.onSearch?.call(query);

    _focusNode.unfocus();
  }

  void _onSubmitted(String value) {
    final query = value.trim();
    if (query.isNotEmpty) {
      _performSearch();
    }
  }

  void _clearSearch() {
    _controller.clear();
    setState(() {}); // Rebuild to hide clear icon

    // Clear search through GlobalSearchController
    ref.read(globalSearchControllerProvider).clearNodeSearch();

    // Optional callback
    widget.onClear?.call();

    _focusNode.unfocus();
  }
}
