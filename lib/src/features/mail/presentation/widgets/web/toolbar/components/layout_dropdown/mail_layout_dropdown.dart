// lib/src/features/mail/presentation/widgets/web/toolbar/components/layout_dropdown/mail_layout_dropdown.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../providers/mail_layout_provider.dart';
import '../../../../../providers/state/mail_layout_state.dart';

/// Mail layout dropdown widget for switching between different view modes
/// 
/// Uses Flutter's built-in MenuAnchor for native dropdown behavior.
/// 
/// Provides three layout options:
/// - Bölme yok (No split) - Single pane view
/// - Dikey bölme (Vertical split) - Two column layout
/// - Yatay bölme (Horizontal split) - Two row layout
class MailLayoutDropdown extends ConsumerStatefulWidget {
  const MailLayoutDropdown({super.key});

  @override
  ConsumerState<MailLayoutDropdown> createState() => _MailLayoutDropdownState();
}

class _MailLayoutDropdownState extends ConsumerState<MailLayoutDropdown> {
  final MenuController _menuController = MenuController();

  @override
  Widget build(BuildContext context) {
    // Watch layout state
    final currentLayout = ref.watch(currentLayoutProvider);
    final isChanging = ref.watch(isLayoutChangingProvider);
    final availableLayouts = ref.watch(availableLayoutsProvider);

    return MenuAnchor(
      controller: _menuController,
      alignmentOffset: const Offset(0, 4),
      // Menü için tema
      style: MenuStyle(
        backgroundColor: WidgetStateProperty.all(Colors.white),
        elevation: WidgetStateProperty.all(4),
        padding: WidgetStateProperty.all(const EdgeInsets.symmetric(vertical: 4)),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
      ),
      menuChildren: availableLayouts
          .map((layout) => _menuItem(
                icon: _getIconForLayout(layout),
                title: layout.title,
                subtitle: layout.subtitle,
                isSelected: currentLayout == layout,
                isChanging: isChanging && currentLayout == layout,
                onTap: () => _handleLayoutChange(layout),
              ))
          .toList(),
      builder: (context, controller, child) {
        return InkWell(
          onTap: isChanging ? null : () => controller.isOpen ? controller.close() : controller.open(),
          borderRadius: BorderRadius.circular(4),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Loading indicator veya current layout icon
                isChanging
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.grey.shade600),
                        ),
                      )
                    : Icon(
                        _getIconForLayout(currentLayout),
                        size: 16,
                        color: Colors.grey.shade700,
                      ),
                const SizedBox(width: 4),
                Icon(
                  controller.isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  size: 16,
                  color: Colors.grey.shade700,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _menuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isSelected,
    required bool isChanging,
    required VoidCallback onTap,
  }) {
    return MenuItemButton(
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.resolveWith<Color?>(
          (states) {
            if (isSelected) {
              return Colors.blue.shade50; // Selected background
            }
            if (states.contains(MaterialState.hovered)) {
              return Colors.grey.shade100; // Hover background
            }
            return Colors.white; // Default background
          },
        ),
        padding: MaterialStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      ),
      leadingIcon: isChanging && isSelected
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(Colors.blue.shade600),
              ),
            )
          : Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.blue.shade600 : Colors.grey.shade800,
            ),
      trailingIcon: isSelected
          ? Icon(
              Icons.check,
              size: 16,
              color: Colors.blue.shade600,
            )
          : null,
      onPressed: isChanging ? null : onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected ? Colors.blue.shade700 : Colors.black,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: isSelected ? Colors.blue.shade600 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  /// Get icon for layout type
  IconData _getIconForLayout(MailLayoutType layout) {
    switch (layout) {
      case MailLayoutType.noSplit:
        return Icons.view_agenda;
      case MailLayoutType.verticalSplit:
        return Icons.view_column;
      case MailLayoutType.horizontalSplit:
        return Icons.view_stream;
    }
  }

  /// Handle layout change using provider
  void _handleLayoutChange(MailLayoutType newLayout) {
    ref.read(mailLayoutProvider.notifier).changeLayout(newLayout);
    _menuController.close();
  }
}