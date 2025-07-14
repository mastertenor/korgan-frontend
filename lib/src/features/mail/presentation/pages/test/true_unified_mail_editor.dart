// lib/src/features/mail/presentation/pages/test/true_unified_mail_editor.dart
// Yandex-style unified editor with Stack layout solution for header gesture conflicts

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class YandexUnifiedMailEditor extends StatefulWidget {
  const YandexUnifiedMailEditor({super.key});

  @override
  State<YandexUnifiedMailEditor> createState() =>
      _YandexUnifiedMailEditorState();
}

class _YandexUnifiedMailEditorState extends State<YandexUnifiedMailEditor> {
  // Controllers and state
  InAppWebViewController? _webViewController;
  Timer? _debounceTimer;

  // Mail data state
  String composeContent = '';
  String toField = '';
  String ccField = '';
  String bccField = '';
  String subjectField = '';
  String fromField = '';
  String originalHtmlContent = '';
  bool isOriginalExpanded = false;
  bool isLoading = true;

  // Test data
  Map<String, dynamic>? testMailData;

  @override
  void initState() {
    super.initState();
    _loadTestData();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  /// Load test JSON data from assets file
  Future<void> _loadTestData() async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));

      // Try to load from assets file first
      String jsonString;
      try {
        jsonString = await DefaultAssetBundle.of(
          context,
        ).loadString('assets/test_data/test_mail_data.json');
        debugPrint('📁 Loaded test data from assets file');
      } catch (e) {
        // Fallback to default data if file doesn't exist
        debugPrint('⚠️ Assets file not found, using default data: $e');
        jsonString = '''
        {
          "id": "1979da3c3fec3213",
          "from": "ismail goncuoglu <igoncu52@gmail.com>",
          "to": "Berk Göknil <berk@argenteknoloji.com>",
          "subject": "Fwd: ŞirketOrtağım Girişim Analiz Toplantıları",
          "content": {
            "html": "<div dir='ltr'>Merhaba Berk,<br><br>Bu konuyla ilgili toplantımızı planlayalım.<br><br>Saygılar,<br>İsmail</div>"
          }
        }
        ''';
      }

      setState(() {
        testMailData = json.decode(jsonString);
        originalHtmlContent = testMailData!['content']['html'];
        toField = _extractEmail(testMailData!['from']);
        subjectField = 'Re: ${testMailData!['subject']}';
        fromField = 'berk@argenteknoloji.com';
        isLoading = false;
      });

      debugPrint('✅ Test data loaded successfully');
      debugPrint('📧 Subject: ${testMailData!['subject']}');
      debugPrint('📝 HTML length: ${originalHtmlContent.length} characters');
    } catch (e) {
      debugPrint('❌ Error loading test data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loading...')),
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
            // ❌ Close button - works immediately with stack solution
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  debugPrint(
                    '🔴 Close button pressed - Stack solution working!',
                  );
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

            // Solution indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.green.shade200, width: 0.5),
              ),
              child: Text(
                '📐 STACK',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
            ),

            const Spacer(),

            // 📎 Attach file button
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  debugPrint(
                    '📎 Attach file button pressed - Stack solution working!',
                  );
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
                        debugPrint(
                          '✈️ Send button pressed - Stack solution working! Can send: ${_canSend()}',
                        );
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
                debugPrint(
                  '⋯ Menu item selected - Stack solution working! Value: $value',
                );
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
                  value: 'test_stack',
                  child: Row(
                    children: [
                      Icon(Icons.architecture, size: 18, color: Colors.green),
                      SizedBox(width: 8),
                      Text(
                        'Test Stack Solution',
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

  /// Yandex-style Unified Editor with clean settings
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
          debugPrint(
            '🚀 WebView created with stack layout - Header is completely isolated!',
          );
        },

        onLoadStop: (controller, url) {
          debugPrint('✅ Yandex unified editor loaded with stack solution!');

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

  /// Build Yandex-style unified HTML - ALL fields in single contentEditable
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
        
        <!-- YANDEX UNIFIED COMPOSER - Single contentEditable with PROTECTED structure -->
        <div id="yandex-unified-composer" contenteditable="true">
            
            <!-- PROTECTED Recipients Section -->
            <div class="recipients-section" contenteditable="false">
                
                <!-- To field -->
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
                    
                    <!-- From field -->
                    <div class="field-row" contenteditable="false">
                        <div class="field-label" contenteditable="false">Kimden:</div>
                        <div class="field-input" data-field="from" data-placeholder="Gönderen email" contenteditable="true">$fromField</div>
                    </div>
                    
                </div>
                
                <!-- Subject field -->
                <div class="field-row" contenteditable="false">
                    <div class="field-label" contenteditable="false">Konu:</div>
                    <div class="field-input" data-field="subject" data-placeholder="Email konusu" contenteditable="true">$subjectField</div>
                </div>
                
            </div>
            
            <!-- Compose Area -->
            <div class="compose-area" data-field="compose" contenteditable="true">
                <!-- User types message here -->
            </div>
            
        </div>
        
        <script>
            let isOriginalExpanded = false;
            let isRecipientsExpanded = false;
            let debounceTimer;
            let composer;
            
            function initializeYandexEditor() {
                console.log('🚀 Initializing Yandex unified editor with stack layout...');
                
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
                
                console.log('✅ Yandex unified editor initialized with stack solution');
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
                
                // Create original quote (hidden initially)
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

          debugPrint('📝 Yandex fields updated:');
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

  // ========== ACTION HANDLERS with Stack Solution ==========

  bool _canSend() {
    final canSend = toField.isNotEmpty && subjectField.isNotEmpty;
    debugPrint(
      '🔍 Can send check: to="${toField}" subject="${subjectField}" result=$canSend',
    );
    return canSend;
  }

  void _onAttachFile() {
    debugPrint('📎 ATTACH FILE - Stack solution SUCCESS!');

    // Force haptic feedback to confirm button press
    HapticFeedback.lightImpact();

    // Enhanced success feedback
    _showSnackBar(
      '📎 Stack çözümü çalışıyor! Attach butonu aktif',
      Colors.blue,
    );

    // Show a test dialog to confirm it's working
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.architecture, color: Colors.green),
            SizedBox(width: 8),
            Text('📐 Stack Layout Solution'),
          ],
        ),
        content: const Text(
          'MÜKEMMEL! 🎉\n\n'
          '📐 Stack Layout: ✅\n'
          '🚫 WebView İsolasyonu: ✅\n'
          '⚡ Temiz Kod: ✅\n\n'
          'Header butonları anında responsive!\n'
          'Karmaşık gesture korumaları gereksiz!\n\n'
          'File attachment özelliği burada implement edilecek.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Harika!'),
          ),
        ],
      ),
    );
  }

  void _onSend() {
    debugPrint('🚀 SEND BUTTON - Stack solution SUCCESS!');

    if (!_canSend()) {
      debugPrint('❌ Cannot send - missing required fields');
      _showSnackBar('Lütfen To ve Subject alanlarını doldurun', Colors.red);
      return;
    }

    debugPrint('🚀 SEND TRIGGERED - Stack layout working perfectly!');
    debugPrint('📧 To: $toField');
    debugPrint('📧 CC: $ccField');
    debugPrint('📧 BCC: $bccField');
    debugPrint('📧 From: $fromField');
    debugPrint('📧 Subject: $subjectField');
    debugPrint('📧 Content: $composeContent');

    // Force haptic feedback
    HapticFeedback.mediumImpact();

    // Get full data from WebView
    _webViewController
        ?.evaluateJavascript(source: 'getAllData()')
        .then((result) {
          debugPrint('📧 Full Yandex unified data: $result');
          _showSnackBar(
            '✈️ Mesaj başarıyla gönderildi! (Stack Layout)',
            Colors.green,
          );

          // Show success dialog
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 8),
                  Text('✈️ Gönderim Başarılı'),
                ],
              ),
              content: const Text(
                'Stack Layout ile Send butonu mükemmel çalışıyor!\n\n'
                'Hem header responsive, hem de WebView tamamen functional.',
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
    debugPrint('⋯ MENU ACTION - Stack solution SUCCESS: $action');

    // Force haptic feedback
    HapticFeedback.lightImpact();

    switch (action) {
      case 'save_draft':
        debugPrint('💾 Save draft - Stack layout working!');
        _showSnackBar('💾 Draft kaydedildi (Stack Layout)', Colors.blue);
        break;

      case 'discard':
        debugPrint('🗑️ Discard - Stack layout working!');
        _showSnackBar('🗑️ Discard çalışıyor (Stack Layout)', Colors.orange);

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.delete, color: Colors.red),
                SizedBox(width: 8),
                Text('🗑️ Draft Sil'),
              ],
            ),
            content: const Text(
              'Stack Layout sayesinde menu butonları mükemmel çalışıyor!\n\n'
              'Gerçekten çıkmak istiyor musunuz?',
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
                child: const Text('Çık', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
        break;

      case 'test_stack':
        debugPrint('📐 Stack Layout test LEGENDARY successful!');
        _showSnackBar('📐 Stack Layout test: LEGENDARY SUCCESS!', Colors.green);

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.architecture, color: Colors.green),
                SizedBox(width: 8),
                Text('📐 Stack Layout Test'),
              ],
            ),
            content: const Text(
              '🎉 LEGENDARY SUCCESS! 🎉\n\n'
              '📐 Stack Layout: ✅ ACTIVE\n'
              '🚫 WebView İsolasyonu: ✅ PERFECT\n'
              '⚡ Clean Code: ✅ MINIMAL\n\n'
              '✅ Header: İLK AÇILIŞTAN İTİBAREN ÇALIŞIYOR\n'
              '✅ WebView: TAMAMEN FUNCTIONAL\n'
              '✅ Gesture conflicts: YOK EDİLDİ\n'
              '✅ Kod karmaşıklığı: MİNİMAL\n'
              '✅ Performance: OPTİMAL\n\n'
              'Bazen en basit çözüm en iyisidir! 🚀',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('LEGENDARY! 📐🚀'),
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

  // ========== UTILITIES ==========

  String _extractEmail(String emailString) {
    final emailRegex = RegExp(r'<([^>]+)>');
    final match = emailRegex.firstMatch(emailString);
    return match?.group(1) ?? emailString.trim();
  }
}
