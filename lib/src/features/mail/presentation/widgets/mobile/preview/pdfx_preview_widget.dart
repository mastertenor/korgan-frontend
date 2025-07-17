// lib/src/features/mail/presentation/widgets/preview/pdfx_preview_widget.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdfx/pdfx.dart';
import '../../../../../../utils/app_logger.dart';

/// Modern PDF preview widget using pdfx package
///
/// Features:
/// - Built-in zoom with pinch-to-zoom
/// - Smooth scrolling and rendering
/// - Text selection support
/// - Modern async/await API
/// - Better performance
/// - No platform view issues
class PdfxPreviewWidget extends StatefulWidget {
  /// PDF file to preview
  final File file;

  /// Optional filename for context
  final String? filename;

  const PdfxPreviewWidget({super.key, required this.file, this.filename});

  @override
  State<PdfxPreviewWidget> createState() => _PdfxPreviewWidgetState();
}

class _PdfxPreviewWidgetState extends State<PdfxPreviewWidget> {
  // ========== MODERN PDFX CONTROLLER ==========
  PdfControllerPinch? _pdfController;

  // PDF state
  bool _isLoading = true;
  String? _errorMessage;
  int _currentPage = 1;
  int _totalPages = 0;
  bool _isReady = false;

  // UI state
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _initializePdfController();
  }

  /// Initialize PDF controller with modern API
  Future<void> _initializePdfController() async {
    try {
      AppLogger.info('📄 Initializing pdfx controller: ${widget.file.path}');

      // Check file existence
      if (!await widget.file.exists()) {
        throw Exception('PDF file not found');
      }

      // ✅ FIXED: Create controller with Future<PdfDocument> directly
      _pdfController = PdfControllerPinch(
        document: PdfDocument.openFile(
          widget.file.path,
        ), // ✅ Pass Future<PdfDocument>
        initialPage: 1,
        viewportFraction: 1.0,
      );

      // ✅ FIXED: Get document from controller to get page count
      final document = await _pdfController!.document;
      _totalPages = document.pagesCount;

      setState(() {
        _isLoading = false;
        _isReady = true;
      });

      AppLogger.info('✅ PDF loaded successfully: $_totalPages pages');

      // Auto-hide controls after 3 seconds
      _autoHideControls();
    } catch (e) {
      AppLogger.error('❌ PDF initialization failed: $e');

      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _pdfController?.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant PdfxPreviewWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.file.path != oldWidget.file.path) {
      _pdfController?.dispose();
      _initializePdfController();
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

    return _buildPdfViewer();
  }

  /// Build loading state
  Widget _buildLoadingState() {
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

  /// Build error state
  Widget _buildErrorState() {
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
                _errorMessage ?? 'Bilinmeyen hata',
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
                        _isLoading = true;
                        _errorMessage = null;
                      });
                      _initializePdfController();
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

  /// Build main PDF viewer
  Widget _buildPdfViewer() {
    // ✅ FIXED: Null check before using controller
    if (_pdfController == null) {
      return _buildLoadingState();
    }

    return GestureDetector(
      onTap: _toggleControls,
      child: Stack(
        children: [
          // ========== MODERN PDFX PINCH VIEWER ==========
          PdfViewPinch(
            controller: _pdfController!,
            onPageChanged: (page) {
              setState(() {
                _currentPage = page;
              });
              AppLogger.debug('📄 Page changed: $page/$_totalPages');

              // Show controls briefly on page change
              _showControlsBriefly();
            },
            onDocumentLoaded: (document) {
              AppLogger.info(
                '📄 Document loaded: ${document.pagesCount} pages',
              );
              setState(() {
                _totalPages = document.pagesCount;
              });
            },
            onDocumentError: (error) {
              AppLogger.error('❌ Document error: $error');
              setState(() {
                _errorMessage = error.toString();
              });
            },

            // ========== PDFX PINCH FEATURES ==========
            scrollDirection: Axis.vertical,

            // Minimum and maximum zoom scales
            minScale: 0.5,
            maxScale: 4.0,

            // ✅ FIXED: padding is double, not EdgeInsets
            padding: 8.0, // 8 pixels padding around pages
            // Custom builders for loading states
            builders: PdfViewPinchBuilders<DefaultBuilderOptions>(
              options: const DefaultBuilderOptions(
                loaderSwitchDuration: Duration(milliseconds: 300),
              ),
              documentLoaderBuilder: (_) => Center(
                child: CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              pageLoaderBuilder: (_) => Center(
                child: CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              errorBuilder: (_, error) => Center(
                child: Text(
                  'Sayfa yüklenemedi: $error',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
              ),
            ),
          ),

          // Top controls overlay
          if (_showControls) _buildTopControls(),

          // Bottom controls overlay
          if (_showControls && _isReady) _buildBottomControls(),
        ],
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
                    '$_currentPage / $_totalPages',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                const Spacer(),

                // ✅ FIXED: Zoom info instead of controls (no programmatic zoom API)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.pinch, color: Colors.white, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          'Pinch-to-zoom',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 8),

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
                  onPressed: _currentPage > 1 ? _goToFirstPage : null,
                ),

                // Previous page
                _buildControlButton(
                  icon: Icons.navigate_before,
                  label: 'Önceki',
                  onPressed: _currentPage > 1 ? _previousPage : null,
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
                  onPressed: _currentPage < _totalPages ? _nextPage : null,
                ),

                // Last page
                _buildControlButton(
                  icon: Icons.last_page,
                  label: 'Son',
                  onPressed: _currentPage < _totalPages ? _goToLastPage : null,
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

  // ========== MODERN PDFX CONTROL ACTIONS ==========
  // Note: pdfx 2.9.2 PdfControllerPinch doesn't have zoom methods
  // Zoom is handled by PdfViewPinch widget via pinch gestures only

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
      // ✅ FIXED: Check if widget is still mounted before using setState
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
        // ✅ FIXED: Check if widget is still mounted before using setState
        if (mounted) {
          setState(() {
            _showControls = false;
          });
        }
      });
    }
  }

  /// Go to first page
  Future<void> _goToFirstPage() async {
    if (_pdfController != null) {
      await _pdfController!.animateToPage(
        pageNumber: 1, // ✅ FIXED: required parameter
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      HapticFeedback.lightImpact();
    }
  }

  /// Go to previous page
  Future<void> _previousPage() async {
    if (_pdfController != null) {
      await _pdfController!.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      HapticFeedback.lightImpact();
    }
  }

  /// Go to next page
  Future<void> _nextPage() async {
    if (_pdfController != null) {
      await _pdfController!.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      HapticFeedback.lightImpact();
    }
  }

  /// Go to last page
  Future<void> _goToLastPage() async {
    if (_pdfController != null) {
      await _pdfController!.animateToPage(
        pageNumber: _totalPages, // ✅ FIXED: required parameter
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      HapticFeedback.lightImpact();
    }
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
              'Toplam $_totalPages sayfa',
              style: TextStyle(color: theme.textTheme.bodyMedium?.color),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Sayfa numarası (1-$_totalPages)',
                hintText: 'Örn: $_currentPage',
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
  Future<void> _goToPageFromInput(String pageText) async {
    final page = int.tryParse(pageText);
    if (page != null && page >= 1 && page <= _totalPages) {
      // ✅ FIXED: Added null check and required pageNumber parameter
      if (_pdfController != null) {
        await _pdfController!.animateToPage(
          pageNumber: page, // ✅ FIXED: Added required pageNumber parameter
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        // ✅ FIXED: Check if widget is still mounted before using context
        if (mounted) {
          Navigator.pop(context);
          HapticFeedback.lightImpact();
        }
      }
    } else {
      // ✅ FIXED: Check if widget is still mounted before using context
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Geçersiz sayfa numarası: $pageText'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
              '$_totalPages sayfa',
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
              '$_currentPage. sayfa',
              style: TextStyle(color: theme.textTheme.bodyMedium?.color),
            ),
            const SizedBox(height: 12),
            Text(
              'Zoom Desteği:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
            Text(
              'Pinch-to-zoom (gesture only)',
              style: TextStyle(color: theme.textTheme.bodyMedium?.color),
            ),
            const SizedBox(height: 12),
            Text(
              'Kalite:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
            Text(
              'Re-render on zoom (kalite kaybı yok)',
              style: TextStyle(color: theme.textTheme.bodyMedium?.color),
            ),
            const SizedBox(height: 12),
            Text(
              'API Versiyonu:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
            Text(
              'pdfx 2.9.2 - Modern async API',
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
    // ✅ FIXED: Check if widget is still mounted before using context
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔗 Harici uygulama özelliği Phase 3\'te!'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }
}
