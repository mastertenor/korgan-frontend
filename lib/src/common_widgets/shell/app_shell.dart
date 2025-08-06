// lib/src/common_widgets/shell/app_shell.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'components/header/factory/global_header_factory.dart';

/// Application shell with unified header
class AppShell extends ConsumerWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: null,
      body: Column(
        children: [
          /// ✅ Platform-aware header çağrısı
          GlobalHeaderFactory.create(context),

          Expanded(
            child: SizedBox(
              width: double.infinity,
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}
