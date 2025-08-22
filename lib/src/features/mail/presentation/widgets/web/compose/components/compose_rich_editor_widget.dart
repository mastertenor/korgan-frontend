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
import 'froala_message_handler.dart';
import 'froala_html_generator.dart';

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
  late final FroalaMessageHandler _messageHandler;

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
    _messageHandler = FroalaMessageHandler(
      channelId: _channelId,
      ref: ref,
      widget: widget,
      context: context,
      onIframeReady: _onIframeReady,
      onPostToIframe: _postToIframe,
    );
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
      final htmlString = FroalaHtmlGenerator.getCompleteHTML(channelId: _channelId);
      
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
        final payload = _messageHandler.normalizeMessage(messageEvent.data);
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

        _messageHandler.handleChannelMessage(payload);
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

  void _onIframeReady() {
    _iframeReady = true;
    _flushQueue();
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