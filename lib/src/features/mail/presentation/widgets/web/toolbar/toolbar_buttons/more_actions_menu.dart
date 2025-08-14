// lib/src/features/mail/presentation/widgets/web/toolbar/toolbar_buttons/more_actions_menu.dart

import 'package:flutter/material.dart';

/// More actions menu button with popup menu
/// 
/// Displays a vertical dots icon that opens a popup menu with additional actions.
class MoreActionsMenu extends StatelessWidget {
  final bool isLoading;
  final Function(String)? onActionSelected;
  final List<MoreActionItem>? customItems;

  const MoreActionsMenu({
    super.key,
    required this.isLoading,
    this.onActionSelected,
    this.customItems,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = !isLoading && onActionSelected != null;

    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert,
        size: 20,
        color: isEnabled ? Colors.grey.shade700 : Colors.grey.shade400,
      ),
      enabled: isEnabled,
      tooltip: 'Diğer işlemler',
      onSelected: onActionSelected,
      itemBuilder: (context) => _buildMenuItems(),
    );
  }

  /// Build menu items
  List<PopupMenuEntry<String>> _buildMenuItems() {
    if (customItems != null && customItems!.isNotEmpty) {
      return customItems!.map((item) => _buildMenuItem(item)).toList();
    }

    // Default items
    return [
      _buildMenuItem(MoreActionItem(
        value: 'test1',
        icon: Icons.info_outline,
        title: 'Test1',
      )),
      _buildMenuItem(MoreActionItem(
        value: 'test2',
        icon: Icons.settings_outlined,
        title: 'Test2',
      )),
    ];
  }

  /// Build a single menu item
  PopupMenuItem<String> _buildMenuItem(MoreActionItem item) {
    return PopupMenuItem<String>(
      value: item.value,
      child: Row(
        children: [
          Icon(item.icon, size: 16),
          const SizedBox(width: 8),
          Text(item.title),
        ],
      ),
    );
  }
}

/// Data class for menu action items
class MoreActionItem {
  final String value;
  final IconData icon;
  final String title;

  const MoreActionItem({
    required this.value,
    required this.icon,
    required this.title,
  });
}