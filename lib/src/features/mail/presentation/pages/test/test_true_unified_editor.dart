// lib/test_true_unified_editor.dart
// Test runner for TRUE unified contentEditable editor

import 'package:flutter/material.dart';
import 'true_unified_mail_editor.dart';

void main() {
  runApp(const TestTrueUnifiedApp());
}

class TestTrueUnifiedApp extends StatelessWidget {
  const TestTrueUnifiedApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TRUE Unified Mail Editor',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const TestTrueLauncher(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class TestTrueLauncher extends StatelessWidget {
  const TestTrueLauncher({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TRUE Unified Editor'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: ElevatedButton.icon(
          onPressed: () => _launchTrueEditor(context),
          icon: const Icon(Icons.edit, size: 24),
          label: const Text('Launch Editor'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          ),
        ),
      ),
    );
  }

  void _launchTrueEditor(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const YandexUnifiedMailEditor()),
    );
  }
}

// Quick launch for development
void launchTrueUnifiedQuickly() {
  runApp(
    MaterialApp(
      home: const YandexUnifiedMailEditor(),
      debugShowCheckedModeBanner: false,
    ),
  );
}

// 🚀 Enhanced launch with fullscreenDialog for testing
void launchTrueUnifiedWithDialog(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (context) => const YandexUnifiedMailEditor(),
    ),
  );
}
