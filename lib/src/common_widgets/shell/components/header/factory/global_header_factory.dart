// lib/src/common_widgets/shell/components/header/factory/global_header_factory.dart

import 'package:flutter/material.dart';
import '../../../../../utils/platform_helper.dart';
import '../../../../../utils/app_logger.dart';
import '../../../utils/shell_utils.dart';
import '../platform/web/global_header_web.dart';
import '../platform/mobile/global_header_mobile.dart';

/// Factory for creating platform-specific header implementations
class GlobalHeaderFactory {
  const GlobalHeaderFactory._(); // Prevent instantiation

  /// Creates platform-appropriate header widget
  static Widget create(BuildContext context) {
    if (PlatformHelper.shouldUseWebExperience) {
      final currentModule = ShellUtils.getCurrentModule(context);
      AppLogger.debug('🌐 Using WebGlobalHeaderWeb (desktop web) - module: $currentModule');
      return GlobalHeaderWeb(currentModule: currentModule); // ✅ parametre verildi
    } else {
      AppLogger.debug('📱 Using WebGlobalHeaderMobile (mobile experience)');
      return const GlobalHeaderMobile();
    }
  }
}
