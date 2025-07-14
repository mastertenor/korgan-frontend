// lib/src/features/mail/presentation/widgets/mobile/mail_detail_actions/mail_detail_bottom_bar.dart

/// Mail Detail Bottom Bar Widget
///
/// Bu widget mail detail sayfasının altında sabit olarak duran action bar'ı sağlar.
/// Yandex Mail benzeri tasarımda 4 ana buton + üç nokta menü bulunur.
///
/// Stack Layout ile gesture conflict'leri önler ve InAppWebView ile çakışmaz.
///
/// Sorumlulukları:
/// - 4 ana action butonunu göstermek (Reply, Forward, Archive, Delete)
/// - Üç nokta menü butonunu sağlamak
/// - Material 3 tasarım uyumluluğu
/// - Safe area ve responsive tasarım desteği
/// - Touch-friendly button sizing
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'mail_detail_actions_models.dart';

/// Mail detail bottom bar widget'ı
///
/// Sabit konumda duran action bar. Stack layout ile position'lanır.
class MailDetailBottomBar extends StatelessWidget {
  /// Mail detay verisi - button state'leri için kullanılır
  final dynamic
  mailDetail; // MailDetail type - import conflict önlemek için dynamic

  /// Mevcut kullanıcının email adresi
  final String currentUserEmail;

  /// Yanıtla butonu callback'i - mevcut _replyToMail method'unu çağıracak
  final VoidCallback? onReply;

  /// İlet butonu callback'i - placeholder implementation
  final VoidCallback? onForward;

  /// Önemli butonu callback'i - placeholder implementation
  final VoidCallback? onMarkImportant;

  /// Sil butonu callback'i - placeholder implementation
  final VoidCallback? onDelete;

  /// Üç nokta menü callback'i - action sheet açacak
  final VoidCallback? onMoreActions;

  /// Widget disabled mi - loading durumunda kullanılır
  final bool isEnabled;

  const MailDetailBottomBar({
    super.key,
    required this.mailDetail,
    required this.currentUserEmail,
    this.onReply,
    this.onForward,
    this.onMarkImportant,
    this.onDelete,
    this.onMoreActions,
    this.isEnabled = true,
  });

  /// Bottom bar height constant - Stack layout için - 🔧 DAHA COMPACT
  static const double height = 60.0; // 80.0'dan 60.0'a düştü

  /// Button padding constant - 🔧 DAHA COMPACT
  static const double buttonPadding = 1.0; // 12.0'dan 8.0'a düştü

  /// Safe area extra padding - 🔧 DAHA COMPACT
  static const double safeAreaPadding = 1.0; // 16.0'dan 12.0'a düştü

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);

    // Safe area bottom padding hesapla
    final bottomPadding = mediaQuery.padding.bottom + safeAreaPadding;
    final totalHeight = height + bottomPadding;

    return Container(
      height: totalHeight,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: safeAreaPadding,
            vertical: buttonPadding,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Ana 4 action butonu
              ...BottomBarActions.primaryActions.map(
                (actionItem) => _buildActionButton(
                  context,
                  actionItem,
                  _getActionCallback(actionItem.action),
                ),
              ),

              // Üç nokta menü butonu
              _buildActionButton(
                context,
                BottomBarActions.moreActionsButton,
                onMoreActions,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Action button builder
  ///
  /// Her action için consistent button tasarımı sağlar.
  /// Material 3 tasarım kılavuzuna uygun iconbutton style.
  Widget _buildActionButton(
    BuildContext context,
    MailActionItem actionItem,
    VoidCallback? onPressed,
  ) {
    final theme = Theme.of(context);
    final isButtonEnabled =
        isEnabled &&
        actionItem.enabled &&
        MailActionUtils.isActionEnabled(actionItem.action, mailDetail);

    return Expanded(
      child: Tooltip(
        message: actionItem.subtitle ?? actionItem.title,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isButtonEnabled
                ? () {
                    // Haptic feedback
                    HapticFeedback.lightImpact();

                    // Debug logging
                    debugPrint(
                      '🔘 Bottom bar action: ${actionItem.action.name}',
                    );

                    // Callback çağır
                    onPressed?.call();
                  }
                : null,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),

                // Subtle background color for better touch feedback
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon
                  Icon(actionItem.icon, size: 24),

                  const SizedBox(height: 4),

                  // Label
                  Text(
                    MailActionUtils.getContextualTitle(actionItem, mailDetail),
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Action callback mapper
  ///
  /// MailAction enum'ını widget callback'lerine map eder.
  /// Her action için ilgili callback method'unu döner.
  VoidCallback? _getActionCallback(MailAction action) {
    switch (action) {
      case MailAction.reply:
        return onReply;
      case MailAction.forward:
        return onForward;
      case MailAction.markImportant:
        return onMarkImportant;
      case MailAction.delete:
        return onDelete;
      case MailAction.moreOptions:
        return onMoreActions;
      default:
        return null;
    }
  }
}

/// Bottom bar placeholder implementations
///
/// Action callback'leri için placeholder implementasyonlar.
/// Gerçek implementasyon daha sonra eklenecek.
class MailDetailBottomBarCallbacks {
  /// Reply action - mevcut _replyToMail method'unu çağırır
  static VoidCallback createReplyCallback({
    required BuildContext context,
    required dynamic mailDetail,
    required String currentUserEmail,
  }) {
    return () {
      debugPrint('🔘 Reply action triggered');

      // Bu callback mail_detail_mobile.dart'daki _replyToMail method'unu çağıracak
      // Implementation parent widget'da yapılacak

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Reply action - parent widget implementation needed'),
          backgroundColor: Colors.blue,
        ),
      );
    };
  }

  /// Forward action placeholder
  static VoidCallback createForwardCallback({
    required BuildContext context,
    required dynamic mailDetail,
  }) {
    return () {
      debugPrint('📤 Forward action - placeholder');
      HapticFeedback.lightImpact();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📤 İletme özelliği yakında!'),
          backgroundColor: Colors.orange,
        ),
      );
    };
  }

  /// Mark important action placeholder
  static VoidCallback createMarkImportantCallback({
    required BuildContext context,
    required dynamic mailDetail,
  }) {
    return () {
      debugPrint('⭐ Mark important action - placeholder');
      HapticFeedback.lightImpact();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⭐ Önemli işaretleme özelliği yakında!'),
          backgroundColor: Colors.amber,
        ),
      );
    };
  }

  /// Delete action placeholder
  static VoidCallback createDeleteCallback({
    required BuildContext context,
    required dynamic mailDetail,
  }) {
    return () {
      debugPrint('🗑️ Delete action - placeholder');
      HapticFeedback.mediumImpact();

      // Confirmation dialog göster
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('🗑️ Maili Sil'),
          content: const Text(
            'Bu maili çöp kutusuna taşımak istediğinizden emin misiniz?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('🗑️ Silme özelliği yakında!'),
                    backgroundColor: Colors.red,
                  ),
                );
              },
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Sil'),
            ),
          ],
        ),
      );
    };
  }

  /// More actions callback - action sheet açar
  static VoidCallback createMoreActionsCallback({
    required BuildContext context,
    required dynamic mailDetail,
    required String currentUserEmail,
  }) {
    return () {
      debugPrint('⋮ More actions - action sheet açılacak');
      HapticFeedback.lightImpact();

      // Şimdilik placeholder snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⋮ Action sheet yakında implementasyon edilecek!'),
          backgroundColor: Colors.purple,
        ),
      );

      // TODO: Action sheet widget'ını çağır
      // showModalBottomSheet(...);
    };
  }
}

/// Bottom bar extension methods
///
/// MailDetail type için extension methodlar.
/// Widget state hesaplamaları için kullanılır.
extension MailDetailBottomBarExtensions on dynamic {
  /// Mail'in reply edilebilir olup olmadığını kontrol eder
  bool get canReply => this != null;

  /// Mail'in forward edilebilir olup olmadığını kontrol eder
  bool get canForward => this != null;

  /// Mail'in archive edilebilir olup olmadığını kontrol eder
  bool get canArchive => this != null;

  /// Mail'in delete edilebilir olup olmadığını kontrol eder
  bool get canDelete => this != null;
}
