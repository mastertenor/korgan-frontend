// lib/src/features/mail/presentation/widgets/mobile/mail_detail_actions/mail_detail_action_sheet.dart

/// Mail Detail Action Sheet Widget
///
/// Bu widget üç nokta menüsüne tıklandığında açılan bottom sheet'i sağlar.
/// Yandex Mail benzeri tasarımda tüm ek aksiyonları içerir.
///
/// Action sheet kategorilere ayrılmış şekilde düzenlenmiştir:
/// - Sık kullanılan aksiyonlar (üstte)
/// - Diğer aksiyonlar (altta)
///
/// Sorumlulukları:
/// - Action listesini göstermek
/// - Action seçimlerini handle etmek
/// - Gesture dismissible bottom sheet sağlamak
/// - Material 3 tasarım uyumluluğu
/// - Safe area ve responsive tasarım desteği
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'mail_detail_actions_models.dart';

/// Action sheet'i gösteren static method
///
/// Bu method bottom sheet'i açar ve kullanıcı seçimini handle eder.
/// Parent widget'dan çağrılması için static olarak tasarlanmıştır.
class MailDetailActionSheet {
  /// Action sheet'i göster
  ///
  /// [context] - BuildContext for navigation
  /// [mailDetail] - Mail detay verisi
  /// [currentUserEmail] - Mevcut kullanıcı email'i
  /// [onActionSelected] - Action seçildiğinde çağrılacak callback
  static Future<void> show({
    required BuildContext context,
    required dynamic mailDetail,
    required String currentUserEmail,
    required Function(MailAction) onActionSelected,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      builder: (context) => _MailDetailActionSheetContent(
        mailDetail: mailDetail,
        currentUserEmail: currentUserEmail,
        onActionSelected: onActionSelected,
      ),
    );
  }
}

/// Action sheet content widget'ı
///
/// Bottom sheet içeriğini oluşturan private widget.
/// Action listesini render eder ve seçimleri handle eder.
class _MailDetailActionSheetContent extends StatelessWidget {
  final dynamic mailDetail;
  final String currentUserEmail;
  final Function(MailAction) onActionSelected;

  const _MailDetailActionSheetContent({
    required this.mailDetail,
    required this.currentUserEmail,
    required this.onActionSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);

    // Safe area bottom padding
    final bottomPadding = mediaQuery.padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            _buildHandleBar(context),

            // Header
            _buildHeader(context),

            // Frequent actions section
            _buildActionsSection(
              context: context,
              title: 'Sık Kullanılan',
              actions: ActionSheetActions.frequentActions,
            ),

            // Divider
            _buildDivider(context),

            // Other actions section
            _buildActionsSection(
              context: context,
              title: 'Diğer Seçenekler',
              actions: ActionSheetActions.otherActions,
            ),

            // Bottom padding
            SizedBox(height: bottomPadding + 16),
          ],
        ),
      ),
    );
  }

  /// Handle bar - sheet'i kaydırmak için
  Widget _buildHandleBar(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 8),
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: theme.colorScheme.outline.withOpacity(0.4),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  /// Header section - title ve açıklama
  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Row(
        children: [
          // Mail icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.email,
              color: theme.colorScheme.primary,
              size: 20,
            ),
          ),

          const SizedBox(width: 16),

          // Title ve subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mail İşlemleri',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Bu mail için mevcut işlemler',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),

          // Close button
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.close,
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
            style: IconButton.styleFrom(
              backgroundColor: theme.colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Actions section builder
  Widget _buildActionsSection({
    required BuildContext context,
    required String title,
    required List<MailActionItem> actions,
  }) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        // Action items
        ...actions.map((actionItem) => _buildActionItem(context, actionItem)),
      ],
    );
  }

  /// Action item builder
  Widget _buildActionItem(BuildContext context, MailActionItem actionItem) {
    final theme = Theme.of(context);
    final isEnabled =
        actionItem.enabled &&
        MailActionUtils.isActionEnabled(actionItem.action, mailDetail);

    // Action color hesapla
    Color? actionColor = MailActionUtils.getActionColor(actionItem, context);
    if (!isEnabled) {
      actionColor = theme.disabledColor;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isEnabled
            ? () => _handleActionSelection(context, actionItem)
            : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            children: [
              // Action icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: actionColor?.withOpacity(0.1) ?? Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(actionItem.icon, color: actionColor, size: 20),
              ),

              const SizedBox(width: 16),

              // Action text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      MailActionUtils.getContextualTitle(
                        actionItem,
                        mailDetail,
                      ),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: isEnabled
                            ? theme.colorScheme.onSurface
                            : theme.disabledColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (actionItem.subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        actionItem.subtitle!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isEnabled
                              ? theme.colorScheme.onSurface.withOpacity(0.7)
                              : theme.disabledColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Arrow icon (opsiyonel)
              if (isEnabled)
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: theme.colorScheme.onSurface.withOpacity(0.4),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Divider builder
  Widget _buildDivider(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      height: 1,
      color: theme.colorScheme.outline.withOpacity(0.2),
    );
  }

  /// Action seçimi handle et
  void _handleActionSelection(BuildContext context, MailActionItem actionItem) {
    // Haptic feedback
    HapticFeedback.lightImpact();

    // Debug logging
    debugPrint('📱 Action sheet selection: ${actionItem.action.name}');

    // Sheet'i kapat
    Navigator.pop(context);

    // Parent callback'i çağır
    onActionSelected(actionItem.action);
  }
}

/// Action sheet placeholder implementations
///
/// Action callback'leri için placeholder implementasyonlar.
/// Gerçek implementasyon daha sonra eklenecek.
class MailDetailActionSheetCallbacks {
  /// Action selection handler
  static Function(MailAction) createActionHandler({
    required BuildContext context,
    required dynamic mailDetail,
    required String currentUserEmail,
  }) {
    return (MailAction action) {
      debugPrint('🎯 Action selected: ${action.name}');

      switch (action) {
        case MailAction.markRead:
          _handleMarkRead(context, mailDetail);
          break;
        case MailAction.markUnread:
          _handleMarkUnread(context, mailDetail);
          break;
        case MailAction.addLabel:
          _handleAddLabel(context, mailDetail);
          break;
        case MailAction.spam:
          _handleSpam(context, mailDetail);
          break;
        case MailAction.permanent:
          _handlePermanent(context, mailDetail);
          break;
        case MailAction.createRule:
          _handleCreateRule(context, mailDetail);
          break;
        case MailAction.translate:
          _handleTranslate(context, mailDetail);
          break;
        case MailAction.print:
          _handlePrint(context, mailDetail);
          break;
        default:
          _handleUnknownAction(context, action);
          break;
      }
    };
  }

  /// Mark as read action
  static void _handleMarkRead(BuildContext context, dynamic mailDetail) {
    debugPrint('✅ Mark as read - placeholder');
    HapticFeedback.lightImpact();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          mailDetail?.isRead == true
              ? '📧 Okunmadı olarak işaretlendi!'
              : '✅ Okundu olarak işaretlendi!',
        ),
        backgroundColor: Colors.blue,
      ),
    );
  }

  /// Mark as unread action
  static void _handleMarkUnread(BuildContext context, dynamic mailDetail) {
    debugPrint('📧 Mark as unread - placeholder');
    HapticFeedback.lightImpact();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📧 Okunmadı işaretleme özelliği yakında!'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  /// Add label / Move to folder action
  static void _handleAddLabel(BuildContext context, dynamic mailDetail) {
    debugPrint('📁 Add label - placeholder');
    HapticFeedback.lightImpact();

    // Show folder selection dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('📁 Klasör Seç'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.inbox),
              title: const Text('Gelen Kutusu'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('📁 Klasör taşıma özelliği yakında!'),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.archive),
              title: const Text('Arşiv'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('📁 Arşivleme özelliği yakında!'),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.folder),
              title: const Text('Özel Klasör'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('📁 Özel klasör özelliği yakında!'),
                  ),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
        ],
      ),
    );
  }

  /// Spam action
  static void _handleSpam(BuildContext context, dynamic mailDetail) {
    debugPrint('🚫 Spam - placeholder');
    HapticFeedback.mediumImpact();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🚫 Spam Olarak İşaretle'),
        content: const Text(
          'Bu maili spam olarak işaretlemek istediğinizden emin misiniz?',
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
                  content: Text('🚫 Spam işaretleme özelliği yakında!'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Spam Olarak İşaretle'),
          ),
        ],
      ),
    );
  }

  /// Permanent action
  static void _handlePermanent(BuildContext context, dynamic mailDetail) {
    debugPrint('📌 Permanent - placeholder');
    HapticFeedback.lightImpact();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📌 Sabitleme özelliği yakında!'),
        backgroundColor: Colors.purple,
      ),
    );
  }

  /// Create rule action
  static void _handleCreateRule(BuildContext context, dynamic mailDetail) {
    debugPrint('⚙️ Create rule - placeholder');
    HapticFeedback.lightImpact();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('⚙️ Kural oluşturma özelliği yakında!'),
        backgroundColor: Colors.indigo,
      ),
    );
  }

  /// Translate action
  static void _handleTranslate(BuildContext context, dynamic mailDetail) {
    debugPrint('🌐 Translate - placeholder');
    HapticFeedback.lightImpact();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🌐 Çeviri özelliği yakında!'),
        backgroundColor: Colors.teal,
      ),
    );
  }

  /// Print action
  static void _handlePrint(BuildContext context, dynamic mailDetail) {
    debugPrint('🖨️ Print - placeholder');
    HapticFeedback.lightImpact();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🖨️ Yazdırma özelliği yakında!'),
        backgroundColor: Colors.brown,
      ),
    );
  }

  /// Unknown action fallback
  static void _handleUnknownAction(BuildContext context, MailAction action) {
    debugPrint('❓ Unknown action: ${action.name}');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('❓ Bilinmeyen işlem: ${action.name}'),
        backgroundColor: Colors.grey,
      ),
    );
  }
}
