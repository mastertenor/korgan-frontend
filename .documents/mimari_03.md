lib/
└── src/
    └── common_widgets/
        └── mail/
            ├── mail_item.dart                 # Ana widget
            ├── mail_item_showcase.dart        # Showcase/Demo
            ├── widgets/                       # Alt bileşenler
            │   ├── mail_avatar.dart          # Avatar widget'ı
            │   ├── mail_content.dart         # İçerik bölümü
            │   ├── mail_swipe_actions.dart   # Swipe aksiyonları
            │   └── mail_confirmation_dialog.dart # Silme onayı
            ├── models/                        # Data modelleri
            │   └── mail_data.dart            # MailData sınıfı
            └── utils/                         # Yardımcı fonksiyonlar
                └── mail_utils.dart           # Avatar rengi vs.



mail/
├── mail_item.dart                 # Ana adaptive widget
├── platform/
│   ├── mail_item_mobile.dart     # Mobile implementation
│   ├── mail_item_desktop.dart    # Desktop implementation
│   └── mail_item_web.dart        # Web implementation
├── adaptive/
│   ├── adaptive_mail_actions.dart # Platform'a göre actions
│   └── adaptive_mail_gestures.dart # Platform'a göre gestures
└── shared/
    ├── mail_content.dart         # Ortak içerik widget'ı
    └── mail_avatar.dart          # Ortak avatar widget'ı



lib/src/common_widgets/mail/
├── mail_item.dart                          # 🎯 Ana adaptive entry point
├── 
├── models/                                 # 📊 Data models (platform agnostic)
│   └── mail_data.dart
├── 
├── shared/                                 # 🔗 Ortak bileşenler (tüm platformlarda aynı)
│   ├── widgets/
│   │   ├── mail_avatar.dart               # Avatar (her platformda aynı)
│   │   ├── mail_content_base.dart         # İçerik base class
│   │   └── mail_confirmation_dialog.dart  # Dialog (platform styled)
│   └── utils/
│       ├── mail_utils.dart                # Utilities
│       └── mail_constants.dart            # Constants, colors, sizes
├── 
├── platform/                              # 📱 Platform-specific implementations
│   ├── mobile/
│   │   ├── mail_item_mobile.dart         # Mobile ana widget
│   │   ├── widgets/
│   │   │   ├── mobile_mail_content.dart  # Mobile içerik layoutu
│   │   │   ├── mobile_swipe_actions.dart # Swipe actions
│   │   │   └── mobile_mail_gestures.dart # Touch gestures
│   │   └── styles/
│   │       └── mobile_mail_styles.dart   # Mobile styles
│   │
│   ├── desktop/
│   │   ├── mail_item_desktop.dart        # Desktop ana widget
│   │   ├── widgets/
│   │   │   ├── desktop_mail_content.dart # Desktop içerik (denser)
│   │   │   ├── desktop_context_menu.dart # Right-click menu
│   │   │   ├── desktop_hover_effects.dart # Hover states
│   │   │   └── desktop_selection.dart    # Multi-selection
│   │   └── styles/
│   │       └── desktop_mail_styles.dart  # Desktop styles
│   │
│   └── web/
│       ├── mail_item_web.dart            # Web ana widget
│       ├── widgets/
│       │   ├── web_mail_content.dart     # Web-specific layout
│       │   ├── web_mail_actions.dart     # Web actions (buttons vs swipe)
│       │   └── web_keyboard_handler.dart # Web keyboard shortcuts
│       └── styles/
│           └── web_mail_styles.dart      # Web styles
├── 
├── adaptive/                              # 🔄 Adaptive logic
│   ├── mail_item_factory.dart            # Platform factory
│   ├── adaptive_mail_actions.dart        # Platform'a göre action seçimi
│   ├── adaptive_styles.dart              # Platform'a göre style seçimi
│   └── platform_detector.dart            # Platform detection utility
├── 
└── showcase/                              # 🎪 Demo & testing
    ├── mail_item_showcase.dart           # Ana showcase
    ├── platform_showcases/
    │   ├── mobile_mail_showcase.dart     # Mobile test
    │   ├── desktop_mail_showcase.dart    # Desktop test
    │   └── web_mail_showcase.dart        # Web test
    └── test_data/
        └── sample_mail_data.dart         # Test verileri






lib/src/
├── features/
│   ├── mail/                          # 📧 Mail Modülü
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   ├── mail.dart
│   │   │   │   ├── attachment.dart
│   │   │   │   └── mail_folder.dart
│   │   │   ├── repositories/
│   │   │   │   └── mail_repository.dart
│   │   │   └── use_cases/
│   │   │       ├── send_mail.dart
│   │   │       ├── get_mails.dart
│   │   │       └── delete_mail.dart
│   │   ├── data/
│   │   │   ├── repositories/
│   │   │   ├── data_sources/
│   │   │   └── models/
│   │   ├── presentation/
│   │   │   ├── pages/
│   │   │   │   ├── mail_list_page.dart
│   │   │   │   ├── mail_detail_page.dart
│   │   │   │   └── compose_mail_page.dart
│   │   │   ├── widgets/                # Mail'e özel widget'lar
│   │   │   │   ├── mail_item/
│   │   │   │   │   ├── mail_item.dart
│   │   │   │   │   ├── platform/
│   │   │   │   │   │   ├── mobile/
│   │   │   │   │   │   ├── desktop/
│   │   │   │   │   │   └── web/
│   │   │   │   │   └── adaptive/
│   │   │   │   ├── mail_viewer/
│   │   │   │   │   ├── mail_viewer.dart
│   │   │   │   │   └── platform/
│   │   │   │   ├── mail_composer/
│   │   │   │   │   ├── mail_composer.dart
│   │   │   │   │   └── platform/
│   │   │   │   └── attachment_picker/
│   │   │   │       ├── attachment_picker.dart
│   │   │   │       └── platform/
│   │   │   ├── providers/              # State management
│   │   │   └── bloc/                   # Business logic
│   │   └── mail.dart                   # Feature barrel export
│   │
│   ├── chat/                          # 💬 Chat Modülü
│   │   ├── domain/
│   │   ├── data/
│   │   ├── presentation/
│   │   │   ├── pages/
│   │   │   │   ├── chat_list_page.dart
│   │   │   │   └── chat_room_page.dart
│   │   │   └── widgets/                # Chat'e özel widget'lar
│   │   │       ├── chat_item/
│   │   │       │   ├── chat_item.dart
│   │   │       │   └── platform/
│   │   │       ├── chat_bubble/
│   │   │       │   ├── chat_bubble.dart
│   │   │       │   └── platform/
│   │   │       ├── message_input/
│   │   │       └── file_picker/
│   │   └── chat.dart
│   │
│   ├── crm/                           # 🏢 CRM Modülü
│   │   ├── domain/
│   │   ├── data/
│   │   ├── presentation/
│   │   │   ├── pages/
│   │   │   └── widgets/                # CRM'e özel widget'lar
│   │   │       ├── customer_card/
│   │   │       │   ├── customer_card.dart
│   │   │       │   └── platform/
│   │   │       ├── deal_tracker/
│   │   │       ├── contact_form/
│   │   │       └── pipeline_view/
│   │   └── crm.dart
│   │
│   └── tasks/                         # ✅ Tasks Modülü
│       ├── domain/
│       ├── data/
│       ├── presentation/
│       │   ├── pages/
│       │   └── widgets/                # Tasks'e özel widget'lar
│       │       ├── task_item/
│       │       │   ├── task_item.dart
│       │       │   └── platform/
│       │       ├── task_board/
│       │       ├── task_form/
│       │       └── priority_badge/
│       └── tasks.dart
│
├── shared/                            # 🔗 Cross-cutting concerns
│   ├── widgets/                       # Gerçekten generic widget'lar
│   │   ├── buttons/
│   │   │   ├── adaptive_button.dart
│   │   │   └── platform/
│   │   ├── cards/
│   │   ├── forms/
│   │   └── navigation/
│   ├── utils/
│   │   ├── platform_helper.dart       # Mevcut dosyanız
│   │   ├── app_logger.dart
│   │   └── constants.dart
│   ├── theme/
│   ├── services/
│   └── exceptions/
│
└── core/                              # 🎯 App-wide infrastructure
    ├── di/                            # Dependency injection
    ├── router/                        # App routing
    ├── config/
    └── app.dart