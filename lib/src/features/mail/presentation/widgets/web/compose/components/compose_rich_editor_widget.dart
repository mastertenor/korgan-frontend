// lib/src/features/mail/presentation/widgets/web/compose/components/compose_rich_editor_widget.dart

import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:web/web.dart' as web;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../providers/froala_editor_provider.dart';
import '../../../../providers/mail_providers.dart';

/// Complete Froala Rich Text Editor Widget - Hybrid Approach
/// 
/// Combines working blob: URL approach with full feature set
/// **FIXED: Enhanced coordination with UnifiedDropZoneWrapper + Queue System + Scroll Fix**
class ComposeRichEditorWidget extends ConsumerStatefulWidget {
  final String? initialContent;
  final Function(String html, String text)? onContentChanged;
  final VoidCallback? onSendShortcut;
  final Function(String base64, String name, int size)? onImagePasted;
  final Function(List<Map<String, dynamic>> files)? onIframeFilesDropped;
  final double height;

  const ComposeRichEditorWidget({
    super.key,
    this.initialContent,
    this.onContentChanged,
    this.onSendShortcut,
    this.onImagePasted,
    this.onIframeFilesDropped,
    this.height = double.infinity,
  });

  @override
  ConsumerState<ComposeRichEditorWidget> createState() => ComposeRichEditorWidgetState();
}

class ComposeRichEditorWidgetState extends ConsumerState<ComposeRichEditorWidget> {
  late final String _viewType;
  late final String _channelId;

  web.HTMLIFrameElement? _iframe;
  Timer? _readyTimeout;
  String? _blobUrl;
  bool _isDisposed = false;
  bool _listenersSetup = false;
  
  // Queue system for message reliability
  bool _iframeReady = false;
  final List<Map<String, dynamic>> _outboxQueue = [];

  @override
  void initState() {
    super.initState();
    _viewType = 'froala-editor-${DateTime.now().millisecondsSinceEpoch}';
    _channelId = 'chan_${DateTime.now().microsecondsSinceEpoch}_${Object().hashCode}';
    _registerView();
  }

  @override
  void dispose() {
    debugPrint('ComposeRichEditorWidget dispose called');
    
    _isDisposed = true;
    _readyTimeout?.cancel();
    _cleanupEventListeners();
    
    try {
      _iframe?.src = 'about:blank';
    } catch (_) {}
    if (_blobUrl != null && kIsWeb) {
      web.URL.revokeObjectURL(_blobUrl!);
      _blobUrl = null;
    }
    _iframe = null;
    super.dispose();
  }

  void _registerView() {
    if (!kIsWeb) return;
    
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      final htmlString = _getCompleteHTML(channelId: _channelId);
      
      final blobParts = [htmlString.toJS].toJS;
      final blob = web.Blob(blobParts, web.BlobPropertyBag(type: 'text/html'));
      _blobUrl = web.URL.createObjectURL(blob);
      
      _iframe = web.HTMLIFrameElement()
        ..src = _blobUrl!
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.display = 'block'
        ..allow = 'clipboard-read; clipboard-write';

      _setupEventListeners();

      _readyTimeout?.cancel();
      _readyTimeout = Timer(const Duration(seconds: 10), () {
        if (!mounted) return;
        final st = ref.read(froalaEditorProvider);
        if (!st.isReady) {
          ref.read(froalaEditorProvider.notifier).onEditorError(
            'Editor yüklenemedi',
            details: 'Süre doldu (timeout). Muhtemel neden: CSP ya da ağ engeli.',
          );
        }
      });

      return _iframe!;
    });
  }

  void _setupEventListeners() {
    if (!kIsWeb || _listenersSetup) return;
    
    try {
      web.window.addEventListener('message', (web.Event event) {
        final messageEvent = event as web.MessageEvent;
        final payload = _normalizeMessage(messageEvent.data);
        if (payload == null) return;
        if (payload['channelId'] != _channelId) return;

        // Handle iframe ready signal
        if (payload['type'] == 'iframe_ready') {
          _iframeReady = true;
          _flushQueue();
          debugPrint('Iframe ready signal received, flushed ${_outboxQueue.length} queued messages');
          return;
        }

        // Handle iframe drag enter - notify parent to show drop zone
        if (payload['type'] == 'iframe_drag_enter') {
          debugPrint('Iframe drag enter detected, notifying parent');
          scheduleMicrotask(() {
            if (_isDisposed || !mounted) return;
            
            try {
              web.window.postMessage(jsonEncode({
                'type': 'force_show_drop_zone',
                'source': 'iframe_drag_enter'
              }).toJS, '*'.toJS);
            } catch (e) {
              debugPrint('Error sending drop zone show message: $e');
            }
          });
          return;
        }

        _handleChannelMessage(payload);
      }.toJS);
      
      _listenersSetup = true;
    } catch (e) {
      debugPrint('Failed to setup event listeners: $e');
    }
  }

  void _cleanupEventListeners() {
    if (!kIsWeb || !_listenersSetup) return;
    
    try {
      _listenersSetup = false;
    } catch (e) {
      debugPrint('Failed to cleanup event listeners: $e');
    }
  }

  // Queue management methods
  void _flushQueue() {
    if (_iframe?.contentWindow == null || _outboxQueue.isEmpty) return;
    
    for (final message in _outboxQueue) {
      _iframe!.contentWindow!.postMessage(jsonEncode(message).toJS, '*'.toJS);
    }
    _outboxQueue.clear();
  }

  void _postToIframe(Map<String, dynamic> message) {
    if (_iframe?.contentWindow == null) return;
    
    if (!_iframeReady) {
      _outboxQueue.add(message);
      debugPrint('Message queued (iframe not ready): ${message['type']}');
      return;
    }
    
    _iframe!.contentWindow!.postMessage(jsonEncode(message).toJS, '*'.toJS);
    debugPrint('Message sent to iframe: ${message['type']}');
  }

  void _handleChannelMessage(Map<String, dynamic> payload) {
    if (_isDisposed) return;
    
    final type = payload['type'] as String?;
    
    switch (type) {
      case 'froala_ready':
        if (payload['ready'] == true) {
          debugPrint('Froala ready via channel!');
          _readyTimeout?.cancel();
          if (!_isDisposed && mounted) {
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
        if (!_isDisposed && mounted) {
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
        if (!_isDisposed && mounted) {
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
        if (!_isDisposed && mounted) {
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
              insertImage(base64: base64, name: name, size: size);
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
          if (_isDisposed || !mounted) return;
          ref.read(froalaEditorProvider.notifier).updateFocus(focused);
        });
        break;
        
      case 'iframe_drop_complete':
        if (_isDisposed) return;
        
        debugPrint('Iframe drop completed, hiding drop zone');
        
        scheduleMicrotask(() {
          if (_isDisposed || !mounted) return;
          
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
            if (!mounted) return;
            FocusScope.of(context).unfocus();
            _postToIframe({
            'type': 'force_focus',
            'channelId': _channelId, // <-- MUTLAKA
            });
          });
          break;
    }
  }

  Map<String, dynamic>? _normalizeMessage(dynamic data) {
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

  // Editor control methods
  void _setEditorContent(String htmlContent) {
    _postToIframe({
      'type': 'froala_command',
      'command': 'setContent',
      'data': htmlContent,
      'channelId': _channelId,
    });
  }

  void insertImage({
    required String base64,
    required String name,
    required int size,
  }) {
    _postToIframe({
      'type': 'froala_command',
      'command': 'insertImage',
      'data': {
        'base64': base64,
        'name': name,
        'size': size,
      },
      'channelId': _channelId,
    });
    
    debugPrint('Inserting image: $name (${_formatFileSize(size)})');
  }

  void sendExternalImageMessage({
    required String base64,
    required String name,
    required int size,
    required String source,
  }) {
    _postToIframe({
      'type': 'external_image_insert',
      'base64': base64,
      'name': name,
      'size': size,
      'source': source,
      'channelId': _channelId,
    });
  }

  void cleanupDragHelper() {
    _postToIframe({
      'type': 'froala_command',
      'command': 'cleanupDragHelper',
      'channelId': _channelId,
    });
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  /// Complete HTML with ready signal, simplified logging and scroll fix
  String _getCompleteHTML({required String channelId}) {
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <link href="https://cdn.jsdelivr.net/npm/froala-editor@latest/css/froala_editor.pkgd.min.css" rel="stylesheet">
  <link href="https://cdn.jsdelivr.net/npm/froala-editor@latest/css/froala_style.min.css" rel="stylesheet">
<style>
  /* Tutarlı kutu modeli */
  *, *::before, *::after { box-sizing: border-box; }

  /* Dış sayfa scroll'u yok, tam yükseklik zinciri */
  html, body {
    height: 100%;
    margin: 0;
    overflow: hidden;
    font-family: system-ui;
    background: transparent;
  }

  /* Froala kök */
  #editor, .fr-box { height: 100%; }

  /* Dış çerçeve - Flutter Container border'ı kullanacağı için border kaldırıldı */
  .fr-box {
    display: flex;
    flex-direction: column;
    min-height: 0;
    border: 0 !important;
    overflow: hidden;
    background: #fff;
  }

  /* ÜST şerit: sadece alt ayırıcı çizgi */
  .fr-toolbar {
    flex: 0 0 auto;
    background: #fafafa !important;
    border-bottom: 1px solid #e0e0e0 !important;
    border-left: 0 !important;
    border-right: 0 !important;
    border-radius: 0 !important;
    box-shadow: none !important;
  }

  /* İÇ kap: dış scroll'u engelle */
  .fr-wrapper {
    flex: 1 1 auto;
    min-height: 0;
    height: auto !important;
    overflow: hidden !important;
    border: 0 !important;
    background: #fff;
  }

  /* İÇERİK: yalnızca burada scroll çıksın */
  .fr-element {
    height: 100% !important;
    min-height: 0 !important;
    overflow: auto !important;
    padding: 16px !important;
    line-height: 1.5 !important;
    font-size: 14px !important;
    border: 0 !important;
    background: #fff;
  }

  /* ALT şeritler: sadece üst ayırıcı çizgi */
  .fr-powered-by,
  .fr-second-toolbar,
  .fr-counter {
    background: #fff !important;
    border-top: 1px solid #e0e0e0 !important;
    border-left: 0 !important;
    border-right: 0 !important;
    border-radius: 0 !important;
    box-shadow: none !important;
  }

  /* Sürükleme helper'ını tamamen gizle */
  .fr-drag-helper {
    display: none !important;
    opacity: 0 !important;
    visibility: hidden !important;
  }
</style>
</head>
<body>
  <div id="editor"></div>

  <script>
    (function(){
      var CHANNEL = ${jsonEncode(channelId)};
      var editor;
      var isReady = false;
      var lastFocused = null;
      
      // Ready signal function
      function notifyReady() {
        try {
          parent.postMessage(JSON.stringify({
            type: 'iframe_ready',
            channelId: CHANNEL,
            ts: Date.now()
          }), '*');
          console.log('Ready signal sent to parent');
        } catch (e) {
          console.error('Error sending ready signal:', e);
        }
      }

      // Safe message parsing
      function safeParseIncoming(data) {
        try {
          if (typeof data === 'string' || data instanceof String) {
            return JSON.parse(data.toString());
          }
          if (data && typeof data === 'object') {
            return data;
          }
        } catch (e) {
          console.log('Parse error:', e);
        }
        return null;
      }
      
      function post(type, extra){
        var msg = Object.assign({ type: type, channelId: CHANNEL }, extra || {});
        try { 
          console.log('Posting message:', msg);
          parent.postMessage(JSON.stringify(msg), '*'); 
        } catch (e) {
          console.error('Failed to post message:', e);
        }
      }

      // SCROLL FIX: Caret visibility helper function
      function scrollCaretIntoView(editorInstance) {
        try {
          const container = editorInstance && editorInstance.el;
          if (!container) return;

          // 1) Seçimden caret konumunu ölç
          const sel = window.getSelection && window.getSelection();
          if (!sel || sel.rangeCount === 0) {
            // Fallback: en alta götür
            container.scrollTop = container.scrollHeight;
            return;
          }

          const range = sel.getRangeAt(0).cloneRange();
          // 2) Görünmez bir işaret ekleyip konumunu ölçelim
          const marker = document.createElement('span');
          marker.textContent = '\\u200b'; // zero-width space
          range.insertNode(marker);

          // 3) Container ve caret marker rect'ine göre delta hesapla
          const cRect = container.getBoundingClientRect();
          const mRect = marker.getBoundingClientRect();
          marker.parentNode && marker.parentNode.removeChild(marker);

          const padding = 8; // küçük tampon
          const deltaDown = mRect.bottom - (cRect.bottom - padding);
          const deltaUp   = (cRect.top + padding) - mRect.top;

          if (deltaDown > 0) {
            container.scrollTop += deltaDown;
          } else if (deltaUp > 0) {
            container.scrollTop -= deltaUp;
          }
        } catch (e) {
          // Son çare: en alta kaydır
          try { 
            (editorInstance && editorInstance.el).scrollTop = (editorInstance && editorInstance.el).scrollHeight; 
          } catch(_) {}
        }
      }

      function loadFroalaScript() {
        return new Promise((resolve, reject) => {
          const script = document.createElement('script');
          script.src = 'https://cdn.jsdelivr.net/npm/froala-editor@latest/js/froala_editor.pkgd.min.js';
          script.onload = () => {
            console.log('Froala main script loaded successfully');
            
            const pluginScript = document.createElement('script');
            pluginScript.src = 'https://cdn.jsdelivr.net/npm/froala-editor@latest/js/plugins.pkgd.min.js';
            pluginScript.onload = () => {
              console.log('Froala plugins loaded successfully');
              resolve(true);
            };
            pluginScript.onerror = (error) => {
              console.warn('Froala plugins failed to load, continuing with basic features:', error);
              resolve(true);
            };
            document.head.appendChild(pluginScript);
          };
          script.onerror = (error) => {
            console.error('Froala main script failed to load:', error);
            reject(error);
          };
          document.head.appendChild(script);
        });
      }

      window.addEventListener('message', function(event) {
        console.log('Raw message received:', {
          origin: event.origin,
          dataType: typeof event.data
        });
        
        var payload = safeParseIncoming(event.data);
        if (!payload) {
          console.log('Invalid payload, skipping');
          return;
        }
        
        if (payload.channelId !== CHANNEL) {
          console.log('Wrong channel, ignoring. Expected:', CHANNEL, 'Got:', payload.channelId);
          return;
        }
        
        if (payload.type === 'froala_command') {
          const command = payload.command;
          const data = payload.data;
          
          if (!editor || !isReady) {
            console.log('Editor not ready for command:', command);
            return;
          }
          
          switch (command) {
            case 'setContent':
              editor.html.set(data || '');
              break;
            case 'insertImage':
              if (data && data.base64) {
                try {
                  editor.image.insert(data.base64, null, null, editor.image.get());
                  
                  post('image_inserted', {
                    name: data.name || 'image',
                    size: data.size || 0
                  });
                  
                  console.log('Image inserted:', data.name);
                } catch (err) {
                  console.error('Failed to insert image:', err);
                }
              }
              break;
            case 'cleanupDragHelper':
              var dragHelpers = document.querySelectorAll('.fr-drag-helper');
              var removedCount = 0;
              dragHelpers.forEach(function(helper) {
                helper.style.display = 'none';
                helper.style.opacity = '0';
                helper.style.visibility = 'hidden';
                helper.remove();
                removedCount++;
              });
              console.log('Manual drag helper cleanup completed, removed:', removedCount);
              break;
          }
        }
        
        else if (payload.type === 'external_image_insert') {
          console.log('External image insert received:', payload.name);
          
          if (!editor || !isReady) {
            console.log('Editor not ready for external image:', payload.name);
            return;
          }
          
          try {
            editor.image.insert(payload.base64, null, null, editor.image.get());
            
            post('image_inserted', {
              name: payload.name || 'image',
              size: payload.size || 0
            });
            
            console.log('External image inserted successfully:', payload.name);
          } catch (err) {
            console.error('Failed to insert external image:', err);
          }
        }
          else if (payload.type === 'force_focus') {
        if (editor && isReady) {
          console.log('Force focusing Froala editor...');
          editor.events.focus(true);
        }
      }

      });

      function setupUnifiedDropHandlers() {
        console.log('Setting up enhanced iframe drop handlers');
        
        document.addEventListener('dragenter', function(e) {
          if (e.dataTransfer && e.dataTransfer.types.includes('Files')) {
            console.log('IFRAME: DRAGENTER - notifying parent to show drop zone');
            try {
              parent.postMessage(JSON.stringify({
                type: 'iframe_drag_enter',
                channelId: CHANNEL
              }), '*');
            } catch (err) {
              console.warn('Could not notify parent about drag enter:', err);
            }
          }
        }, true);
        
        document.addEventListener('drop', function(e) {
          console.log('IFRAME: DROP EVENT - high priority capture');
          
          if (e.dataTransfer && e.dataTransfer.files.length > 0) {
            e.preventDefault();
            e.stopPropagation();
            e.stopImmediatePropagation();
            
            console.log('IFRAME: Processing', e.dataTransfer.files.length, 'files');
            
            const files = Array.from(e.dataTransfer.files);
            const fileData = [];
            
            files.forEach((file, index) => {
              const reader = new FileReader();
              reader.onload = function(event) {
                fileData.push({
                  name: file.name,
                  type: file.type,
                  size: file.size,
                  base64: event.target.result
                });
                
                if (fileData.length === files.length) {
                  post('files_dropped_in_iframe', {
                    files: fileData,
                    source: 'iframe_drop'
                  });
                  
                  try {
                    parent.postMessage(JSON.stringify({
                      type: 'iframe_drop_complete',
                      channelId: CHANNEL
                    }), '*');
                    console.log('IFRAME: Notified parent about drop completion');
                  } catch (err) {
                    console.warn('Could not notify parent about drop completion:', err);
                  }
                }
              };
              reader.readAsDataURL(file);
            });
          }
        }, true);
        
        document.addEventListener('dragover', function(e) {
          if (e.dataTransfer && e.dataTransfer.types.includes('Files')) {
            e.preventDefault();
            e.dataTransfer.dropEffect = 'copy';
          }
        }, true);
      }

      document.addEventListener('DOMContentLoaded', async function(){
        console.log('DOM ready, channel:', CHANNEL);
        
        notifyReady();
        
        try {
          console.log('Loading Froala script...');
          await loadFroalaScript();
          
          if (typeof FroalaEditor === 'undefined') {
            throw new Error('FroalaEditor still not found after script load');
          }
          
          console.log('FroalaEditor found, version:', FroalaEditor.VERSION || 'unknown');
          
          setupUnifiedDropHandlers();
          
          editor = new FroalaEditor('#editor', {
            placeholderText: 'Mesajınızı yazın...',
            theme: 'gray',
            charCounterCount: false,
            toolbarInline: false,
            toolbarSticky: true,
            quickInsertEnabled: false,
            
            toolbarButtons: {
              'moreText': {
                'buttons': ['fontFamily','bold', 'italic', 'underline', 'strikeThrough', 'fontSize', 'textColor', 'backgroundColor'],
                'align': 'left',
                'buttonsVisible': 8
              },
              'moreParagraph': {
                'buttons': ['alignLeft', 'alignCenter', 'alignRight', 'formatOL', 'formatUL', 'outdent', 'indent', 'quote'],
                'align': 'left', 
                'buttonsVisible': 8
              },
              'moreRich': {
                'buttons': ['insertLink', 'insertImage', 'insertTable', 'insertHR'],
                'align': 'left',
                'buttonsVisible': 4
              },
              'moreMisc': {
                'buttons': ['undo', 'redo'],
                'align': 'right',
                'buttonsVisible': 4
              }
            },
            
            toolbarButtonsXS: ['bold', 'italic', 'underline', 'insertLink', 'undo', 'redo'],
            
            pastePlain: false,
            pasteDeniedTags: ['script', 'style', 'meta', 'link', 'form', 'input', 'button', 'iframe', 'object', 'embed'],
            pasteDeniedAttrs: ['onload', 'onclick', 'onmouseover', 'onfocus', 'onblur', 'onchange', 'onsubmit'],
            
            imageUpload: false,
            imageInsertButtons: ['imageByURL'],
            imageResizeWithPercent: true,
            dragInline: false,
            linkAlwaysBlank: true,
            
            events: {
              'initialized': function () { 
                console.log('Froala initialized!');
                isReady = true;
                
                // SCROLL FIX: Froala'nın kaydırma hedefini gerçek içerik konteynerine yönlendir
                this.opts.scrollableContainer = this.el;
                
                console.log('Toolbar inline mode:', this.opts.toolbarInline);
                console.log('Available toolbar buttons:', Object.keys(this.button || {}));
                
                post('froala_ready', { ready: true });
                notifyReady();
              },

              'keydown': function(e) {
                if ((e.ctrlKey || e.metaKey) && e.key === 'Enter') {
                  e.preventDefault();
                  post('send_shortcut');
                }
                // SCROLL FIX: Enter'dan hemen sonra layout güncelleneceği için rAF ile kaydır
                if (e.key === 'Enter') {
                  requestAnimationFrame(() => scrollCaretIntoView(this));
                }
              },

              'keyup': function (e) {
                if (e.key === 'Enter') {
                  // SCROLL FIX: Emniyet için bir kez daha (özellikle Chrome'da)
                  setTimeout(() => scrollCaretIntoView(this), 0);
                }
              },
              
              'contentChanged': function () {
                if (!isReady) return;
                var html = editor.html.get();
                var text = editor.el.textContent || '';
                post('content_changed', { 
                  html: html, 
                  text: text,
                  isEmpty: text.trim() === '' || html === '<p><br></p>',
                  wordCount: text.split(/\\s+/).filter(w => w.length > 0).length
                });
              },
              
              
              'focus': function() {
                if (lastFocused === true) return;
                lastFocused = true;
                post('focus_changed', { focused: true });
              },
              
              'blur': function() {
                if (lastFocused === false) return;
                lastFocused = false;
                post('focus_changed', { focused: false });
              },
              
                'focus': function () {
    post('froala_focus_in');
  },
  'mousedown': function () {
    // mouse ile içeriğe tıklandığında da tetikle
    post('froala_focus_in');
  },
  'touchstart': function () {
    // mobil/surface için
    post('froala_focus_in');
  },

              'paste.before': function(e) {
                var clipboardData = null;
                
                try {
                  if (e && e.originalEvent && e.originalEvent.clipboardData) {
                    clipboardData = e.originalEvent.clipboardData;
                  } else if (e && e.clipboardData) {
                    clipboardData = e.clipboardData;
                  } else if (window.event && window.event.clipboardData) {
                    clipboardData = window.event.clipboardData;
                  }
                  
                  if (!clipboardData) {
                    console.log('No clipboard data found, allowing paste');
                    return true;
                  }
                  
                  var allowedTypes = ['text/plain', 'text/html', 'image/png', 'image/jpeg', 'image/gif'];
                  var hasValidType = false;
                  
                  if (clipboardData.items && clipboardData.items.length) {
                    for (let i = 0; i < clipboardData.items.length; i++) {
                      const item = clipboardData.items[i];
                      if (item && item.type) {
                        if (allowedTypes.includes(item.type)) {
                          hasValidType = true;
                          break;
                        }
                      }
                    }
                  } else if (clipboardData.types && clipboardData.types.length) {
                    for (let i = 0; i < clipboardData.types.length; i++) {
                      const type = clipboardData.types[i];
                      if (allowedTypes.includes(type)) {
                        hasValidType = true;
                        break;
                      }
                    }
                  } else {
                    console.log('Cannot determine clipboard types, allowing paste for Excel compatibility');
                    return true;
                  }
                  
                  if (!hasValidType) {
                    console.log('Blocked paste - no valid content types found');
                    e.preventDefault();
                    
                    post('paste_blocked', { 
                      message: 'Bu içerik türü desteklenmiyor. Sadece metin ve resim yapıştırabilirsiniz.'
                    });
                    
                    return false;
                  }
                  
                  return true;
                  
                } catch (err) {
                  console.warn('Paste validation error:', err);
                  return true;
                }
              },

              'paste.after': function () {
                // SCROLL FIX: yapıştırmada caret genelde altta kalır
                setTimeout(() => scrollCaretIntoView(this), 0);
              },

              'image.beforeUpload': function(images) {
                console.log('Blocking Froala image upload, using unified system instead');
                return false;
              },

              'image.inserted': function () {
                // SCROLL FIX: görsel eklenince içerik yüksekliği artar
                setTimeout(() => scrollCaretIntoView(this), 0);
              },
              
              'dragenter': function(e) {
                console.log('Froala dragenter - allowing bubble');
                e.stopPropagation();
              },
              
              'dragover': function(e) {
                console.log('Froala dragover - allowing bubble');
                e.stopPropagation();
              },
              
              'dragleave': function(e) {
                console.log('Froala dragleave - allowing bubble');
                e.stopPropagation();
                setTimeout(function() {
                  var dragHelpers = document.querySelectorAll('.fr-drag-helper');
                  var removedCount = 0;
                  dragHelpers.forEach(function(helper) {
                    helper.style.display = 'none';
                    helper.style.opacity = '0';
                    helper.style.visibility = 'hidden';
                    helper.remove();
                    removedCount++;
                  });
                  if (removedCount > 0) {
                    console.log('Cleaned up orphaned drag helper, count:', removedCount);
                  }
                }, 100);
              },
              
              'drop': function(e) {
                console.log('Froala drop - deferring to unified system');
                setTimeout(function() {
                  var dragHelpers = document.querySelectorAll('.fr-drag-helper');
                  var removedCount = 0;
                  dragHelpers.forEach(function(helper) {
                    helper.style.display = 'none';
                    helper.style.opacity = '0';
                    helper.style.visibility = 'hidden';
                    helper.remove();
                    removedCount++;
                  });
                  if (removedCount > 0) {
                    console.log('Cleaned up drag helper after drop, count:', removedCount);
                  }
                }, 50);
                return false;
              }
            }
          });
          
          console.log('Froala setup complete with enhanced coordination');
          
        } catch(err) {
          console.error('Froala initialization error:', err);
          post('froala_error', { 
            error: 'Froala init failed', 
            details: (err && err.message) ? err.message : String(err) 
          });
        }
      });

      window.addEventListener('load', notifyReady);
    })();
  </script>
</body>
</html>
''';
  }

  @override
  Widget build(BuildContext context) {
    final editorState = ref.watch(froalaEditorProvider);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Stack(
          children: [
SizedBox.expand(
  child: FocusableActionDetector(
    focusNode: FocusNode(skipTraversal: true, canRequestFocus: false),
    child: HtmlElementView(viewType: _viewType),
  ),
),            
            if (!editorState.isReady)
              Container(
                color: Colors.white,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (editorState.error == null) ...[
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        const Text(
                          'Froala Editor yükleniyor...',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ] else ...[
                        const Icon(Icons.error_outline, color: Colors.red, size: 48),
                        const SizedBox(height: 16),
                        Text(
                          'Hata: ${editorState.error}',
                          style: const TextStyle(color: Colors.red, fontSize: 14),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}