// lib/src/features/mail/data/models/mail_context_model.dart

import '../../domain/entities/mail_context.dart';

/// Data model for mail context API responses
///
/// Handles JSON serialization/deserialization for mail context data
/// from the backend API context array.
///
/// Expected API response format:
/// {
///   "id": "ctx_zRrjMPUTVVty0onD",
///   "contextKey": "berk",
///   "emailAddress": "berk@argenteknoloji.com",
///   "displayName": "Berk Göknil",
///   "contextType": "personal",
///   "isActive": true,
///   "settings": {"description": "Berk kişisel mail hesabı"},
///   "contextPermissions": [
///     "korgan.mail.read.context",
///     "korgan.mail.send.context"
///   ]
/// }
class MailContextModel {
  final String id;
  final String contextKey;
  final String emailAddress;
  final String displayName;
  final String contextType;
  final bool isActive;
  final Map<String, dynamic> settings;
  final List<String> contextPermissions;

  const MailContextModel({
    required this.id,
    required this.contextKey,
    required this.emailAddress,
    required this.displayName,
    required this.contextType,
    required this.isActive,
    required this.settings,
    required this.contextPermissions,
  });

  // ========== JSON SERIALIZATION ==========

  /// Create from JSON response
  factory MailContextModel.fromJson(Map<String, dynamic> json) {
    return MailContextModel(
      id: json['id']?.toString() ?? '',
      contextKey: json['contextKey']?.toString() ?? '',
      emailAddress: json['emailAddress']?.toString() ?? '',
      displayName: json['displayName']?.toString() ?? '',
      contextType: json['contextType']?.toString() ?? 'personal',
      isActive: json['isActive'] as bool? ?? true,
      settings: (json['settings'] as Map<String, dynamic>?) ?? {},
      contextPermissions:
          (json['contextPermissions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'contextKey': contextKey,
      'emailAddress': emailAddress,
      'displayName': displayName,
      'contextType': contextType,
      'isActive': isActive,
      'settings': settings,
      'contextPermissions': contextPermissions,
    };
  }

  // ========== DOMAIN CONVERSION ==========

  /// Convert to domain MailContext entity
  MailContext toDomain() {
    return MailContext(
      id: id,
      contextKey: contextKey,
      emailAddress: emailAddress,
      displayName: displayName,
      contextType: contextType,
      isActive: isActive,
      settings: settings,
      contextPermissions: contextPermissions,
    );
  }

  /// Create model from domain entity
  factory MailContextModel.fromDomain(MailContext entity) {
    return MailContextModel(
      id: entity.id,
      contextKey: entity.contextKey,
      emailAddress: entity.emailAddress,
      displayName: entity.displayName,
      contextType: entity.contextType,
      isActive: entity.isActive,
      settings: entity.settings,
      contextPermissions: entity.contextPermissions,
    );
  }

  // ========== VALIDATION ==========

  /// Check if model data is valid
  bool get isValid {
    return id.isNotEmpty &&
        contextKey.isNotEmpty &&
        emailAddress.isNotEmpty &&
        displayName.isNotEmpty &&
        _isValidEmail(emailAddress) &&
        _isValidContextType(contextType);
  }

  bool _isValidEmail(String email) {
    return RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    ).hasMatch(email);
  }

  bool _isValidContextType(String type) {
    return type == 'personal' || type == 'group';
  }

  // ========== EQUALITY & DEBUGGING ==========

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MailContextModel &&
        other.id == id &&
        other.contextKey == contextKey &&
        other.emailAddress == emailAddress;
  }

  @override
  int get hashCode => Object.hash(id, contextKey, emailAddress);

  @override
  String toString() {
    return 'MailContextModel(id: $id, email: $emailAddress, type: $contextType, active: $isActive)';
  }

  // ========== STATIC HELPERS ==========

  /// Parse list of contexts from JSON array
  static List<MailContextModel> fromJsonList(List<dynamic> jsonList) {
    return jsonList
        .map((json) => MailContextModel.fromJson(json as Map<String, dynamic>))
        .where((model) => model.isValid)
        .toList();
  }

  /// Convert list of models to domain entities
  static List<MailContext> toDomainList(List<MailContextModel> models) {
    return models.map((model) => model.toDomain()).toList();
  }
}
