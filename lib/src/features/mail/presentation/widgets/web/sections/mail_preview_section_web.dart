// lib/src/features/mail/presentation/widgets/web/mail_preview_section_web.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

import '../../../../../../utils/app_logger.dart';
import '../../../../domain/entities/mail_detail.dart';
import '../../../providers/mail_providers.dart';
import '../preview/mail_renderer_platform.dart';


class MailPreviewSectionWeb extends ConsumerStatefulWidget {
  final String userEmail;
  
  const MailPreviewSectionWeb({
    super.key,
    required this.userEmail,
  });

  @override
  ConsumerState<MailPreviewSectionWeb> createState() => _MailPreviewSectionWebState();
}

class _MailPreviewSectionWebState extends ConsumerState<MailPreviewSectionWeb> {
  // ScrollController - preview panel'in kendi controller'ı
  final ScrollController _scrollController = ScrollController();

  // Web renderer instance - preview panel'in kendi renderer'ı
  late final MailWebRenderer _webRenderer;

  @override
  void initState() {
    super.initState();
    AppLogger.info('🖥️ MailPreviewSectionWeb initialized for: ${widget.userEmail}');
    
    // Initialize web renderer
    _webRenderer = MailWebRenderer(
      scrollController: _scrollController,
      onHeightChanged: (height) {
        if (mounted) {
          setState(() {
            // Height changes handled by renderer
          });
        }
      },
    );
    
    // Initialize web renderer
    if (kIsWeb) {
      _webRenderer.initialize();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _webRenderer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Provider watches
    final mailDetail = ref.watch(currentMailDetailProvider);
    final mailDetailLoading = ref.watch(mailDetailLoadingProvider);

    return _buildPreviewPanel(context, mailDetail, mailDetailLoading);
  }

  // Preview panel - buildRenderedHtmlSection ile mail içeriği gösterimi
  Widget _buildPreviewPanel(BuildContext context, MailDetail? mailDetail, bool isLoading) {
  return Container(
    color: Colors.white,
    child: _buildPreviewContent(context, mailDetail, isLoading),
  );
}


  Widget _buildPreviewContent(BuildContext context, MailDetail? mailDetail, bool isLoading) {
    // Loading state
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // No mail selected
    if (mailDetail == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.mail_outline, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Önizlemek için bir mail seçin',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    // Mail selected - show content using web renderer
    return _webRenderer.buildMailContent(context, mailDetail);
  }
}