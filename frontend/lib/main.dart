import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'services/config_service.dart';
import 'services/api_service.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize configuration
  final configService = ConfigService();
  await configService.initialize();

  runApp(const ScholarMateApp());
}

class ScholarMateApp extends StatelessWidget {
  const ScholarMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthService(),
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
