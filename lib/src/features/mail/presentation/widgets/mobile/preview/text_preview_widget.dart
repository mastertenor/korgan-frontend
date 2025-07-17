// lib/src/features/mail/presentation/widgets/preview/text_preview_widget.dart

import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../../utils/app_logger.dart';

/// Text file preview widget
///
/// Displays text files with proper formatting and user interactions:
/// - Selectable text for copy/paste
/// - Scrollable content for large files
/// - Monospace font for code files
/// - Loading and error states
/// - Character encoding detection
class TextPreviewWidget extends StatefulWidget {
  /// File to preview
  final File file;

  /// Optional filename for context
  final String? filename;

  const TextPreviewWidget({super.key, required this.file, this.filename});

  @override
  State<TextPreviewWidget> createState() => _TextPreviewWidgetState();
}

class _TextPreviewWidgetState extends State<TextPreviewWidget> {
  String? _content;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isCodeFile = false;

  // Text styling options
  double _fontSize = 14.0;
  final double _minFontSize = 10.0;
  final double _maxFontSize = 24.0;

  @override
  void initState() {
    super.initState();
    _loadTextContent();
    _detectFileType();
  }

  /// Detect if this is a code file for appropriate styling
  void _detectFileType() {
    if (widget.filename != null) {
      final filename = widget.filename!.toLowerCase();
      _isCodeFile = _codeFileExtensions.any((ext) => filename.endsWith(ext));
    }
  }

  /// Load text content from file
  Future<void> _loadTextContent() async {
    try {
      AppLogger.info('📄 Loading text content from: ${widget.file.path}');

      // Check file size - warn for very large files
      final fileSize = await widget.file.length();
      if (fileSize > 1024 * 1024) {
        // 1MB
        AppLogger.warning('⚠️ Large text file: ${fileSize} bytes');
      }

      // Try different encodings
      String content = await _readFileWithEncoding();

      setState(() {
        _content = content;
        _isLoading = false;
      });

      AppLogger.info('✅ Text content loaded successfully');
    } catch (e) {
      AppLogger.error('❌ Failed to load text content: $e');

      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  /// Read file with proper encoding detection
  Future<String> _readFileWithEncoding() async {
    // Try UTF-8 first (most common)
    try {
      return await widget.file.readAsString(encoding: utf8);
    } catch (e) {
      AppLogger.debug('UTF-8 failed, trying latin1: $e');

      // Fallback to latin1 for older files
      try {
        return await widget.file.readAsString(encoding: latin1);
      } catch (e) {
        AppLogger.debug('latin1 failed, trying raw bytes: $e');

        // Last resort: read as bytes and convert
        final bytes = await widget.file.readAsBytes();
        return String.fromCharCodes(bytes);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    return _buildTextViewer();
  }

  /// Build loading state
  Widget _buildLoadingState() {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: theme.colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            'Metin yükleniyor...',
            style: TextStyle(color: theme.textTheme.bodyMedium?.color),
          ),
        ],
      ),
    );
  }

  /// Build error state
  Widget _buildErrorState() {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Metin yüklenemedi',
              style: TextStyle(
                color: theme.textTheme.headlineSmall?.color,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Bilinmeyen hata',
              style: TextStyle(
                color: theme.textTheme.bodyMedium?.color,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _errorMessage = null;
                });
                _loadTextContent();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Tekrar Dene'),
            ),
          ],
        ),
      ),
    );
  }

  /// Build main text viewer
  Widget _buildTextViewer() {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Text controls toolbar
        _buildToolbar(),

        // Main content area
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: SelectableText(
                _content ?? '',
                style: TextStyle(
                  fontFamily: _isCodeFile ? 'monospace' : null,
                  fontSize: _fontSize,
                  color: theme.textTheme.bodyLarge?.color,
                  height: 1.4, // Line height for readability
                ),
                // Enable text selection tools
                showCursor: true,
                cursorColor: theme.colorScheme.primary,
                toolbarOptions: const ToolbarOptions(
                  copy: true,
                  selectAll: true,
                ),
              ),
            ),
          ),
        ),

        // Content info bar
        _buildInfoBar(),
      ],
    );
  }

  /// Build toolbar with text controls
  Widget _buildToolbar() {
    final theme = Theme.of(context);

    return Container(
      color: theme.colorScheme.surface.withOpacity(0.3),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Font size controls
          IconButton(
            onPressed: _fontSize > _minFontSize ? _decreaseFontSize : null,
            icon: Icon(Icons.text_decrease, color: theme.iconTheme.color),
            tooltip: 'Yazı boyutunu küçült',
          ),

          Text(
            '${_fontSize.round()}',
            style: TextStyle(
              color: theme.textTheme.bodySmall?.color,
              fontSize: 12,
            ),
          ),

          IconButton(
            onPressed: _fontSize < _maxFontSize ? _increaseFontSize : null,
            icon: Icon(Icons.text_increase, color: theme.iconTheme.color),
            tooltip: 'Yazı boyutunu büyült',
          ),

          const Spacer(),

          // File type indicator
          if (_isCodeFile)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.blue.withOpacity(0.5)),
              ),
              child: const Text(
                'CODE',
                style: TextStyle(
                  color: Colors.blue,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Build info bar with content statistics
  Widget _buildInfoBar() {
    final theme = Theme.of(context);
    final lines = _content?.split('\n').length ?? 0;
    final chars = _content?.length ?? 0;
    final words = _content?.split(RegExp(r'\s+')).length ?? 0;

    return Container(
      color: theme.colorScheme.surface.withOpacity(0.3),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildStatItem('Satır', lines.toString()),
          const SizedBox(width: 16),
          _buildStatItem('Kelime', words.toString()),
          const SizedBox(width: 16),
          _buildStatItem('Karakter', chars.toString()),

          const Spacer(),

          // Copy all button
          TextButton.icon(
            onPressed: _copyAllText,
            icon: Icon(Icons.copy, size: 16, color: theme.iconTheme.color),
            label: Text(
              'Tümünü Kopyala',
              style: TextStyle(
                color: theme.textTheme.bodySmall?.color,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build individual stat item
  Widget _buildStatItem(String label, String value) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            color: theme.textTheme.bodyLarge?.color,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: theme.textTheme.bodySmall?.color,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  // ========== ACTION HANDLERS ==========

  /// Increase font size
  void _increaseFontSize() {
    if (_fontSize < _maxFontSize) {
      setState(() {
        _fontSize += 1.0;
      });
      HapticFeedback.lightImpact();
    }
  }

  /// Decrease font size
  void _decreaseFontSize() {
    if (_fontSize > _minFontSize) {
      setState(() {
        _fontSize -= 1.0;
      });
      HapticFeedback.lightImpact();
    }
  }

  /// Copy all text to clipboard
  void _copyAllText() {
    if (_content != null) {
      Clipboard.setData(ClipboardData(text: _content!));
      HapticFeedback.lightImpact();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📋 Tüm metin kopyalandı'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // ========== CONSTANTS ==========

  /// File extensions that should be treated as code
  static const Set<String> _codeFileExtensions = {
    '.dart',
    '.java',
    '.swift',
    '.kt',
    '.py',
    '.js',
    '.ts',
    '.cpp',
    '.c',
    '.h',
    '.cs',
    '.php',
    '.rb',
    '.go',
    '.rs',
    '.scala',
    '.clj',
    '.hs',
    '.ml',
    '.pl',
    '.sh',
    '.bash',
    '.zsh',
    '.fish',
    '.ps1',
    '.bat',
    '.cmd',
    '.vbs',
    '.html',
    '.htm',
    '.css',
    '.scss',
    '.sass',
    '.less',
    '.xml',
    '.json',
    '.yaml',
    '.yml',
    '.toml',
    '.ini',
    '.cfg',
    '.conf',
    '.properties',
    '.sql',
    '.md',
    '.markdown',
    '.tex',
    '.r',
    '.m',
    '.matlab',
  };
}
