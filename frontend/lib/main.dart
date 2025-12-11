import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'database/database.dart';
import 'services/auth_service.dart';
import 'services/config_service.dart';
import 'services/api_service.dart';
import 'services/cache_service.dart';
import 'services/connectivity_service.dart';
import 'services/drive_service.dart';
import 'services/sync_manager.dart';
import 'services/pdf_viewer_manager.dart';
import 'services/annotation_service.dart';
import 'services/ocr_service.dart';
import 'services/tag_service.dart';
import 'services/tts_service.dart';
import 'services/sharing_service.dart';
import 'services/permission_service.dart';
import 'services/indexing_service.dart';
import 'services/metadata_service.dart';
import 'services/simple_theme_service.dart';
import 'services/notebook_service.dart';
import 'services/collaboration_service.dart';
import 'services/realtime_service.dart';
import 'services/annotation_sync_service.dart';
import 'services/document_extraction_service.dart';
import 'services/file_chat_service.dart';
import 'services/subscription_service.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/advanced_search_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize configuration
  final configService = ConfigService();
  await configService.initialize();

  // Initialize Supabase
  await Supabase.initialize(
    url: configService.supabaseUrl,
    anonKey: configService.supabaseAnonKey,
  );

  // Initialize cache service
  final cacheService = CacheService();
  // Database is initialized automatically when accessed

  // Initialize theme service
  final themeService = SimpleThemeService();
  await themeService.initialize();

  runApp(
    ScholarMateApp(
      cacheService: cacheService,
      themeService: themeService,
      configService: configService,
    ),
  );
}

class ScholarMateApp extends StatelessWidget {
  final CacheService cacheService;
  final SimpleThemeService themeService;
  final ConfigService configService;

  const ScholarMateApp({
    super.key,
    required this.cacheService,
    required this.themeService,
    required this.configService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ConfigService>.value(value: configService),
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider.value(value: cacheService),
        ChangeNotifierProvider.value(value: themeService),
        Provider<AppDatabase>(create: (_) => cacheService.database),
        ChangeNotifierProvider(create: (_) => ConnectivityService()),
        ChangeNotifierProxyProvider2<
          AuthService,
          ConnectivityService,
          DriveService
        >(
          create: (context) => DriveService(
            authService: context.read<AuthService>(),
            cacheService: cacheService,
            connectivityService: context.read<ConnectivityService>(),
          ),
          update: (context, auth, connectivity, previous) =>
              previous ??
              DriveService(
                authService: auth,
                cacheService: cacheService,
                connectivityService: connectivity,
              ),
        ),
        ChangeNotifierProxyProvider3<
          CacheService,
          ConnectivityService,
          DriveService,
          SyncManager
        >(
          create: (context) {
            final syncManager = SyncManager(
              cacheService: cacheService,
              connectivityService: context.read<ConnectivityService>(),
              driveService: context.read<DriveService>(),
            );
            // Set sync manager reference in DriveService
            context.read<DriveService>().setSyncManager(syncManager);
            return syncManager;
          },
          update: (context, cache, connectivity, drive, previous) {
            if (previous != null) return previous;
            final syncManager = SyncManager(
              cacheService: cache,
              connectivityService: connectivity,
              driveService: drive,
            );
            drive.setSyncManager(syncManager);
            return syncManager;
          },
        ),
        ChangeNotifierProxyProvider3<
          CacheService,
          DriveService,
          ConnectivityService,
          PdfViewerManager
        >(
          create: (context) => PdfViewerManager(
            cacheService: cacheService,
            driveService: context.read<DriveService>(),
            connectivityService: context.read<ConnectivityService>(),
          ),
          update: (context, cache, drive, connectivity, previous) =>
              previous ??
              PdfViewerManager(
                cacheService: cache,
                driveService: drive,
                connectivityService: connectivity,
              ),
        ),
        ChangeNotifierProxyProvider<CacheService, AnnotationService>(
          create: (context) => AnnotationService(
            database: cacheService.database,
            cacheService: cacheService,
          ),
          update: (context, cache, previous) =>
              previous ??
              AnnotationService(database: cache.database, cacheService: cache),
        ),
        Provider<OCRService>(create: (context) => OCRService(configService)),
        ChangeNotifierProxyProvider3<
          ConfigService,
          AuthService,
          OCRService,
          DocumentExtractionService
        >(
          create: (context) => DocumentExtractionService(
            configService: configService,
            authService: context.read<AuthService>(),
            ocrService: context.read<OCRService>(),
          ),
          update: (context, config, auth, ocr, previous) =>
              previous ??
              DocumentExtractionService(
                configService: config,
                authService: auth,
                ocrService: ocr,
              ),
        ),
        ChangeNotifierProvider<TtsService>(create: (_) => TtsService()),
        ChangeNotifierProxyProvider2<
          CacheService,
          ConnectivityService,
          TagService
        >(
          create: (context) => TagService(
            database: cacheService.database,
            apiService: ApiService(),
            authService: context.read<AuthService>(),
            connectivityService: context.read<ConnectivityService>(),
          ),
          update: (context, cache, connectivity, previous) =>
              previous ??
              TagService(
                database: cache.database,
                apiService: ApiService(),
                authService: context.read<AuthService>(),
                connectivityService: connectivity,
              ),
        ),
        ChangeNotifierProxyProvider<AuthService, SharingService>(
          create: (context) =>
              SharingService(authService: context.read<AuthService>()),
          update: (context, auth, previous) =>
              previous ?? SharingService(authService: auth),
        ),
        ChangeNotifierProxyProvider2<
          AuthService,
          SharingService,
          PermissionService
        >(
          create: (context) => PermissionService(
            authService: context.read<AuthService>(),
            sharingService: context.read<SharingService>(),
          ),
          update: (context, auth, sharing, previous) =>
              previous ??
              PermissionService(authService: auth, sharingService: sharing),
        ),
        ChangeNotifierProxyProvider<AuthService, IndexingService>(
          create: (context) => IndexingService(
            apiService: ApiService(),
            authService: context.read<AuthService>(),
          ),
          update: (context, auth, previous) =>
              previous ??
              IndexingService(apiService: ApiService(), authService: auth),
        ),
        ProxyProvider<AuthService, MetadataService>(
          create: (context) => MetadataService(
            baseUrl: configService.apiBaseUrl,
            getToken: () => context.read<AuthService>().getAccessToken(),
            getUserId: () => context.read<AuthService>().currentUser?.id ?? '',
          ),
          update: (context, auth, previous) =>
              previous ??
              MetadataService(
                baseUrl: configService.apiBaseUrl,
                getToken: () => auth.getAccessToken(),
                getUserId: () => auth.currentUser?.id ?? '',
              ),
        ),
        ChangeNotifierProxyProvider2<
          CacheService,
          AuthService,
          NotebookService
        >(
          create: (context) => NotebookService(
            database: cacheService.database,
            apiService: ApiService(),
            authService: context.read<AuthService>(),
          ),
          update: (context, cache, auth, previous) =>
              previous ??
              NotebookService(
                database: cache.database,
                apiService: ApiService(),
                authService: auth,
              ),
        ),
        Provider<CollaborationService>(
          create: (context) =>
              CollaborationService(configService, Supabase.instance.client),
        ),
        // Realtime service for annotation sync
        Provider<RealtimeService>(
          create: (_) => RealtimeService(Supabase.instance.client),
          dispose: (_, service) => service.dispose(),
        ),
        // Annotation sync service with realtime support
        ChangeNotifierProxyProvider3<
          AppDatabase,
          AuthService,
          RealtimeService,
          AnnotationSyncService
        >(
          create: (context) => AnnotationSyncService(
            database: context.read<AppDatabase>(),
            authService: context.read<AuthService>(),
            baseUrl: configService.apiBaseUrl,
            realtimeService: context.read<RealtimeService>(),
          ),
          update: (context, database, auth, realtime, previous) =>
              previous ??
              AnnotationSyncService(
                database: database,
                authService: auth,
                baseUrl: configService.apiBaseUrl,
                realtimeService: realtime,
              ),
        ),
        // File chat service for PDF collaboration
        ChangeNotifierProxyProvider<AppDatabase, FileChatService>(
          create: (context) => FileChatService(
            database: context.read<AppDatabase>(),
            supabase: Supabase.instance.client,
          ),
          update: (context, database, previous) =>
              previous ??
              FileChatService(
                database: database,
                supabase: Supabase.instance.client,
              ),
        ),
        // Subscription service for payment and subscription management
        ChangeNotifierProvider<SubscriptionService>(
          create: (_) => SubscriptionService(),
        ),
      ],
      child: Consumer<SimpleThemeService>(
        builder: (context, themeService, child) {
          return MaterialApp(
            title: 'ScholarMate',
            debugShowCheckedModeBanner: false,
            theme: themeService.lightTheme,
            darkTheme: themeService.darkTheme,
            themeMode: themeService.themeMode,
            home: const AppInitializer(),
            routes: {'/search': (context) => const AdvancedSearchScreen()},
          );
        },
      ),
    );
  }
}

/// Widget that handles app initialization and authentication state
class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _isInitializing = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      final configService = ConfigService();
      final authService = context.read<AuthService>();

      // Check if configuration is valid
      if (!configService.isConfigured) {
        setState(() {
          _errorMessage =
              'App configuration is incomplete. Please check your .env file.';
          _isInitializing = false;
        });
        return;
      }

      // Initialize auth service
      // Note: serverClientId is not supported on web
      // On Android/iOS, serverClientId should be the Web OAuth client ID
      await authService.initialize(
        clientId: configService.googleClientId,
        serverClientId: kIsWeb ? null : configService.googleClientId,
      );

      // Listen to auth state changes
      authService.authStateChanges.listen((user) {
        if (mounted) {
          debugPrint('Auth state changed: ${user?.email ?? 'signed out'}');
        }
      });

      setState(() {
        _isInitializing = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to initialize app: $e';
        _isInitializing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const SplashScreen();
    }

    if (_errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Initialization Error',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isInitializing = true;
                      _errorMessage = null;
                    });
                    _initializeApp();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Show appropriate screen based on auth state
    return Consumer<AuthService>(
      builder: (context, authService, _) {
        if (authService.currentUser != null) {
          return const HomeScreen();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}
