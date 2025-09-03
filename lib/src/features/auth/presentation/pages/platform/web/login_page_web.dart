// lib/src/features/auth/presentation/pages/platform/web/login_page_web.dart

import 'package:flutter/material.dart';
import '../../../../../../utils/app_logger.dart';
import '../../../widgets/web/login_form.dart'; // Sonraki adımda oluşturacağız

/// Web-specific login page with centered modal design
///
/// Features:
/// - Gmail-style centered modal card (400px width, auto height)
/// - Light gradient background for professional look
/// - Clean shadows and elevation
/// - Responsive design (tablets get margin, mobile gets full screen)
/// - LoginForm widget integration
/// - App branding/logo display
class LoginPageWeb extends StatelessWidget {
  const LoginPageWeb({super.key});

  @override
  Widget build(BuildContext context) {
    AppLogger.debug('🌐 Building LoginPageWeb');

    return Scaffold(
      backgroundColor: Colors.transparent, // Let background gradient show
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: _buildBackgroundDecoration(),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: _buildLoginCard(context),
            ),
          ),
        ),
      ),
    );
  }

  /// Build gradient background decoration
  BoxDecoration _buildBackgroundDecoration() {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Colors.blue[50]!, Colors.blue[100]!, Colors.grey[100]!],
      ),
    );
  }

  /// Build main login card container
  Widget _buildLoginCard(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        maxWidth: 400, // Gmail-style fixed width
        minHeight: 400, // Minimum height for proper proportions
      ),
      child: Card(
        elevation: 12, // Strong shadow for professional look
        shadowColor: Colors.black.withOpacity(0.15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(40), // Generous padding
          child: Column(
            mainAxisSize: MainAxisSize.min, // Shrink to content
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(context),
              const SizedBox(height: 32),
              _buildLoginForm(),
              const SizedBox(height: 24),
              _buildFooter(context),
            ],
          ),
        ),
      ),
    );
  }

  /// Build header section with logo and title
  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        // App Logo/Icon
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.blue[600],
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.email_outlined,
            size: 40,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 24),

        // App Title
        Text(
          'Korgan Platform',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),

        // Subtitle
        Text(
          'Hesabınıza giriş yapın',
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Build login form section
  Widget _buildLoginForm() {
    // LoginForm widget will be implemented in next step
    return const LoginForm(); // Bu widget'ı sonraki adımda oluşturacağız
  }

  /// Build footer section
  Widget _buildFooter(BuildContext context) {
    return Column(
      children: [
        // Divider
        Divider(color: Colors.grey[300], thickness: 1),
        const SizedBox(height: 16),

        // Footer text
        Text(
          '© 2024 Korgan Platform',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
