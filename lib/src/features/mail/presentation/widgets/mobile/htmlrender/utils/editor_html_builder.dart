// lib/src/features/mail/presentation/widgets/mobile/htmlrender/utils/editor_html_builder.dart

import '../../../../../domain/entities/mail_detail.dart';

/// HTML Builder for Editor Mode - Yandex-style unified editor
class EditorHtmlBuilder {
  /// Build complete HTML document for editor mode
  static String buildEditorHtml({
    required MailDetail mailDetail,
    required String currentUserEmail,
  }) {
    return _buildYandexUnifiedHtml(mailDetail, currentUserEmail);
  }

  static String _buildYandexUnifiedHtml(
    MailDetail mailDetail,
    String currentUserEmail,
  ) {
    // Prepare field values
    final String toField = mailDetail.senderEmail;
    final String ccField = '';
    final String bccField = '';
    final String fromField = currentUserEmail;
    final String subjectField = _buildReplySubject(mailDetail.subject);
    final String originalHtmlContent = _getOriginalHtmlContent(mailDetail);
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

  // ===========================================
  // HELPER METODLARI BURAYA EKLEYEBİLİRSİN
  // _buildReplySubject, _getOriginalHtmlContent vb.
  // ===========================================

  /// Helper method for reply subject
  static String _buildReplySubject(String originalSubject) {
    if (originalSubject.toLowerCase().startsWith('re:')) {
      return originalSubject;
    }
    return 'Re: $originalSubject';
  }

  /// Helper method for original content
  static String _getOriginalHtmlContent(MailDetail mailDetail) {
    if (mailDetail.htmlContent.isNotEmpty) {
      return mailDetail.htmlContent;
    }
    return _convertTextToHtml(mailDetail.textContent);
  }

  /// Helper method for text to HTML conversion
  static String _convertTextToHtml(String text) {
    if (text.trim().isEmpty) {
      return '<p>Bu mailde içerik bulunmuyor.</p>';
    }

    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('\n\n', '</p><p>')
        .replaceAll('\n', '<br>')
        .replaceAll(RegExp(r'^'), '<p>')
        .replaceAll(RegExp(r'$'), '</p>');
  }
}
