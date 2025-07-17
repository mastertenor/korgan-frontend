// lib/src/features/mail/presentation/widgets/preview/pdf_preview_widget.dart

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import '../../../../../../utils/app_logger.dart';

/// Professional PDF preview widget
///
/// Features:
/// - Page navigation with controls
/// - Page indicator (current/total)
/// - Loading and error states
/// - Smooth page transitions
/// - Landscape/portrait support
/// - Based on original flutter_pdfview API
class PdfPreviewWidget extends StatefulWidget {
  /// PDF file to preview
  final File file;

  /// Optional filename for context
  final String? filename;

  const PdfPreviewWidget({super.key, required this.file, this.filename});

  @override
  State<PdfPreviewWidget> createState() => _PdfPreviewWidgetState();
}

class _PdfPreviewWidgetState extends State<PdfPreviewWidget> {
  // ========== ORIGINAL API PATTERN ==========
  final Completer<PDFViewController> _controller =
      Completer<PDFViewController>();

  // PDF state (using original API pattern)
  int? pages = 0;
  int? currentPage = 0;
  bool isReady = false;
  String errorMessage = '';

  // UI state
  bool _showControls = true;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleControls,
      child: Stack(
        children: [
          // ========== ORIGINAL PDFView IMPLEMENTATION ==========
          PDFView(
            filePath: widget.file.path,
            enableSwipe: true,
            swipeHorizontal: false, // Vertical scrolling like original
            autoSpacing: false,
            pageFling: true,
            pageSnap: true,
            defaultPage: currentPage!,
            fitPolicy: FitPolicy.BOTH,
            preventLinkNavigation: false,
            onRender: (pagesCount) {
              setState(() {
                pages = pagesCount;
                isReady = true;
              });
              AppLogger.info('✅ PDF rendered: $pagesCount pages');

              // Auto-hide controls after 3 seconds
              _autoHideControls();
            },
            onError: (error) {
              setState(() {
                errorMessage = error.toString();
              });
              AppLogger.error('❌ PDF error: $error');
            },
            onPageError: (page, error) {
              setState(() {
                errorMessage = '$page: ${error.toString()}';
              });
              AppLogger.error('❌ PDF page error on $page: $error');
            },
            onViewCreated: (PDFViewController pdfViewController) {
              _controller.complete(pdfViewController);
              AppLogger.debug('📄 PDF view controller created');
            },
            onLinkHandler: (String? uri) {
              AppLogger.debug('🔗 PDF link clicked: $uri');
            },
            onPageChanged: (int? page, int? total) {
              setState(() {
                currentPage = page;
              });
              AppLogger.debug('📄 Page changed: ${(page ?? 0) + 1}/$total');

              // Show controls briefly on page change
              _showControlsBriefly();
            },
          ),

          // Top controls overlay
          if (_showControls) _buildTopControls(),

          // Bottom controls overlay
          if (_showControls && isReady) _buildBottomControls(),

          // Loading overlay
          if (errorMessage.isEmpty && !isReady) _buildLoadingOverlay(),

          // Error overlay
          if (errorMessage.isNotEmpty) _buildErrorOverlay(),
        ],
      ),
    );
  }

  /// Build loading overlay
  Widget _buildLoadingOverlay() {
    final theme = Theme.of(context);

    return Container(
      color: theme.scaffoldBackgroundColor,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              'PDF yükleniyor...',
              style: TextStyle(color: theme.textTheme.bodyMedium?.color),
            ),
            if (widget.filename != null) ...[
              const SizedBox(height: 8),
              Text(
                widget.filename!,
                style: TextStyle(
                  color: theme.textTheme.bodySmall?.color,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Build error overlay
  Widget _buildErrorOverlay() {
    final theme = Theme.of(context);

    return Container(
      color: theme.scaffoldBackgroundColor,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.picture_as_pdf,
                size: 64,
                color: Colors.red.withOpacity(0.7),
              ),
              const SizedBox(height: 16),
              Text(
                'PDF yüklenemedi',
                style: TextStyle(
                  color: theme.textTheme.headlineSmall?.color,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                errorMessage,
                style: TextStyle(
                  color: theme.textTheme.bodyMedium?.color,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        errorMessage = '';
                        isReady = false;
                      });
                      // File will be re-rendered automatically
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Tekrar Dene'),
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton.icon(
                    onPressed: _openWithExternalApp,
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Harici Aç'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build top controls overlay
  Widget _buildTopControls() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black.withOpacity(0.7), Colors.transparent],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                // Page indicator
                if (pages != null && pages! > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${(currentPage ?? 0) + 1} / $pages',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                const Spacer(),

                // PDF info button
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: IconButton(
                    onPressed: _showPdfInfo,
                    icon: const Icon(Icons.info_outline, color: Colors.white),
                    tooltip: 'PDF Bilgileri',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build bottom controls overlay
  Widget _buildBottomControls() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Colors.black.withOpacity(0.7), Colors.transparent],
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // First page
                _buildControlButton(
                  icon: Icons.first_page,
                  label: 'İlk',
                  onPressed: (currentPage ?? 0) > 0 ? _goToFirstPage : null,
                ),

                // Previous page
                _buildControlButton(
                  icon: Icons.navigate_before,
                  label: 'Önceki',
                  onPressed: (currentPage ?? 0) > 0 ? _previousPage : null,
                ),

                // Go to page
                _buildControlButton(
                  icon: Icons.list,
                  label: 'Sayfa',
                  onPressed: _showPageSelector,
                ),

                // Next page
                _buildControlButton(
                  icon: Icons.navigate_next,
                  label: 'Sonraki',
                  onPressed: (currentPage ?? 0) < (pages ?? 0) - 1
                      ? _nextPage
                      : null,
                ),

                // Last page
                _buildControlButton(
                  icon: Icons.last_page,
                  label: 'Son',
                  onPressed: (currentPage ?? 0) < (pages ?? 0) - 1
                      ? _goToLastPage
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build control button
  Widget _buildControlButton({
    required IconData icon,
    required String label,
    VoidCallback? onPressed,
  }) {
    final isEnabled = onPressed != null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.6),
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            onPressed: onPressed,
            icon: Icon(icon, color: isEnabled ? Colors.white : Colors.white54),
            tooltip: label,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isEnabled ? Colors.white : Colors.white54,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  // ========== CONTROL ACTIONS ==========

  /// Toggle controls visibility
  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    HapticFeedback.lightImpact();
  }

  /// Auto-hide controls after delay
  void _autoHideControls() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _showControls) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  /// Show controls briefly
  void _showControlsBriefly() {
    if (!_showControls) {
      setState(() {
        _showControls = true;
      });

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _showControls = false;
          });
        }
      });
    }
  }

  /// Go to first page
  void _goToFirstPage() async {
    final controller = await _controller.future;
    await controller.setPage(0);
    HapticFeedback.lightImpact();
  }

  /// Go to previous page
  void _previousPage() async {
    final controller = await _controller.future;
    final targetPage = (currentPage ?? 0) - 1;
    if (targetPage >= 0) {
      await controller.setPage(targetPage);
      HapticFeedback.lightImpact();
    }
  }

  /// Go to next page
  void _nextPage() async {
    final controller = await _controller.future;
    final targetPage = (currentPage ?? 0) + 1;
    if (targetPage < (pages ?? 0)) {
      await controller.setPage(targetPage);
      HapticFeedback.lightImpact();
    }
  }

  /// Go to last page
  void _goToLastPage() async {
    final controller = await _controller.future;
    await controller.setPage((pages ?? 1) - 1);
    HapticFeedback.lightImpact();
  }

  /// Show page selector dialog
  void _showPageSelector() {
    final theme = Theme.of(context);
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Sayfaya Git',
          style: TextStyle(color: theme.textTheme.titleLarge?.color),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Toplam $pages sayfa',
              style: TextStyle(color: theme.textTheme.bodyMedium?.color),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Sayfa numarası (1-$pages)',
                hintText: 'Örn: ${((currentPage ?? 0) + 1)}',
                border: const OutlineInputBorder(),
              ),
              onSubmitted: (value) => _goToPageFromInput(value),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => _goToPageFromInput(controller.text),
            child: const Text('Git'),
          ),
        ],
      ),
    );
  }

  /// Go to page from text input
  void _goToPageFromInput(String pageText) async {
    final page = int.tryParse(pageText);
    if (page != null && page >= 1 && page <= (pages ?? 0)) {
      final controller = await _controller.future;
      await controller.setPage(page - 1); // Convert to 0-indexed
      Navigator.pop(context);
      HapticFeedback.lightImpact();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Geçersiz sayfa numarası: $pageText'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Show PDF information dialog
  void _showPdfInfo() {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'PDF Bilgileri',
          style: TextStyle(color: theme.textTheme.titleLarge?.color),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.filename != null) ...[
              Text(
                'Dosya Adı:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
              Text(
                widget.filename!,
                style: TextStyle(color: theme.textTheme.bodyMedium?.color),
              ),
              const SizedBox(height: 12),
            ],
            Text(
              'Toplam Sayfa:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
            Text(
              '$pages sayfa',
              style: TextStyle(color: theme.textTheme.bodyMedium?.color),
            ),
            const SizedBox(height: 12),
            Text(
              'Şu Anki Sayfa:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
            Text(
              '${(currentPage ?? 0) + 1}. sayfa',
              style: TextStyle(color: theme.textTheme.bodyMedium?.color),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  /// Open with external app
  void _openWithExternalApp() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🔗 Harici uygulama özelliği Phase 3\'te!'),
        backgroundColor: Colors.orange,
      ),
    );
  }
}
