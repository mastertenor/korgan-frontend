// lib/src/features/mail/presentation/widgets/mobile/mail_detail_actions/mail_detail_actions_models.dart

/// Mail Detail Actions Model Sınıfları
///
/// Bu dosya mail detail sayfasında kullanılan action butonları ve menü öğeleri
/// için model sınıflarını içerir. Yandex Mail benzeri UI için tasarlanmıştır.
///
/// Sorumlulukları:
/// - Action type enums tanımlamak
/// - Action item model sınıfları sağlamak
/// - Constant action listeleri sunmak
/// - UI metadata yönetmek
library;

import 'package:flutter/material.dart';

/// Mail üzerinde yapılabilecek aksiyonların enum listesi
///
/// Bottom bar ve action sheet'te kullanılacak tüm aksiyonları içerir.
/// Her action'ın kendine ait icon, title ve davranışı vardır.
enum MailAction {
  // Ana bottom bar aksiyonları
  reply, // Yanıtla
  forward, // İlet
  markImportant, // Önemli olarak işaretle (eski archive yerine)
  delete, // Sil
  // Action sheet (üç nokta menü) aksiyonları
  markRead, // Okundu/Okunmadı olarak işaretle
  markUnread, // Okunmadı olarak işaretle (ayrı enum değer)
  addLabel, // Klasöre taşı / Etiket ekle
  archive, // Arşivle (action sheet'e taşındı)
  spam, // Spam olarak işaretle
  permanent, // Sabitle
  createRule, // Kural oluştur
  translate, // Çevirmeni göster
  print, // Yazdır
  moreOptions, // Daha fazla seçenek (nested menu için)
}

/// Action item model sınıfı
///
/// Her action item'ı için UI metadata'sını tutar.
/// ListTile, IconButton ve diğer UI componentleri tarafından kullanılır.
class MailActionItem {
  /// Action type - hangi aksiyonun yapılacağını belirler
  final MailAction action;

  /// Action icon - Material Icons
  final IconData icon;

  /// Action title - kullanıcıya gösterilecek ana metin
  final String title;

  /// Action subtitle - opsiyonel açıklama metni
  final String? subtitle;

  /// Action aktif mi - false ise disabled gösterilir
  final bool enabled;

  /// Action destructive mi - kırmızı renk kullanılır (delete, spam vb.)
  final bool isDestructive;

  /// Action color override - özel renk kullanımı için
  final Color? color;

  const MailActionItem({
    required this.action,
    required this.icon,
    required this.title,
    this.subtitle,
    this.enabled = true,
    this.isDestructive = false,
    this.color,
  });

  /// Copy with method - immutable updates için
  MailActionItem copyWith({
    MailAction? action,
    IconData? icon,
    String? title,
    String? subtitle,
    bool? enabled,
    bool? isDestructive,
    Color? color,
  }) {
    return MailActionItem(
      action: action ?? this.action,
      icon: icon ?? this.icon,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      enabled: enabled ?? this.enabled,
      isDestructive: isDestructive ?? this.isDestructive,
      color: color ?? this.color,
    );
  }

  /// Debugging için string representation
  @override
  String toString() {
    return 'MailActionItem(action: $action, title: $title, enabled: $enabled)';
  }
}

/// Bottom bar actions - ana 4 buton
///
/// Yandex Mail benzeri bottom bar için constant action listesi.
/// Her action'ın icon ve title bilgisi bulunur.
class BottomBarActions {
  static const List<MailActionItem> primaryActions = [
    MailActionItem(
      action: MailAction.reply,
      icon: Icons.reply,
      title: 'Yanıtla',
      subtitle: 'Bu maile yanıt yaz',
    ),
    MailActionItem(
      action: MailAction.forward,
      icon: Icons.forward,
      title: 'İlet',
      subtitle: 'Bu maili başkasına ilet',
    ),
    MailActionItem(
      action: MailAction.markImportant,
      icon: Icons.label_important,
      title: 'Önemli',
      subtitle: 'Önemli olarak işaretle',
    ),
    MailActionItem(
      action: MailAction.delete,
      icon: Icons.delete,
      title: 'Sil',
      subtitle: 'Çöp kutusuna taşı',
      isDestructive: true,
    ),
  ];

  /// More actions butonu için
  static const MailActionItem moreActionsButton = MailActionItem(
    action: MailAction.moreOptions,
    icon: Icons.more_horiz, // 🔄 Yatay üç nokta
    title: 'Daha fazla',
    subtitle: 'Ek seçenekler',
  );
}

/// Action sheet actions - üç nokta menü öğeleri
///
/// Action sheet'te gösterilecek tüm aksiyonların listesi.
/// Kategorilere ayrılmış olarak düzenlenmiştir.
class ActionSheetActions {
  /// Sık kullanılan aksiyonlar - üstte gösterilir
  static const List<MailActionItem> frequentActions = [
    MailActionItem(
      action: MailAction.markRead,
      icon: Icons.mark_email_read,
      title: 'Okundu olarak işaretle',
      subtitle: 'Bu maili okundu duruma getir',
    ),
    MailActionItem(
      action: MailAction.markUnread,
      icon: Icons.mark_email_unread,
      title: 'Okunmadı olarak işaretle',
      subtitle: 'Bu maili okunmadı duruma getir',
    ),
    MailActionItem(
      action: MailAction.addLabel,
      icon: Icons.folder,
      title: 'Klasöre taşı',
      subtitle: 'Farklı klasöre taşı veya etiket ekle',
    ),
  ];

  /// Diğer aksiyonlar - altta gösterilir
  static const List<MailActionItem> otherActions = [
    MailActionItem(
      action: MailAction.archive,
      icon: Icons.archive,
      title: 'Arşivle',
      subtitle: 'Arşiv klasörüne taşı',
    ),
    MailActionItem(
      action: MailAction.spam,
      icon: Icons.report,
      title: 'Spam',
      subtitle: 'Spam olarak işaretle',
      isDestructive: true,
      color: Colors.orange,
    ),
    MailActionItem(
      action: MailAction.permanent,
      icon: Icons.push_pin,
      title: 'Sabitle',
      subtitle: 'Bu maili listede sabitle',
    ),
    MailActionItem(
      action: MailAction.createRule,
      icon: Icons.rule,
      title: 'Kural oluştur',
      subtitle: 'Bu tip mailler için otomatik kural oluştur',
    ),
    MailActionItem(
      action: MailAction.translate,
      icon: Icons.translate,
      title: 'Çevirmeni göster',
      subtitle: 'Mail içeriğini çevir',
    ),
    MailActionItem(
      action: MailAction.print,
      icon: Icons.print,
      title: 'Yazdır',
      subtitle: 'Bu maili yazdır',
    ),
  ];

  /// Tüm action sheet aksiyonları - birleştirilmiş liste
  static List<MailActionItem> get allActions => [
    ...frequentActions,
    ...otherActions,
  ];
}

/// Action result model - action tamamlandığında dönen sonuç
///
/// Action handler'ların sonuç bilgisini taşır.
/// Success/failure durumları ve mesajları içerir.
class MailActionResult {
  /// Action başarılı mı
  final bool success;

  /// Sonuç mesajı - kullanıcıya gösterilecek
  final String message;

  /// Hata durumunda hata detayı
  final String? error;

  /// Action sonrası UI güncellemesi gerekli mi
  final bool requiresRefresh;

  /// Action sonrası navigasyon gerekli mi (ör: delete sonrası geri dön)
  final bool requiresNavigation;

  const MailActionResult({
    required this.success,
    required this.message,
    this.error,
    this.requiresRefresh = false,
    this.requiresNavigation = false,
  });

  /// Success result factory
  factory MailActionResult.success({
    required String message,
    bool requiresRefresh = false,
    bool requiresNavigation = false,
  }) {
    return MailActionResult(
      success: true,
      message: message,
      requiresRefresh: requiresRefresh,
      requiresNavigation: requiresNavigation,
    );
  }

  /// Failure result factory
  factory MailActionResult.failure({required String message, String? error}) {
    return MailActionResult(success: false, message: message, error: error);
  }

  @override
  String toString() {
    return 'MailActionResult(success: $success, message: $message)';
  }
}

/// Action context - action'ın yapıldığı bağlam bilgisi
///
/// Action handler'lara geçirilecek context bilgisini tutar.
/// Mail detayı, kullanıcı bilgisi ve UI callback'leri içerir.
class MailActionContext {
  /// Aksiyon yapılacak mail detayı
  final dynamic
  mailDetail; // MailDetail type - import conflict önlemek için dynamic

  /// Mevcut kullanıcının email adresi
  final String currentUserEmail;

  /// Parent widget context - navigation ve snackbar için
  final BuildContext context;

  /// Action tamamlandığında çağrılacak callback
  final Function(MailActionResult)? onActionCompleted;

  const MailActionContext({
    required this.mailDetail,
    required this.currentUserEmail,
    required this.context,
    this.onActionCompleted,
  });
}

/// Utility sınıfı - action helper methodları
///
/// Action'larla ilgili yardımcı methodlar ve validasyonlar.
class MailActionUtils {
  /// Action'ın mail durumuna göre enabled olup olmadığını kontrol eder
  static bool isActionEnabled(MailAction action, dynamic mailDetail) {
    // Örnek validasyonlar
    switch (action) {
      case MailAction.markRead:
        return mailDetail?.isRead == false; // Sadece okunmamış maillerde aktif
      case MailAction.markUnread:
        return mailDetail?.isRead == true; // Sadece okunmuş maillerde aktif
      case MailAction.archive:
        return mailDetail != null; // Mail varsa aktif
      case MailAction.delete:
        return mailDetail != null; // Mail varsa aktif
      default:
        return true; // Diğerleri her zaman aktif
    }
  }

  /// Action için uygun icon rengini döner
  static Color? getActionColor(
    MailActionItem actionItem,
    BuildContext context,
  ) {
    if (actionItem.color != null) {
      return actionItem.color;
    }

    if (actionItem.isDestructive) {
      return Theme.of(context).colorScheme.error;
    }

    if (!actionItem.enabled) {
      return Theme.of(context).disabledColor;
    }

    return Theme.of(context).colorScheme.primary;
  }

  /// Action title'ı mail durumuna göre güncellenmiş haliyle döner
  static String getContextualTitle(
    MailActionItem actionItem,
    dynamic mailDetail,
  ) {
    switch (actionItem.action) {
      case MailAction.markRead:
        return mailDetail?.isRead == true
            ? 'Okunmadı olarak işaretle'
            : 'Okundu olarak işaretle';
      case MailAction.markUnread:
        return mailDetail?.isRead == false
            ? 'Okundu olarak işaretle'
            : 'Okunmadı olarak işaretle';
      default:
        return actionItem.title;
    }
  }
}
