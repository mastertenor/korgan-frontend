// lib/src/features/mail/presentation/pages/test/yandex_unified_mail_editor.dart
// Phase 1: Constructor refactored to use real mail data instead of test data

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../../../domain/entities/mail_detail.dart';

class YandexUnifiedMailEditor extends StatefulWidget {
  /// Mail detail data to compose reply for
  final MailDetail mailDetail;

  /// Current user's email address
  final String currentUserEmail;

  const YandexUnifiedMailEditor({
    super.key,
    required this.mailDetail,
    required this.currentUserEmail,
  });

  @override
  State<YandexUnifiedMailEditor> createState() =>
      _YandexUnifiedMailEditorState();
}

class _YandexUnifiedMailEditorState extends State<YandexUnifiedMailEditor> {
  // Controllers and state
  InAppWebViewController? _webViewController;
  Timer? _debounceTimer;

  // Mail data state - initialized from constructor
  String composeContent = '';
  String toField = '';
  String ccField = '';
  String bccField = '';
  String subjectField = '';
  String fromField = '';
  String originalHtmlContent = '';
  bool isOriginalExpanded = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeWithMailData();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  /// Initialize editor with real mail data from constructor
  void _initializeWithMailData() {
    debugPrint('🚀 Initializing editor with mail data...');
    debugPrint('📧 Original subject: ${widget.mailDetail.subject}');
    debugPrint('📧 Original sender: ${widget.mailDetail.senderName}');
    debugPrint('📧 Current user: ${widget.currentUserEmail}');

    setState(() {
      // Reply field setup
      toField = widget.mailDetail.senderEmail;
      fromField = widget.currentUserEmail;
      subjectField = _buildReplySubject(widget.mailDetail.subject);

      // CC field - include other original recipients if needed
      ccField = _buildCcField();

      // BCC field - empty for new reply
      bccField = '';

      // Original content processing
      originalHtmlContent = _getOriginalHtmlContent();

      // Clear compose content for new reply
      composeContent = '';

      // Mark as loaded
      isLoading = false;
    });

    debugPrint('✅ Mail data initialized successfully');
    debugPrint('📧 Reply to: $toField');
    debugPrint('📧 Reply subject: $subjectField');
    debugPrint(
      '📧 Original content length: ${originalHtmlContent.length} chars',
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loading Reply...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final headerHeight = 56 + MediaQuery.of(context).padding.top;

    // 🎯 STACK SOLUTION: WebView positioned below header to prevent gesture conflicts
    return Scaffold(
      body: Stack(
        children: [
          // WebView positioned BELOW header - completely isolated from header gestures
          Positioned(
            top: headerHeight,
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildYandexUnifiedEditor(),
          ),

          // Header positioned ON TOP - WebView cannot interfere with header buttons
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: headerHeight,
            child: _buildFixedHeader(),
          ),
        ],
      ),
    );
  }

  /// Fixed header with STACK SOLUTION - no extra protection layers needed
  Widget _buildFixedHeader() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // ❌ Close button
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  debugPrint('🔴 Close reply editor');
                  HapticFeedback.lightImpact();
                  Navigator.of(context).pop();
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  child: const Icon(Icons.close, size: 24),
                ),
              ),
            ),

            const Spacer(),

            // Reply indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200, width: 0.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.reply, size: 16, color: Colors.blue),
                  const SizedBox(width: 4),
                  Text(
                    'Yanıtla',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // 📎 Attach file button
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  debugPrint('📎 Attach file button pressed');
                  _onAttachFile();
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  child: const Icon(Icons.attach_file, size: 24),
                ),
              ),
            ),

            // ✈️ Send button
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _canSend()
                    ? () {
                        debugPrint('✈️ Send reply button pressed');
                        _onSend();
                      }
                    : null,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.send,
                    size: 24,
                    color: _canSend() ? Colors.blue : Colors.grey,
                  ),
                ),
              ),
            ),

            // ⋯ More menu
            PopupMenuButton<String>(
              onSelected: (value) {
                debugPrint('⋯ Menu item selected: $value');
                _onMenuAction(value);
              },
              icon: const Icon(Icons.more_vert, size: 24),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'save_draft',
                  child: Row(
                    children: [
                      Icon(Icons.save, size: 18),
                      SizedBox(width: 8),
                      Text('Save draft'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'discard',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Discard', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'view_original',
                  child: Row(
                    children: [
                      Icon(Icons.visibility, size: 18, color: Colors.green),
                      SizedBox(width: 8),
                      Text(
                        'View Original',
                        style: TextStyle(color: Colors.green),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Yandex-style Unified Editor with real mail data
  Widget _buildYandexUnifiedEditor() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: InAppWebView(
        initialData: InAppWebViewInitialData(
          data: _buildYandexUnifiedHtml(),
          mimeType: "text/html",
          encoding: "utf-8",
        ),

        // Clean settings - no complex gesture handling needed
        initialSettings: InAppWebViewSettings(
          javaScriptEnabled: true,
          domStorageEnabled: false,
          verticalScrollBarEnabled: true,
          horizontalScrollBarEnabled: false,
          supportZoom: false,
          transparentBackground: false,
          useHybridComposition: true,
          allowsInlineMediaPlayback: true,
          allowFileAccess: false,
          allowContentAccess: false,
          allowsBackForwardNavigationGestures: false,
        ),

        onWebViewCreated: (controller) {
          _webViewController = controller;
          _setupJavaScriptBridge(controller);
          debugPrint('🚀 WebView created for reply editor');
        },

        onLoadStop: (controller, url) {
          debugPrint('✅ Reply editor loaded successfully!');

          // Initialize editor
          controller.evaluateJavascript(
            source: '''
            setTimeout(function() {
              initializeYandexEditor();
            }, 100);
          ''',
          );
        },

        onConsoleMessage: (controller, consoleMessage) {
          debugPrint('📝 WebView Console: ${consoleMessage.message}');
        },
      ),
    );
  }

  /// Build Yandex-style unified HTML - with real mail data
  String _buildYandexUnifiedHtml() {
    return '''
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no">
        
        <style>
            * {
                box-sizing: border-box;
            }
            
            body {
                margin: 0;
                padding: 0;
                font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                background-color: #fff;
                font-size: 16px;
                line-height: 1.5;
                min-height: 100vh;
                overflow-x: hidden;
                overflow-y: auto;
            }
            
            /* YANDEX UNIFIED EDITOR - Single contentEditable for ALL fields */
            #yandex-unified-composer {
                padding: 16px;
                outline: none;
                cursor: text;
                min-height: calc(100vh - 32px);
                -webkit-user-select: text;
                user-select: text;
            }
            
            /* Recipients section styling */
            .recipients-section {
                border-bottom: 1px solid #e0e0e0;
                padding-bottom: 16px;
                margin-bottom: 16px;
            }
            
            .field-row {
                display: flex;
                align-items: center;
                min-height: 36px;
                padding: 4px 0;
                border-bottom: 1px solid #f0f0f0;
            }
            
            .field-row:last-child {
                border-bottom: none;
            }
            
            /* Protected label styling - Cannot be deleted */
            .field-label {
                min-width: 80px;
                color: #666;
                font-size: 14px;
                font-weight: 500;
                padding-right: 8px;
                flex-shrink: 0;
                -webkit-user-select: none;
                user-select: none;
                pointer-events: none;
                contenteditable: false;
            }
            
            .field-input {
                flex: 1;
                outline: none;
                border: none;
                background: transparent;
                font-size: 16px;
                color: #333;
                -webkit-user-select: text;
                user-select: text;
                contenteditable: true;
            }
            
            .field-input:empty:before {
                content: attr(data-placeholder);
                color: #999;
                font-style: italic;
                pointer-events: none;
            }
            
            .field-input:focus {
                background-color: #f8f9fa;
                border-radius: 4px;
                padding: 2px 4px;
                margin: -2px -4px;
            }
            
            /* Expand toggle button for recipients */
            .recipients-toggle {
                width: 24px;
                height: 24px;
                border: none;
                background: transparent;
                cursor: pointer;
                display: flex;
                align-items: center;
                justify-content: center;
                border-radius: 4px;
                margin-left: 8px;
                transition: background-color 0.2s, transform 0.3s ease;
                flex-shrink: 0;
                -webkit-user-select: none;
                user-select: none;
                contenteditable: false;
            }
            
            .recipients-toggle:hover {
                background-color: #f0f0f0;
            }
            
            .recipients-toggle.expanded {
                transform: rotate(180deg);
            }
            
            .toggle-icon {
                font-size: 16px;
                color: #666;
                pointer-events: none;
            }
            
            /* Expandable recipients section */
            .expandable-recipients {
                max-height: 0;
                overflow: hidden;
                transition: max-height 0.3s cubic-bezier(0.4, 0, 0.2, 1);
            }
            
            .expandable-recipients.expanded {
                max-height: 200px;
            }
            
            /* Special styling for different fields */
            .field-input[data-field="to"] {
                color: #1976d2;
                font-weight: 500;
            }
            
            .field-input[data-field="subject"] {
                font-weight: 600;
            }
            
            .field-input[data-field="from"] {
                color: #666;
                font-size: 14px;
            }
            
            /* Compose area styling */
            .compose-area {
                min-height: 120px;
                margin-bottom: 20px;
                font-size: 16px;
                line-height: 1.5;
            }
            
            .compose-area:empty:before {
                content: "Mesajınızı yazın...";
                color: #999;
                font-style: italic;
                pointer-events: none;
            }
            
            /* Quote toggle button */
            .quote-toggle {
                margin: 20px 0 10px 0;
                padding: 12px 0;
                cursor: pointer;
                color: #1976d2;
                display: flex;
                align-items: center;
                font-size: 14px;
                border-radius: 4px;
                transition: background-color 0.2s;
            }
            
            .quote-toggle:hover {
                background-color: #f5f5f5;
            }
            
            .quote-icon {
                margin-right: 8px;
                transition: transform 0.3s ease;
                font-size: 16px;
            }
            
            .quote-icon.expanded {
                transform: rotate(180deg);
            }
            
            /* Original message quote styling */
            .original-quote {
                border-left: 4px solid #e0e0e0;
                padding-left: 16px;
                margin: 16px 0;
                background-color: #f8f9fa;
                border-radius: 0 8px 8px 0;
                max-height: 0;
                overflow: hidden;
                transition: max-height 0.4s cubic-bezier(0.4, 0, 0.2, 1), 
                           padding 0.4s ease,
                           margin 0.4s ease;
                padding-top: 0;
                padding-bottom: 0;
                margin-top: 0;
                margin-bottom: 0;
            }
            
            .original-quote.expanded {
                max-height: 5000px;
                padding-top: 16px;
                padding-bottom: 16px;
                margin-top: 16px;
                margin-bottom: 16px;
            }
            
            /* Mobile optimizations */
            @media (max-width: 768px) {
                #yandex-unified-composer {
                    padding: 12px;
                }
                
                .field-label {
                    min-width: 60px;
                    font-size: 13px;
                }
                
                .field-input {
                    font-size: 15px;
                }
            }
        </style>
    </head>
    <body>
        
        <!-- YANDEX UNIFIED COMPOSER - Single contentEditable with REAL MAIL DATA -->
        <div id="yandex-unified-composer" contenteditable="true">
            
            <!-- PROTECTED Recipients Section -->
            <div class="recipients-section" contenteditable="false">
                
                <!-- To field - populated with original sender -->
                <div class="field-row" contenteditable="false">
                    <div class="field-label" contenteditable="false">Alıcı:</div>
                    <div class="field-input" data-field="to" data-placeholder="Alıcı email adresi" contenteditable="true">$toField</div>
                    <button class="recipients-toggle" id="recipients-toggle" onclick="toggleRecipients()" contenteditable="false">
                        <span class="toggle-icon">▼</span>
                    </button>
                </div>
                
                <!-- Expandable recipients -->
                <div class="expandable-recipients" id="expandable-recipients" contenteditable="false">
                    
                    <!-- CC field -->
                    <div class="field-row" contenteditable="false">
                        <div class="field-label" contenteditable="false">Bilgi:</div>
                        <div class="field-input" data-field="cc" data-placeholder="CC email adresi" contenteditable="true">$ccField</div>
                    </div>
                    
                    <!-- BCC field -->
                    <div class="field-row" contenteditable="false">
                        <div class="field-label" contenteditable="false">Gizli kopya:</div>
                        <div class="field-input" data-field="bcc" data-placeholder="BCC email adresi" contenteditable="true">$bccField</div>
                    </div>
                    
                    <!-- From field - populated with current user -->
                    <div class="field-row" contenteditable="false">
                        <div class="field-label" contenteditable="false">Kimden:</div>
                        <div class="field-input" data-field="from" data-placeholder="Gönderen email" contenteditable="true">$fromField</div>
                    </div>
                    
                </div>
                
                <!-- Subject field - populated with Re: prefix -->
                <div class="field-row" contenteditable="false">
                    <div class="field-label" contenteditable="false">Konu:</div>
                    <div class="field-input" data-field="subject" data-placeholder="Email konusu" contenteditable="true">$subjectField</div>
                </div>
                
            </div>
            
            <!-- Compose Area -->
            <div class="compose-area" data-field="compose" contenteditable="true">
                <!-- User types reply message here -->
            </div>
            
        </div>
        
        <script>
            let isOriginalExpanded = false;
            let isRecipientsExpanded = false;
            let debounceTimer;
            let composer;
            
            function initializeYandexEditor() {
                console.log('🚀 Initializing Yandex reply editor with real mail data...');
                
                composer = document.getElementById('yandex-unified-composer');
                
                // Add quote toggle and original content
                insertOriginalContent();
                
                // Event listeners
                composer.addEventListener('input', onContentChange);
                composer.addEventListener('focus', onFocus, true);
                composer.addEventListener('blur', onBlur, true);
                composer.addEventListener('keydown', onKeyDown);
                
                // Focus on compose area initially
                focusOnCompose();
                
                console.log('✅ Yandex reply editor initialized successfully');
            }
            
            function toggleRecipients() {
                console.log('📧 Toggling recipients section...');
                
                const expandableSection = document.getElementById('expandable-recipients');
                const toggleButton = document.getElementById('recipients-toggle');
                
                isRecipientsExpanded = !isRecipientsExpanded;
                
                if (isRecipientsExpanded) {
                    expandableSection.classList.add('expanded');
                    toggleButton.classList.add('expanded');
                } else {
                    expandableSection.classList.remove('expanded');
                    toggleButton.classList.remove('expanded');
                }
                
                // Notify Flutter
                if (window.flutter_inappwebview) {
                    window.flutter_inappwebview.callHandler('onRecipientsToggle', isRecipientsExpanded);
                }
            }
            
            function insertOriginalContent() {
                const composeArea = composer.querySelector('.compose-area');
                
                // Create quote toggle
                const quoteToggle = document.createElement('div');
                quoteToggle.className = 'quote-toggle';
                quoteToggle.innerHTML = \`
                    <span class="quote-icon" id="quote-icon">▼</span>
                    <span id="quote-text">Orijinal mesajı göster</span>
                \`;
                quoteToggle.onclick = toggleOriginal;
                
                // Create original quote (hidden initially) - with REAL content
                const originalQuote = document.createElement('blockquote');
                originalQuote.className = 'original-quote';
                originalQuote.id = 'original-quote';
                originalQuote.innerHTML = \`$originalHtmlContent\`;
                
                // Insert after compose area
                composeArea.parentNode.insertBefore(quoteToggle, composeArea.nextSibling);
                composeArea.parentNode.insertBefore(originalQuote, quoteToggle.nextSibling);
            }
            
            function onContentChange(event) {
                clearTimeout(debounceTimer);
                debounceTimer = setTimeout(function() {
                    const data = extractAllFields();
                    
                    // Send to Flutter with 300ms debounce
                    if (window.flutter_inappwebview) {
                        window.flutter_inappwebview.callHandler('onFieldsChange', data);
                    }
                }, 300);
            }
            
            function extractAllFields() {
                const toField = composer.querySelector('[data-field="to"]').textContent.trim();
                const ccField = composer.querySelector('[data-field="cc"]').textContent.trim();
                const bccField = composer.querySelector('[data-field="bcc"]').textContent.trim();
                const fromField = composer.querySelector('[data-field="from"]').textContent.trim();
                const subjectField = composer.querySelector('[data-field="subject"]').textContent.trim();
                const composeArea = composer.querySelector('.compose-area');
                const composeContent = composeArea.textContent.trim();
                
                return {
                    to: toField,
                    cc: ccField,
                    bcc: bccField,
                    from: fromField,
                    subject: subjectField,
                    compose: composeContent,
                    canSend: toField.length > 0 && subjectField.length > 0
                };
            }
            
            function toggleOriginal() {
                const originalQuote = document.getElementById('original-quote');
                const quoteIcon = document.getElementById('quote-icon');
                const quoteText = document.getElementById('quote-text');
                
                isOriginalExpanded = !isOriginalExpanded;
                
                if (isOriginalExpanded) {
                    originalQuote.classList.add('expanded');
                    quoteIcon.classList.add('expanded');
                    quoteText.textContent = 'Orijinal mesajı gizle';
                } else {
                    originalQuote.classList.remove('expanded');
                    quoteIcon.classList.remove('expanded');
                    quoteText.textContent = 'Orijinal mesajı göster';
                }
                
                // Notify Flutter
                if (window.flutter_inappwebview) {
                    window.flutter_inappwebview.callHandler('onExpansionToggle', isOriginalExpanded);
                }
            }
            
            function onFocus(event) {
                const target = event.target;
                
                if (window.flutter_inappwebview) {
                    window.flutter_inappwebview.callHandler('onFocusChange', {
                        focused: true,
                        field: target.getAttribute('data-field') || 'unknown'
                    });
                }
            }
            
            function onBlur(event) {
                if (window.flutter_inappwebview) {
                    window.flutter_inappwebview.callHandler('onFocusChange', {
                        focused: false,
                        field: 'none'
                    });
                }
            }
            
            function onKeyDown(event) {
                // Handle Tab navigation between fields
                if (event.key === 'Tab') {
                    event.preventDefault();
                    navigateToNextField(event.target, !event.shiftKey);
                }
                
                // Handle Enter in specific fields
                if (event.key === 'Enter') {
                    const field = event.target.getAttribute('data-field');
                    if (field && field !== 'compose') {
                        event.preventDefault();
                        navigateToNextField(event.target, true);
                    }
                }
            }
            
            function navigateToNextField(currentElement, forward) {
                const visibleFields = getVisibleFields();
                
                let currentField = currentElement.getAttribute('data-field');
                if (!currentField) {
                    currentField = currentElement.closest('[data-field]')?.getAttribute('data-field');
                }
                
                const currentIndex = visibleFields.indexOf(currentField);
                let nextIndex;
                
                if (forward) {
                    nextIndex = (currentIndex + 1) % visibleFields.length;
                } else {
                    nextIndex = currentIndex === 0 ? visibleFields.length - 1 : currentIndex - 1;
                }
                
                const nextField = composer.querySelector(\`[data-field="\${visibleFields[nextIndex]}"]\`);
                if (nextField) {
                    nextField.focus();
                    
                    // Place cursor at end
                    const range = document.createRange();
                    const sel = window.getSelection();
                    range.selectNodeContents(nextField);
                    range.collapse(false);
                    sel.removeAllRanges();
                    sel.addRange(range);
                }
            }
            
            function getVisibleFields() {
                let fields = ['to'];
                
                if (isRecipientsExpanded) {
                    fields.push('cc', 'bcc', 'from');
                }
                
                fields.push('subject', 'compose');
                return fields;
            }
            
            function focusOnCompose() {
                const composeArea = composer.querySelector('.compose-area');
                composeArea.focus();
                
                // Place cursor at beginning
                const range = document.createRange();
                const sel = window.getSelection();
                range.setStart(composeArea, 0);
                range.collapse(true);
                sel.removeAllRanges();
                sel.addRange(range);
            }
            
            function getAllData() {
                return {
                    fields: extractAllFields(),
                    html: composer.innerHTML
                };
            }
            
            function setFieldContent(field, content) {
                const fieldElement = composer.querySelector(\`[data-field="\${field}"]\`);
                if (fieldElement) {
                    fieldElement.textContent = content;
                }
            }
        </script>
    </body>
    </html>
    ''';
  }

  // ========== MAIL DATA PROCESSING UTILITIES ==========

  /// Build reply subject with "Re:" prefix
  String _buildReplySubject(String originalSubject) {
    final cleanSubject = originalSubject.trim();

    // If already starts with "Re:" (case insensitive), don't add another
    if (cleanSubject.toLowerCase().startsWith('re:')) {
      return cleanSubject;
    }

    return 'Re: $cleanSubject';
  }

  /// Build CC field - include other original recipients if needed
  String _buildCcField() {
    // For now, keep CC empty in replies
    // In future, could include other original recipients
    return '';
  }

  /// Get original HTML content for quote
  String _getOriginalHtmlContent() {
    // Use HTML content if available, otherwise convert plain text
    if (widget.mailDetail.htmlContent.isNotEmpty) {
      return _sanitizeHtmlContent(widget.mailDetail.htmlContent);
    } else if (widget.mailDetail.textContent.isNotEmpty) {
      return _convertPlainTextToHtml(widget.mailDetail.textContent);
    } else {
      return _convertPlainTextToHtml(widget.mailDetail.content);
    }
  }

  /// Convert plain text to HTML format
  String _convertPlainTextToHtml(String plainText) {
    if (plainText.isEmpty) return '<p>İçerik bulunamadı.</p>';

    // Basic text to HTML conversion
    final htmlContent = plainText
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('\n\n', '</p><p>')
        .replaceAll('\n', '<br>')
        .replaceAll(
          RegExp(r'(https?://[^\s]+)'),
          '<a href="\$1" target="_blank">\$1</a>',
        );

    return '''
    <div style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; line-height: 1.6; color: #333; padding: 16px;">
      <p>$htmlContent</p>
    </div>
    ''';
  }

  /// Basic HTML content sanitization
  String _sanitizeHtmlContent(String htmlContent) {
    // Basic sanitization - remove script tags and dangerous attributes
    return htmlContent
        .replaceAll(
          RegExp(
            r'<script[^>]*>.*?</script>',
            caseSensitive: false,
            dotAll: true,
          ),
          '',
        )
        .replaceAll(RegExp(r'javascript:', caseSensitive: false), '')
        .replaceAll(RegExp(r'on\w+\s*=', caseSensitive: false), '');
  }

  /// Setup JavaScript bridge for communication
  void _setupJavaScriptBridge(InAppWebViewController controller) {
    // All fields change handler (debounced 300ms)
    controller.addJavaScriptHandler(
      handlerName: 'onFieldsChange',
      callback: (args) {
        if (args.isNotEmpty) {
          final data = args[0] as Map<String, dynamic>;
          setState(() {
            toField = data['to'] ?? '';
            ccField = data['cc'] ?? '';
            bccField = data['bcc'] ?? '';
            fromField = data['from'] ?? '';
            subjectField = data['subject'] ?? '';
            composeContent = data['compose'] ?? '';
          });

          debugPrint('📝 Reply fields updated:');
          debugPrint('  To: $toField');
          debugPrint('  CC: $ccField');
          debugPrint('  Subject: $subjectField');
          debugPrint(
            '  Compose: ${composeContent.length > 50 ? composeContent.substring(0, 50) + '...' : composeContent}',
          );
        }
      },
    );

    // Recipients expansion toggle handler
    controller.addJavaScriptHandler(
      handlerName: 'onRecipientsToggle',
      callback: (args) {
        if (args.isNotEmpty) {
          final isExpanded = args[0] as bool;
          debugPrint(
            '📧 Recipients section ${isExpanded ? "expanded" : "collapsed"}',
          );
        }
      },
    );

    // Expansion toggle handler (original message)
    controller.addJavaScriptHandler(
      handlerName: 'onExpansionToggle',
      callback: (args) {
        if (args.isNotEmpty) {
          setState(() {
            isOriginalExpanded = args[0] as bool;
          });
          debugPrint(
            '📧 Original message ${isOriginalExpanded ? "expanded" : "collapsed"}',
          );
        }
      },
    );

    // Focus change handler
    controller.addJavaScriptHandler(
      handlerName: 'onFocusChange',
      callback: (args) {
        if (args.isNotEmpty) {
          final data = args[0] as Map<String, dynamic>;
          debugPrint(
            '🎯 Focus changed - Field: ${data['field']}, Focused: ${data['focused']}',
          );
        }
      },
    );
  }

  // ========== ACTION HANDLERS ==========

  bool _canSend() {
    final canSend = toField.isNotEmpty && subjectField.isNotEmpty;
    debugPrint(
      '🔍 Can send check: to="${toField}" subject="${subjectField}" result=$canSend',
    );
    return canSend;
  }

  void _onAttachFile() {
    debugPrint('📎 ATTACH FILE - Reply mode');
    HapticFeedback.lightImpact();

    _showSnackBar('📎 Dosya ekleme özelliği yakında!', Colors.blue);
  }

  void _onSend() {
    debugPrint('🚀 SEND REPLY BUTTON');

    if (!_canSend()) {
      debugPrint('❌ Cannot send - missing required fields');
      _showSnackBar('Lütfen To ve Subject alanlarını doldurun', Colors.red);
      return;
    }

    debugPrint('✈️ SENDING REPLY TO: ${widget.mailDetail.senderName}');
    debugPrint('📧 Reply To: $toField');
    debugPrint('📧 Reply CC: $ccField');
    debugPrint('📧 Reply BCC: $bccField');
    debugPrint('📧 Reply From: $fromField');
    debugPrint('📧 Reply Subject: $subjectField');
    debugPrint('📧 Reply Content: $composeContent');
    debugPrint('📧 Original Mail ID: ${widget.mailDetail.id}');
    debugPrint('📧 Thread ID: ${widget.mailDetail.threadId}');

    // Force haptic feedback
    HapticFeedback.mediumImpact();

    // Get full data from WebView
    _webViewController
        ?.evaluateJavascript(source: 'getAllData()')
        .then((result) {
          debugPrint('📧 Full reply data: $result');

          // TODO: Implement actual send logic here
          // - Call API to send reply
          // - Include thread ID for conversation
          // - Handle attachments if any

          _showSnackBar('✈️ Yanıt başarıyla gönderildi!', Colors.green);

          // Show success dialog
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 8),
                  Text('✈️ Yanıt Gönderildi'),
                ],
              ),
              content: Text(
                'Yanıtınız ${widget.mailDetail.senderName} adresine başarıyla gönderildi.\n\n'
                'Konu: $subjectField',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    Navigator.pop(context); // Close editor
                  },
                  child: const Text('Tamam'),
                ),
              ],
            ),
          );
        })
        .catchError((error) {
          debugPrint('❌ Error getting WebView data: $error');
          _showSnackBar('Gönderim hatası', Colors.red);
        });
  }

  void _onMenuAction(String action) {
    debugPrint('⋯ MENU ACTION: $action');
    HapticFeedback.lightImpact();

    switch (action) {
      case 'save_draft':
        debugPrint('💾 Save draft - Reply mode');
        _showSnackBar('💾 Taslak kaydedildi', Colors.blue);
        // TODO: Implement draft saving
        break;

      case 'discard':
        debugPrint('🗑️ Discard reply');
        _showSnackBar('🗑️ Yanıt siliniyor...', Colors.orange);

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.delete, color: Colors.red),
                SizedBox(width: 8),
                Text('🗑️ Yanıtı Sil'),
              ],
            ),
            content: const Text(
              'Yazdığınız yanıt silinecek. Bu işlem geri alınamaz.\n\n'
              'Devam etmek istiyor musunuz?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('İptal'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Close editor
                },
                child: const Text('Sil', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
        break;

      case 'view_original':
        debugPrint('👁️ View original mail');
        _showSnackBar('👁️ Orijinal mesaj gösteriliyor', Colors.green);

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.visibility, color: Colors.green),
                const SizedBox(width: 8),
                const Text('📧 Orijinal Mesaj'),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              height: 300,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Kimden: ${widget.mailDetail.senderName}'),
                    Text('Email: ${widget.mailDetail.senderEmail}'),
                    Text('Konu: ${widget.mailDetail.subject}'),
                    Text('Tarih: ${widget.mailDetail.time}'),
                    const Divider(),
                    Text(
                      widget.mailDetail.content,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Kapat'),
              ),
            ],
          ),
        );
        break;

      default:
        debugPrint('❓ Unknown menu action: $action');
        _showSnackBar('❓ Bilinmeyen action: $action', Colors.grey);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
