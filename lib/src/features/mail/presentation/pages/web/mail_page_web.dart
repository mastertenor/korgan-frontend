// lib/src/features/mail/presentation/pages/web/mail_page_web.dart

import 'package:flutter/material.dart';

/// Web-optimized mail page with Gmail-style interface
///
/// Features (To be implemented):
/// - Gmail-style layout with sidebar and content area
/// - Integrated search bar in header
/// - Hover effects and keyboard shortcuts
/// - Dense information display
/// - Multi-pane view support
/// - Advanced filtering and search
/// - Bulk operations with checkboxes
/// - Context menus and tooltips
class MailPageWeb extends StatelessWidget {
  final String userEmail;

  const MailPageWeb({super.key, required this.userEmail});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.web, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Web Mail Interface',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Coming Soon...',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            Text(
              'Gmail-style web interface with:',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFeatureItem('• Integrated search bar'),
                _buildFeatureItem('• Multi-pane layout'),
                _buildFeatureItem('• Keyboard shortcuts'),
                _buildFeatureItem('• Advanced hover effects'),
                _buildFeatureItem('• Context menus'),
                _buildFeatureItem('• Dense information display'),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'User: $userEmail',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[500],
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        text,
        style: TextStyle(color: Colors.grey[600], fontSize: 14),
      ),
    );
  }
}
