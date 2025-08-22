// lib/src/features/mail/presentation/widgets/web/compose/components/froala_message_handler.dart

import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'package:web/web.dart' as web;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../providers/froala_editor_provider.dart';
import '../../../../providers/mail_providers.dart';

class FroalaMessageHandler {
  final String channelId;
  final WidgetRef ref;
  final dynamic widget;
  final BuildContext context;
  final VoidCallback onIframeReady;
  final Function(Map<String, dynamic>) onPostToIframe;
  
  bool _isDisposed = false;
  Timer? _readyTimeout;

  FroalaMessageHandler({
    required this.channelId,
    required this.ref,
    required this.widget,
    required this.context,
    required this.onIframeReady,
    required this.onPostToIframe,
  });

  void dispose() {
    _isDisposed = true;
    _readyTimeout?.cancel();
  }

  Map<String, dynamic>? normalizeMessage(dynamic data) {
    try {
      if (data == null) return null;

      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }

      if (data is String) {
        final trimmed = data.trim();
        if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
          return Map<String, dynamic>.from(jsonDecode(trimmed));
        }

        final guess = trimmed
            .replaceAll(RegExp(r'([{,]\s*)([a-zA-Z0-9_]+)\s*:'), r'$1"$2":')
            .replaceAll(RegExp(r':\s*([a-zA-Z_][a-zA-Z0-9_]*)\s*([,}])'), r':"$1"$2');

        if (guess != trimmed && guess.startsWith('{') && guess.endsWith('}')) {
          return Map<String, dynamic>.from(jsonDecode(guess));
        }
      }

      final str = data.toString();
      if (str.startsWith('{') && str.endsWith('}')) {
        return Map<String, dynamic>.from(jsonDecode(str));
      }
    } catch (_) {}
    return null;
  }

  void handleChannelMessage(Map<String, dynamic> payload) {
    if (_isDisposed) return;
    
    final type = payload['type'] as String?;
    
    switch (type) {
      case 'froala_ready':
        if (payload['ready'] == true) {
          debugPrint('Froala ready via channel!');
          _readyTimeout?.cancel();
          if (!_isDisposed) {
            ref.read(froalaEditorProvider.notifier).onEditorReady();
            
            if (widget.initialContent != null && widget.initialContent!.isNotEmpty) {
              _setEditorContent(widget.initialContent!);
            }
          }
        }
        break;
        
      case 'froala_error':
        debugPrint('Froala error: ${payload['error']}');
        _readyTimeout?.cancel();
        if (!_isDisposed) {
          ref.read(froalaEditorProvider.notifier).onEditorError(
            payload['error'] ?? 'Unknown error',
            details: payload['details'],
          );
        }
        break;
        
      case 'content_changed':
        if (_isDisposed) return;
        
        final htmlContent = payload['html'] as String? ?? '';
        final textContent = payload['text'] as String? ?? '';
        final isEmpty = payload['isEmpty'] as bool? ?? true;
        final wordCount = payload['wordCount'] as int? ?? 0;
        
        ref.read(mailComposeProvider.notifier).updateHtmlContent(
          isEmpty ? null : htmlContent,
        );
        ref.read(mailComposeProvider.notifier).updateTextContent(textContent);
        
        ref.read(froalaEditorProvider.notifier).updateContent(
          htmlContent: htmlContent,
          textContent: textContent,
          isEmpty: isEmpty,
          wordCount: wordCount,
        );
        
        widget.onContentChanged?.call(htmlContent, textContent);
        
        debugPrint('Content updated: $wordCount words');
        break;
        
      case 'send_shortcut':
        if (!_isDisposed) {
          widget.onSendShortcut?.call();
          debugPrint('Send shortcut triggered');
        }
        break;
        
      case 'image_pasted':
        if (_isDisposed) return;
        
        final base64 = payload['base64'] as String? ?? '';
        final name = payload['name'] as String? ?? 'image.png';
        final size = payload['size'] as int? ?? 0;
        
        ref.read(froalaEditorProvider.notifier).onImagePasted(
          base64: base64,
          name: name,
          size: size,
        );
        
        widget.onImagePasted?.call(base64, name, size);
        
        debugPrint('Image pasted: $name ($size bytes)');
        break;

      case 'image_inserted':
        if (_isDisposed) return;
        
        final name = payload['name'] as String? ?? 'image';
        final size = payload['size'] as int? ?? 0;
        
        debugPrint('Image inserted successfully: $name (${_formatFileSize(size)})');
        break;

      case 'paste_blocked':
        if (!_isDisposed) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(payload['message'] ?? 'İzin verilmeyen içerik türü'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        break;        
        
      case 'files_dropped_in_iframe':
        if (_isDisposed) return;
        
        final files = payload['files'] as List?;
        if (files != null && files.isNotEmpty) {
          debugPrint('IFRAME FILES: ${files.length} files received');
          
          final nonImageFiles = <Map<String, dynamic>>[];
          
          for (final fileData in files) {
            final name = fileData['name'] as String;
            final type = fileData['type'] as String;
            final size = fileData['size'] as int;
            final base64 = fileData['base64'] as String;
            
            debugPrint('Processing iframe file: $name ($type, $size bytes)');
            
            if (type.startsWith('image/')) {
              _insertImage(base64: base64, name: name, size: size);
            } else {
              nonImageFiles.add({
                'name': name,
                'type': type,
                'size': size,
                'base64': base64,
              });
            }
          }
          
          if (nonImageFiles.isNotEmpty && widget.onIframeFilesDropped != null) {
            debugPrint('Sending ${nonImageFiles.length} non-image files to parent callback');
            widget.onIframeFilesDropped!(nonImageFiles);
          }
        }
        break;

      case 'focus_changed':
        final focused = payload['focused'] as bool? ?? false;
        scheduleMicrotask(() {
          if (_isDisposed) return;
          ref.read(froalaEditorProvider.notifier).updateFocus(focused);
        });
        break;
        
      case 'iframe_drop_complete':
        if (_isDisposed) return;
        
        debugPrint('Iframe drop completed, hiding drop zone');
        
        scheduleMicrotask(() {
          if (_isDisposed) return;
          
          try {
            web.window.postMessage(jsonEncode({
              'type': 'force_hide_drop_zone',
              'source': 'iframe_completion'
            }).toJS, '*'.toJS);
          } catch (e) {
            debugPrint('Error sending drop zone hide message: $e');
          }
        });
        break;

      case 'froala_focus_in':
        scheduleMicrotask(() {
          FocusScope.of(context).unfocus();
          onPostToIframe({
            'type': 'force_focus',
            'channelId': channelId,
          });
        });
        break;

      case 'files_pasted_in_iframe':
        final files = payload['files'] as List?;
        if (files != null && files.isNotEmpty) {
          // Hepsi non-image olarak geliyor; direkt parent'a iletelim
          if (widget.onIframeFilesDropped != null) {
            widget.onIframeFilesDropped!(files.cast<Map<String, dynamic>>());
          }
        }
        break;
    }
  }

  void _setEditorContent(String htmlContent) {
    onPostToIframe({
      'type': 'froala_command',
      'command': 'setContent',
      'data': htmlContent,
      'channelId': channelId,
    });
  }

  void _insertImage({
    required String base64,
    required String name,
    required int size,
  }) {
    onPostToIframe({
      'type': 'froala_command',
      'command': 'insertImage',
      'data': {
        'base64': base64,
        'name': name,
        'size': size,
      },
      'channelId': channelId,
    });
    
    debugPrint('Inserting image: $name (${_formatFileSize(size)})');
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
}