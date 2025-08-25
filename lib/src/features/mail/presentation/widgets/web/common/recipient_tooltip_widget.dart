// lib/src/features/mail/presentation/widgets/common/recipient_tooltip_widget.dart

import 'package:flutter/material.dart';

/// Email recipient tooltip widget that appears on chip hover
class RecipientTooltipWidget extends StatelessWidget {
  final String name;
  final String? email;

  const RecipientTooltipWidget({
    super.key,
    required this.name,
    this.email,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints.tightFor(width: 250), // Tight constraint
      child: Container(
        // width artık gerekli değil; tight constraint zaten 250 yapar
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar circle with first letter
            Row(
              mainAxisSize: MainAxisSize.min, // Row'u shrink-wrap yap
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getAvatarColor(name),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      _getInitial(name),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Flexible( // Expanded yerine Flexible kullan
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      // Email (if available)
                      if (email != null && email!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          email!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Action buttons row
            Row(
              mainAxisSize: MainAxisSize.min, // Row'u shrink-wrap yap
              children: [
                // Email button
                _buildActionButton(
                  icon: Icons.email_outlined,
                  label: 'E-posta Gönder',
                  onPressed: () {
                    // TODO: Email gönder action
                    print('Email gönder clicked');
                  },
                ),
                const SizedBox(width: 8),
                // Copy button  
                _buildActionButton(
                  icon: Icons.copy_outlined,
                  label: 'Kopyala',
                  onPressed: () {
                    // TODO: Copy action
                    print('Kopyala clicked');
                  },
                ),
                const SizedBox(width: 8),
                // More button
                _buildActionButton(
                  icon: Icons.more_horiz,
                  label: 'Daha fazla',
                  onPressed: () {
                    // TODO: More options
                    print('Daha fazla clicked');
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build action button - CLICK-THROUGH PROBLEMİNİ ÇÖZ
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque, // Tüm click'leri yakala
        onTap: () {
          // Click'i consume et ve sonra action'ı çalıştır
          onPressed();
        },
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(
            icon,
            size: 16,
            color: Colors.grey.shade600,
          ),
        ),
      ),
    );
  }

  /// Get first letter for avatar
  String _getInitial(String name) {
    if (name.isEmpty) return '?';
    return name.trim().substring(0, 1).toUpperCase();
  }

  /// Get color for avatar based on name
  Color _getAvatarColor(String name) {
    final colors = [
      Colors.blue.shade600,
      Colors.green.shade600,
      Colors.orange.shade600,
      Colors.purple.shade600,
      Colors.teal.shade600,
      Colors.indigo.shade600,
      Colors.red.shade600,
      Colors.pink.shade600,
    ];
    
    final hash = name.toLowerCase().codeUnits.fold(0, (prev, element) => prev + element);
    return colors[hash % colors.length];
  }
}