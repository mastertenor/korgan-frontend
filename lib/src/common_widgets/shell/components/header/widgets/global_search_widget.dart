// lib/src/common_widgets/shell/components/header/widgets/global_search_widget.dart

import 'package:flutter/material.dart';

/// Global search widget for web header
/// 
/// Features:
/// - Gmail-style search box design
/// - Placeholder text "Postalarda arama yap"
/// - Search icon on left
/// - Clear icon on right when text is entered
/// - Enter key and search icon click support (functionality will be added later)
/// 
/// States:
/// - Empty: [🔍] "Postalarda arama yap"
/// - Active: [🔍] "user input" [❌]
class GlobalSearchWidget extends StatefulWidget {
  /// Callback when search is performed (Enter key or search icon)
  final Function(String)? onSearch;
  
  /// Callback when search is cleared
  final VoidCallback? onClear;
  
  /// Current search query (for external state control)
  final String? initialQuery;

  const GlobalSearchWidget({
    super.key,
    this.onSearch,
    this.onClear,
    this.initialQuery,
  });

  @override
  State<GlobalSearchWidget> createState() => _GlobalSearchWidgetState();
}

class _GlobalSearchWidgetState extends State<GlobalSearchWidget> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _isHovered = false;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery ?? '');
    _focusNode = FocusNode();
    
    // Listen to focus changes
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void didUpdateWidget(GlobalSearchWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Update controller if external query changes
    if (widget.initialQuery != oldWidget.initialQuery) {
      _controller.text = widget.initialQuery ?? '';
    }
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
      width: 600, // Fixed width like Gmail
      height: 48,  // Compact height for header
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

  /// Search box decoration with hover and focus states
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
      borderRadius: BorderRadius.circular(24), // Rounded like Gmail
      border: Border.all(color: borderColor, width: 1),
      boxShadow: _isFocused ? [
        BoxShadow(
          color: Colors.blue.withOpacity(0.1),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ] : null,
    );
  }

  /// Search icon on the left
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

  /// Main text field
  Widget _buildTextField() {
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      decoration: InputDecoration(
        hintText: 'Postalarda arama yap',
        hintStyle: TextStyle(
          color: Colors.grey[500],
          fontSize: 16,
        ),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
      ),
      style: const TextStyle(
        fontSize: 16,
        color: Colors.black87,
      ),
      onSubmitted: _onSubmitted,
      onChanged: (value) {
        setState(() {}); // Rebuild to show/hide clear icon
      },
      textInputAction: TextInputAction.search,
    );
  }

  /// Clear icon on the right (shown when text is not empty)
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
        child: Icon(
          Icons.close,
          color: Colors.grey[600],
          size: 18,
        ),
      ),
    );
  }

  // ========== EVENT HANDLERS ==========

  /// Handle search icon tap
  void _performSearch() {
    final query = _controller.text.trim();
    if (query.isNotEmpty) {
      widget.onSearch?.call(query);
      _focusNode.unfocus(); // Hide keyboard/lose focus
    }
  }

  /// Handle enter key press
  void _onSubmitted(String value) {
    final query = value.trim();
    if (query.isNotEmpty) {
      widget.onSearch?.call(query);
    }
  }

  /// Handle clear icon tap
  void _clearSearch() {
    _controller.clear();
    setState(() {}); // Rebuild to hide clear icon
    widget.onClear?.call();
    _focusNode.unfocus(); // Lose focus
  }
}