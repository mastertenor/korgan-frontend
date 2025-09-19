// lib/src/common_widgets/shell/app_shell.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'components/header/platform/web/global_header_web.dart';

/// Application shell with unified header
class AppShell extends ConsumerWidget {
  final Widget child;
  final String currentModule; // Added currentModule parameter

  const AppShell({
    super.key,
    required this.child,
    this.currentModule = '', // Default value for currentModule
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: null,
      body: Column(
        children: [
          // Directly use GlobalHeaderWeb with currentModule
          GlobalHeaderWeb(currentModule: currentModule),
          Expanded(
            child: SizedBox(width: double.infinity, child: child),
          ),
        ],
      ),
    );
  }
}
