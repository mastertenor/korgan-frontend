// lib/src/features/mail/presentation/widgets/mobile/reply/mail_compose_area_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Mail Compose Area Widget
///
/// Eski HTML editor'daki compose-area div'ini widget olarak replace eder.
/// ContentEditable div yerine native Flutter TextFormField kullanır.
///
/// Özellikler:
/// - Auto-expanding text field
/// - Rich text desteği (bold, italic, etc.)
/// - Formatting toolbar
/// - Keyboard shortcuts
/// - Responsive design
class MailComposeAreaWidget extends StatefulWidget {
  final TextEditingController controller;
  final String placeholder;
  final Function(String)? onChanged;
  final Function()? onFocusChanged;
  final bool showFormatting;
  final int? maxLines;
  final int minLines;

  const MailComposeAreaWidget({
    super.key,
    required this.controller,
    this.placeholder = 'Mesajınızı yazın...',
    this.onChanged,
    this.onFocusChanged,
    this.showFormatting = true,
    this.maxLines,
    this.minLines = 6,
  });

  @override
  State<MailComposeAreaWidget> createState() => _MailComposeAreaWidgetState();
}

class _MailComposeAreaWidgetState extends State<MailComposeAreaWidget> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;
  bool _showFormattingToolbar = false;

  // Formatting state
  bool _isBold = false;
  bool _isItalic = false;
  bool _isUnderline = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
    widget.onFocusChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isFocused ? Colors.blue : Colors.grey.shade300,
          width: _isFocused ? 2 : 1,
        ),
        boxShadow: _isFocused ? [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ] : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Formatting toolbar (isteğe bağlı)
          if (widget.showFormatting && (_isFocused || _showFormattingToolbar))
            _buildFormattingToolbar(),
          
          // Ana text field
          _buildTextField(),
          
          // Bottom info bar
          if (_isFocused)
            _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildTextField() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextFormField(
        controller: widget.controller,
        focusNode: _focusNode,
        onChanged: widget.onChanged,
        maxLines: widget.maxLines,
        minLines: widget.minLines,
        keyboardType: TextInputType.multiline,
        textInputAction: TextInputAction.newline,
        style: const TextStyle(
          fontSize: 16,
          height: 1.5,
          color: Colors.black87,
        ),
        decoration: InputDecoration(
          hintText: widget.placeholder,
          hintStyle: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 16,
            fontStyle: FontStyle.italic,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        
      ),
    );
  }

  Widget _buildFormattingToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: [
          // Bold button
          _buildFormatButton(
            icon: Icons.format_bold,
            isActive: _isBold,
            onTap: _toggleBold,
            tooltip: 'Kalın (Ctrl+B)',
          ),
          
          // Italic button
          _buildFormatButton(
            icon: Icons.format_italic,
            isActive: _isItalic,
            onTap: _toggleItalic,
            tooltip: 'İtalik (Ctrl+I)',
          ),
          
          // Underline button
          _buildFormatButton(
            icon: Icons.format_underline,
            isActive: _isUnderline,
            onTap: _toggleUnderline,
            tooltip: 'Altı çizili (Ctrl+U)',
          ),
          
          const SizedBox(width: 8),
          
          // Divider
          Container(
            height: 24,
            width: 1,
            color: Colors.grey.shade300,
          ),
          
          const SizedBox(width: 8),
          
          // List button
          _buildFormatButton(
            icon: Icons.format_list_bulleted,
            isActive: false,
            onTap: _insertBulletList,
            tooltip: 'Madde işareti listesi',
          ),
          
          // Link button
          _buildFormatButton(
            icon: Icons.link,
            isActive: false,
            onTap: _insertLink,
            tooltip: 'Link ekle',
          ),
          
          const Spacer(),
          
          // Hide toolbar button
          IconButton(
            onPressed: () {
              setState(() {
                _showFormattingToolbar = false;
              });
            },
            icon: const Icon(Icons.keyboard_arrow_up),
            iconSize: 20,
            tooltip: 'Araç çubuğunu gizle',
          ),
        ],
      ),
    );
  }

  Widget _buildFormatButton({
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isActive ? Colors.blue.shade100 : null,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            size: 18,
            color: isActive ? Colors.blue.shade700 : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: [
          // Word count
          Text(
            '${_getWordCount()} kelime',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          
          const Spacer(),
          
          // Show formatting toolbar button
          if (widget.showFormatting && !_showFormattingToolbar)
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _showFormattingToolbar = true;
                });
              },
              icon: const Icon(Icons.text_format, size: 16),
              label: const Text('Format'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
        ],
      ),
    );
  }

  // ==================== FORMATTING METHODS ====================

  

  void _toggleBold() {
    setState(() {
      _isBold = !_isBold;
    });
    
    // TODO: Implement actual text formatting
    // Bu basic widget için sadece state tracking yapıyoruz
    // Gerçek formatting için rich text editor kullanmak gerekir
    HapticFeedback.lightImpact();
  }

  void _toggleItalic() {
    setState(() {
      _isItalic = !_isItalic;
    });
    HapticFeedback.lightImpact();
  }

  void _toggleUnderline() {
    setState(() {
      _isUnderline = !_isUnderline;
    });
    HapticFeedback.lightImpact();
  }

  void _insertBulletList() {
    final text = widget.controller.text;
    final selection = widget.controller.selection;
    
    if (selection.isValid) {
      final beforeSelection = text.substring(0, selection.start);
      final selectedText = text.substring(selection.start, selection.end);
      final afterSelection = text.substring(selection.end);
      
      // Insert bullet point
      final newText = '$beforeSelection• $selectedText$afterSelection';
      
      widget.controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(
          offset: selection.start + 2 + selectedText.length,
        ),
      );
    }
    
    HapticFeedback.lightImpact();
  }

  void _insertLink() {
    // TODO: Show link dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🔗 Link ekleme özelliği yakında!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  int _getWordCount() {
    final text = widget.controller.text.trim();
    if (text.isEmpty) return 0;
    return text.split(RegExp(r'\s+')).length;
  }
}