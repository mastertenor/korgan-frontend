// Platform-aware export - automatically selects the right implementation
export 'resizable_split_view_stub.dart'
    if (dart.library.html) 'resizable_split_view_web.dart';