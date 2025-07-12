// lib/src/features/mail/presentation/pages/mail_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:korgan/src/utils/app_logger.dart';
import '../../../../utils/platform_helper.dart';
import 'mobile/mail_page_mobile.dart';
import 'web/mail_page_web.dart';

void main() {
  AppLogger.init();
  runApp(const MailPageTestApp());
}

/// Test uygulaması - mail_page.dart'ı direkt test etmek için
class MailPageTestApp extends StatelessWidget {
  const MailPageTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp(
        title: 'Mail Page Test - ${PlatformHelper.platformName}',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const MailPageTestWrapper(),
      ),
    );
  }
}

class MailPageTestWrapper extends StatelessWidget {
  const MailPageTestWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mail Page Test - ${PlatformHelper.platformName}'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Platform: ${PlatformHelper.platformName}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text(
              'Experience: ${PlatformHelper.recommendedExperience}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        const MailPage(userEmail: 'berk@argenteknoloji.com'),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
              child: const Text('Test Mail Page'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Platform-aware mail page router

class MailPage extends StatelessWidget {
  final String userEmail;

  const MailPage({super.key, required this.userEmail});

  @override
  Widget build(BuildContext context) {
    // Platform-based routing using PlatformHelper
    if (PlatformHelper.shouldUseMobileExperience) {
      return MailPageMobile(userEmail: userEmail);
    } else if (PlatformHelper.shouldUseWebExperience) {
      return MailPageWeb(userEmail: userEmail);
    }

    // Fallback to mobile implementation
    return MailPageMobile(userEmail: userEmail);
  }
}
