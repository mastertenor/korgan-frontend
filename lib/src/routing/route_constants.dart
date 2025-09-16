// lib/src/routing/route_constants.dart

/// Type-safe route constants for the application with organization support
class RouteConstants {
  RouteConstants._();

  // ========== CORE ROUTES ==========
  static const String home = '/home'; // Home route stays without organization
  static const String error = '/error';

  // ========== ORGANIZATION-BASED MODULE PREFIXES ==========
  // All modules except home now require organization slug
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

  /// ✅ YENİ: Validate organization slug format
  static bool isValidOrgSlug(String slug) {
    return RegExp(r'^[a-z0-9-]+$').hasMatch(slug) &&
        slug.isNotEmpty &&
        slug.length <= 50;
  }

  /// Validate route parameter (no slashes, not empty)
  static bool isValidRouteParam(String param) {
    return param.isNotEmpty && !param.contains('/');
  }
}

// ========== ROUTE PARAMETERS ==========

class RouteParams {
  RouteParams._();

  static const String orgSlug =
      'orgSlug'; // ✅ YENİ: Organization slug parametresi
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

// ========== MAIL MODULE ROUTES WITH ORGANIZATION SUPPORT ==========

class MailRoutes {
  MailRoutes._();

  // ✅ YENİ: Organization-based route patterns
  static const String orgUserMail =
      '/:orgSlug${RouteConstants.mailPrefix}/:email';
  static const String orgUserMailFolder =
      '/:orgSlug${RouteConstants.mailPrefix}/:email/:folder';
  static const String orgUserMailDetail =
      '/:orgSlug${RouteConstants.mailPrefix}/:email/:folder/:mailId';


  // ========== ORGANIZATION-AWARE PATH GENERATORS ==========

  /// ✅ YENİ: Generate organization-based mail path
  /// Example: /argen-teknoloji/mail/user@example.com
  static String orgUserMailPath(String orgSlug, String email) {
    return '/$orgSlug${RouteConstants.mailPrefix}/$email';
  }

  /// ✅ YENİ: Generate organization-based folder path
  /// Example: /argen-teknoloji/mail/user@example.com/inbox
  static String orgFolderPath(String orgSlug, String email, String folder) {
    return '/$orgSlug${RouteConstants.mailPrefix}/$email/$folder';
  }

  /// ✅ YENİ: Generate organization-based mail detail path
  /// Example: /argen-teknoloji/mail/user@example.com/inbox/mail_123
  static String orgMailDetailPath(
    String orgSlug,
    String email,
    String folder,
    String mailId,
  ) {
    return '/$orgSlug${RouteConstants.mailPrefix}/$email/$folder/$mailId';
  }

  /// ✅ YENİ: Generate organization-based compose path
  /// Example: /argen-teknoloji/mail/user@example.com/compose
  static String orgComposePath(String orgSlug, String email) {
    return '/$orgSlug${RouteConstants.mailPrefix}/$email/compose';
  }

  /// ✅ YENİ: Generate organization-based compose reply path
  /// Example: /argen-teknoloji/mail/user@example.com/compose?replyTo=123
  static String orgComposeReplyPath(
    String orgSlug,
    String email,
    String replyToId,
  ) {
    return '/$orgSlug${RouteConstants.mailPrefix}/$email/compose?replyTo=$replyToId';
  }

  /// ✅ YENİ: Generate default folder redirect path (inbox)
  /// Example: /argen-teknoloji/mail/user@example.com/inbox
  static String orgDefaultFolderPath(String orgSlug, String email) {
    return orgFolderPath(orgSlug, email, MailFolderNames.inbox);
  }

  // ========== LEGACY PATH GENERATORS (for backward compatibility) ==========

  /// Generate folder path for specific folder (LEGACY - will redirect)
  /// Example: /mail/user@example.com/inbox
  static String folderPath(String email, String folder) {
    return '${RouteConstants.mailPrefix}/$email/$folder';
  }

  /// Generate mail detail path (LEGACY - will redirect)
  /// Example: /mail/user@example.com/inbox/mail_123
  static String mailDetailPath(String email, String folder, String mailId) {
    return '${RouteConstants.mailPrefix}/$email/$folder/$mailId';
  }

  /// Generate user mail path (LEGACY - will redirect)
  static String userMailPath(String email) {
    return '${RouteConstants.mailPrefix}/$email';
  }

  /// Default folder redirect path (LEGACY - will redirect)
  static String defaultFolderPath(String email) {
    return folderPath(email, MailFolderNames.inbox);
  }

  // Legacy paths (deprecated but kept for compatibility)
  static String messagePath(String email, String messageId) {
    return '${RouteConstants.mailPrefix}/$email/message/$messageId';
  }

  static String composePath(String email) {
    return '${RouteConstants.mailPrefix}/$email/compose';
  }

  static String composeReplyPath(String email, String replyToId) {
    return '${RouteConstants.mailPrefix}/$email/compose?replyTo=$replyToId';
  }
}

// ========== OTHER MODULE ROUTES WITH ORGANIZATION SUPPORT ==========

/// ✅ YENİ: CRM Routes with organization support
class CrmRoutes {
  CrmRoutes._();

  static const String orgCrm = '/:orgSlug${RouteConstants.crmPrefix}';
  static const String orgContacts =
      '/:orgSlug${RouteConstants.crmPrefix}/contacts';
  static const String orgCompanies =
      '/:orgSlug${RouteConstants.crmPrefix}/companies';

  static String orgCrmPath(String orgSlug) =>
      '/$orgSlug${RouteConstants.crmPrefix}';
  static String orgContactsPath(String orgSlug) =>
      '/$orgSlug${RouteConstants.crmPrefix}/contacts';
  static String orgCompaniesPath(String orgSlug) =>
      '/$orgSlug${RouteConstants.crmPrefix}/companies';
}

/// ✅ YENİ: Task Routes with organization support
class TaskRoutes {
  TaskRoutes._();

  static const String orgTasks = '/:orgSlug${RouteConstants.tasksPrefix}';
  static const String orgTaskDetail =
      '/:orgSlug${RouteConstants.tasksPrefix}/:taskId';

  static String orgTasksPath(String orgSlug) =>
      '/$orgSlug${RouteConstants.tasksPrefix}';
  static String orgTaskDetailPath(String orgSlug, String taskId) =>
      '/$orgSlug${RouteConstants.tasksPrefix}/$taskId';
}

/// ✅ YENİ: Dashboard Routes with organization support
class DashboardRoutes {
  DashboardRoutes._();

  static const String orgDashboard =
      '/:orgSlug${RouteConstants.dashboardPrefix}';

  static String orgDashboardPath(String orgSlug) =>
      '/$orgSlug${RouteConstants.dashboardPrefix}';
}

/// ✅ YENİ: Files Routes with organization support
class FilesRoutes {
  FilesRoutes._();

  static const String orgFiles = '/:orgSlug${RouteConstants.filesPrefix}';

  static String orgFilesPath(String orgSlug) =>
      '/$orgSlug${RouteConstants.filesPrefix}';
}

/// ✅ YENİ: Chat Routes with organization support
class ChatRoutes {
  ChatRoutes._();

  static const String orgChat = '/:orgSlug${RouteConstants.chatPrefix}';

  static String orgChatPath(String orgSlug) =>
      '/$orgSlug${RouteConstants.chatPrefix}';
}

// ========== MAIL FOLDER CONSTANTS (UNCHANGED) ==========

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
