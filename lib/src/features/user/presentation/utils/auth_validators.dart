// lib/src/features/auth/presentation/utils/auth_validators.dart

/// Utility class for authentication form validation
///
/// Provides static methods for validating email and password inputs
/// with Turkish language support and appropriate error messages.
class AuthValidators {
  const AuthValidators._(); // Prevent instantiation

  /// Validate email address format
  ///
  /// Returns null if valid, error message if invalid
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'E-posta adresi gereklidir';
    }

    final email = value.trim();
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(email)) {
      return 'Geçerli bir e-posta adresi girin';
    }

    return null;
  }

  /// Validate password strength and requirements
  ///
  /// Returns null if valid, error message if invalid
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Şifre gereklidir';
    }

    if (value.length < 6) {
      return 'Şifre en az 6 karakter olmalıdır';
    }

    // Additional password strength checks can be added here
    // For now, keeping it simple as per business requirements

    return null;
  }

  /// Validate password confirmation (for future use)
  static String? validatePasswordConfirmation(
    String? password,
    String? confirmation,
  ) {
    if (confirmation == null || confirmation.isEmpty) {
      return 'Şifre tekrarı gereklidir';
    }

    if (password != confirmation) {
      return 'Şifreler eşleşmiyor';
    }

    return null;
  }
}
