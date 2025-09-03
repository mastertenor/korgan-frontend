// lib/src/routing/route_constants.dart

/// Type-safe route constants for the application
class RouteConstants {
  RouteConstants._();

  // ========== CORE ROUTES ==========
  static const String home ='/home'; 
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
    return RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    ).hasMatch(email);
  }

  /// Validate route parameter (no slashes, not empty)
  static bool isValidRouteParam(String param) {
    return param.isNotEmpty && !param.contains('/');
  }
}

// ========== MAIL MODULE ROUTES ==========

class MailRoutes {
  MailRoutes._();

  // ✅ UPDATED: Route patterns with folder support
  static const String userMail = '${RouteConstants.mailPrefix}/:email';
  static const String userMailFolder =
      '${RouteConstants.mailPrefix}/:email/:folder';
  static const String userMailDetail =
      '${RouteConstants.mailPrefix}/:email/:folder/:mailId';

  // Legacy routes (keeping for backwards compatibility)
  static const String message = '/message/:messageId';
  static const String compose = '/compose';
  static const String folder = '/folder/:folderId';

  // ✅ UPDATED: Path generators
  static String userMailPath(String email) {
    return '${RouteConstants.mailPrefix}/$email';
  }

  /// Generate folder path for specific folder
  /// Example: /mail/user@example.com/inbox
  static String folderPath(String email, String folder) {
    return '${RouteConstants.mailPrefix}/$email/$folder';
  }

  /// Generate mail detail path
  /// Example: /mail/user@example.com/inbox/mail_123
  static String mailDetailPath(String email, String folder, String mailId) {
    return '${RouteConstants.mailPrefix}/$email/$folder/$mailId';
  }

  // Legacy message path (deprecated)
  static String messagePath(String email, String messageId) {
    return '${RouteConstants.mailPrefix}/$email/message/$messageId';
  }

  static String composePath(String email) {
    return '${RouteConstants.mailPrefix}/$email/compose';
  }

  static String composeReplyPath(String email, String replyToId) {
    return '${RouteConstants.mailPrefix}/$email/compose?replyTo=$replyToId';
  }

  // ✅ NEW: Default folder redirect path
  /// Redirect to default folder (inbox) when no folder specified
  static String defaultFolderPath(String email) {
    return folderPath(email, MailFolderNames.inbox);
  }
}

// ✅ NEW: Mail folder name constants
class MailFolderNames {
  MailFolderNames._();

  static const String inbox = 'inbox';
  static const String sent = 'sent';
  static const String drafts = 'drafts';
  static const String spam = 'spam';
  static const String trash = 'trash';
  static const String starred = 'starred';
  static const String important = 'important';
  static const String archive = 'archive';

  /// All valid folder names
  static const List<String> all = [
    inbox,
    sent,
    drafts,
    spam,
    trash,
    starred,
    important,
    archive,
  ];

  /// Check if folder name is valid
  static bool isValid(String folderName) {
    return all.contains(folderName.toLowerCase());
  }

  /// Convert MailFolder enum to URL string
  static String fromEnum(dynamic mailFolder) {
    final folderStr = mailFolder.toString().split('.').last.toLowerCase();
    return folderStr;
  }

  /// Convert URL string to MailFolder enum value name
  static String toEnumName(String folderName) {
    return folderName.toLowerCase();
  }
}

// ========== ROUTE PARAMETERS ==========

class RouteParams {
  RouteParams._();

  static const String email = 'email';
  static const String folder = 'folder';
  static const String mailId = 'mailId';
  static const String messageId = 'messageId';
  static const String folderId = 'folderId';
}

// ========== QUERY PARAMETERS ==========

class QueryParams {
  QueryParams._();

  static const String replyTo = 'replyTo';
  static const String forward = 'forward';
  static const String query = 'q';
  static const String page = 'page';
  static const String pageToken = 'pageToken';
}
