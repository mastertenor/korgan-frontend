Mükemmel soru! Mail silme işleminin tüm akışını takip edelim:

## 🔄 **API ÇAĞRISI AKIŞI**

### **1️⃣ UI Trigger (mail_page.dart)**
```dart
// Kullanıcı swipe yapar
onDismissed: (direction) async {
  await _moveToTrash(mail, index); // ← BURADAN BAŞLAR
}

// _moveToTrash metodu
Future<void> _moveToTrash(Mail mail, int index) async {
  await ref
      .read(mailProvider.notifier)
      .moveToTrash(mail.id, widget.userEmail); // ← PROVIDER'A GİDER
}
```

### **2️⃣ Provider (mail_provider.dart)**
```dart
/// Move mail to trash (soft delete)
Future<void> moveToTrash(String mailId, String email) async {
  final params = MailActionParams(id: mailId, email: email);
  final result = await _mailActionsUseCase.moveToTrash(params); // ← USECASE'E GİDER
}
```

### **3️⃣ UseCase (mail_actions_usecase.dart)**
```dart
/// Move email to trash (soft delete)
Future<Result<void>> moveToTrash(MailActionParams params) async {
  return await _repository.moveToTrash(id: params.id, email: params.email); // ← REPOSITORY'E GİDER
}
```

### **4️⃣ Repository (mail_repository_impl.dart)**
```dart
@override
Future<Result<void>> moveToTrash({required String id, required String email}) async {
  try {
    await _remoteDataSource.moveToTrash(id: id, email: email); // ← DATASOURCE'A GİDER
    return const Success(null);
  } catch (e) {
    return Failure(...);
  }
}
```

### **5️⃣ DataSource (mail_remote_datasource.dart)** - **ASIL API ÇAĞRISI**
```dart
@override
Future<void> moveToTrash({required String id, required String email}) async {
  try {
    // ✅ BURDA API URL'İ OLUŞTURULUYOR
    final url = ApiEndpoints.buildGmailActionUrl(
      operation: ApiEndpoints.trashOperation, // ← "trash" operation
      emailId: id,
      email: email,
    );

    // ✅ BURDA HTTP İSTEĞİ YAPILIYOR
    final response = await _apiClient.get(url);

    if (response.statusCode != 200) {
      throw ServerException.internalError(
        message: 'Failed to move email to trash',
        endpoint: url,
      );
    }
  } catch (e) {
    // Error handling
  }
}
```

### **6️⃣ API Endpoints (api_endpoints.dart)** - **URL OLUŞTURMA**
```dart
/// Build Gmail action URL for specific operations
static String buildGmailActionUrl({
  required String operation,
  required String emailId,
  required String email,
}) {
  final uri = Uri.http(
    baseUrl,
    '$apiPath/gmail/queue', // ← /api/gmail/queue
    {
      'operation': operation,    // ← operation=trash
      'messageId': emailId,      // ← messageId=mail_id
      'email': email,            // ← email=user@example.com
    },
  );
  return uri.toString();
}

// Trash operation constant
static const String trashOperation = 'trash'; // ← "trash" değeri
```

### **7️⃣ API Client (api_client.dart)** - **HTTP İSTEĞİ**
```dart
/// GET request
Future<Response<T>> get<T>(String path, ...) async {
  try {
    final response = await _dio.get<T>(path, ...); // ← DIO HTTP GET
    return response;
  } catch (e) {
    throw _handleDioException(e);
  }
}
```

## 🎯 **ÖZET: HANGİ DOSYADA HANGİ İŞLEM**

| **Dosya** | **Yapılan İş** | **Kod** |
|-----------|----------------|---------|
| `mail_page.dart` | UI trigger | `await _moveToTrash(mail, index)` |
| `mail_provider.dart` | State management | `await _mailActionsUseCase.moveToTrash(params)` |
| `mail_actions_usecase.dart` | Business logic | `await _repository.moveToTrash(...)` |
| `mail_repository_impl.dart` | Data coordination | `await _remoteDataSource.moveToTrash(...)` |
| **`mail_remote_datasource.dart`** | **🔥 ASIL API ÇAĞRISI** | **`await _apiClient.get(url)`** |
| `api_endpoints.dart` | URL building | `buildGmailActionUrl(operation: "trash")` |
| `api_client.dart` | HTTP client | `_dio.get<T>(path)` |

## 🌐 **OLUŞAN URL**

```
https://your-backend.com/api/gmail/queue?operation=trash&messageId=123456&email=user@example.com
```

**En kritik dosya: `mail_remote_datasource.dart`** - Burada gerçek HTTP isteği yapılıyor!