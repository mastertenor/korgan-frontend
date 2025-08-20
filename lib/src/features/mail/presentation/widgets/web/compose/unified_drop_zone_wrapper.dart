// lib/src/features/mail/presentation/widgets/web/compose/unified_drop_zone_wrapper.dart

import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:web/web.dart' as web;

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

  const UnifiedDropZoneWrapper({
    super.key,
    required this.child,
    this.onFilesReceived,
  });

  @override
  State<UnifiedDropZoneWrapper> createState() => _UnifiedDropZoneWrapperState();
}

class _UnifiedDropZoneWrapperState extends State<UnifiedDropZoneWrapper> {
  // ========== STATE VARIABLES ==========
  bool _isDragOver = false;
  bool _showDropZone = false;
  Timer? _dragLeaveTimer;
  
  // Event listeners cleanup
  bool _listenersSetup = false;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _setupEventListeners();
    }
  }

  @override
  void dispose() {
    _dragLeaveTimer?.cancel();
    _cleanupEventListeners();
    super.dispose();
  }

  /// Setup global event listeners for drag&drop and paste using package:web
  void _setupEventListeners() {
    if (!kIsWeb || _listenersSetup) return;
    
    try {
      // Global paste event
      web.document.addEventListener('paste', _handleGlobalPaste.toJS);
      
      // Global drag events
      web.document.addEventListener('dragenter', _handleDragEnter.toJS);
      web.document.addEventListener('dragover', _handleDragOver.toJS);
      web.document.addEventListener('dragleave', _handleDragLeave.toJS);
      web.document.addEventListener('drop', _handleDrop.toJS);
      
      // Listen for iframe drop completion messages
      web.window.addEventListener('message', (web.Event event) {
        final messageEvent = event as web.MessageEvent;
        try {
          final data = messageEvent.data;
          
          String? dataString;
          if (data != null) {
            dataString = (data).dartify() as String?;
          }
          
          if (dataString != null && dataString.isNotEmpty) {
            final parsed = jsonDecode(dataString);
            if (parsed is Map && parsed['type'] == 'force_hide_drop_zone') {
              _dragLeaveTimer?.cancel();
              if (mounted) {
                setState(() {
                  _showDropZone = false;
                  _isDragOver = false;
                });
              }
            }
            // NEW: Handle force show drop zone from iframe
            else if (parsed is Map && parsed['type'] == 'force_show_drop_zone') {
              _dragLeaveTimer?.cancel();
              if (mounted && !_showDropZone) {
                setState(() {
                  _showDropZone = true;
                  _isDragOver = true;
                });
              }
            }
          }
        } catch (e) {
          // Silent ignore - not our message
        }
      }.toJS);
      
      _listenersSetup = true;
    } catch (e) {
      // Setup failed
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
      
      _listenersSetup = false;
    } catch (e) {
      // Cleanup failed
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
          
          widget.onFilesReceived?.call(fileList, 'paste');
        }
      }
    } catch (e) {
      // Paste handling error
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
        _dragLeaveTimer?.cancel();
        
        if (!_showDropZone) {
          setState(() {
            _showDropZone = true;
            _isDragOver = true;
          });
        }
      }
    } catch (e) {
      // Drag enter handling error
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
      // Drag over handling error
    }
  }

  /// Handle drag leave events
  void _handleDragLeave(web.Event event) {
    if (!kIsWeb || !mounted) return;
    
    try {
      _dragLeaveTimer?.cancel();
      
      _dragLeaveTimer = Timer(const Duration(milliseconds: 100), () {
        if (!mounted) return;
        
        final relatedTarget = (event as web.DragEvent).relatedTarget;
        
        if (_shouldHideDropZone(relatedTarget)) {
          setState(() {
            _showDropZone = false;
            _isDragOver = false;
          });
        }
      });
    } catch (e) {
      // Drag leave handling error
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
      
      _dragLeaveTimer?.cancel();
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
          
          widget.onFilesReceived?.call(fileList, 'drop');
        }
      }
    } catch (e) {
      // Drop handling error
    }
  }

  /// Safe helper method to determine if drop zone should be hidden
  bool _shouldHideDropZone(web.EventTarget? relatedTarget) {
    // If no related target, definitely leaving
    if (relatedTarget == null) return true;
    
    try {
      // Check if relatedTarget is a Node and contained in document
      if (relatedTarget is web.Node) {
        return !web.document.contains(relatedTarget);
      }
      
      // If relatedTarget is not a Node (like Window), consider it as leaving
      return true;
    } catch (e) {
      return true;
    }
  }

  /// Check if DataTransfer contains files
  bool _containsFiles(web.DataTransfer dataTransfer) {
    try {
      final types = dataTransfer.types;
      
      for (int i = 0; i < types.length; i++) {
        if (types[i] == 'Files') {
          return true;
        }
      }
      
      // Also check files directly as backup
      final files = dataTransfer.files;
      return files.length > 0;
    } catch (e) {
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