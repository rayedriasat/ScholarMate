import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../widgets/ui/animated_background.dart';
import '../widgets/ui/glass_container.dart';
import '../widgets/ui/modern_button.dart';

/// Login screen with modern glassmorphism UI
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    if (kIsWeb) {
      debugPrint(
        'Warning: Direct signIn() called on web, should use signInButton()',
      );
      return;
    }

    setState(() {
      _errorMessage = null;
    });

    final authService = context.read<AuthService>();

    try {
      await authService.signInWithGoogle();
    } catch (e) {
      setState(() {
        final errorMessage = e.toString();
        if (errorMessage.contains('canceled') ||
            errorMessage.contains('cancelled')) {
          _errorMessage = 'Sign-in was canceled';
        } else if (errorMessage.contains('timed out') ||
            errorMessage.contains('browser settings')) {
          _errorMessage =
              'Please enable third-party sign-in in your browser settings';
        } else {
          _errorMessage = 'An unexpected error occurred. Please try again.';
        }
      });
    }
  }

  Widget _buildWebSignInButton(AuthService authService) {
    if (authService.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    final signInButton = authService.getWebSignInButton();

    if (signInButton == null) {
      return Container(
        width: double.infinity,
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'Web sign-in not available',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return SizedBox(width: double.infinity, height: 48, child: signInButton);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWideScreen = size.width >= 900;

    return Scaffold(
      body: AnimatedBackground(
        child: Center(
          child: isWideScreen
              ? _buildSplitLayout(context)
              : _buildSingleLayout(context),
        ),
      ),
    );
  }

  Widget _buildSingleLayout(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: GlassContainer(
            width: 400,
            padding: const EdgeInsets.all(32),
            blur: 20,
            opacity: 0.1,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildLogo(),
                const SizedBox(height: 32),
                _buildWelcomeText(),
                const SizedBox(height: 48),
                _buildLoginForm(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSplitLayout(BuildContext context) {
    return Row(
      children: [
        // Left Side - Branding
        Expanded(
          flex: 5,
          child: Container(
            padding: const EdgeInsets.all(64),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLogo(size: 80),
                const SizedBox(height: 32),
                const Text(
                  'ScholarMate',
                  style: TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Your AI-Powered Research Workspace',
                  style: TextStyle(
                    fontSize: 24,
                    color: Colors.white.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w300,
                  ),
                ),
                const SizedBox(height: 64),
                _buildFeaturesList(),
              ],
            ),
          ),
        ),

        // Right Side - Login Form
        Expanded(
          flex: 4,
          child: Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: GlassContainer(
                width: 450,
                margin: const EdgeInsets.all(48),
                padding: const EdgeInsets.all(48),
                blur: 30,
                opacity: 0.15,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Welcome Back',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sign in to continue your research',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 48),
                    _buildLoginForm(context),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogo({double size = 60}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(size * 0.25),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Icon(Icons.school, size: size * 0.5, color: Colors.white),
    );
  }

  Widget _buildWelcomeText() {
    return Column(
      children: [
        const Text(
          'ScholarMate',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Your AI Research Workspace',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm(BuildContext context) {
    final authService = context.watch<AuthService>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (kIsWeb)
          _buildWebSignInButton(authService)
        else
          ModernButton(
            label: 'Sign in with Google',
            icon: Icons.login, // Placeholder, ideally use SVG
            isLoading: authService.isLoading,
            onPressed: _handleSignIn,
            variant: ModernButtonVariant.primary,
          ),

        if (_errorMessage != null) ...[
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFeaturesList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFeatureItem(Icons.cloud_outlined, 'Cloud Storage & Sync'),
        const SizedBox(height: 24),
        _buildFeatureItem(Icons.psychology_outlined, 'AI Research Assistant'),
        const SizedBox(height: 24),
        _buildFeatureItem(Icons.auto_stories_outlined, 'Smart Notebooks'),
      ],
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.accent, size: 24),
        ),
        const SizedBox(width: 16),
        Text(
          text,
          style: const TextStyle(
            fontSize: 18,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
