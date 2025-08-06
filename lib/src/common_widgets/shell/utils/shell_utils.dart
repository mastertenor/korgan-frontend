// lib/src/common_widgets/shell/utils/shell_utils.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Utility functions for shell components
/// 
/// Shell bileşenleri tarafından kullanılan yardımcı fonksiyonlar.
/// Route parsing, module detection, text formatting vb.
class ShellUtils {
  const ShellUtils._(); // Prevent instantiation

  /// Get current module from route
  /// 
  /// GoRouter'daki mevcut route'dan hangi modülde olduğumuzu çıkarır.
  /// Route segments'ini parse ederek display name'e çevirir.
  /// 
  /// Example:
  /// - /mail/user@example.com → 'Mail'
  /// - /crm/contacts → 'CRM'
  /// - / → '' (empty - home page)
  static String getCurrentModule(BuildContext context) {
    final location = GoRouter.of(context).routerDelegate.currentConfiguration.uri.toString();
    final segments = location.split('/');
    
    if (segments.length > 1 && segments[1].isNotEmpty) {
      final module = segments[1];
      // Map route segments to display names
      switch (module) {
        case 'mail':
          return 'Mail';
        case 'crm':
          return 'CRM';
        case 'tasks':
          return 'Görevler';
        case 'files':
          return 'Dosyalar';
        case 'chat':
          return 'Sohbet';
        case 'dashboard':
          return 'Dashboard';
        default:
          return _capitalize(module);
      }
    }
    return '';
  }

  /// Capitalize first letter of text
  /// 
  /// String'in ilk harfini büyük yapar.
  /// Bilinmeyen module name'ler için kullanılır.
  static String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  /// Check if currently on home page
  /// 
  /// Şu anda ana sayfada mıyız kontrolü.
  static bool isOnHomePage(BuildContext context) {
    final location = GoRouter.of(context).routerDelegate.currentConfiguration.uri.toString();
    return location == '/' || location.isEmpty;
  }

  /// Get route segments
  /// 
  /// Route'u segment'lere böler. Debug için yararlı.
  static List<String> getRouteSegments(BuildContext context) {
    final location = GoRouter.of(context).routerDelegate.currentConfiguration.uri.toString();
    return location.split('/').where((segment) => segment.isNotEmpty).toList();
  }

  /// Get current route location
  /// 
  /// Mevcut route'un tam path'ini döndürür.
  static String getCurrentLocation(BuildContext context) {
    return GoRouter.of(context).routerDelegate.currentConfiguration.uri.toString();
  }
}