// lib/src/features/mail/presentation/widgets/web/tree/tree_error_widget.dart

import 'package:flutter/material.dart';
import '../../../../../../core/error/exceptions.dart';

/// Error widget for tree loading failures
///
/// Displays appropriate error messages and retry options
class TreeErrorWidget extends StatelessWidget {
  final Object error;
  final VoidCallback? onRetry;

  const TreeErrorWidget({super.key, required this.error, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final errorInfo = _getErrorInfo(error);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Error icon
            Icon(errorInfo.icon, size: 48, color: errorInfo.color),

            const SizedBox(height: 16),

            // Error title
            Text(
              errorInfo.title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            // Error message
            Text(
              errorInfo.message,
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 20),

            // Action buttons
            _buildActionButtons(context, errorInfo),
          ],
        ),
      ),
    );
  }

  /// Build action buttons
  Widget _buildActionButtons(BuildContext context, ErrorInfo errorInfo) {
    return Column(
      children: [
        // Retry button
        if (onRetry != null)
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Tekrar Dene'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),

        const SizedBox(height: 8),

        // Help text
        if (errorInfo.helpText != null)
          TextButton(
            onPressed: () => _showHelpDialog(context, errorInfo),
            child: Text(
              'Yardım',
              style: TextStyle(fontSize: 12, color: Colors.blue[600]),
            ),
          ),
      ],
    );
  }

  /// Show help dialog
  void _showHelpDialog(BuildContext context, ErrorInfo errorInfo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yardım'),
        content: Text(errorInfo.helpText!),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  /// Get error information based on error type
  ErrorInfo _getErrorInfo(Object error) {
    if (error is NetworkException) {
      return ErrorInfo(
        icon: Icons.wifi_off,
        color: Colors.orange[600]!,
        title: 'Bağlantı Hatası',
        message: 'İnternet bağlantınızı kontrol edin',
        helpText:
            'Ağ bağlantınızın aktif olduğundan ve sunucuya erişebildiğinizden emin olun.',
      );
    }

    if (error is ServerException) {
      return ErrorInfo(
        icon: Icons.error_outline,
        color: Colors.red[600]!,
        title: 'Sunucu Hatası',
        message: 'Sunucuya erişilemiyor',
        helpText:
            'Sunucu geçici olarak kullanılamıyor olabilir. Lütfen daha sonra tekrar deneyin.',
      );
    }

    if (error.toString().contains('context') ||
        error.toString().contains('organization')) {
      return ErrorInfo(
        icon: Icons.account_tree,
        color: Colors.blue[600]!,
        title: 'Bağlam Hatası',
        message: 'Organizasyon veya bağlam seçilmedi',
        helpText:
            'Klasörleri görüntülemek için önce bir organizasyon ve mail bağlamı seçin.',
      );
    }

    if (error.toString().contains('permission') ||
        error.toString().contains('unauthorized')) {
      return ErrorInfo(
        icon: Icons.lock_outline,
        color: Colors.orange[600]!,
        title: 'Yetki Hatası',
        message: 'Bu klasörlere erişim yetkiniz yok',
        helpText:
            'Klasörlere erişmek için gerekli izinlere sahip olmayabilirsiniz. Yöneticinizle iletişime geçin.',
      );
    }

    // Generic error
    return ErrorInfo(
      icon: Icons.error_outline,
      color: Colors.red[600]!,
      title: 'Bilinmeyen Hata',
      message: 'Klasörler yüklenirken bir hata oluştu',
      helpText:
          'Beklenmeyen bir hata oluştu. Sayfayı yenilemeyi veya daha sonra tekrar denemeyi deneyin.',
    );
  }
}

/// Error information model
class ErrorInfo {
  final IconData icon;
  final Color color;
  final String title;
  final String message;
  final String? helpText;

  const ErrorInfo({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
    this.helpText,
  });
}
