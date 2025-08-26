// lib/src/features/mail/presentation/providers/froala_editor_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// State class for Froala rich text editor
class FroalaEditorState {
  /// Editor initialization state
  final bool isReady;
  final bool isLoading;
  
  /// Content state
  final String htmlContent;
  final String textContent;
  final bool isEmpty;
  final int wordCount;
  
  /// Editor interaction state
  final bool isFocused;
  final bool hasUnsavedChanges;
  
  /// Error state
  final String? error;
  
  /// Image handling
  final List<String> pastedImages; // Base64 images
  
  const FroalaEditorState({
    this.isReady = false,
    this.isLoading = true,
    this.htmlContent = '',
    this.textContent = '',
    this.isEmpty = true,
    this.wordCount = 0,
    this.isFocused = false,
    this.hasUnsavedChanges = false,
    this.error,
    this.pastedImages = const [],
  });

  /// Create initial state
  factory FroalaEditorState.initial() {
    return const FroalaEditorState();
  }

  /// Copy with updated values
  FroalaEditorState copyWith({
    bool? isReady,
    bool? isLoading,
    String? htmlContent,
    String? textContent,
    bool? isEmpty,
    int? wordCount,
    bool? isFocused,
    bool? hasUnsavedChanges,
    String? error,
    List<String>? pastedImages,
  }) {
    return FroalaEditorState(
      isReady: isReady ?? this.isReady,
      isLoading: isLoading ?? this.isLoading,
      htmlContent: htmlContent ?? this.htmlContent,
      textContent: textContent ?? this.textContent,
      isEmpty: isEmpty ?? this.isEmpty,
      wordCount: wordCount ?? this.wordCount,
      isFocused: isFocused ?? this.isFocused,
      hasUnsavedChanges: hasUnsavedChanges ?? this.hasUnsavedChanges,
      error: error,
      pastedImages: pastedImages ?? this.pastedImages,
    );
  }

  /// Check if content is valid for sending
  bool get canSend => isReady && !isEmpty;

  /// Get content summary
  String get contentSummary {
    if (isEmpty) return 'Boş mesaj';
    if (wordCount == 0) return 'Sadece formatlamalı içerik';
    return '$wordCount kelime';
  }

  @override
  String toString() {
    return 'FroalaEditorState('
           'isReady: $isReady, '
           'isEmpty: $isEmpty, '
           'wordCount: $wordCount, '
           'isFocused: $isFocused'
           ')';
  }
}

/// Froala editor state notifier
class FroalaEditorNotifier extends StateNotifier<FroalaEditorState> {
  FroalaEditorNotifier() : super(FroalaEditorState.initial());

  // ========== EDITOR LIFECYCLE ==========

  /// Called when editor is ready
  void onEditorReady() {
    if (!state.isReady) {  // Sadece bir kez çalışsın
      state = state.copyWith(
        isReady: true,
        isLoading: false,
        error: null,
      );
    }
  }

  /// Called when editor fails to load
  void onEditorError(String error, {String? details}) {
    state = state.copyWith(
      isReady: false,
      isLoading: false,
      error: details != null ? '$error: $details' : error,
    );
  }

  /// Reset editor state
  void reset() {
    state = FroalaEditorState.initial();
  }

  // ========== CONTENT MANAGEMENT ==========

  /// Update content from editor
  void updateContent({
    required String htmlContent,
    required String textContent,
    required bool isEmpty,
    required int wordCount,
  }) {
    final hasChanges = htmlContent != state.htmlContent || 
                      textContent != state.textContent;

    state = state.copyWith(
      htmlContent: htmlContent,
      textContent: textContent,
      isEmpty: isEmpty,
      wordCount: wordCount,
      hasUnsavedChanges: hasChanges,
      error: null,
    );
  }

  /// Set initial content (without marking as changed)
  void setInitialContent({
    required String htmlContent,
    required String textContent,
  }) {
    state = state.copyWith(
      htmlContent: htmlContent,
      textContent: textContent,
      isEmpty: htmlContent.trim().isEmpty || htmlContent == '<p><br></p>',
      wordCount: textContent.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).length,
      hasUnsavedChanges: false,
    );
  }

  /// Clear content
  void clearContent() {
    state = state.copyWith(
      htmlContent: '',
      textContent: '',
      isEmpty: true,
      wordCount: 0,
      hasUnsavedChanges: false,
    );
  }

  // ========== FOCUS MANAGEMENT ==========

  /// Update focus state
  void updateFocus(bool isFocused) {
    state = state.copyWith(isFocused: isFocused);
  }

  // ========== IMAGE HANDLING ==========

  /// Handle pasted image
  void onImagePasted({
    required String base64,
    required String name,
    required int size,
  }) {
    final updatedImages = List<String>.from(state.pastedImages)..add(base64);
    
    state = state.copyWith(
      pastedImages: updatedImages,
      hasUnsavedChanges: true,
    );
  }

  /// 🎯 NEW: Insert image directly into editor (for unified file handling)
  void insertImage({
    required String base64,
    required String name,
    required int size,
  }) {
    // Add to pasted images list for tracking
    final updatedImages = List<String>.from(state.pastedImages)..add(base64);
    
    // Update state
    state = state.copyWith(
      pastedImages: updatedImages,
      hasUnsavedChanges: true,
      error: null, // Clear any previous errors
    );
    
    // Note: The actual insertion into editor is handled by the widget
    // through the insertImage() method in ComposeRichEditorWidgetState
  }

  /// Remove pasted image
  void removePastedImage(String base64) {
    final updatedImages = List<String>.from(state.pastedImages)..remove(base64);
    
    state = state.copyWith(
      pastedImages: updatedImages,
    );
  }

  /// Clear all pasted images
  void clearPastedImages() {
    state = state.copyWith(pastedImages: []);
  }

  // ========== VALIDATION ==========

  /// Validate content for sending
  bool validateForSend() {
    if (!state.isReady) {
      state = state.copyWith(error: 'Editor henüz hazır değil');
      return false;
    }

    if (state.isEmpty) {
      state = state.copyWith(error: 'Mesaj içeriği boş olamaz');
      return false;
    }

    if (state.textContent.trim().length < 2) {
      state = state.copyWith(error: 'Mesaj çok kısa');
      return false;
    }

    // Clear any previous errors
    state = state.copyWith(error: null);
    return true;
  }

  /// Mark content as saved
  void markAsSaved() {
    state = state.copyWith(hasUnsavedChanges: false);
  }

  // ========== UTILITY METHODS ==========

  /// Get safe HTML content for email
  String getSafeHtmlContent() {
    if (state.isEmpty) return '';
    
    // Basic HTML sanitization for email
    String content = state.htmlContent;
    
    // Remove potentially problematic tags
    content = content.replaceAll(RegExp(r'<(script|style|link|meta)[^>]*>.*?</\1>', caseSensitive: false, dotAll: true), '');
    content = content.replaceAll(RegExp(r'<(script|style|link|meta)[^>]*/?>', caseSensitive: false), '');
    
    // Remove dangerous attributes
    content = content.replaceAll(RegExp(r'\s(onload|onclick|onmouseover|onfocus|onblur|onchange|onsubmit)="[^"]*"', caseSensitive: false), '');
    
    return content;
  }

  /// Get content statistics
  Map<String, dynamic> getContentStats() {
    return {
      'wordCount': state.wordCount,
      'characterCount': state.textContent.length,
      'htmlSize': state.htmlContent.length,
      'imageCount': state.pastedImages.length,
      'isEmpty': state.isEmpty,
      'canSend': state.canSend,
    };
  }
}

/// Provider for Froala editor state
final froalaEditorProvider = StateNotifierProvider<FroalaEditorNotifier, FroalaEditorState>((ref) {
  return FroalaEditorNotifier();
});

/// Provider for content validation
final froalaContentValidationProvider = Provider<bool>((ref) {
  final editorState = ref.watch(froalaEditorProvider);
  return editorState.canSend;
});

/// Provider for content statistics
final froalaContentStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final notifier = ref.read(froalaEditorProvider.notifier);
  return notifier.getContentStats();
});