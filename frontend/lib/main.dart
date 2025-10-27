import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'services/config_service.dart';
import 'services/api_service.dart';
import 'services/cache_service.dart';
import 'services/connectivity_service.dart';
import 'services/drive_service.dart';
import 'services/sync_manager.dart';
import 'services/pdf_viewer_manager.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize configuration
  final configService = ConfigService();
  await configService.initialize();

  // Initialize cache service
  final cacheService = CacheService();
  // Database is initialized automatically when accessed

  runApp(ScholarMateApp(cacheService: cacheService));
}

class ScholarMateApp extends StatelessWidget {
  final CacheService cacheService;

  const ScholarMateApp({super.key, required this.cacheService});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider.value(value: cacheService),
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
      ],
      child: MaterialApp(
        title: 'ScholarMate',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6366F1),
            secondary: const Color(0xFF8B5CF6),
          ),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(centerTitle: false, elevation: 0),
        ),
        home: const AppInitializer(),
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
          // Handle token storage when user signs in
          if (user != null && user.accessToken != null) {
            _storeTokensInBackend(user);
          }
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

  Future<void> _storeTokensInBackend(user) async {
    try {
      final apiService = ApiService();
      await apiService.storeTokens(
        userId: user.id,
        email: user.email,
        name: user.displayName,
        pictureUrl: user.photoUrl,
        accessToken: user.accessToken ?? '',
        idToken: user.idToken,
      );
    } catch (e) {
      debugPrint('Failed to store tokens in backend: $e');
      // Don't show error to user as this is a background operation
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
