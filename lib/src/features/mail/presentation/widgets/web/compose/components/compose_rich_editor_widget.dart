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
/// **NEW: Added insertImage() method for unified file handling**
class ComposeRichEditorWidget extends ConsumerStatefulWidget {
  final String? initialContent;
  final Function(String html, String text)? onContentChanged;
  final VoidCallback? onSendShortcut;
  final Function(String base64, String name, int size)? onImagePasted;
  final double height;

  const ComposeRichEditorWidget({
    super.key,
    this.initialContent,
    this.onContentChanged,
    this.onSendShortcut,
    this.onImagePasted,
    this.height = 300,
  });

  @override
  ConsumerState<ComposeRichEditorWidget> createState() => ComposeRichEditorWidgetState();
}

class ComposeRichEditorWidgetState extends ConsumerState<ComposeRichEditorWidget> {
  late final String _viewType;
  late final String _channelId;

  web.HTMLIFrameElement? _iframe;
  StreamController<void>? _eventController;
  Timer? _readyTimeout;
  String? _blobUrl;
  bool _isDisposed = false; // Dispose tracking
  bool _listenersSetup = false;

  @override
  void initState() {
    super.initState();
    _viewType = 'froala-editor-${DateTime.now().millisecondsSinceEpoch}';
    _channelId = 'chan_${DateTime.now().microsecondsSinceEpoch}_${Object().hashCode}';
    _registerView();
  }

  @override
  void dispose() {
    _isDisposed = true; // İLK ÖNCE bu flag'i set et
    _readyTimeout?.cancel();
    _cleanupEventListeners();
    ref.read(froalaEditorProvider.notifier).reset();
    try {
      _iframe?.src = 'about:blank';
    } catch (_) {}
    // blob URL'i revoke et
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
      
      // blob: URL kullan (çalışan yaklaşım)
      final blobParts = [htmlString.toJS].toJS;
      final blob = web.Blob(blobParts, web.BlobPropertyBag(type: 'text/html'));
      _blobUrl = web.URL.createObjectURL(blob);
      
      _iframe = web.HTMLIFrameElement()
        ..src = _blobUrl!
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%'
        ..allow = 'clipboard-read; clipboard-write';

      _setupEventListeners();

      // Timeout protection
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

  /// Setup modern event listeners
  void _setupEventListeners() {
    if (!kIsWeb || _listenersSetup) return;
    
    try {
      _eventController = StreamController<void>();
      
      // Channel-based message listener with modern web API
      web.window.addEventListener('message', (web.Event event) {
        final messageEvent = event as web.MessageEvent;
        final payload = _normalizeMessage(messageEvent.data);
        if (payload == null) return;
        if (payload['channelId'] != _channelId) return;

        _handleChannelMessage(payload);
      }.toJS);
      
      _listenersSetup = true;
    } catch (e) {
      debugPrint('❌ Failed to setup event listeners: $e');
    }
  }

  /// Cleanup event listeners
  void _cleanupEventListeners() {
    if (!kIsWeb || !_listenersSetup) return;
    
    try {
      _eventController?.close();
      _listenersSetup = false;
    } catch (e) {
      debugPrint('❌ Failed to cleanup event listeners: $e');
    }
  }

  /// Handle all channel messages
  void _handleChannelMessage(Map<String, dynamic> payload) {
    if (_isDisposed) return; // Kritik ilk kontrol
    
    final type = payload['type'] as String?;
    
    switch (type) {
      case 'froala_ready':
        if (payload['ready'] == true) {
          debugPrint('✅ Froala ready via channel!');
          _readyTimeout?.cancel();
          if (!_isDisposed && mounted) {
            ref.read(froalaEditorProvider.notifier).onEditorReady();
            
            // Set initial content if provided
            if (widget.initialContent != null && widget.initialContent!.isNotEmpty) {
              _setEditorContent(widget.initialContent!);
            }
          }
        }
        break;
        
      case 'froala_error':
        debugPrint('❌ Froala error: ${payload['error']}');
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
        
        // Update mail compose provider
        ref.read(mailComposeProvider.notifier).updateHtmlContent(
          isEmpty ? null : htmlContent,
        );
        ref.read(mailComposeProvider.notifier).updateTextContent(textContent);
        
        // Update froala provider
        ref.read(froalaEditorProvider.notifier).updateContent(
          htmlContent: htmlContent,
          textContent: textContent,
          isEmpty: isEmpty,
          wordCount: wordCount,
        );
        
        // Notify parent callback
        widget.onContentChanged?.call(htmlContent, textContent);
        
        debugPrint('📝 Content updated: $wordCount words');
        break;
        
      case 'send_shortcut':
        if (!_isDisposed && mounted) {
          widget.onSendShortcut?.call();
          debugPrint('⚡ Send shortcut triggered');
        }
        break;
        
      case 'image_pasted':
        if (_isDisposed) return;
        
        final base64 = payload['base64'] as String? ?? '';
        final name = payload['name'] as String? ?? 'image.png';
        final size = payload['size'] as int? ?? 0;
        
        // Update froala provider
        ref.read(froalaEditorProvider.notifier).onImagePasted(
          base64: base64,
          name: name,
          size: size,
        );
        
        // Notify parent callback
        widget.onImagePasted?.call(base64, name, size);
        
        debugPrint('🖼️ Image pasted: $name ($size bytes)');
        break;

      // 🎯 NEW: Handle image insertion confirmation
      case 'image_inserted':
        if (_isDisposed) return;
        
        final name = payload['name'] as String? ?? 'image';
        final size = payload['size'] as int? ?? 0;
        
        debugPrint('✅ Image inserted successfully: $name (${_formatFileSize(size)})');
        break;

      case 'paste_blocked':
        if (!_isDisposed && mounted) {
          // Snackbar veya dialog göster
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(payload['message'] ?? 'İzin verilmeyen içerik türü'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        break;        
        
      // 🎯 NEW: Handle files dropped directly in iframe
      case 'files_dropped_in_iframe':
        if (_isDisposed) return;
        
        final files = payload['files'] as List?;
        if (files != null && files.isNotEmpty) {
          debugPrint('🎯 IFRAME FILES: ${files.length} files received');
          
          // Convert to web.File objects and forward to wrapper
          final webFiles = <web.File>[];
          for (final fileData in files) {
            final name = fileData['name'] as String;
            final type = fileData['type'] as String;
            final size = fileData['size'] as int;
            final base64 = fileData['base64'] as String;
            
            // Create a mock web.File for unified processing
            // Note: This is a simplified approach - in production you'd want proper File objects
            debugPrint('🎯 Processing iframe file: $name ($type, $size bytes)');
          }
          
          // For now, just trigger the unified file handler manually
          // TODO: Create proper web.File objects from base64 data
        }
        break;

      case 'focus_changed':
        final focused = payload['focused'] as bool? ?? false;
        // MicroTask ile provider'ı güncelle - dispose ile yarışmayı önle
        scheduleMicrotask(() {
          if (_isDisposed || !mounted) return;
          ref.read(froalaEditorProvider.notifier).updateFocus(focused);
        });
        break;
    }
  }

  /// Message normalization
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

  // ========== EDITOR CONTROL METHODS ==========

  /// Set content in editor
  void _setEditorContent(String htmlContent) {
    if (_iframe?.contentWindow != null) {
      _iframe!.contentWindow!.postMessage(jsonEncode({
        'type': 'froala_command',
        'command': 'setContent',
        'data': htmlContent,
        'channelId': _channelId,
      }).toJS, '*'.toJS);
    }
  }

  /// Insert text at current cursor position
  void insertText(String text) {
    if (_iframe?.contentWindow != null) {
      _iframe!.contentWindow!.postMessage(jsonEncode({
        'type': 'froala_command',
        'command': 'insertText',
        'data': text,
        'channelId': _channelId,
      }).toJS, '*'.toJS);
    }
  }

  /// 🎯 NEW: Insert image directly into editor
  void insertImage({
    required String base64,
    required String name,
    required int size,
  }) {
    if (_iframe?.contentWindow != null) {
      _iframe!.contentWindow!.postMessage(jsonEncode({
        'type': 'froala_command',
        'command': 'insertImage',
        'data': {
          'base64': base64,
          'name': name,
          'size': size,
        },
        'channelId': _channelId,
      }).toJS, '*'.toJS);
      
      debugPrint('🖼️ Inserting image: $name (${_formatFileSize(size)})');
    }
  }

  /// Insert signature
  void insertSignature(String signatureHtml) {
    if (_iframe?.contentWindow != null) {
      _iframe!.contentWindow!.postMessage(jsonEncode({
        'type': 'froala_command',
        'command': 'insertSignature',
        'data': signatureHtml,
        'channelId': _channelId,
      }).toJS, '*'.toJS);
    }
  }

  /// Focus editor
  void focusEditor() {
    if (_iframe?.contentWindow != null) {
      _iframe!.contentWindow!.postMessage(jsonEncode({
        'type': 'froala_command',
        'command': 'focus',
        'channelId': _channelId,
      }).toJS, '*'.toJS);
    }
  }

  /// Clear editor content
  void clearContent() {
    if (_iframe?.contentWindow != null) {
      _iframe!.contentWindow!.postMessage(jsonEncode({
        'type': 'froala_command',
        'command': 'clearContent',
        'channelId': _channelId,
      }).toJS, '*'.toJS);
    }
  }

  /// 🎯 NEW: Format file size helper
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  /// Complete HTML with all features
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
    html,body{margin:0;height:100%;font-family:system-ui}
    #editor{min-height:200px;padding:16px}
    .fr-wrapper{border:none !important}
    .fr-element{padding:16px !important;min-height:150px !important;font-size:14px !important;line-height:1.5 !important}
    .fr-toolbar{border-bottom:1px solid #e0e0e0 !important;background:#fafafa !important}
    .fr-placeholder{color:#9e9e9e !important;font-style:normal !important}
  </style>
</head>
<body>
  <div id="editor">Froala yükleniyor...</div>

  <script>
    (function(){
      var CHANNEL = ${jsonEncode(channelId)};
      var editor;
      var isReady = false;
      var lastFocused = null; // Focus flood önleme
      
      function post(type, extra){
        var msg = Object.assign({ type: type, channelId: CHANNEL }, extra || {});
        try { 
          console.log('📤 Posting message:', msg);
          parent.postMessage(JSON.stringify(msg), '*'); 
        } catch (e) {
          console.error('❌ Failed to post message:', e);
        }
      }

      // Froala script yükleme
      function loadFroalaScript() {
        return new Promise((resolve, reject) => {
          const script = document.createElement('script');
          script.src = 'https://cdn.jsdelivr.net/npm/froala-editor@latest/js/froala_editor.pkgd.min.js';
          script.onload = () => {
            console.log('✅ Froala script loaded successfully');
            resolve(true);
          };
          script.onerror = (error) => {
            console.error('❌ Froala script failed to load:', error);
            reject(error);
          };
          document.head.appendChild(script);
        });
      }

      // Flutter command listener
      window.addEventListener('message', function(event) {
        if (!event.data || typeof event.data !== 'string') return;
        
        try {
          const data = JSON.parse(event.data);
          if (data.type !== 'froala_command' || data.channelId !== CHANNEL) return;
          
          const command = data.command;
          const payload = data.data;
          
          if (!editor || !isReady) return;
          
          switch (command) {
            case 'setContent':
              editor.html.set(payload || '');
              break;
            case 'insertText':
              editor.html.insert(payload || '');
              break;
            case 'insertSignature':
              const currentContent = editor.html.get();
              const newContent = currentContent + '<br><br>' + (payload || '');
              editor.html.set(newContent);
              break;
            case 'insertImage':
              // 🎯 NEW: Handle image insertion from unified file handler
              if (payload && payload.base64) {
                try {
                  editor.image.insert(payload.base64, null, null, editor.image.get());
                  
                  // Notify Flutter that image was inserted
                  post('image_inserted', {
                    name: payload.name || 'image',
                    size: payload.size || 0
                  });
                  
                  console.log('✅ Image inserted:', payload.name);
                } catch (err) {
                  console.error('❌ Failed to insert image:', err);
                }
              }
              break;
            case 'focus':
              editor.events.focus();
              break;
            case 'clearContent':
              editor.html.set('');
              break;
          }
        } catch (e) {
          console.warn('⚠️ Error handling Flutter command:', e);
        }
      });

      // 🎯 NEW: Override document drag&drop events to capture files
      function setupUnifiedDropHandlers() {
        console.log('🎯 Setting up unified drop handlers in iframe');
        
        // Override ALL drag&drop events in iframe
        document.addEventListener('dragenter', function(e) {
          console.log('🎯 IFRAME: dragenter');
          // Don't prevent - let Flutter handle it
        }, true);
        
        document.addEventListener('dragover', function(e) {
          console.log('🎯 IFRAME: dragover');
          if (e.dataTransfer && e.dataTransfer.types.includes('Files')) {
            e.preventDefault(); // Allow drop
            e.dataTransfer.dropEffect = 'copy';
          }
        }, true);
        
        document.addEventListener('drop', function(e) {
          console.log('🎯 IFRAME: DROP EVENT!');
          if (e.dataTransfer && e.dataTransfer.files.length > 0) {
            e.preventDefault();
            e.stopPropagation();
            e.stopImmediatePropagation();
            
            console.log('🎯 IFRAME: Processing', e.dataTransfer.files.length, 'files');
            
            // Send files to Flutter via postMessage
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
                
                // Send when all files are processed
                if (fileData.length === files.length) {
                  post('files_dropped_in_iframe', {
                    files: fileData,
                    source: 'iframe_drop'
                  });
                }
              };
              reader.readAsDataURL(file);
            });
          }
        }, true);
      }

      document.addEventListener('DOMContentLoaded', async function(){
        console.log('📄 DOM ready, channel:', CHANNEL);
        
        try {
          console.log('🔄 Loading Froala script...');
          await loadFroalaScript();
          
          if (typeof FroalaEditor === 'undefined') {
            throw new Error('FroalaEditor still not found after script load');
          }
          
          console.log('✅ FroalaEditor found, version:', FroalaEditor.VERSION || 'unknown');
          console.log('🔧 Creating Froala editor...');
          
          // 🎯 Setup unified drop handlers BEFORE Froala init
          setupUnifiedDropHandlers();
          
          editor = new FroalaEditor('#editor', {
            height: 200,
            placeholderText: 'Mesajınızı yazın...',
            theme: 'gray',
            charCounterCount: false,
            
            // Email-optimized toolbar
            toolbarButtons: {
              'moreText': {
                'buttons': ['bold', 'italic', 'underline', 'strikeThrough', 'fontSize', 'textColor', 'backgroundColor', 'clearFormatting']
              },
              'moreParagraph': {
                'buttons': ['alignLeft', 'alignCenter', 'alignRight', 'formatOLSimple', 'formatUL', 'outdent', 'indent', 'quote']
              },
              'moreRich': {
                'buttons': ['insertLink', 'insertImage', 'insertTable', 'insertHR']
              },
              'moreMisc': {
                'buttons': ['undo', 'redo', 'fullscreen', 'html']
              }
            },
            
            // Mobile toolbar
            toolbarButtonsXS: ['bold', 'italic', 'underline', 'insertLink', 'undo', 'redo'],
            
            // Paste settings
            pastePlain: false,
            pasteDeniedTags: ['script', 'style', 'meta', 'link', 'form', 'input', 'button', 'iframe', 'object', 'embed'],
            pasteDeniedAttrs: ['onload', 'onclick', 'onmouseover', 'onfocus', 'onblur', 'onchange', 'onsubmit'],
            
            // Image settings
            imageUpload: false,
            imageInsertButtons: ['imageByURL'],
            imageResizeWithPercent: true,
            
            // 🎯 NEW: Disable Froala's own drag&drop to prevent conflicts
            dragInline: false,
            
            // Link settings
            linkAlwaysBlank: true,
            
            events: {
              'initialized': function () { 
                console.log('✅ Froala initialized event!');
                isReady = true;
                post('froala_ready', { ready: true });
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
                if (lastFocused === true) return; // Aynı durumsa skip
                lastFocused = true;
                post('focus_changed', { focused: true });
              },
              
              'blur': function() {
                if (lastFocused === false) return; // Aynı durumsa skip
                lastFocused = false;
                post('focus_changed', { focused: false });
              },
              
              'keydown': function(e) {
                if ((e.ctrlKey || e.metaKey) && e.key === 'Enter') {
                  e.preventDefault();
                  post('send_shortcut');
                }
              },
              
              'paste.before': function(e) {
                console.log('PASTE BEFORE OLAYI ÇALIŞTI');
                const clipboardData = e.originalEvent.clipboardData;
                if (!clipboardData) return true;
                
                // İzin verilen MIME türleri
                const allowedTypes = ['text/plain', 'text/html', 'image/png', 'image/jpeg', 'image/gif'];
                
                for (let i = 0; i < clipboardData.items.length; i++) {
                  const item = clipboardData.items[i];
                  if (!allowedTypes.includes(item.type)) {
                    console.log('🚫 Blocked paste type:', item.type);
                    e.preventDefault();
                    
                    // Kullanıcıya bilgi ver
                    post('paste_blocked', { 
                      blockedType: item.type,
                      message: 'Bu içerik türü desteklenmiyor. Sadece metin ve resim yapıştırabilirsiniz.'
                    });
                    
                    return false;
                  }
                }
                
                return true;
              },              
              'image.beforeUpload': function(images) {
                // Block ALL Froala image uploads - we handle them via unified system
                console.log('🚫 Blocking Froala image upload, using unified system instead');
                return false;
              },
              
              // 🎯 NEW: Block Froala's own drag&drop events  
              'dragenter': function(e) {
                console.log('🚫 Blocking Froala dragenter');
                return false;
              },
              
              'dragover': function(e) {
                console.log('🚫 Blocking Froala dragover');
                return false;
              },
              
              'drop': function(e) {
                console.log('🚫 Blocking Froala drop');
                return false;
              }
            }
          });
          
          console.log('🎉 Froala setup complete');
          
        } catch(err) {
          console.error('❌ Froala initialization error:', err);
          post('froala_error', { 
            error: 'Froala init failed', 
            details: (err && err.message) ? err.message : String(err) 
          });
        }
      });
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
      height: widget.height,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Stack(
        children: [
          HtmlElementView(viewType: _viewType),

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
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ] else ...[
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Hata: ${editorState.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}