// lib/src/features/mail/presentation/widgets/web/compose/mail_compose_modal_platform.dart

// Platform-aware export - automatically selects the right implementation
export 'mail_compose_modal_web_stub.dart'
    if (dart.library.html) 'mail_compose_modal_web.dart';