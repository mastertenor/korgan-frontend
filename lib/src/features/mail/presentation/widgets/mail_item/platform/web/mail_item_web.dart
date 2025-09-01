// lib/src/features/mail/presentation/widgets/mail_item/platform/web/mail_item_web.dart

import 'package:flutter/material.dart';
import 'package:korgan/src/features/mail/domain/entities/mail.dart';
import '../../shared/mail_utils.dart';

class MailItemWeb extends StatefulWidget {
  final Mail mail;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onArchive;
  final VoidCallback? onDelete;
  final VoidCallback? onToggleStar;
  final VoidCallback? onToggleSelection;
  final VoidCallback? onToggleRead;

  const MailItemWeb({
    super.key,
    required this.mail,
    this.isSelected = false,
    this.onTap,
    this.onArchive,
    this.onDelete,
    this.onToggleStar,
    this.onToggleSelection,
    this.onToggleRead,
  });

  @override
  State<MailItemWeb> createState() => _MailItemWebState();
}

class _MailItemWebState extends State<MailItemWeb>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _animationController.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _animationController.reverse();
      },
      child: Stack(
        children: [
          // Main mail item content
          InkWell(
            onTap: widget.onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: widget.isSelected
                    ? Colors.blue.withOpacity(0.08)
                    : _isHovered
                    ? Colors.grey.withOpacity(0.03)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  // Checkbox
                  SizedBox(
                    width: 32,
                    child: Transform.scale(
                    scale: 0.8,
                    child: Checkbox(
                      value: widget.isSelected,
                      onChanged: (_) => widget.onToggleSelection?.call(),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      activeColor: const Color(0xFF1976D2),
                      checkColor: Colors.white,
                      focusColor: const Color(0xFF1976D2).withOpacity(0.1),
                    ),
                  )
                  ),

                  const SizedBox(width: 8),

                  // Star icon
                  GestureDetector(
                    onTap: widget.onToggleStar,
                    child: Tooltip(
                      message: widget.mail.isStarred
                          ? 'Yıldızı kaldır'
                          : 'Yıldızla',
                      child: Icon(
                        widget.mail.isStarred ? Icons.star : Icons.star_border,
                        color: widget.mail.isStarred
                            ? Colors.amber
                            : Colors.grey[400],
                        size: 18,
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Avatar
                  CircleAvatar(
                    radius: 18, // Medium size for web
                    backgroundColor: MailUtils.getAvatarColor(
                      widget.mail.senderName,
                    ),
                    child: Text(
                      MailUtils.getAvatarInitial(widget.mail.senderName),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),

                  const SizedBox(width: 14),

                  // Mail content - Gmail web style layout
                  Expanded(
                    child: Row(
                      children: [
                        // Sender name - fixed width
                        SizedBox(
                          width: 200,
                          child: Text(
                            widget.mail.senderName,
                            style: TextStyle(
                              fontWeight: widget.mail.isRead
                                  ? FontWeight.normal
                                  : FontWeight.w600,
                              fontSize: 14,
                              color: widget.mail.isRead
                                  ? Colors.black87
                                  : Colors.black,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        const SizedBox(width: 16),

                        // Subject and content - flexible
                        Expanded(
                          child: _buildSubjectAndContent(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 36),

                  // Time (right-aligned, hidden on hover)
                  if (!_isHovered)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.mail.hasAttachments) ...[
                        Icon(
                          Icons.attachment,
                          size: 22,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                      ],
                      SizedBox(
                        width: 80,
                        child: Text(
                            widget.mail.time,
                            style: TextStyle(
                              fontSize: 12,
                              color: widget.mail.isRead
                                  ? Colors.black87
                                  : Colors.black, // Sender ile aynı
                              fontWeight: widget.mail.isRead
                                  ? FontWeight.normal
                                  : FontWeight.w600, // Sender ile aynı
                            ),
                            textAlign: TextAlign.right,
                          ),
                      ),
                    ],
                  ),
                  if (_isHovered) const SizedBox(width: 80),
                ],
              ),
            ),
          ),

          // Gmail-style hover overlay actions
          if (_isHovered)
            Positioned(
              right: 16,
              top: 0,
              bottom: 0,
              child: FadeTransition(
                opacity: _fadeAnimation,

                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHoverAction(
                      icon: Icons.delete_outlined,
                      tooltip: 'Sil',
                      onPressed:  widget.onArchive,
                    ),
                    _buildHoverAction(
                      icon: widget.mail.isRead
                          ? Icons.mark_email_unread_outlined
                          : Icons.mark_email_read_outlined,
                      tooltip: widget.mail.isRead
                          ? 'Okunmadı olarak işaretle'
                          : 'Okundu olarak işaretle',
                      onPressed: widget.onToggleRead,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // 🆕 BUILD SUBJECT AND CONTENT WITH HIGHLIGHT SUPPORT
  Widget _buildSubjectAndContent() {
    // Use highlight snippet if available, otherwise use normal content
    final displayContent = widget.mail.displaySnippet;
    
    // Check if this is highlighted content (contains HTML markup)
    if (widget.mail.hasHighlight && displayContent.contains('<mark>')) {
      return _buildHighlightedContent(displayContent);
    } else {
      return _buildNormalContent();
    }
  }

  // 🆕 BUILD HIGHLIGHTED CONTENT WITH HTML PARSING
  Widget _buildHighlightedContent(String htmlContent) {
    // Parse HTML and build RichText with highlights
    final spans = _parseHighlightedHtml(htmlContent);
    
    return RichText(
      overflow: TextOverflow.ellipsis,
      text: TextSpan(children: spans),
    );
  }

  // 🆕 BUILD NORMAL CONTENT (ORIGINAL LOGIC)
Widget _buildNormalContent() {
    return RichText(
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        children: [
          TextSpan(
            text: widget.mail.subject,
            style: TextStyle(
              fontWeight: widget.mail.isRead
                  ? FontWeight.normal
                  : FontWeight.w600, // Sender ile aynı
              fontSize: 14,
              color: widget.mail.isRead
                  ? Colors
                        .black87 // Sender ile aynı
                  : Colors.black,
            ),
          ),
          TextSpan(
            text: ' - ${widget.mail.content}',
            style: TextStyle(
              fontSize: 14,
              color: widget.mail.isRead
                  ? Colors
                        .black87 // Sender ile aynı
                  : Colors.black,
              fontWeight: widget.mail.isRead
                  ? FontWeight.normal
                  : FontWeight.w600, // Sender ile aynı
            ),
          ),
        ],
      ),
    );
  }
  
      // 🆕 PARSE HIGHLIGHTED HTML AND CONVERT TO TEXT SPANS
  List<TextSpan> _parseHighlightedHtml(String htmlContent) {
    final spans = <TextSpan>[];
    final regex = RegExp(r'<mark>(.*?)</mark>');
    
    int lastMatchEnd = 0;
    
    // Find all <mark> tags and create spans
    for (final match in regex.allMatches(htmlContent)) {
      // Add text before highlight
      if (match.start > lastMatchEnd) {
        final beforeText = htmlContent.substring(lastMatchEnd, match.start);
        if (beforeText.isNotEmpty) {
          spans.add(_createNormalSpan(_cleanHtml(beforeText)));
        }
      }
      
      // Add highlighted text
      final highlightedText = match.group(1) ?? '';
      if (highlightedText.isNotEmpty) {
        spans.add(_createHighlightSpan(_cleanHtml(highlightedText)));
      }
      
      lastMatchEnd = match.end;
    }
    
    // Add remaining text after last highlight
    if (lastMatchEnd < htmlContent.length) {
      final remainingText = htmlContent.substring(lastMatchEnd);
      if (remainingText.isNotEmpty) {
        spans.add(_createNormalSpan(_cleanHtml(remainingText)));
      }
    }
    
    return spans.isEmpty ? [_createNormalSpan(htmlContent)] : spans;
  }

  // 🆕 CREATE NORMAL TEXT SPAN
  TextSpan _createNormalSpan(String text) {
    return TextSpan(
      text: text,
      style: TextStyle(
        fontSize: 14,
        color: Colors.grey[600],
        fontWeight: FontWeight.normal,
      ),
    );
  }

  // 🆕 CREATE HIGHLIGHTED TEXT SPAN
  TextSpan _createHighlightSpan(String text) {
    return TextSpan(
      text: text,
      style: TextStyle(
        fontSize: 14,
        color: Colors.black,
        fontWeight: FontWeight.w600,
        backgroundColor: Colors.yellow[200],
      ),
    );
  }

  // 🆕 CLEAN HTML TAGS FROM TEXT
  String _cleanHtml(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'");
  }

  Widget _buildHoverAction({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(icon, size: 20, color: Colors.grey[700]),
          ),
        ),
      ),
    );
  }

}