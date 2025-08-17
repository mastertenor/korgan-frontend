// lib/src/features/mail/presentation/widgets/web/compose/components/compose_header_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../providers/mail_compose_modal_provider.dart';

/// Compose modal header component
/// 
/// Gmail benzeri header with:
/// - Modal title (Yeni İleti, Yanıtla, İlet)
/// - Control buttons (minimize, maximize, close)
/// - Responsive behavior
/// - Hover effects
/// - Tooltips
class ComposeHeaderWidget extends ConsumerWidget {
  /// Modal title
  final String title;
  
  /// Is modal currently maximized?
  final bool isMaximized;
  
  /// Custom close callback (optional)
  final VoidCallback? onClose;

  const ComposeHeaderWidget({
    super.key,
    this.title = 'Yeni İleti',
    required this.isMaximized,
    this.onClose,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Row(
        children: [
          // Modal icon (optional)
          _buildModalIcon(),
          
          const SizedBox(width: 8),
          
          // Title
          _buildTitle(),
          
          const Spacer(),
          
          // Control buttons
          _buildControlButtons(context, ref),
        ],
      ),
    );
  }

  /// Build modal icon
  Widget _buildModalIcon() {
    return Icon(
      Icons.email_outlined,
      size: 18,
      color: Colors.grey.shade600,
    );
  }

  /// Build modal title
  Widget _buildTitle() {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: Colors.black87,
      ),
    );
  }

  /// Build control buttons row
  Widget _buildControlButtons(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Minimize button
        _ComposeHeaderButton(
          icon: Icons.minimize,
          tooltip: 'Küçült',
          onPressed: () => ref.read(mailComposeModalProvider.notifier).minimizeModal(),
        ),
        
        const SizedBox(width: 4),
        
        // Maximize/Restore button
        _ComposeHeaderButton(
          icon: isMaximized ? Icons.fullscreen_exit : Icons.fullscreen,
          tooltip: isMaximized ? 'Geri yükle' : 'Tam ekran',
          onPressed: () => ref.read(mailComposeModalProvider.notifier).toggleMaximize(),
        ),
        
        const SizedBox(width: 4),
        
        // Close button
        _ComposeHeaderButton(
          icon: Icons.close,
          tooltip: 'Kapat',
          onPressed: () {
            if (onClose != null) {
              onClose!();
            } else {
              ref.read(mailComposeModalProvider.notifier).closeModal();
            }
          },
          isClose: true,
        ),
      ],
    );
  }
}

/// Header button component with hover effects
class _ComposeHeaderButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool isClose;

  const _ComposeHeaderButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.isClose = false,
  });

  @override
  State<_ComposeHeaderButton> createState() => _ComposeHeaderButtonState();
}

class _ComposeHeaderButtonState extends State<_ComposeHeaderButton> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      waitDuration: const Duration(milliseconds: 500),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovering = true),
        onExit: (_) => setState(() => _isHovering = false),
        child: GestureDetector(
          onTap: widget.onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _getBackgroundColor(),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(
              widget.icon,
              size: 18,
              color: _getIconColor(),
            ),
          ),
        ),
      ),
    );
  }

  /// Get background color based on state
  Color _getBackgroundColor() {
    if (!_isHovering) return Colors.transparent;
    
    if (widget.isClose) {
      return Colors.red.shade50;
    }
    
    return Colors.grey.shade100;
  }

  /// Get icon color based on state
  Color _getIconColor() {
    if (!_isHovering) return Colors.grey.shade600;
    
    if (widget.isClose) {
      return Colors.red.shade700;
    }
    
    return Colors.grey.shade800;
  }
}

/// Minimize bar header for bottom modal
class ComposeMinimizedHeaderWidget extends ConsumerWidget {
  /// Modal title
  final String title;
  
  /// Custom restore callback (optional)
  final VoidCallback? onRestore;
  
  /// Custom close callback (optional)
  final VoidCallback? onClose;

  const ComposeMinimizedHeaderWidget({
    super.key,
    this.title = 'Yeni İleti',
    this.onRestore,
    this.onClose,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade300),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Restore button
          _ComposeHeaderButton(
            icon: Icons.keyboard_arrow_up,
            tooltip: 'Geri yükle',
            onPressed: () {
              if (onRestore != null) {
                onRestore!();
              } else {
                ref.read(mailComposeModalProvider.notifier).restoreModal();
              }
            },
          ),
          
          const SizedBox(width: 12),
          
          // Mini icon
          Icon(
            Icons.email_outlined,
            size: 16,
            color: Colors.grey.shade600,
          ),
          
          const SizedBox(width: 8),
          
          // Title
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          
          const Spacer(),
          
          // Close button
          _ComposeHeaderButton(
            icon: Icons.close,
            tooltip: 'Kapat',
            onPressed: () {
              if (onClose != null) {
                onClose!();
              } else {
                ref.read(mailComposeModalProvider.notifier).closeModal();
              }
            },
            isClose: true,
          ),
        ],
      ),
    );
  }
}

/// Header button styles utility
class ComposeHeaderStyles {
  static const double buttonSize = 32.0;
  static const double iconSize = 18.0;
  static const double miniIconSize = 16.0;
  static const double headerHeight = 50.0;
  
  static const Duration hoverDuration = Duration(milliseconds: 150);
  static const Duration tooltipDelay = Duration(milliseconds: 500);
  
  static BorderRadius get buttonBorderRadius => BorderRadius.circular(4);
  
  static TextStyle get titleStyle => const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: Colors.black87,
  );
  
  static TextStyle get miniTitleStyle => const TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: Colors.black87,
  );
  
  static Color get borderColor => Colors.grey.shade300;
  static Color get iconColor => Colors.grey.shade600;
  static Color get iconHoverColor => Colors.grey.shade800;
  static Color get closeHoverBackground => Colors.red.shade50;
  static Color get closeHoverIcon => Colors.red.shade700;
  static Color get normalHoverBackground => Colors.grey.shade100;
}