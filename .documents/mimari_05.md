# 📁 KORGAN PROJESİ MİMARİ REHBERİ

## 🎯 GENEL PROJE YAPISI

```
lib/src/
├── 🏗️ core/                    # TEMEL ALTYAPI
├── 📧 features/mail/            # MAİL ÖZELLİĞİ
├── 💬 features/chat/            # CHAT ÖZELLİĞİ (gelecek)
├── ✅ features/task/            # TASK ÖZELLİĞİ (gelecek)
└── 🛠️ utils/                   # YARDIMCI ARAÇLAR
```

---

## 🏗️ CORE KATMANI (TEMEL ALTYAPI)

### 📍 Lokasyon: `lib/src/core/`

```
core/
├── network/                 # AĞ İŞLEMLERİ
│   ├── api_client.dart     # HTTP Client
│   ├── api_endpoints.dart  # URL Yönetimi
│   ├── network_exceptions.dart # Ağ Hataları
│   └── api_interceptors.dart   # Middleware
├── error/                   # HATA YÖNETİMİ
│   ├── failures.dart       # İş Mantığı Hataları
│   └── exceptions.dart     # Teknik Hatalar
└── utils/                   # YARDIMCI ARAÇLAR
    └── result.dart         # Success/Failure Wrapper
```

### 🔧 Her Dosyanın Görevi:

#### **`api_client.dart`** - HTTP Motor
```dart
// GÖREV: Tüm HTTP isteklerini yönetir
- GET, POST, PUT, DELETE operations
- Timeout management
- Interceptor support
- Platform-specific configurations (web/mobile)
```

#### **`api_endpoints.dart`** - URL Fabrikası
```dart
// GÖREV: API URL'lerini oluşturur
- Base URL management
- Query parameter building
- Environment switching (dev/prod)
- Gmail API URL construction
```

#### **`network_exceptions.dart`** - Ağ Hata Çevirmeni
```dart
// GÖREV: Dio hatalarını kullanıcı dostu mesajlara çevirir
- Connection timeout → "Bağlantı zaman aşımı"
- 404 Not Found → "Kaynak bulunamadı"
- Network error → "İnternet bağlantınızı kontrol edin"
```

#### **`api_interceptors.dart`** - Middleware Koleksiyonu
```dart
// GÖREV: HTTP isteklerini intercept eder
- LoggingInterceptor: İstekleri loglar
- AuthInterceptor: Token ekler
- CacheInterceptor: Response'ları cache'ler
- RetryInterceptor: Başarısız istekleri tekrar dener
```

#### **`failures.dart`** - İş Mantığı Hataları
```dart
// GÖREV: Domain layer hataları
- NetworkFailure: Ağ sorunları
- ServerFailure: Sunucu sorunları
- ValidationFailure: Validasyon hataları
- MailFailure: Mail-specific hatalar
```

#### **`exceptions.dart`** - Teknik Hatalar
```dart
// GÖREV: Data layer exceptions
- ServerException: HTTP hataları
- NetworkException: Bağlantı hataları
- CacheException: Cache sorunları
- ParseException: JSON parsing hataları
```

#### **`result.dart`** - Success/Failure Wrapper
```dart
// GÖREV: Type-safe error handling
- Success<T>: İşlem başarılı
- Failure<T>: İşlem başarısız
- Pattern matching support
```

---

## 📧 MAIL FEATURE (ÖZELLİK KATMANLARI)

### 📍 Lokasyon: `lib/src/features/mail/`

```
features/mail/
├── 💾 data/                 # VERİ KATMANI
│   ├── datasources/
│   ├── models/
│   └── repositories/
├── 🎯 domain/               # İŞ MANTIĞI KATMANI
│   ├── entities/
│   ├── repositories/
│   └── usecases/
└── 🎨 presentation/         # SUNUM KATMANI
    ├── providers/
    ├── widgets/
    └── pages/
```

### 💾 DATA LAYER (Veri Katmanı)

#### **`data/models/`**

**`mail_model.dart`** - JSON Çevirmen
```dart
// GÖREV: API JSON'ını Dart object'e çevirir
class MailModel {
  - fromJson(): API → Dart object
  - toJson(): Dart object → API
  - toDomain(): Data model → Domain entity
}
```

**`mail_response_model.dart`** - Liste Response Parser
```dart
// GÖREV: Gmail API list response'ını parse eder
class MailResponseModel {
  - List<MailModel> messages
  - String? nextPageToken
  - int resultSizeEstimate
  - Pagination support
}
```

#### **`data/datasources/`**

**`mail_remote_datasource.dart`** - API Konuşmacı
```dart
// GÖREV: API ile direkt iletişim
interface MailRemoteDataSource {
  - getMails(): Email listesi getir
  - markAsRead(): Okundu işaretle
  - deleteMail(): Email sil
  - starMail(): Yıldızla
}

class MailRemoteDataSourceImpl {
  - ApiClient kullanır
  - HTTP requests yapar
  - Raw API responses döndürür
}
```

#### **`data/repositories/`**

**`mail_repository_impl.dart`** - Çevirmen Koordinatör
```dart
// GÖREV: Exception → Failure dönüştürür, Data → Domain koordine eder
class MailRepositoryImpl implements MailRepository {
  - Remote datasource'u çağırır
  - Exception'ları Failure'a çevirir
  - Model'leri Entity'e çevirir
  - Business logic coordination
}
```

### 🎯 DOMAIN LAYER (İş Mantığı Katmanı)

#### **`domain/entities/`**

**`mail.dart`** - İş Mantığı Modeli
```dart
// GÖREV: Pure business object
class Mail {
  - senderName, subject, content
  - isRead, isStarred
  - UI'dan bağımsız
  - Immutable
}
```

#### **`domain/repositories/`**

**`mail_repository.dart`** - Sözleşme
```dart
// GÖREV: Data layer ile Domain arasındaki contract
abstract class MailRepository {
  - getMails(): Result<List<Mail>>
  - markAsRead(): Result<void>
  - deleteMail(): Result<void>
  - Interface, implementation değil
}
```

#### **`domain/usecases/`**

**`get_mails_usecase.dart`** - İş Kuralları
```dart
// GÖREV: Email getirme business logic
class GetMailsUseCase {
  - Email format validation
  - Max results kontrolü (1-100)
  - Repository'yi çağırır
  - Business rules uygular
}
```

**`mail_actions_usecase.dart`** - Email İşlemleri
```dart
// GÖREV: Email actions business logic
class MailActionsUseCase {
  - markAsRead(), deleteMail(), starMail()
  - Parameter validation
  - Repository'yi çağırır
}
```

**`get_mail_by_id_usecase.dart`** - Tek Email
```dart
// GÖREV: Specific email retrieval business logic
class GetMailByIdUseCase {
  - ID validation
  - Email format kontrolü
  - Repository'yi çağırır
}
```

### 🎨 PRESENTATION LAYER (Sunum Katmanı)

#### **`presentation/providers/`**

**`mail_provider.dart`** - State Yöneticisi
```dart
// GÖREV: Email state management
class MailNotifier extends StateNotifier<MailState> {
  - Use case'leri çağırır
  - UI state'ini yönetir
  - Loading, error, success states
  - Automatic UI updates trigger eder
}

class MailState {
  - List<Mail> mails
  - bool isLoading
  - String? error
  - int unreadCount
}
```

**`mail_providers.dart`** - Dependency Injection
```dart
// GÖREV: Provider dependency tree setup
- apiClientProvider
- mailRemoteDataSourceProvider
- mailRepositoryProvider
- getMailsUseCaseProvider
- mailProvider
- Computed providers (unreadMailsProvider, etc.)
```

#### **`presentation/widgets/`**

**`mail_item_showcase_updated.dart`** - UI Widget
```dart
// GÖREV: Mail listesi UI
class MailItemShowcase extends ConsumerStatefulWidget {
  - Provider'ları watch eder
  - User interactions handle eder
  - State changes'i UI'ye yansıtır
  - Business logic'i use case'lere delegate eder
}
```

---

## 🔄 UYGULAMA AKIŞ HİYERARŞİSİ

### 📱 **1. UYGULAMA BAŞLATILDIĞINDA**

```
main.dart
├── ProviderScope(child: MailItemShowcaseApp())
├── MaterialApp creates
├── MailItemShowcase widget builds
├── initState() calls
└── ref.read(mailProvider.notifier).loadMails(userEmail)
```

### 🔄 **2. MAİL LİSTESİ YÜKLEME AKIŞI**

```
🎨 UI Layer
   │ user action: loadMails()
   ↓
📊 Provider Layer
   │ MailNotifier.loadMails()
   ↓ 
🎯 Domain Layer
   │ GetMailsUseCase.call()
   │ ├── email validation
   │ ├── maxResults validation  
   │ └── repository.getMails()
   ↓
📋 Repository Interface
   │ MailRepository.getMails()
   ↓
💾 Data Layer
   │ MailRepositoryImpl.getMails()
   │ ├── remoteDataSource.getMails()
   │ ├── exception → failure mapping
   │ └── model → entity conversion
   ↓
🌐 DataSource Layer
   │ MailRemoteDataSourceImpl.getMails()
   │ ├── ApiEndpoints.buildGmailQueueUrl()
   │ ├── ApiClient.get()
   │ └── MailResponseModel.fromJson()
   ↓
🔧 Network Layer
   │ ApiClient uses Dio
   │ ├── Interceptors apply
   │ ├── HTTP GET request
   │ └── Response parsing
   ↓
🌍 Backend API
   │ Next.js API route
   │ ├── CORS middleware
   │ ├── Gmail API call
   │ └── JSON response
```

### ⬅️ **3. RESPONSe GERİ DÖNÜŞ AKIŞI**

```
🌍 Backend → JSON response
   ↓
🔧 ApiClient → Response<Map<String, dynamic>>
   ↓
🌐 DataSource → MailResponseModel
   ↓
💾 Repository → List<Mail> entities
   ↓
🎯 UseCase → Result<List<Mail>>
   ↓
📊 Provider → MailState updates
   ↓
🎨 UI → Automatic rebuild & display
```

### ⚡ **4. USER İNTERACTION AKIŞI (Örnek: Mark as Read)**

```
🎨 UI: User taps mail item
   │ onTap: _toggleRead(mail)
   ↓
📊 Provider: mailProvider.notifier.markAsRead()
   ↓
🎯 UseCase: MailActionsUseCase.markAsRead()
   │ ├── parameter validation
   │ └── repository.markAsRead()
   ↓
💾 Repository: API call + local state update
   ↓
🌐 DataSource: HTTP POST to mark read
   ↓
🔧 Network: API request
   ↓
🌍 Backend: Gmail API update
   ↓
⬅️ Response: Success/Failure
   ↓
📊 Provider: State update (mail.isRead = true)
   ↓
🎨 UI: Mail item visual update (bold → normal)
```

---

## 🎭 HATALAR NASIL YÖNETİLİR?

### ❌ **Hata Akış Zinciri**

```
🌍 Backend Error (404, 500, timeout)
   ↓
🔧 ApiClient → DioException
   ↓
🌐 DataSource → ServerException/NetworkException
   ↓
💾 Repository → NetworkFailure/ServerFailure  
   ↓
🎯 UseCase → Result.Failure(failure)
   ↓
📊 Provider → state.error = failure.message
   ↓
🎨 UI → Error banner/snackbar gösterir
```

---

## 🔗 DEPENDENCy INJECTİON AĞACI

```
Provider Tree:
├── apiClientProvider
    ├── mailRemoteDataSourceProvider
        ├── mailRepositoryProvider
            ├── getMailsUseCaseProvider
            ├── mailActionsUseCaseProvider
                └── mailProvider (STATE)
                    ├── unreadMailsProvider
                    ├── starredMailsProvider
                    ├── mailLoadingProvider
                    └── mailErrorProvider
```

---

## 🎯 KATMAN SORUMLULUKLARI ÖZET

| Katman | Sorumluluğu | Bildiği | Bilmediği |
|--------|-------------|---------|-----------|
| **UI** | Kullanıcı etkileşimi | Provider, Widget | API, Database |
| **Provider** | State management | UseCase, State | HTTP, JSON |
| **UseCase** | Business rules | Repository interface | API details |
| **Repository** | Data coordination | DataSource, Entity | HTTP implementation |
| **DataSource** | API communication | ApiClient, Model | Business rules |
| **ApiClient** | HTTP operations | Dio, Network | Business logic |

---

## 🔮 YENİ MODÜL EKLERKEn (Chat, Task, CRM)

Aynı pattern'i takip et:

```
features/chat/
├── data/
│   ├── models/chat_model.dart
│   ├── datasources/chat_remote_datasource.dart
│   └── repositories/chat_repository_impl.dart
├── domain/
│   ├── entities/chat.dart
│   ├── repositories/chat_repository.dart
│   └── usecases/get_chats_usecase.dart
└── presentation/
    ├── providers/chat_provider.dart
    └── widgets/chat_list_widget.dart
```

**Core katmanı değişmez**, sadece feature'a özel provider'lar ve use case'ler eklenir!

---

Bu mimari sayesinde:
- ✅ Her katman bağımsız test edilebilir
- ✅ Kod değişiklikleri izole
- ✅ Yeni özellikler kolayca eklenir  
- ✅ Business logic UI'dan ayrı
- ✅ API değişiklikleri sadece DataSource'u etkiler