// lib/src/features/mail/utils/subject_prefix_utils.dart

import '../../domain/enums/reply_type.dart';

/// Email subject prefix utilities - RFC 5322 compliant
/// 
/// Prevents duplicate Re: Re: Re: or Fwd: Fwd: situations
/// Follows standard email client behavior (Gmail, Outlook, etc.)
class SubjectPrefixUtils {
  
  /// Add "Re:" prefix only if not already present
  /// 
  /// Examples:
  /// - "Hello" -> "Re: Hello"  
  /// - "Re: Hello" -> "Re: Hello" (no change)
  /// - "RE: Hello" -> "RE: Hello" (preserves case)
  /// - "Fwd: Re: Hello" -> "Re: Fwd: Re: Hello"
  static String addReplyPrefix(String originalSubject) {
    if (originalSubject.trim().isEmpty) {
      return 'Re: ';
    }
    
    final trimmed = originalSubject.trim();
    
    // Check if already starts with "Re:" (case insensitive)
    if (_startsWithReplyPrefix(trimmed)) {
      return trimmed; // Already has Re:, don't add another
    }
    
    return 'Re: $trimmed';
  }
  
  /// Add "Fwd:" prefix only if not already present
  /// 
  /// Examples:
  /// - "Hello" -> "Fwd: Hello"
  /// - "Fwd: Hello" -> "Fwd: Hello" (no change) 
  /// - "FWD: Hello" -> "FWD: Hello" (preserves case)
  /// - "Re: Hello" -> "Fwd: Re: Hello"
  static String addForwardPrefix(String originalSubject) {
    if (originalSubject.trim().isEmpty) {
      return 'Fwd: ';
    }
    
    final trimmed = originalSubject.trim();
    
    // Check if already starts with forward prefix (case insensitive)
    if (_startsWithForwardPrefix(trimmed)) {
      return trimmed; // Already has Fwd:/Fw:, don't add another
    }
    
    return 'Fwd: $trimmed';
  }
  
  /// Remove all reply prefixes from subject
  /// Useful for getting clean original subject
  static String removeReplyPrefixes(String subject) {
    if (subject.trim().isEmpty) return subject;
    
    String result = subject.trim();
    
    // Keep removing Re: prefixes until none left
    while (_startsWithReplyPrefix(result)) {
      result = result.substring(3).trim(); // Remove "Re:" and spaces
    }
    
    return result;
  }
  
  /// Remove all forward prefixes from subject
  static String removeForwardPrefixes(String subject) {
    if (subject.trim().isEmpty) return subject;
    
    String result = subject.trim();
    
    // Keep removing Fwd:/Fw: prefixes until none left
    while (_startsWithForwardPrefix(result)) {
      if (result.toLowerCase().startsWith('fwd:')) {
        result = result.substring(4).trim(); // Remove "Fwd:"
      } else if (result.toLowerCase().startsWith('fw:')) {
        result = result.substring(3).trim(); // Remove "Fw:"
      }
    }
    
    return result;
  }
  
  /// Get clean subject without any prefixes
  static String getCleanSubject(String subject) {
    String result = subject.trim();
    result = removeReplyPrefixes(result);
    result = removeForwardPrefixes(result);
    return result;
  }
  
  /// Check if subject has reply prefix
  static bool hasReplyPrefix(String subject) {
    return _startsWithReplyPrefix(subject.trim());
  }
  
  /// Check if subject has forward prefix
  static bool hasForwardPrefix(String subject) {
    return _startsWithForwardPrefix(subject.trim());
  }
  
  // Private helper methods
  
  static bool _startsWithReplyPrefix(String subject) {
    if (subject.length < 3) return false;
    return subject.toLowerCase().startsWith('re:');
  }
  
  static bool _startsWithForwardPrefix(String subject) {
    if (subject.length < 3) return false;
    final lower = subject.toLowerCase();
    return lower.startsWith('fwd:') || lower.startsWith('fw:');
  }
  
  /// Generate subject based on reply type (recommended method)
  static String generateSubjectForReply({
    required String originalSubject,
    required ReplyType replyType,
  }) {
    switch (replyType) {
      case ReplyType.reply:
      case ReplyType.replyAll:
        return addReplyPrefix(originalSubject);
      case ReplyType.forward:
        return addForwardPrefix(originalSubject);
    }
  }
}