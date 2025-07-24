// lib/src/features/mail/domain/entities/mail_recipient.dart

/// Mail recipient entity for compose functionality
///
/// Represents an email recipient with email and name information.
/// Used for from, to, cc, and bcc fields in mail composition.
class MailRecipient {
  /// Email address of the recipient
  final String email;

  /// Display name of the recipient
  final String name;

  const MailRecipient({
    required this.email,
    required this.name,
  });

  /// Create from email only (name will be email)
  factory MailRecipient.fromEmail(String email) {
    return MailRecipient(
      email: email,
      name: email,
    );
  }

  /// Create from "Name <email>" format
  factory MailRecipient.fromDisplayString(String displayString) {
    if (displayString.contains('<') && displayString.contains('>')) {
      final parts = displayString.split('<');
      final name = parts[0].trim().replaceAll(RegExp(r'^"|"$'), '');
      final email = parts[1].replaceAll('>', '').trim();
      return MailRecipient(
        email: email,
        name: name.isNotEmpty ? name : email,
      );
    }
    
    // If no brackets, treat as email only
    return MailRecipient.fromEmail(displayString.trim());
  }

  /// Convert to JSON format for API request
  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'name': name,
    };
  }

  /// Create from JSON
  factory MailRecipient.fromJson(Map<String, dynamic> json) {
    return MailRecipient(
      email: json['email']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }

  /// Get display string in "Name <email>" format
  String get displayString {
    if (name.isEmpty || name == email) {
      return email;
    }
    return '$name <$email>';
  }

  /// Copy with updated values
  MailRecipient copyWith({
    String? email,
    String? name,
  }) {
    return MailRecipient(
      email: email ?? this.email,
      name: name ?? this.name,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MailRecipient && 
           other.email == email && 
           other.name == name;
  }

  @override
  int get hashCode => Object.hash(email, name);

  @override
  String toString() {
    return 'MailRecipient(email: $email, name: $name)';
  }
}