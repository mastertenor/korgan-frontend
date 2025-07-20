// lib/src/features/mail/domain/enums/reply_type.dart

/// Mail yanıtlama türlerini tanımlayan enum
///
/// Bu enum mail reply sayfasında hangi türde yanıt verileceğini belirler.
/// Her türün kendine özel davranışları vardır:
/// - reply: Sadece gönderene yanıt
/// - replyAll: Tüm alıcılara yanıt  
/// - forward: Başka kişilere iletme
enum ReplyType {
  /// Sadece gönderene yanıt verme
  reply,
  
  /// Tüm alıcılara (to + cc) yanıt verme
  replyAll,
  
  /// Başka kişilere iletme
  forward,
}

/// ReplyType için extension metodları
extension ReplyTypeExtension on ReplyType {
  /// Display için uygun Türkçe isim
  String get displayName {
    switch (this) {
      case ReplyType.reply:
        return 'Yanıtla';
      case ReplyType.replyAll:
        return 'Tümüne Yanıtla';
      case ReplyType.forward:
        return 'İlet';
    }
  }
  
  /// AppBar title'da kullanılacak prefix
  String get titlePrefix {
    switch (this) {
      case ReplyType.reply:
        return 'Yanıtla:';
      case ReplyType.replyAll:
        return 'Tümüne Yanıtla:';
      case ReplyType.forward:
        return 'İlet:';
    }
  }
  
  /// Subject prefix (Re: veya Fw:)
  String get subjectPrefix {
    switch (this) {
      case ReplyType.reply:
      case ReplyType.replyAll:
        return 'Re:';
      case ReplyType.forward:
        return 'Fw:';
    }
  }
  

}