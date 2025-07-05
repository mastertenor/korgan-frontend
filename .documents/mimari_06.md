sequenceDiagram
    participant Main as 📱 main.dart<br/>🏗️ ROOT LAYER<br/>(ProviderScope)
    participant ShowcaseApp as 🎨 MailItemShowcaseApp<br/>🎨 PRESENTATION LAYER<br/>(MaterialApp Widget)
    participant ShowcaseWidget as 🎨 MailItemShowcase<br/>🎨 PRESENTATION LAYER<br/>(ConsumerStatefulWidget)
    participant Providers as 📊 mail_providers.dart<br/>🎨 PRESENTATION LAYER<br/>(Provider Dependency Tree)
    participant ApiClient as 🔧 api_client.dart<br/>🔧 CORE NETWORK LAYER<br/>(Singleton HTTP Client)
    participant MailProvider as 📊 mail_provider.dart<br/>🎨 PRESENTATION LAYER<br/>(StateNotifier<MailState>)
    participant GetMailsUseCase as 🎯 get_mails_usecase.dart<br/>🎯 DOMAIN LAYER<br/>(Business Logic UseCase)
    participant MailRepository as 💾 mail_repository_impl.dart<br/>💾 DATA LAYER<br/>(Repository Implementation)
    participant RemoteDataSource as 🌐 mail_remote_datasource.dart<br/>💾 DATA LAYER<br/>(API Communication)
    participant ApiEndpoints as 🛠️ api_endpoints.dart<br/>🔧 CORE NETWORK LAYER<br/>(URL Builder Utility)
    participant Backend as 🌍 Next.js API<br/>🌍 BACKEND LAYER<br/>(route.ts + middleware.ts)

    Note over Main,Backend: 🚀 UYGULAMA BAŞLATMA SEQUENCEİ

    Main->>Main: 1. runApp() çalışır<br/>Type: void Function()
    Main->>Main: 2. ProviderScope() wrapper oluşturulur<br/>Type: ProviderScope Widget
    Main->>ShowcaseApp: 3. MailItemShowcaseApp() widget'ı build edilir<br/>Type: StatelessWidget
    
    ShowcaseApp->>ShowcaseApp: 4. MaterialApp() configuration<br/>Type: MaterialApp Widget
    ShowcaseApp->>ShowcaseApp: 5. Theme, title ayarları<br/>Type: ThemeData, String
    ShowcaseApp->>ShowcaseWidget: 6. MailItemShowcase() home widget'ı çağırılır<br/>Type: ConsumerStatefulWidget

    Note over ShowcaseWidget: 🔄 WIDGET LIFECYCLE - PRESENTATION LAYER

    ShowcaseWidget->>ShowcaseWidget: 7. ConsumerStatefulWidget.createState()<br/>Type: ConsumerState<MailItemShowcase>
    ShowcaseWidget->>ShowcaseWidget: 8. initState() çalışır<br/>Type: void override method
    ShowcaseWidget->>ShowcaseWidget: 9. WidgetsBinding.addPostFrameCallback()<br/>Type: VoidCallback

    Note over Providers: 📦 DEPENDENCY INJECTION TREE - PRESENTATION LAYER

    ShowcaseWidget->>Providers: 10. ref.read() çağrısı başlatır dependency tree<br/>Type: ProviderRef
    Providers->>ApiClient: 11. apiClientProvider create<br/>Type: Provider<ApiClient>
    ApiClient->>ApiClient: 12. ApiClient._internal() singleton oluşur<br/>Type: ApiClient instance
    ApiClient->>ApiClient: 13. Dio configuration (baseURL, timeouts, headers)<br/>Type: BaseOptions, Map<String, dynamic>
    ApiClient->>ApiClient: 14. LogInterceptor eklenir<br/>Type: LogInterceptor
    
    Providers->>Providers: 15. mailRemoteDataSourceProvider create<br/>Type: Provider<MailRemoteDataSource>
    Providers->>Providers: 16. mailRepositoryProvider create<br/>Type: Provider<MailRepository>
    Providers->>Providers: 17. getMailsUseCaseProvider create<br/>Type: Provider<GetMailsUseCase>
    Providers->>Providers: 18. mailActionsUseCaseProvider create<br/>Type: Provider<MailActionsUseCase>
    Providers->>MailProvider: 19. mailProvider (StateNotifier) create<br/>Type: StateNotifierProvider<MailNotifier, MailState>

    MailProvider->>MailProvider: 20. MailNotifier() constructor<br/>Type: MailNotifier extends StateNotifier
    MailProvider->>MailProvider: 21. super(const MailState()) - initial state<br/>Type: MailState(mails: [], isLoading: false)

    Note over ShowcaseWidget: 🎯 İLK VERİ YÜKLEME - DOMAIN LAYER BAŞLANGICI

    ShowcaseWidget->>MailProvider: 22. ref.read(mailProvider.notifier).loadMails(userEmail)<br/>Type: Future<void>, String email
    MailProvider->>MailProvider: 23. state = MailState(isLoading: true)<br/>Type: MailState update
    MailProvider->>GetMailsUseCase: 24. _getMailsUseCase.call(GetMailsParams)<br/>Type: Future<Result<List<Mail>>>

    GetMailsUseCase->>GetMailsUseCase: 25. Email validation (_isValidEmail)<br/>Type: bool, RegExp validation
    GetMailsUseCase->>GetMailsUseCase: 26. MaxResults validation (1-100)<br/>Type: int range validation
    GetMailsUseCase->>MailRepository: 27. _repository.getMails()<br/>Type: Future<Result<List<Mail>>>

    MailRepository->>RemoteDataSource: 28. _remoteDataSource.getMails()<br/>Type: Future<MailResponseModel>
    RemoteDataSource->>ApiEndpoints: 29. ApiEndpoints.buildGmailQueueUrl()<br/>Type: String URL

    ApiEndpoints->>ApiEndpoints: 30. URL params building<br/>Type: Map<String, dynamic>
    ApiEndpoints->>ApiEndpoints: 31. _buildQueryString() helper<br/>Type: String queryString
    ApiEndpoints-->>RemoteDataSource: 32. Complete URL döndürür<br/>Type: String URL

    RemoteDataSource->>ApiClient: 33. _apiClient.get(url)<br/>Type: Future<Response<T>>
    ApiClient->>ApiClient: 34. LogInterceptor.onRequest() - request logging<br/>Type: RequestOptions
    ApiClient->>Backend: 35. HTTP GET request gönder<br/>Type: HTTP Request

    Note over Backend: 🌍 BACKEND PROCESSING - BACKEND LAYER

    Backend->>Backend: 36. CORS middleware (middleware.ts)<br/>Type: NextResponse with CORS headers
    Backend->>Backend: 37. route.ts GET handler<br/>Type: NextRequest → NextResponse
    Backend->>Backend: 38. handleListOperation()<br/>Type: URLSearchParams processing
    Backend->>Backend: 39. Gmail API queue.enqueue()<br/>Type: Gmail API call
    Backend-->>ApiClient: 40. JSON response döner<br/>Type: { messages: MailModel[], nextPageToken?: string }

    Note over ApiClient,ShowcaseWidget: ⬅️ RESPONSE İŞLEME - DATA LAYER

    ApiClient->>ApiClient: 41. LogInterceptor.onResponse() - response logging<br/>Type: Response logging
    ApiClient-->>RemoteDataSource: 42. Response<Map<String, dynamic>><br/>Type: Response<Map<String, dynamic>>

    RemoteDataSource->>RemoteDataSource: 43. MailResponseModel.fromJson()<br/>Type: MailResponseModel instance
    RemoteDataSource->>RemoteDataSource: 44. MailModel.fromJson() for each message<br/>Type: List<MailModel>
    RemoteDataSource-->>MailRepository: 45. MailResponseModel return<br/>Type: MailResponseModel

    MailRepository->>MailRepository: 46. mailModel.toDomain() conversion<br/>Type: MailModel → Mail entity
    MailRepository->>MailRepository: 47. List<Mail> entities oluştur<br/>Type: List<Mail> domain entities
    MailRepository-->>GetMailsUseCase: 48. Success(List<Mail>)<br/>Type: Result<List<Mail>>

    GetMailsUseCase-->>MailProvider: 49. Result<List<Mail>><br/>Type: Result<List<Mail>>

    MailProvider->>MailProvider: 50. result.when() pattern matching<br/>Type: Result pattern matching
    MailProvider->>MailProvider: 51. _handleLoadSuccess() çağrılır<br/>Type: void method
    MailProvider->>MailProvider: 52. unreadCount calculation<br/>Type: int count
    MailProvider->>MailProvider: 53. state = MailState(mails: [...], isLoading: false)<br/>Type: MailState update

    Note over MailProvider: 🔄 STATE NOTIFICATION - PRESENTATION LAYER

    MailProvider-->>ShowcaseWidget: 54. StateNotifier triggers listeners<br/>Type: StateNotifier notification
    ShowcaseWidget->>ShowcaseWidget: 55. ref.watch(mailProvider) detects change<br/>Type: MailState change detection
    ShowcaseWidget->>ShowcaseWidget: 56. Consumer.build() method called<br/>Type: Widget build()
    ShowcaseWidget->>ShowcaseWidget: 57. UI rebuild başlar<br/>Type: Widget tree rebuild

    Note over ShowcaseWidget: 🎨 UI RENDERING - PRESENTATION LAYER

    ShowcaseWidget->>ShowcaseWidget: 58. AppBar title update (mail count)<br/>Type: String title update
    ShowcaseWidget->>ShowcaseWidget: 59. Loading spinner → Mail list switch<br/>Type: Widget conditional rendering
    ShowcaseWidget->>ShowcaseWidget: 60. ListView.separated builder<br/>Type: ListView.separated Widget
    ShowcaseWidget->>ShowcaseWidget: 61. MailItem widgets creation<br/>Type: List<MailItem> widgets
    ShowcaseWidget->>ShowcaseWidget: 62. Final UI render complete<br/>Type: Complete Widget tree

    Note over Main,Backend: ✅ UYGULAMA HAZıR - KULLANICI ETKİLEŞİMİ BEKLİYOR