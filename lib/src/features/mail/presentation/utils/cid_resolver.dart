// lib/src/features/mail/utils/cid_resolver.dart

import '../../domain/entities/attachment.dart';
import '../../domain/entities/mail_detail.dart';
import '../../domain/repositories/mail_repository.dart';
import 'dart:convert';

/// CID Resolver - Mail görüntüleme için CID referanslarını çözer
///
/// Problem: HTML'de `<img src="cid:img_123">` var ama iframe bunu çözemez
/// Çözüm: CID'leri karşılık gelen attachment'lara eşleştir ve uygun action al
class CidResolver {
  
  /// Resolve CID references in HTML content using mail attachments
  /// 
  /// Bu metod:
  /// 1. HTML'deki `<img src="cid:xxx">` tag'lerini bulur
  /// 2. Mail attachment'larında corresponding CID'i arar  
  /// 3. CID'i çözer (download API kullanarak)
  /// 4. Resolved HTML'i döner
  static Future<String> resolveCidsInHtml(
    String htmlContent, 
    MailDetail mailDetail, 
    String userEmail,
    MailRepository repository,
  ) async {
    if (htmlContent.isEmpty || !mailDetail.hasAttachments) {
      return htmlContent;
    }

    print('🔧 CidResolver: Processing HTML with ${mailDetail.attachments.length} attachments');

    String resolvedHtml = htmlContent;
    int resolvedCount = 0;
    int skippedCount = 0;

    // Find all CID references: <img src="cid:xxx">
    final cidRegex = RegExp(
      r'<img([^>]*)src="cid:([^"]+)"([^>]*)>',
      caseSensitive: false,
      dotAll: true,
    );

    // Process each CID reference
    final matches = cidRegex.allMatches(htmlContent).toList();
    
    for (final match in matches) {
      try {
        final beforeSrc = match.group(1) ?? '';
        final cidValue = match.group(2) ?? '';
        final afterSrc = match.group(3) ?? '';
        final originalTag = match.group(0)!;

        print('🖼️ Found CID reference: cid:$cidValue');

        // Find corresponding attachment by CID
        final attachment = _findAttachmentByCid(mailDetail, cidValue);
        
        if (attachment != null) {
          print('✅ Found matching attachment: ${attachment.filename}');
          
          try {
            // 🆕 Download attachment content using existing repository
            final downloadResult = await repository.downloadAttachment(
              messageId: mailDetail.id,
              attachmentId: attachment.id,
              filename: attachment.filename,
              email: userEmail,
              mimeType: attachment.mimeType,
            );
            
            final downloadSuccess = downloadResult.when(
              success: (bytes) {
                if (bytes.isNotEmpty) {
                  // Convert to base64
                  final base64Content = base64Encode(bytes);
                  final base64Src = 'data:${attachment.mimeType};base64,$base64Content';
                  final resolvedTag = '<img${beforeSrc}src="$base64Src"$afterSrc>';
                  
                  // Replace in HTML
                  resolvedHtml = resolvedHtml.replaceFirst(originalTag, resolvedTag);
                  
                  print('✅ CID resolved: cid:$cidValue → ${attachment.mimeType} (${_formatFileSize(bytes.length)})');
                  resolvedCount++;
                  return true;
                } else {
                  print('⚠️ Empty content for attachment: ${attachment.filename}');
                  skippedCount++;
                  return false;
                }
              },
              failure: (error) {
                print('❌ Download failed: ${error.message}');
                skippedCount++;
                return false;
              },
            );
            
            if (!downloadSuccess) {
              skippedCount++;
            }
          } catch (e) {
            print('❌ Failed to download attachment content: $e');
            skippedCount++;
          }
        } else {
          print('⚠️ CID not found in attachments: cid:$cidValue');
          skippedCount++;
        }
      } catch (e) {
        print('❌ Error resolving CID: $e');
        skippedCount++;
      }
    }

    print('✅ CidResolver: Found ${matches.length} CIDs, resolved $resolvedCount, skipped $skippedCount');
    return resolvedHtml;
  }

  /// Find attachment by Content-ID
  /// 
  /// Tries multiple strategies to match CID with attachments:
  /// 1. Direct ID match
  /// 2. Filename pattern matching  
  /// 3. Inline attachment heuristics
  static MailAttachment? _findAttachmentByCid(MailDetail mailDetail, String cidValue) {
    print('🔍 Searching for CID: $cidValue in ${mailDetail.attachments.length} attachments');
    
    // Normalize CID value - remove < > brackets if present
    final normalizedCid = cidValue.replaceAll(RegExp(r'^<|>$'), '');
    print('🔧 Normalized CID: $normalizedCid');
    
    for (int i = 0; i < mailDetail.attachments.length; i++) {
      final attachment = mailDetail.attachments[i];
      
      print('📎 Attachment $i: ${attachment.filename} (${attachment.mimeType})');
      print('   - id: ${attachment.id}');
      print('   - isInline: ${attachment.isInline}');
      print('   - size: ${attachment.sizeFormatted}');
      
      // Strategy 1: Direct ID match
      if (attachment.id == normalizedCid || attachment.id == cidValue) {
        print('✅ Match by ID: ${attachment.filename}');
        return attachment;
      }
      
      // Strategy 2: Filename contains CID pattern
      if (attachment.filename.contains(normalizedCid)) {
        print('✅ Match by filename pattern: ${attachment.filename}');
        return attachment;
      }
      
      // Strategy 3: Inline attachment with image type
      if (attachment.isInline && attachment.mimeType.startsWith('image/')) {
        // If CID contains img_ pattern and attachment is inline image
        if (normalizedCid.contains('img_')) {
          print('✅ Match by inline image heuristic: ${attachment.filename}');
          return attachment;
        }
        
        // If only one inline image attachment and we have an image CID
        final inlineImages = mailDetail.attachments
            .where((a) => a.isInline && a.mimeType.startsWith('image/'))
            .toList();
        if (inlineImages.length == 1) {
          print('✅ Match by single inline image: ${attachment.filename}');
          return attachment;
        }
      }
      
      // Strategy 4: Image type with img pattern in CID
      if (attachment.mimeType.startsWith('image/') && normalizedCid.contains('img_')) {
        print('✅ Match by image type + pattern: ${attachment.filename}');
        return attachment;
      }
    }
    
    print('❌ No attachment found for CID: $cidValue');
    return null;
  }

  /// Check if HTML contains CID references
  static bool containsCidReferences(String htmlContent) {
    return htmlContent.contains('src="cid:');
  }

  /// Get list of all CID values in HTML
  static List<String> extractCidValues(String htmlContent) {
    final cidRegex = RegExp(r'src="cid:([^"]+)"', caseSensitive: false);
    final matches = cidRegex.allMatches(htmlContent);
    
    return matches
        .map((match) => match.group(1) ?? '')
        .where((cid) => cid.isNotEmpty)
        .toList();
  }

  /// Format file size for logging
  static String _formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  /// Debug method to analyze CID situation
  static CidAnalysisResult analyzeCids(String htmlContent, MailDetail mailDetail) {
    final cidValues = extractCidValues(htmlContent);
    final attachmentCount = mailDetail.attachments.length;
    
    int foundCount = 0;
    final missingCids = <String>[];
    
    for (final cid in cidValues) {
      final attachment = _findAttachmentByCid(mailDetail, cid);
      if (attachment != null) {
        foundCount++;
      } else {
        missingCids.add(cid);
      }
    }
    
    return CidAnalysisResult(
      totalCids: cidValues.length,
      foundAttachments: foundCount,
      missingCids: missingCids,
      totalAttachments: attachmentCount,
    );
  }
}

/// Result of CID analysis
class CidAnalysisResult {
  final int totalCids;
  final int foundAttachments;
  final List<String> missingCids;
  final int totalAttachments;

  const CidAnalysisResult({
    required this.totalCids,
    required this.foundAttachments,
    required this.missingCids,
    required this.totalAttachments,
  });

  bool get hasMissingCids => missingCids.isNotEmpty;
  bool get allFound => totalCids > 0 && foundAttachments == totalCids;

  @override
  String toString() {
    return 'CidAnalysisResult('
           'total: $totalCids, '
           'found: $foundAttachments, '
           'missing: ${missingCids.length}, '
           'attachments: $totalAttachments'
           ')';
  }
}