// lib/src/features/mail/presentation/widgets/web/compose/unified_drop_zone_wrapper.dart

import 'dart:async';
import 'dart:js_interop';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:web/web.dart' as web;
import '../../../../../../utils/app_logger.dart';

/// Unified drag&drop ve copy/paste wrapper widget
/// 
/// Gmail benzeri dosya yönetimi için üst seviye container:
/// - Global drag&drop events
/// - Global paste events  
/// - Visual feedback (dashed border overlay)
/// - File type routing (image vs attachment)
/// 
/// Usage:
/// ```dart
/// UnifiedDropZoneWrapper(
///   onFilesReceived: (files, source) => _handleFiles(files, source),
///   child: MailComposeContent(),
/// )
/// ```
class UnifiedDropZoneWrapper extends StatefulWidget {
  /// Child widget to wrap
  final Widget child;
  
  /// Callback when files are received (drag/drop or paste)
  /// Parameters: (files, source) where source is 'drop' or 'paste'
  final Function(List<web.File>, String source)? onFilesReceived;
  
  /// Whether to show debug information
  final bool debugMode;

  const UnifiedDropZoneWrapper({
    super.key,
    required this.child,
    this.onFilesReceived,
    this.debugMode = false,
  });

  @override
  State<UnifiedDropZoneWrapper> createState() => _UnifiedDropZoneWrapperState();
}

class _UnifiedDropZoneWrapperState extends State<UnifiedDropZoneWrapper> {
  // ========== STATE VARIABLES ==========
  bool _isDragOver = false;
  bool _showDropZone = false;
  int _dragCounter = 0; // Drag enter/leave counter to handle nested elements
  
  // Event listeners cleanup
  StreamController<void>? _eventController;
  bool _listenersSetup = false;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _setupEventListeners();
      AppLogger.info('🎯 UnifiedDropZoneWrapper initialized with package:web');
    }
  }

  @override
  void dispose() {
    _cleanupEventListeners();
    super.dispose();
  }

  /// Setup global event listeners for drag&drop and paste using package:web
  void _setupEventListeners() {
    if (!kIsWeb || _listenersSetup) return;
    
    try {
      _eventController = StreamController<void>();
      
      // Global paste event
      web.document.addEventListener('paste', _handleGlobalPaste.toJS);
      
      // Global drag events
      web.document.addEventListener('dragenter', _handleDragEnter.toJS);
      web.document.addEventListener('dragover', _handleDragOver.toJS);
      web.document.addEventListener('dragleave', _handleDragLeave.toJS);
      web.document.addEventListener('drop', _handleDrop.toJS);
      
      _listenersSetup = true;
      
      if (widget.debugMode) {
        AppLogger.debug('✅ Event listeners setup complete with package:web');
      }
    } catch (e) {
      AppLogger.error('❌ Failed to setup event listeners: $e');
    }
  }

  /// Cleanup event listeners
  void _cleanupEventListeners() {
    if (!kIsWeb || !_listenersSetup) return;
    
    try {
      // Remove event listeners
      web.document.removeEventListener('paste', _handleGlobalPaste.toJS);
      web.document.removeEventListener('dragenter', _handleDragEnter.toJS);
      web.document.removeEventListener('dragover', _handleDragOver.toJS);
      web.document.removeEventListener('dragleave', _handleDragLeave.toJS);
      web.document.removeEventListener('drop', _handleDrop.toJS);
      
      _eventController?.close();
      _listenersSetup = false;
      
      if (widget.debugMode) {
        AppLogger.debug('🧹 Event listeners cleaned up');
      }
    } catch (e) {
      AppLogger.error('❌ Failed to cleanup event listeners: $e');
    }
  }

  // ========== EVENT HANDLERS ==========

  /// Handle global paste events
  void _handleGlobalPaste(web.Event event) {
    if (!kIsWeb || !mounted) return;
    
    try {
      final clipboardEvent = event as web.ClipboardEvent;
      final clipboardData = clipboardEvent.clipboardData;
      
      if (clipboardData != null) {
        final files = clipboardData.files;
        
        if (files.length > 0) {
          event.preventDefault();
          event.stopPropagation();
          
          final fileList = <web.File>[];
          for (int i = 0; i < files.length; i++) {
            final file = files.item(i);
            if (file != null) {
              fileList.add(file);
            }
          }
          
          if (widget.debugMode) {
            AppLogger.debug('📋 Paste detected: ${fileList.length} files');
            for (final file in fileList) {
              AppLogger.debug('  - ${file.name} (${file.type})');
            }
          }
          
          widget.onFilesReceived?.call(fileList, 'paste');
        }
      }
    } catch (e) {
      AppLogger.error('❌ Paste handling error: $e');
    }
  }

  /// Handle drag enter events
  void _handleDragEnter(web.Event event) {
    if (!kIsWeb || !mounted) return;
    
    try {
      final dragEvent = event as web.DragEvent;
      final dataTransfer = dragEvent.dataTransfer;
      
      // Check if dragging files
      if (dataTransfer != null && _containsFiles(dataTransfer)) {
        event.preventDefault();
        event.stopPropagation();
        
        _dragCounter++;
        
        if (!_showDropZone) {
          setState(() {
            _showDropZone = true;
            _isDragOver = true;
          });
          
          if (widget.debugMode) {
            AppLogger.debug('🎯 Drag enter: showing drop zone');
          }
        }
      }
    } catch (e) {
      AppLogger.error('❌ Drag enter handling error: $e');
    }
  }

  /// Handle drag over events
  void _handleDragOver(web.Event event) {
    if (!kIsWeb || !mounted) return;
    
    try {
      final dragEvent = event as web.DragEvent;
      final dataTransfer = dragEvent.dataTransfer;
      
      if (dataTransfer != null && _containsFiles(dataTransfer)) {
        event.preventDefault();
        event.stopPropagation();
        
        // Set drop effect
        dataTransfer.dropEffect = 'copy';
      }
    } catch (e) {
      AppLogger.error('❌ Drag over handling error: $e');
    }
  }

  /// Handle drag leave events
  void _handleDragLeave(web.Event event) {
    if (!kIsWeb || !mounted) return;
    
    try {
      if (widget.debugMode) {
        AppLogger.debug('🎯 DragLeave: target=${event.target.runtimeType}, counter=$_dragCounter');
      }
      
      // 🎯 SIMPLIFIED: Always decrement and check if we should hide
      _dragCounter--;
      
      if (widget.debugMode) {
        AppLogger.debug('🎯 DragLeave: decremented to $_dragCounter');
      }
      
      // Hide when counter reaches 0 or below
      if (_dragCounter <= 0 && mounted) {
        _dragCounter = 0;
        setState(() {
          _showDropZone = false;
          _isDragOver = false;
        });
        
        if (widget.debugMode) {
          AppLogger.debug('🎯 Drag leave: hiding drop zone (counter: $_dragCounter)');
        }
      }
    } catch (e) {
      AppLogger.error('❌ Drag leave handling error: $e');
    }
  }

  /// Handle drop events
  void _handleDrop(web.Event event) {
    if (!kIsWeb || !mounted) return;
    
    try {
      event.preventDefault();
      event.stopPropagation();
      
      final dragEvent = event as web.DragEvent;
      final dataTransfer = dragEvent.dataTransfer;
      
      // Reset drag state
      _dragCounter = 0;
      setState(() {
        _showDropZone = false;
        _isDragOver = false;
      });
      
      if (dataTransfer != null) {
        final files = dataTransfer.files;
        
        if (files.length > 0) {
          final fileList = <web.File>[];
          for (int i = 0; i < files.length; i++) {
            final file = files.item(i);
            if (file != null) {
              fileList.add(file);
            }
          }
          
          if (widget.debugMode) {
            AppLogger.debug('🎯 Drop detected: ${fileList.length} files');
            for (final file in fileList) {
              AppLogger.debug('  - ${file.name} (${file.type})');
            }
          }
          
          widget.onFilesReceived?.call(fileList, 'drop');
        }
      }
    } catch (e) {
      AppLogger.error('❌ Drop handling error: $e');
    }
  }

  /// Check if DataTransfer contains files
  bool _containsFiles(web.DataTransfer dataTransfer) {
    try {
      final types = dataTransfer.types;
      
      if (widget.debugMode) {
        AppLogger.debug('🔍 DataTransfer types: ${types.length}');
        for (int i = 0; i < types.length; i++) {
          AppLogger.debug('  - Type $i: ${types[i]}');
        }
      }
      
      for (int i = 0; i < types.length; i++) {
        if (types[i] == 'Files') {
          return true;
        }
      }
      
      // Also check files directly as backup
      final files = dataTransfer.files;
      final hasFiles = files.length > 0;
      
      if (widget.debugMode) {
        AppLogger.debug('🔍 Direct files check: $hasFiles (${files.length} files)');
      }
      
      return hasFiles;
    } catch (e) {
      if (widget.debugMode) {
        AppLogger.debug('❌ Error checking files: $e');
      }
      return false;
    }
  }

  // ========== UI BUILDERS ==========

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main child content
        widget.child,
        
        // Drop zone overlay (only when dragging)
        if (_showDropZone) _buildDropOverlay(context),
        
        // Debug info (if enabled)
        if (widget.debugMode) _buildDebugInfo(),
      ],
    );
  }

  /// Build the drop zone overlay with dashed border
  Widget _buildDropOverlay(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.blue.withOpacity(0.05),
        child: _DashedBorder(
          isActive: _isDragOver,
          child: Container(
            margin: const EdgeInsets.all(20),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.cloud_upload_outlined,
                      size: _isDragOver ? 72 : 64,
                      color: Colors.blue.shade600,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Text(
                    'Dosyaları buraya bırakın',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  Text(
                    'Resimler editöre, diğer dosyalar ek olarak eklenir',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // File type indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildFileTypeIndicator(
                        Icons.image_outlined,
                        'Resimler',
                        'Editöre eklenir',
                        Colors.green,
                      ),
                      const SizedBox(width: 32),
                      _buildFileTypeIndicator(
                        Icons.attach_file,
                        'Dosyalar',
                        'Ek olarak eklenir',
                        Colors.orange,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build file type indicator
  Widget _buildFileTypeIndicator(
    IconData icon,
    String title,
    String subtitle,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  /// Build debug information overlay
  Widget _buildDebugInfo() {
    return Positioned(
      top: 10,
      right: 10,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'DEBUG: UnifiedDropZone',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Drag: $_isDragOver',
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
            Text(
              'Show: $_showDropZone',
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
            Text(
              'Counter: $_dragCounter',
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}

// ========== DASHED BORDER COMPONENT ==========

/// Custom dashed border widget for drop zone styling
class _DashedBorder extends StatelessWidget {
  final Widget child;
  final bool isActive;
  
  const _DashedBorder({
    required this.child,
    this.isActive = false,
  });
  
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(
        color: isActive ? Colors.blue.shade600 : Colors.blue.shade400,
        strokeWidth: isActive ? 3 : 2,
        dashWidth: 10,
        dashSpace: 5,
      ),
      child: child,
    );
  }
}

/// Custom painter for dashed border
class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;
  
  _DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.dashWidth,
    required this.dashSpace,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    
    // Draw dashed rectangle
    _drawDashedLine(canvas, const Offset(0, 0), Offset(size.width, 0), paint);
    _drawDashedLine(canvas, Offset(size.width, 0), Offset(size.width, size.height), paint);
    _drawDashedLine(canvas, Offset(size.width, size.height), Offset(0, size.height), paint);
    _drawDashedLine(canvas, Offset(0, size.height), const Offset(0, 0), paint);
  }
  
  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    final distance = (end - start).distance;
    final dashCount = (distance / (dashWidth + dashSpace)).floor();
    
    final dashVector = (end - start) / distance * dashWidth;
    final spaceVector = (end - start) / distance * (dashWidth + dashSpace);
    
    for (int i = 0; i < dashCount; i++) {
      final dashStart = start + spaceVector * i.toDouble();
      final dashEnd = dashStart + dashVector;
      canvas.drawLine(dashStart, dashEnd, paint);
    }
  }
  
  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return color != oldDelegate.color ||
           strokeWidth != oldDelegate.strokeWidth ||
           dashWidth != oldDelegate.dashWidth ||
           dashSpace != oldDelegate.dashSpace;
  }
}