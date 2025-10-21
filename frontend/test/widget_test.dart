// ScholarMate widget tests
//
// Tests for the ScholarMate authentication flow and UI components

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/screens/splash_screen.dart';
import 'package:frontend/services/config_service.dart';
import 'package:frontend/services/auth_service.dart';

void main() {
  group('ScholarMate UI Tests', () {
    testWidgets('Splash screen displays correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: SplashScreen()));

      // Verify splash screen elements
      expect(find.byIcon(Icons.school), findsOneWidget);
      expect(find.text('ScholarMate'), findsOneWidget);
      expect(find.text('Your AI Research Workspace'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('Splash screen has animated elements', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: SplashScreen()));

      // Initial state
      expect(find.byType(AnimatedBuilder), findsWidgets);

      // Pump animation frames
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      // Elements should still be visible after animation
      expect(find.text('ScholarMate'), findsOneWidget);
      expect(find.byIcon(Icons.school), findsOneWidget);
    });

    testWidgets('Splash screen has gradient background', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: SplashScreen()));

      // Verify gradient container exists
      final container = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(Scaffold),
              matching: find.byType(Container),
            )
            .first,
      );

      expect(container.decoration, isA<BoxDecoration>());
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.gradient, isA<LinearGradient>());
    });
  });

  group('Service Tests', () {
    test('ConfigService initializes correctly', () async {
      final configService = ConfigService();

      // Initialize should not throw
      await configService.initialize();

      // Should be marked as initialized
      expect(configService.isInitialized, isTrue);
    });

    test('ConfigService provides configuration values', () async {
      final configService = ConfigService();
      await configService.initialize();

      // Should have configuration methods
      expect(configService.googleClientId, isA<String>());
      expect(configService.apiBaseUrl, isA<String>());
      expect(configService.supabaseUrl, isA<String>());
    });

    test('AuthService can be created', () {
      final authService = AuthService();

      // Should start with no current user
      expect(authService.currentUser, isNull);
      expect(authService.isLoading, isFalse);
      expect(authService.isInitialized, isFalse);
    });

    test('AuthService has required methods', () {
      final authService = AuthService();

      // Verify methods exist
      expect(authService.signOut, isA<Function>());
      expect(authService.getAccessToken, isA<Function>());
      expect(authService.refreshToken, isA<Function>());
      expect(authService.supportsAuthenticate, isA<Function>());
    });
  });

  group('Theme Tests', () {
    testWidgets('App theme uses Material 3', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF6366F1),
              secondary: const Color(0xFF8B5CF6),
            ),
            useMaterial3: true,
          ),
          home: const Scaffold(body: Text('Test')),
        ),
      );

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      final theme = materialApp.theme!;

      // Verify Material 3 is enabled
      expect(theme.useMaterial3, isTrue);
    });

    testWidgets('App theme has correct seed color', (
      WidgetTester tester,
    ) async {
      const seedColor = Color(0xFF6366F1);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: seedColor),
            useMaterial3: true,
          ),
          home: const Scaffold(body: Text('Test')),
        ),
      );

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      final theme = materialApp.theme!;

      // Verify color scheme exists
      expect(theme.colorScheme, isNotNull);
      expect(theme.colorScheme.primary, isNotNull);
    });
  });

  group('Widget Structure Tests', () {
    testWidgets('Splash screen has proper widget hierarchy', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: SplashScreen()));

      // Verify widget hierarchy
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(Container), findsWidgets);
      expect(find.byType(Column), findsOneWidget);
      expect(find.byType(Icon), findsOneWidget);
      expect(find.byType(Text), findsNWidgets(2)); // App name and tagline
    });

    testWidgets('Splash screen logo has correct styling', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: SplashScreen()));

      // Find the logo container
      final logoContainer = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(Column),
              matching: find.byType(Container),
            )
            .first,
      );

      // Verify logo container properties
      expect(logoContainer.decoration, isA<BoxDecoration>());
      final decoration = logoContainer.decoration as BoxDecoration;
      expect(decoration.color, equals(Colors.white));
      expect(decoration.borderRadius, isNotNull);
      expect(decoration.boxShadow, isNotNull);
    });
  });
}
