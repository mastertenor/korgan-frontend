// lib/src/common_widgets/shell/components/header/global_header.dart

import 'package:flutter/material.dart';
import 'factory/global_header_factory.dart';

class WebGlobalHeader extends StatelessWidget {
  const WebGlobalHeader({super.key});

  @override
  Widget build(BuildContext context) {
    // ✅ context parametresi eklendi
    return GlobalHeaderFactory.create(context);
  }
}
