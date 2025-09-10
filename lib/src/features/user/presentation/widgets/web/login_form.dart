// lib/src/features/auth/presentation/widgets/web/login_form.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../utils/app_logger.dart';
import '../../../../../routing/route_constants.dart';
import '../../providers/auth_providers.dart';
import '../../state/auth_state.dart';
import '../../utils/auth_validators.dart'; // Bu dosyayı da oluşturacağız

/// Reusable login form widget
///
/// Features:
/// - Email/password form validation with real-time feedback
/// - Auth state integration with Riverpod
/// - Loading state handling
/// - Error message display
/// - Success navigation handling
/// - Form submission prevention when invalid
/// - Responsive button design
class LoginForm extends ConsumerStatefulWidget {
  const LoginForm({super.key});

  @override
  ConsumerState<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends ConsumerState<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _autoValidate = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    // Listen for auth state changes
    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      _handleAuthStateChange(previous, next);
    });

    return Form(
      key: _formKey,
      autovalidateMode: _autoValidate
          ? AutovalidateMode.onUserInteraction
          : AutovalidateMode.disabled,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildEmailField(authState),
          const SizedBox(height: 16),
          _buildPasswordField(authState),
          const SizedBox(height: 24),
          _buildLoginButton(authState),
          if (authState.hasError) ...[
            const SizedBox(height: 16),
            _buildErrorDisplay(authState.error!),
          ],
        ],
      ),
    );
  }

  /// Build email input field
  Widget _buildEmailField(AuthState authState) {
    return TextFormField(
      controller: _emailController,
      enabled: !authState.isLoggingIn,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: 'e-posta',
        hintText: 'ornek@korgan.com',
        prefixIcon: const Icon(Icons.email_outlined),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue[600]!),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
      validator: AuthValidators.validateEmail,
      onChanged: (value) {
        if (_autoValidate) {
          _formKey.currentState?.validate();
        }
      },
    );
  }

  /// Build password input field
  Widget _buildPasswordField(AuthState authState) {
    return TextFormField(
      controller: _passwordController,
      enabled: !authState.isLoggingIn,
      obscureText: !_isPasswordVisible,
      textInputAction: TextInputAction.done,
      decoration: InputDecoration(
        labelText: 'Şifre',
        hintText: 'Şifrenizi girin',
        prefixIcon: const Icon(Icons.lock_outlined),
        suffixIcon: IconButton(
          icon: Icon(
            _isPasswordVisible
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
          ),
          onPressed: () {
            setState(() {
              _isPasswordVisible = !_isPasswordVisible;
            });
          },
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue[600]!),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
      validator: AuthValidators.validatePassword,
      onChanged: (value) {
        if (_autoValidate) {
          _formKey.currentState?.validate();
        }
      },
      onFieldSubmitted: (value) => _handleLogin(),
    );
  }

  /// Build login button
  Widget _buildLoginButton(AuthState authState) {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: authState.isLoggingIn ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue[600],
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey[300],
          disabledForegroundColor: Colors.grey[600],
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: authState.isLoggingIn
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.grey[600]!,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text('Giriş yapılıyor...'),
                ],
              )
            : const Text(
                'Giriş Yap',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }

  /// Build error display
  Widget _buildErrorDisplay(String error) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        border: Border.all(color: Colors.red[200]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[700], size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error,
              style: TextStyle(color: Colors.red[700], fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  /// Handle login form submission
  void _handleLogin() {
    AppLogger.info('🔑 LoginForm: Login attempt initiated');

    // Enable auto-validation for future interactions
    if (!_autoValidate) {
      setState(() {
        _autoValidate = true;
      });
    }

    // Validate form
    if (!_formKey.currentState!.validate()) {
      AppLogger.warning('🔑 LoginForm: Form validation failed');
      return;
    }

    // Clear any existing errors
    ref.read(authNotifierProvider.notifier).clearError();

    // Attempt login
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    AppLogger.info('🔑 LoginForm: Submitting login for $email');
    ref
        .read(authNotifierProvider.notifier)
        .login(email: email, password: password);
  }

  /// Handle auth state changes
  void _handleAuthStateChange(AuthState? previous, AuthState next) {
    // Handle successful authentication
    if (next.isAuthenticated && (previous?.isAuthenticated != true)) {
      AppLogger.info('✅ LoginForm: Login successful, navigating to home');
      context.go(RouteConstants.home);
      return;
    }

    // Handle errors
    if (next.hasError && !next.isLoggingIn) {
      AppLogger.warning('❌ LoginForm: Login failed - ${next.error}');
      _showErrorSnackBar(next.error!);
    }
  }

  /// Show error snackbar
  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Kapat',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    }
  }
}
