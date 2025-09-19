// lib/src/features/mail/presentation/providers/mail_context_provider.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../utils/app_logger.dart';
import '../../../organization/presentation/providers/organization_providers.dart';
import '../../domain/entities/mail_context.dart';

/// Mail context state notifier
///
/// Manages the currently selected mail context and provides
/// context switching functionality for the mail module.
class MailContextNotifier extends StateNotifier<MailContext?> {
  MailContextNotifier() : super(null) {
    AppLogger.info('🔧 MailContextNotifier: Initialized');
  }

  /// Set the selected mail context
  void setContext(MailContext context) {
    final previousContext = state;
    state = context;

    AppLogger.info(
      '🔄 Mail context switched: ${previousContext?.emailAddress} → ${context.emailAddress}',
    );

    // Log permission summary
    AppLogger.debug(
      '📧 Context permissions: ${context.contextPermissions.length} permissions',
    );
  }

  /// Clear the selected context
  void clearContext() {
    final previousEmail = state?.emailAddress;
    state = null;

    AppLogger.info('🧹 Mail context cleared: $previousEmail');
  }

  /// Auto-select first available context if none selected
  void autoSelectFirstContext(List<MailContext> availableContexts) {
    if (state == null && availableContexts.isNotEmpty) {
      setContext(availableContexts.first);
      AppLogger.info(
        '🎯 Auto-selected first context: ${availableContexts.first.emailAddress}',
      );
    }
  }

  /// Check if context has specific permission
  bool hasPermission(String permission) {
    return state?.hasPermission(permission) ?? false;
  }

  /// Validate current context is still available
  void validateContext(List<MailContext> availableContexts) {
    if (state == null) return;

    final currentContextExists = availableContexts.any(
      (context) => context.id == state!.id,
    );

    if (!currentContextExists) {
      AppLogger.warning(
        '⚠️ Current context no longer available, clearing: ${state!.emailAddress}',
      );
      clearContext();
    }
  }
}

// ========== MAIN PROVIDERS ==========

/// Selected mail context provider
///
/// Manages the currently selected mail context for the mail module.
/// Returns null if no context is selected.
final selectedMailContextProvider =
    StateNotifierProvider<MailContextNotifier, MailContext?>((ref) {
      return MailContextNotifier();
    });

/// Available mail contexts provider
///
/// Returns list of mail contexts that the user can access
/// based on the currently selected organization.
final availableMailContextsProvider = Provider<List<MailContext>>((ref) {
  final selectedOrg = ref.watch(selectedOrganizationProvider);

  if (selectedOrg == null) {
    AppLogger.debug('📭 No organization selected, no mail contexts available');
    return [];
  }

  final contexts = selectedOrg.getActiveMailContexts();
  AppLogger.debug('📬 Available mail contexts: ${contexts.length}');

  return contexts;
});

/// Mail context notifier actions provider
///
/// Provides access to mail context notifier methods for UI interactions.
final mailContextActionsProvider = Provider<MailContextNotifier>((ref) {
  return ref.read(selectedMailContextProvider.notifier);
});

// ========== CONVENIENCE PROVIDERS ==========

/// Current mail email provider
///
/// Returns the email address of the currently selected mail context.
/// Returns null if no context is selected.
final currentMailEmailProvider = Provider<String?>((ref) {
  final context = ref.watch(selectedMailContextProvider);
  final email = context?.emailAddress;

  if (email != null) {
    AppLogger.debug('📧 Current mail email: $email');
  }

  return email;
});

/// Has mail access provider
///
/// Checks if the user has any mail access through the currently
/// selected mail context.
final hasMailAccessProvider = Provider<bool>((ref) {
  final context = ref.watch(selectedMailContextProvider);
  final hasAccess = context?.hasAnyMailAccess ?? false;

  AppLogger.debug('🔑 Has mail access: $hasAccess');
  return hasAccess;
});

/// Has mail contexts provider
///
/// Checks if the user has any available mail contexts
/// in the currently selected organization.
final hasMailContextsProvider = Provider<bool>((ref) {
  final contexts = ref.watch(availableMailContextsProvider);
  final hasContexts = contexts.isNotEmpty;

  AppLogger.debug(
    '📮 Has mail contexts: $hasContexts (${contexts.length} contexts)',
  );
  return hasContexts;
});

/// Is context selected provider
///
/// Checks if any mail context is currently selected.
final isContextSelectedProvider = Provider<bool>((ref) {
  final context = ref.watch(selectedMailContextProvider);
  return context != null;
});

// ========== PERMISSION PROVIDERS ==========

/// Context permission provider family
///
/// Checks if the currently selected context has a specific permission.
/// Usage: ref.watch(contextHasPermissionProvider('korgan.mail.send.context'))
final contextHasPermissionProvider = Provider.family<bool, String>((
  ref,
  permission,
) {
  final context = ref.watch(selectedMailContextProvider);
  final hasPermission = context?.hasPermission(permission) ?? false;

  AppLogger.debug('🔐 Context permission "$permission": $hasPermission');
  return hasPermission;
});

/// Specific permission providers for common use cases
final canSendMailProvider = Provider<bool>((ref) {
  return ref.watch(contextHasPermissionProvider('korgan.mail.send.context'));
});

final canDeleteMailProvider = Provider<bool>((ref) {
  return ref.watch(contextHasPermissionProvider('korgan.mail.delete.context'));
});

final canArchiveMailProvider = Provider<bool>((ref) {
  return ref.watch(contextHasPermissionProvider('korgan.mail.archive.context'));
});

final canSearchMailProvider = Provider<bool>((ref) {
  return ref.watch(contextHasPermissionProvider('korgan.mail.search.context'));
});

final canAccessAttachmentsProvider = Provider<bool>((ref) {
  return ref.watch(
    contextHasPermissionProvider('korgan.mail.attachment.context'),
  );
});

// ========== DISPLAY PROVIDERS ==========

/// Current context display info provider
///
/// Returns display information for the currently selected context.
/// Useful for UI elements that show current context status.
final currentContextDisplayProvider = Provider<Map<String, dynamic>>((ref) {
  final context = ref.watch(selectedMailContextProvider);

  if (context == null) {
    return {
      'hasContext': false,
      'displayName': 'Context seçilmedi',
      'email': null,
      'type': null,
      'icon': null,
      'color': null,
    };
  }

  return {
    'hasContext': true,
    'displayName': context.displayName,
    'email': context.emailAddress,
    'type': context.contextTypeDisplayName,
    'icon': context.contextIcon,
    'color': context.contextColor,
    'initials': context.initials,
    'permissionCount': context.contextPermissions.length,
  };
});

/// Context count info provider
///
/// Returns information about available contexts count for display.
final contextCountInfoProvider = Provider<String>((ref) {
  final availableContexts = ref.watch(availableMailContextsProvider);
  final selectedContext = ref.watch(selectedMailContextProvider);

  if (availableContexts.isEmpty) {
    return 'Mail hesabı yok';
  }

  if (availableContexts.length == 1) {
    return '1 mail hesabı';
  }

  final selectedIndex = selectedContext != null
      ? availableContexts.indexWhere((c) => c.id == selectedContext.id) + 1
      : 0;

  return selectedIndex > 0
      ? '$selectedIndex/${availableContexts.length} mail hesabı'
      : '${availableContexts.length} mail hesabı';
});

// ========== AUTO-SELECTION LOGIC ==========

/// Auto context selector provider
///
/// Automatically selects the first available context if none is selected.
/// This is a side-effect provider that should be watched in widgets
/// that need auto-selection behavior.
final autoContextSelectorProvider = Provider<void>((ref) {
  final availableContexts = ref.watch(availableMailContextsProvider);
  final selectedContext = ref.watch(selectedMailContextProvider);
  final notifier = ref.read(selectedMailContextProvider.notifier);

  // Auto-select logic
  if (selectedContext == null && availableContexts.isNotEmpty) {
    // Use addPostFrameCallback to avoid modifying provider during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifier.autoSelectFirstContext(availableContexts);
    });
  }

  // Validation logic
  if (selectedContext != null && availableContexts.isNotEmpty) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifier.validateContext(availableContexts);
    });
  }
});

// ========== DEBUGGING PROVIDER ==========

/// Debug info provider for development
final mailContextDebugProvider = Provider<Map<String, dynamic>>((ref) {
  final selectedContext = ref.watch(selectedMailContextProvider);
  final availableContexts = ref.watch(availableMailContextsProvider);
  final hasAccess = ref.watch(hasMailAccessProvider);

  return {
    'selectedContext': selectedContext?.toString(),
    'availableContextsCount': availableContexts.length,
    'hasMailAccess': hasAccess,
    'currentEmail': selectedContext?.emailAddress,
    'permissions': selectedContext?.contextPermissions ?? [],
  };
});
