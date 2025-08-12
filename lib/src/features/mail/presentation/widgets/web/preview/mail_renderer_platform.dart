// lib/src/features/mail/presentation/widgets/web/preview/mail_renderer_platform.dart

// Platform-aware export - automatically selects the right implementation
export 'mail_renderer_stub.dart'
    if (dart.library.html) 'mail_renderer_web.dart';