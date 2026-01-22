import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../widgets/ui/animated_background.dart';
import '../widgets/ui/glass_container.dart';
import '../widgets/ui/modern_button.dart';
import '../widgets/landing/landing_sections.dart';

/// Dedicated landing page for mobile/Android with comprehensive sections
class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  final ScrollController _scrollController = ScrollController();
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
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
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
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

  void _scrollToSignUp() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBackground(
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Column(
            children: [
              // Hero section with sign up
              _buildHeroSection(context),
              // Landing sections
              LandingSections(
                isWeb: false,
                onGetStarted: _scrollToSignUp,
                scrollController: _scrollController,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                children: [
                  _buildLogo(),
                  const SizedBox(height: 32),
                  _buildWelcomeText(),
                  const SizedBox(height: 48),
                  _buildQuickFeatures(),
                  const SizedBox(height: 48),
                  _buildSignUpSection(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Icon(Icons.school, size: 40, color: Colors.white),
    );
  }

  Widget _buildWelcomeText() {
    return Column(
      children: [
        Text(
          'ScholarMate',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'Your AI-Powered Research Workspace',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.7),
            fontWeight: FontWeight.w300,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Offline-first • Privacy-focused • Completely Free',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickFeatures() {
    return Column(
      children: [
        _buildQuickFeatureItem(
          Icons.cloud_off_outlined,
          'Work Offline Anywhere',
        ),
        const SizedBox(height: 16),
        _buildQuickFeatureItem(
          Icons.psychology_outlined,
          'AI Research Assistant',
        ),
        const SizedBox(height: 16),
        _buildQuickFeatureItem(
          Icons.security_outlined,
          'Your Data, Your Control',
        ),
      ],
    );
  }

  Widget _buildQuickFeatureItem(IconData icon, String text) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: TextStyle(
            fontSize: 16,
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSignUpSection(BuildContext context) {
    final authService = context.watch<AuthService>();

    return GlassContainer(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      blur: 20,
      opacity: 0.1,
      child: Column(
        children: [
          Text(
            'Get Started',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sign in with Google to start your research journey',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 32),
          ModernButton(
            label: 'Sign in with Google',
            icon: Icons.login,
            isLoading: authService.isLoading,
            onPressed: _handleSignIn,
            variant: ModernButtonVariant.primary,
            size: ModernButtonSize.large,
            width: double.infinity,
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
          const SizedBox(height: 24),
          Text(
            'By signing in, you agree to store your files in your Google Drive',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}
