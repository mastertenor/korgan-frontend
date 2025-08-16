// lib/src/core/services/web_attachment_platform.dart

// Platform-aware export - automatically selects the right implementation
export 'web_attachment_stub.dart'
    if (dart.library.html) 'web_attachment_downloader.dart';