// lib/src/features/mail/presentation/widgets/web/compose/components/froala_html_generator.dart

import 'dart:convert';

class FroalaHtmlGenerator {
  /// Complete HTML with ready signal, simplified logging and scroll fix
  static String getCompleteHTML({required String channelId}) {
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

  /* Froala upload UI'larını kapat */
  .fr-image-upload-layer,
  .fr-upload-progress,
  .fr-upload-layer,
  .fr-file-upload-layer,
  .fr-video-upload-layer {
    display: none !important;
    opacity: 0 !important;
    visibility: hidden !important;
    pointer-events: none !important;
  }
</style>
</head>
<body>
  <div id="editor"></div>

  <script>
    (function(){
      var CHANNEL = ${jsonEncode(channelId)};
      var SECURE_CHANNEL = 'korgan-froala-editor';
      var editor;
      var isReady = false;
      var lastFocused = null;
      
      // Güvenli mesaj gönderimi
      function post(type, data) {
        try {
          var message = {
            type: type,
            channel: SECURE_CHANNEL,
            channelId: CHANNEL,
            timestamp: Date.now()
          };
          if (data) {
            Object.assign(message, data);
          }
          parent?.postMessage(JSON.stringify(message), '*');
        } catch (e) {
          console.error('Failed to post message:', e);
        }
      }
      
      // Ready signal function
      function notifyReady() {
        post('iframe_ready', { ts: Date.now() });
        console.log('Secure ready signal sent to parent');
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

      // Güvenli mesaj alma
      window.addEventListener('message', function(event) {
        try {
          if (typeof event.data !== 'string') return;
          
          var msg = JSON.parse(event.data);
          if (!msg || typeof msg !== 'object') return;
          
          // Kanal kontrolü - hem eski hem yeni sistemi destekle
          if (msg.channelId !== CHANNEL && msg.channel !== SECURE_CHANNEL) return;
          
          handleIncomingMessage(msg);
        } catch (e) {
          console.error('Message parse error:', e);
        }
      });
      
      function handleIncomingMessage(payload) {
        var type = payload.type;
        switch (type) {
          case 'froala_command':
            handleFroalaCommand(payload);
            break;
          case 'external_image_insert':
            handleExternalImageInsert(payload);
            break;
          case 'force_focus':
            if (editor && isReady) {
              console.log('Force focusing Froala editor...');
              editor.events.focus(true);
            }
            break;
        }
      }
      
      function handleFroalaCommand(payload) {
        const command = payload.command;
        const data = payload.data;
        
        if (!editor || !isReady) {
          console.log('Editor not ready for command:', command);
          return;
        }
        
        try {
          switch (command) {
            case 'setContent':
              editor.html.set(data || '');
              break;
                        case 'setContentWithQuote':
              // NEW: Set content and position cursor at the beginning
              const quoteContent = data.quoteContent || data || '';
              editor.html.set(quoteContent);
              
              // Position cursor at the very beginning of the editor
              setTimeout(function() {
                try {
                  editor.selection.setAtStart(editor.el);
                  editor.events.focus(true);
                  console.log('Quote content loaded, cursor positioned at start');
                  
                  // Notify parent that quote is ready
                  post('quote_content_ready', {
                    contentLength: quoteContent.length
                  });
                } catch (e) {
                  console.warn('Failed to position cursor at start:', e);
                }
              }, 100);
              break;
                
            case 'insertImage':
              if (data && data.base64) {
                editor.image.insert(data.base64, null, null, editor.image.get());
                post('image_inserted', {
                  name: data.name || 'image',
                  size: data.size || 0
                });
                console.log('Image inserted:', data.name);
              }
              break;
            case 'cleanupDragHelper':
              var dragHelpers = document.querySelectorAll('.fr-drag-helper');
              var removedCount = 0;
              dragHelpers.forEach(function(helper) {
                helper.remove();
                removedCount++;
              });
              console.log('Manual drag helper cleanup completed, removed:', removedCount);
              break;
          }
        } catch (err) {
          console.error('Command execution error:', err);
        }
      }
      
      function handleExternalImageInsert(payload) {
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

      function setupUnifiedDropHandlers() {
        console.log('Setting up enhanced iframe drop handlers');
        
        document.addEventListener('dragenter', function(e) {
          if (e.dataTransfer && e.dataTransfer.types.includes('Files')) {
            console.log('IFRAME: DRAGENTER - notifying parent to show drop zone');
            try {
              post('iframe_drag_enter');
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
                  
                  post('iframe_drop_complete');
                  console.log('IFRAME: Notified parent about drop completion');
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

      function setupNativePasteInterceptor() {
        // Capture fazında çalışır; Froala'dan önce yakalar
        document.addEventListener('paste', function(e) {
          try {
            // Editör fokus değilse hiç uğraşma (zaten parent tarafında global paste var)
            if (!editor || !isReady || !editor.core.hasFocus()) return;

            const cd = e.clipboardData || (e.originalEvent && e.originalEvent.clipboardData) || null;
            if (!cd) return;

            // Clipboard'ta file var mı?
            let items = cd.items ? Array.from(cd.items) : [];
            let files = [];

            if (cd.files && cd.files.length) {
              files = Array.from(cd.files);
            } else if (items.length) {
              files = items
                .filter(it => it.kind === 'file')
                .map(it => it.getAsFile())
                .filter(Boolean);
            }
            if (!files.length) return;

            const images = files.filter(f => f && f.type && f.type.indexOf('image/') === 0);
            const nonImages = files.filter(f => !(f && f.type && f.type.indexOf('image/') === 0));

            if (nonImages.length > 0) {
              // Froala'ya hiç ulaşmadan blokla ve parent'a EK olarak gönder
              e.preventDefault();
              e.stopPropagation();
              e.stopImmediatePropagation();

              const payload = [];
              let done = 0;
              nonImages.forEach(function(file) {
                const r = new FileReader();
                r.onload = function(ev) {
                  payload.push({
                    name: file.name,
                    type: file.type || 'application/octet-stream',
                    size: file.size || 0,
                    base64: ev.target.result
                  });
                  done++;
                  if (done === nonImages.length) {
                    post('files_pasted_in_iframe', { files: payload, source: 'iframe_paste' });
                  }
                };
                r.readAsDataURL(file);
              });

              return; // Non-image'lar için tamamen kestik
            }

            // Sadece resim varsa Froala'ya izin veriyoruz (editöre girsin)

          } catch (err) {
            console.warn('native paste interceptor error:', err);
          }
        }, true); // CAPTURE
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
          setupNativePasteInterceptor();
          
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
            videoUpload: false,
            fileUpload: false,
            imageInsertButtons: ['imageByURL'],
            imageResizeWithPercent: true,
            dragInline: false,
            linkAlwaysBlank: true,
            
events: {
  'initialized': function () { 
    console.log('Froala initialized with security enhancements');
    isReady = true;
    this.opts.scrollableContainer = this.el;
    post('froala_ready', { ready: true });
    notifyReady();
  },

  'keydown': function(e) {
    if ((e.ctrlKey || e.metaKey) && e.key === 'Enter') {
      e.preventDefault();
      post('send_shortcut');
    }
    if (e.key === 'Enter') {
      requestAnimationFrame(() => scrollCaretIntoView(this));
    }
  },

  'keyup': function (e) {
    if (e.key === 'Enter') {
      setTimeout(() => scrollCaretIntoView(this), 0);
    }
  },
  
  'contentChanged': function () {
    if (!isReady) return;
    try {
      var html = this.html.get();
      var text = this.el.textContent || '';
      post('content_changed', { 
        html: html, 
        text: text,
        isEmpty: text.trim() === '' || html === '<p><br></p>',
        wordCount: text.split(/\\s+/).filter(w => w.length > 0).length
      });
    } catch (e) {
      console.error('Content change error:', e);
    }
  },
  
  'focus': function() {
    if (lastFocused === true) return;
    lastFocused = true;
    post('focus_changed', { focused: true });
    post('froala_focus_in');
  },
  
  'blur': function() {
    if (lastFocused === false) return;
    lastFocused = false;
    post('focus_changed', { focused: false });
  },
  
  'mousedown': function () {
    post('froala_focus_in');
  },
  
  'touchstart': function () {
    post('froala_focus_in');
  },

  'image.beforeUpload': function(images) { 
    console.log('Blocking Froala image upload, using unified system instead'); 
    return false; 
  },
  'image.beforePasteUpload': function(img) { 
    return false; 
  },
  'file.beforeUpload': function(files) { return false; },
  'video.beforeUpload': function(videos) { return false; },
  'image.uploaded': function () { return false; },
  'file.uploaded': function () { return false; },
  'video.uploaded': function () { return false; },

  'paste.before': function(e) {
    var cd = null;
    try {
      cd = (e && e.originalEvent && e.originalEvent.clipboardData)
        || (e && e.clipboardData)
        || (window.event && window.event.clipboardData)
        || null;
    } catch(_) {}

    if (!cd) return true;

    var hasFiles = !!(cd.files && cd.files.length) ||
                  !!(cd.items && Array.from(cd.items).some(it => it.kind === 'file'));
    if (!hasFiles) return true;

    var files = [];
    if (cd.files && cd.files.length) {
      files = Array.from(cd.files);
    } else if (cd.items && cd.items.length) {
      files = Array.from(cd.items)
        .filter(it => it.kind === 'file')
        .map(it => it.getAsFile())
        .filter(Boolean);
    }
    if (!files.length) return true;

    var nonImages = files.filter(f => !(f && f.type && f.type.indexOf('image/') === 0));
    if (nonImages.length === 0) {
      return true;
    }

    e.preventDefault();
    e.stopPropagation();

    var payload = [];
    var done = 0;
    nonImages.forEach(function(file){
      var r = new FileReader();
      r.onload = function(ev){
        payload.push({
          name: file.name,
          type: file.type || 'application/octet-stream',
          size: file.size || 0,
          base64: ev.target.result
        });
        done++;
        if (done === nonImages.length) {
          post('files_pasted_in_iframe', { files: payload, source: 'iframe_paste' });
        }
      };
      r.readAsDataURL(file);
    });

    return false;
  },

  'paste.after': function () {
    setTimeout(() => scrollCaretIntoView(this), 0);
  },

  'image.inserted': function () {
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
}