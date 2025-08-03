// lib/src/routing/route_constants.dart

/// Type-safe route constants for the application
class RouteConstants {
  RouteConstants._();

  // ========== CORE ROUTES ==========
  static const String home = '/';
  static const String error = '/error';

  // ========== MODULE PREFIXES ==========
  static const String mailPrefix = '/mail';
  static const String crmPrefix = '/crm';
  static const String erpPrefix = '/erp';
  static const String tasksPrefix = '/tasks';
  static const String filesPrefix = '/files';
  static const String chatPrefix = '/chat';
  static const String dashboardPrefix = '/dashboard';

  // ========== UTILITY METHODS ==========
  
  /// Validate email format for routes
  static bool isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(email);
  }
  
  /// Validate route parameter (no slashes, not empty)
  static bool isValidRouteParam(String param) {
    return param.isNotEmpty && !param.contains('/');
  }
}

// ========== MAIL MODULE ROUTES ==========

class MailRoutes {
  MailRoutes._();
  
  // Route patterns
  static const String userMail = '${RouteConstants.mailPrefix}/:email';
  static const String message = '/message/:messageId';
  static const String compose = '/compose';
  static const String folder = '/folder/:folderId';
  
  // Path generators
  static String userMailPath(String email) {
    return '${RouteConstants.mailPrefix}/$email';
  }
  
  static String messagePath(String email, String messageId) {
    return '${RouteConstants.mailPrefix}/$email/message/$messageId';
  }
  
  static String composePath(String email) {
    return '${RouteConstants.mailPrefix}/$email/compose';
  }
  
  static String composeReplyPath(String email, String replyToId) {
    return '${RouteConstants.mailPrefix}/$email/compose?replyTo=$replyToId';
  }
  
  static String folderPath(String email, String folderId) {
    return '${RouteConstants.mailPrefix}/$email/folder/$folderId';
  }
}

// ========== ROUTE PARAMETERS ==========

class RouteParams {
  RouteParams._();
  
  static const String email = 'email';
  static const String messageId = 'messageId';
  static const String folderId = 'folderId';
}

// ========== QUERY PARAMETERS ==========

class QueryParams {
  QueryParams._();
  
  static const String replyTo = 'replyTo';
  static const String forward = 'forward';
  static const String query = 'q';
}