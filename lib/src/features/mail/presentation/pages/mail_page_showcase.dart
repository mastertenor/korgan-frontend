// lib/src/features/mail/presentation/pages/mail_page_showcase.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'mail_page.dart';
import '../../../../utils/platform_helper.dart';

void main() {
  runApp(const MailPageShowcaseApp());
}

/// Mail Page Showcase uygulaması
///
/// MailPage widget'ını test etmek ve demo olarak göstermek için kullanılır.
/// Production seviyesi MailPage'in showcase versiyonudur.
class MailPageShowcaseApp extends StatelessWidget {
  const MailPageShowcaseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp(
        title: 'Mail Page Showcase - ${PlatformHelper.platformName}',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
          // Gmail benzeri checkbox teması
          checkboxTheme: CheckboxThemeData(
            fillColor: WidgetStateProperty.resolveWith<Color>((states) {
              if (states.contains(WidgetState.selected)) {
                return const Color(0xFF1A73E8); // Gmail mavi
              }
              return Colors.transparent;
            }),
            checkColor: WidgetStateProperty.all(Colors.white),
          ),
          // AppBar teması
          appBarTheme: const AppBarTheme(centerTitle: false, elevation: 0),
        ),
        darkTheme: ThemeData.dark().copyWith(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
          checkboxTheme: CheckboxThemeData(
            fillColor: WidgetStateProperty.resolveWith<Color>((states) {
              if (states.contains(WidgetState.selected)) {
                return const Color(0xFF1A73E8);
              }
              return Colors.transparent;
            }),
            checkColor: WidgetStateProperty.all(Colors.white),
          ),
        ),
        themeMode: ThemeMode.system,
        home: const MailPageWrapper(),
      ),
    );
  }
}

/// MailPage wrapper - email parametresini sağlar ve platform bilgilerini gösterir
class MailPageWrapper extends StatelessWidget {
  const MailPageWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Mail Page Showcase'),
            Text(
              'Platform: ${PlatformHelper.platformName} | Experience: ${PlatformHelper.recommendedExperience.toUpperCase()}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          // Platform bilgileri
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showPlatformInfo(context),
            tooltip: 'Platform Bilgileri',
          ),
          // Test e-posta seçici
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle),
            tooltip: 'Test Hesabı Seç',
            onSelected: (email) => _navigateToMailPage(context, email),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'berk@argenteknoloji.com',
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue,
                    child: Text('B', style: TextStyle(color: Colors.white)),
                  ),
                  title: Text('Berk (Test Account)'),
                  subtitle: Text('berk@argenteknoloji.com'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'demo@example.com',
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.green,
                    child: Text('D', style: TextStyle(color: Colors.white)),
                  ),
                  title: Text('Demo Account'),
                  subtitle: Text('demo@example.com'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Ana logo/icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(Icons.mail, size: 64, color: Colors.white),
              ),

              const SizedBox(height: 32),

              // Başlık
              Text(
                'Production Mail App',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // Açıklama
              Text(
                'Gmail benzeri, production seviyesi mail uygulaması.\n'
                'Filtering, pagination, bulk operations destekli.',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // Platform bilgi kartı
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _getPlatformIcon(),
                          size: 24,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          PlatformHelper.platformName,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Experience: ${PlatformHelper.recommendedExperience.toUpperCase()}',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 48),

              // Ana giriş butonu
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () =>
                      _navigateToMailPage(context, 'berk@argenteknoloji.com'),
                  icon: const Icon(Icons.launch),
                  label: const Text('Mail Uygulamasını Başlat'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Özellikler listesi
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  _buildFeatureChip('Gmail API Filtering'),
                  _buildFeatureChip('Infinite Scroll'),
                  _buildFeatureChip('Bulk Operations'),
                  _buildFeatureChip('Platform Adaptive'),
                  _buildFeatureChip('Material 3'),
                  _buildFeatureChip('State Management'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Platform ikonunu döndür
  IconData _getPlatformIcon() {
    if (PlatformHelper.isMobile) {
      return Icons.smartphone;
    } else if (PlatformHelper.isDesktop) {
      return Icons.desktop_windows;
    } else if (PlatformHelper.isWeb) {
      return Icons.language;
    }
    return Icons.device_unknown;
  }

  /// Özellik chip'i oluştur
  Widget _buildFeatureChip(String label) {
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      backgroundColor: Colors.blue.withOpacity(0.1),
      side: BorderSide(color: Colors.blue.withOpacity(0.3)),
    );
  }

  /// Mail sayfasına git
  void _navigateToMailPage(BuildContext context, String userEmail) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => MailPage(userEmail: userEmail)),
    );
  }

  /// Platform bilgileri dialogu
  void _showPlatformInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Platform Bilgileri'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Platform', PlatformHelper.platformName),
            _buildInfoRow('Experience', PlatformHelper.recommendedExperience),
            _buildInfoRow('Is Mobile', PlatformHelper.isMobile.toString()),
            _buildInfoRow('Is Desktop', PlatformHelper.isDesktop.toString()),
            _buildInfoRow('Is Web', PlatformHelper.isWeb.toString()),
            _buildInfoRow(
              'Supports Touch',
              PlatformHelper.supportsTouchInput.toString(),
            ),
            _buildInfoRow(
              'Has Keyboard',
              PlatformHelper.hasPhysicalKeyboard.toString(),
            ),
            _buildInfoRow(
              'Needs Safe Area',
              PlatformHelper.needsSafeArea.toString(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  /// Bilgi satırı oluştur
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontFamily: 'monospace')),
          ),
        ],
      ),
    );
  }
}
