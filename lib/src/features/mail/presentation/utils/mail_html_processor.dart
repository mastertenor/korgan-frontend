// lib/src/features/mail/utils/mail_html_processor.dart

import '../../domain/entities/attachment_upload.dart';

/// Mail HTML processor for converting base64 images to CID references
///
/// This utility processes HTML content before sending emails to:
/// 1. Find base64 embedded images (data:image/jpeg;base64,xxx)
/// 2. Convert them to CID references (cid:image_123)
/// 3. Create corresponding inline attachments
/// 4. Return processed HTML + inline attachments for API
class MailHtmlProcessor {
  
  /// Process HTML content for mail sending
  ///
  /// Converts base64 embedded images to CID references and creates
  /// corresponding inline attachments that mail clients can display.
  ///
  /// [htmlContent] - Raw HTML from Froala editor (may contain base64 images)
  ///
  /// Returns [ProcessedHtmlResult] containing:
  /// - processedHtml: HTML with CID references
  /// - inlineAttachments: List of inline attachments for API
  static ProcessedHtmlResult processHtmlForMail(String? htmlContent) {
    // Early return for empty content
    if (htmlContent == null || htmlContent.trim().isEmpty) {
      return ProcessedHtmlResult(
        processedHtml: htmlContent,
        inlineAttachments: [],
      );
    }

    print('🔧 MailHtmlProcessor: Processing HTML content (${htmlContent.length} chars)');

    final List<AttachmentUpload> inlineAttachments = [];
    String processedHtml = htmlContent;
    int imageCounter = 0;

    // Regex to find base64 image tags
    // Matches: <img src="data:image/jpeg;base64,/9j/4AAQSkZJRgABAQEAYABgAAD..." />
    final base64ImageRegex = RegExp(
      r'<img[^>]*src="data:image/([^;]+);base64,([^"]+)"[^>]*>',
      caseSensitive: false,
      dotAll: true,
    );

    // Process each base64 image found
    processedHtml = processedHtml.replaceAllMapped(base64ImageRegex, (match) {
      try {
        final imageType = match.group(1)!; // jpeg, png, gif, etc.
        final base64Data = match.group(2)!; // Base64 content
        final fullImgTag = match.group(0)!; // Complete img tag

        // Generate unique Content-ID
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final contentId = 'img_${timestamp}_${imageCounter++}';

        print('🖼️ Converting base64 image: $imageType (${base64Data.length} chars) → CID: $contentId');

        // Create inline attachment
        final inlineAttachment = AttachmentUpload(
          content: base64Data,
          type: 'image/$imageType',
          filename: 'image_$imageCounter.$imageType',
          disposition: 'inline',
          contentId: contentId, // 🆕 Will be added to AttachmentUpload
        );

        inlineAttachments.add(inlineAttachment);

        // Replace src with CID reference
        final updatedImgTag = fullImgTag.replaceAll(
          'src="data:image/$imageType;base64,$base64Data"',
          'src="cid:$contentId"',
        );

        print('✅ Image converted successfully: ${updatedImgTag.length} chars');
        return updatedImgTag;

      } catch (e) {
        print('❌ Error processing base64 image: $e');
        // Return original tag if processing fails
        return match.group(0)!;
      }
    });

    final result = ProcessedHtmlResult(
      processedHtml: processedHtml,
      inlineAttachments: inlineAttachments,
    );

    print('✅ MailHtmlProcessor: Processing complete - ${result.inlineAttachments.length} inline images');
    return result;
  }

  /// Validate base64 content
  ///
  /// Basic validation to ensure base64 content is properly formatted
  static bool isValidBase64(String base64Content) {
    if (base64Content.isEmpty) return false;

    // Remove any whitespace
    final cleaned = base64Content.replaceAll(RegExp(r'\s'), '');

    // Check if it matches base64 pattern
    final base64Pattern = RegExp(r'^[A-Za-z0-9+/]*={0,2}$');
    return base64Pattern.hasMatch(cleaned);
  }

  /// Get supported image types for inline embedding
  static const List<String> supportedImageTypes = [
    'jpeg', 'jpg', 'png', 'gif', 'webp', 'bmp', 'svg+xml'
  ];

  /// Check if image type is supported for inline embedding
  static bool isSupportedImageType(String imageType) {
    return supportedImageTypes.contains(imageType.toLowerCase());
  }

  /// Get estimated size of base64 content in bytes
  ///
  /// Base64 encoding increases size by ~33%, so we reverse calculate
  static int getBase64SizeBytes(String base64Content) {
    final contentLength = base64Content.replaceAll('=', '').length;
    return (contentLength * 0.75).round();
  }

  /// Format file size for display
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  /// Debug method to analyze HTML content
  ///
  /// Useful for debugging what images are found in HTML
  static HtmlAnalysisResult analyzeHtml(String? htmlContent) {
    if (htmlContent == null || htmlContent.trim().isEmpty) {
      return HtmlAnalysisResult(
        totalImages: 0,
        base64Images: 0,
        externalImages: 0,
        totalEstimatedSize: 0,
      );
    }

    // Find all img tags
    final allImgRegex = RegExp(r'<img[^>]*>', caseSensitive: false);
    final allImages = allImgRegex.allMatches(htmlContent);

    // Find base64 images
    final base64ImageRegex = RegExp(
      r'<img[^>]*src="data:image/([^;]+);base64,([^"]+)"[^>]*>',
      caseSensitive: false,
    );
    final base64Images = base64ImageRegex.allMatches(htmlContent);

    // Calculate total size
    int totalSize = 0;
    for (final match in base64Images) {
      final base64Data = match.group(2) ?? '';
      totalSize += getBase64SizeBytes(base64Data);
    }

    return HtmlAnalysisResult(
      totalImages: allImages.length,
      base64Images: base64Images.length,
      externalImages: allImages.length - base64Images.length,
      totalEstimatedSize: totalSize,
    );
  }
}

/// Result of HTML processing operation
class ProcessedHtmlResult {
  /// HTML content with base64 images converted to CID references
  final String? processedHtml;

  /// List of inline attachments created from base64 images
  final List<AttachmentUpload> inlineAttachments;

  const ProcessedHtmlResult({
    required this.processedHtml,
    required this.inlineAttachments,
  });

  /// Check if any inline attachments were created
  bool get hasInlineAttachments => inlineAttachments.isNotEmpty;

  /// Get total size of all inline attachments
  int get totalInlineSize {
    return inlineAttachments
        .map((attachment) => attachment.estimatedSizeBytes)
        .fold(0, (a, b) => a + b);
  }

  /// Get formatted total size
  String get totalInlineSizeFormatted {
    return MailHtmlProcessor.formatFileSize(totalInlineSize);
  }

  @override
  String toString() {
    return 'ProcessedHtmlResult('
           'hasInlineAttachments: $hasInlineAttachments, '
           'inlineCount: ${inlineAttachments.length}, '
           'totalSize: $totalInlineSizeFormatted'
           ')';
  }
}

/// Result of HTML analysis operation
class HtmlAnalysisResult {
  /// Total number of img tags found
  final int totalImages;

  /// Number of base64 embedded images
  final int base64Images;

  /// Number of external images (src="http://...")
  final int externalImages;

  /// Total estimated size of all base64 images in bytes
  final int totalEstimatedSize;

  const HtmlAnalysisResult({
    required this.totalImages,
    required this.base64Images,
    required this.externalImages,
    required this.totalEstimatedSize,
  });

  /// Get formatted total size
  String get totalSizeFormatted {
    return MailHtmlProcessor.formatFileSize(totalEstimatedSize);
  }

  @override
  String toString() {
    return 'HtmlAnalysisResult('
           'total: $totalImages, '
           'base64: $base64Images, '
           'external: $externalImages, '
           'size: $totalSizeFormatted'
           ')';
  }
}