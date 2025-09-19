// lib/src/features/mail/domain/entities/mail_context.dart

import 'package:flutter/material.dart';

/// Mail context domain entity
///
/// Represents a mail context (email account) that a user can access within an organization.
/// Each context has its own set of permissions and represents a specific email address.
///
/// Business rules:
/// - ID must be non-empty
/// - Context key must be non-empty
/// - Email address must be valid
/// - Display name must be non-empty
/// - Context type must be 'personal' or 'group'
class MailContext {
  final String id;
  final String contextKey;
  final String emailAddress;
  final String displayName;
  final String contextType; // 'personal' or 'group'
  final bool isActive;
  final Map<String, dynamic> settings;
  final List<String> contextPermissions;

  const MailContext({
    required this.id,
    required this.contextKey,
    required this.emailAddress,
    required this.displayName,
    required this.contextType,
    required this.isActive,
    required this.settings,
    required this.contextPermissions,
  });

  // ========== VALIDATION ==========

  /// Check if context data is valid
  bool get isValid {
    return id.isNotEmpty &&
        contextKey.isNotEmpty &&
        emailAddress.isNotEmpty &&
        displayName.isNotEmpty &&
        _isValidEmail(emailAddress) &&
        _isValidContextType(contextType);
  }

  /// Check if email format is valid
  bool _isValidEmail(String email) {
    return RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    ).hasMatch(email);
  }

  /// Check if context type is valid
  bool _isValidContextType(String type) {
    return type == 'personal' || type == 'group';
  }

  // ========== PERMISSION HELPERS ==========

  /// Check if context has specific permission
  bool hasPermission(String permission) {
    return contextPermissions.contains(permission);
  }

  /// Check if context has mail access permission
  bool get hasMailAccess {
    return hasPermission('korgan.mail.context.access');
  }

  /// Check if context has mail list permission
  bool get hasListAccess {
    return hasPermission('korgan.mail.list.context');
  }

  /// Check if context has mail read permission
  bool get hasReadAccess {
    return hasPermission('korgan.mail.read.context');
  }

  /// Check if context has mail send permission
  bool get hasSendAccess {
    return hasPermission('korgan.mail.send.context');
  }

  /// Check if context has mail delete permission
  bool get hasDeleteAccess {
    return hasPermission('korgan.mail.delete.context');
  }

  /// Check if context has mail archive permission
  bool get hasArchiveAccess {
    return hasPermission('korgan.mail.archive.context');
  }

  /// Check if context has mail search permission
  bool get hasSearchAccess {
    return hasPermission('korgan.mail.search.context');
  }

  /// Check if context has attachment access permission
  bool get hasAttachmentAccess {
    return hasPermission('korgan.mail.attachment.context');
  }

  /// Check if context has any mail access (basic check)
  bool get hasAnyMailAccess {
    return hasMailAccess || hasListAccess;
  }

  // ========== DISPLAY HELPERS ==========

  /// Get icon for context type
  IconData get contextIcon {
    switch (contextType) {
      case 'personal':
        return Icons.person;
      case 'group':
        return Icons.group;
      default:
        return Icons.email;
    }
  }

  /// Get color for context type
  Color get contextColor {
    switch (contextType) {
      case 'personal':
        return Colors.blue;
      case 'group':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  /// Get context type display name
  String get contextTypeDisplayName {
    switch (contextType) {
      case 'personal':
        return 'Kişisel';
      case 'group':
        return 'Grup';
      default:
        return contextType;
    }
  }

  /// Get short email for display (username part)
  String get shortEmail {
    final parts = emailAddress.split('@');
    return parts.isNotEmpty ? parts[0] : emailAddress;
  }

  /// Get domain from email
  String get emailDomain {
    final parts = emailAddress.split('@');
    return parts.length > 1 ? parts[1] : '';
  }

  /// Get display name with type badge
  String get displayNameWithType {
    return '$displayName ($contextTypeDisplayName)';
  }

  /// Get permission count for display
  String get permissionCountInfo {
    return '${contextPermissions.length} yetki';
  }

  /// Get status display text
  String get statusDisplayText {
    return isActive ? 'Aktif' : 'Pasif';
  }

  /// Get status color
  Color get statusColor {
    return isActive ? Colors.green : Colors.red;
  }

  // ========== COMPUTED PROPERTIES ==========

  /// Check if this is a personal context
  bool get isPersonal => contextType == 'personal';

  /// Check if this is a group context
  bool get isGroup => contextType == 'group';

  /// Get initials from display name (for avatar)
  String get initials {
    final words = displayName.trim().split(' ');
    if (words.isEmpty) return 'U';

    if (words.length == 1) {
      return words[0].substring(0, 1).toUpperCase();
    }

    return (words[0].substring(0, 1) + words[1].substring(0, 1)).toUpperCase();
  }

  // ========== EQUALITY & SERIALIZATION ==========

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MailContext &&
        other.id == id &&
        other.contextKey == contextKey &&
        other.emailAddress == emailAddress;
  }

  @override
  int get hashCode => Object.hash(id, contextKey, emailAddress);

  @override
  String toString() {
    return 'MailContext(id: $id, email: $emailAddress, type: $contextType, active: $isActive)';
  }

  // ========== COPY METHODS ==========

  /// Create a copy with optional field updates
  MailContext copyWith({
    String? id,
    String? contextKey,
    String? emailAddress,
    String? displayName,
    String? contextType,
    bool? isActive,
    Map<String, dynamic>? settings,
    List<String>? contextPermissions,
  }) {
    return MailContext(
      id: id ?? this.id,
      contextKey: contextKey ?? this.contextKey,
      emailAddress: emailAddress ?? this.emailAddress,
      displayName: displayName ?? this.displayName,
      contextType: contextType ?? this.contextType,
      isActive: isActive ?? this.isActive,
      settings: settings ?? this.settings,
      contextPermissions: contextPermissions ?? this.contextPermissions,
    );
  }

  // ========== UTILITY METHODS ==========

  /// Create a test/mock context for development
  factory MailContext.mock({
    String? id,
    String? email,
    String? displayName,
    String? contextType,
    bool? isActive,
    List<String>? permissions,
  }) {
    return MailContext(
      id: id ?? 'mock_context_1',
      contextKey: 'mock',
      emailAddress: email ?? 'test@example.com',
      displayName: displayName ?? 'Test User',
      contextType: contextType ?? 'personal',
      isActive: isActive ?? true,
      settings: {},
      contextPermissions:
          permissions ??
          [
            'korgan.mail.context.access',
            'korgan.mail.list.context',
            'korgan.mail.read.context',
            'korgan.mail.send.context',
          ],
    );
  }
}
