import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_colors.dart';
import '../ui/glass_container.dart';
import '../ui/modern_button.dart';

/// Comprehensive landing page sections for ScholarMate
class LandingSections extends StatelessWidget {
  final bool isWeb;
  final VoidCallback? onGetStarted;
  final ScrollController? scrollController;

  const LandingSections({
    super.key,
    this.isWeb = true,
    this.onGetStarted,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildWhyUsSection(context),
        const SizedBox(height: 80),
        _buildFeaturesSection(context),
        const SizedBox(height: 80),
        _buildBuiltBySection(context),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildWhyUsSection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isWeb ? 64 : 24,
        vertical: isWeb ? 80 : 40,
      ),
      child: Column(
        children: [
          Text(
            'Why Choose ScholarMate?',
            style: TextStyle(
              fontSize: isWeb ? 48 : 32,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'The only research workspace you\'ll ever need',
            style: TextStyle(
              fontSize: isWeb ? 20 : 16,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 60),
          isWeb ? _buildWhyUsGridWeb(context) : _buildWhyUsListMobile(context),
        ],
      ),
    );
  }

  Widget _buildWhyUsGridWeb(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildWhyUsCard(
            context,
            Icons.cloud_off_outlined,
            'Offline-First',
            'Work anywhere, anytime. Full functionality without internet connection.',
            AppColors.primary,
          ),
        ),
        const SizedBox(width: 32),
        Expanded(
          child: _buildWhyUsCard(
            context,
            Icons.security_outlined,
            'Your Data, Your Control',
            'All files stored in your Google Drive. Complete privacy and ownership.',
            Colors.green,
          ),
        ),
        const SizedBox(width: 32),
        Expanded(
          child: _buildWhyUsCard(
            context,
            Icons.money_off_outlined,
            '100% Free',
            'No subscriptions, no hidden costs. Free tier only, forever.',
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildWhyUsListMobile(BuildContext context) {
    return Column(
      children: [
        _buildWhyUsCard(
          context,
          Icons.cloud_off_outlined,
          'Offline-First',
          'Work anywhere, anytime. Full functionality without internet connection.',
          AppColors.primary,
        ),
        const SizedBox(height: 24),
        _buildWhyUsCard(
          context,
          Icons.security_outlined,
          'Your Data, Your Control',
          'All files stored in your Google Drive. Complete privacy and ownership.',
          Colors.green,
        ),
        const SizedBox(height: 24),
        _buildWhyUsCard(
          context,
          Icons.money_off_outlined,
          '100% Free',
          'No subscriptions, no hidden costs. Free tier only, forever.',
          Colors.orange,
        ),
      ],
    );
  }

  Widget _buildWhyUsCard(
    BuildContext context,
    IconData icon,
    String title,
    String description,
    Color color,
  ) {
    return GlassContainer(
      padding: EdgeInsets.all(isWeb ? 32 : 24),
      blur: 20,
      opacity: 0.1,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, size: isWeb ? 48 : 40, color: color),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: TextStyle(
              fontSize: isWeb ? 24 : 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: TextStyle(
              fontSize: isWeb ? 16 : 14,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.7),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesSection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isWeb ? 64 : 24,
        vertical: isWeb ? 80 : 40,
      ),
      child: Column(
        children: [
          Text(
            'Powerful Features',
            style: TextStyle(
              fontSize: isWeb ? 48 : 32,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Everything you need for academic research and note-taking',
            style: TextStyle(
              fontSize: isWeb ? 20 : 16,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 60),
          isWeb
              ? _buildFeaturesGridWeb(context)
              : _buildFeaturesListMobile(context),
        ],
      ),
    );
  }

  Widget _buildFeaturesGridWeb(BuildContext context) {
    return Column(
      children: [
        // First row
        Row(
          children: [
            Expanded(
              child: _buildFeatureCard(
                context,
                Icons.picture_as_pdf_outlined,
                'Advanced PDF Viewer',
                'Annotate, highlight, and interact with PDFs like never before.',
                AppColors.primary,
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: _buildFeatureCard(
                context,
                Icons.chat_outlined,
                'Chat with Files & Folders',
                'AI-powered conversations with your documents and entire folders.',
                Colors.blue,
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: _buildFeatureCard(
                context,
                Icons.auto_stories_outlined,
                'Notebook Studio',
                'Create, organize, and manage your research notebooks effortlessly.',
                Colors.purple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        // Second row
        Row(
          children: [
            Expanded(
              child: _buildFeatureCard(
                context,
                Icons.format_quote_outlined,
                'Citation Generation',
                'Automatic citation generation in multiple academic formats.',
                Colors.green,
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: _buildFeatureCard(
                context,
                Icons.edit_note_outlined,
                'Markdown & Drawing Notes',
                'Rich text editing with markdown support and drawing capabilities.',
                Colors.orange,
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: _buildFeatureCard(
                context,
                Icons.search_outlined,
                'Smart Search',
                'Semantic search across all your documents with AI-powered insights.',
                Colors.teal,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        // Third row
        Row(
          children: [
            Expanded(
              child: _buildFeatureCard(
                context,
                Icons.scanner_outlined,
                'OCR & Text Extraction',
                'Extract text from images and scanned documents with high accuracy.',
                Colors.indigo,
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: _buildFeatureCard(
                context,
                Icons.share_outlined,
                'Seamless File Sharing',
                'Share documents and folders with flexible permissions and public links.',
                Colors.pink,
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: _buildFeatureCard(
                context,
                Icons.sync_outlined,
                'Cross-Platform Sync',
                'Seamless synchronization across all your devices and platforms.',
                Colors.cyan,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFeaturesListMobile(BuildContext context) {
    final features = [
      (
        Icons.picture_as_pdf_outlined,
        'Advanced PDF Viewer',
        'Annotate, highlight, and interact with PDFs like never before.',
        AppColors.primary,
      ),
      (
        Icons.chat_outlined,
        'Chat with Files & Folders',
        'AI-powered conversations with your documents and entire folders.',
        Colors.blue,
      ),
      (
        Icons.auto_stories_outlined,
        'Notebook Studio',
        'Create, organize, and manage your research notebooks effortlessly.',
        Colors.purple,
      ),
      (
        Icons.format_quote_outlined,
        'Citation Generation',
        'Automatic citation generation in multiple academic formats.',
        Colors.green,
      ),
      (
        Icons.edit_note_outlined,
        'Markdown & Drawing Notes',
        'Rich text editing with markdown support and drawing capabilities.',
        Colors.orange,
      ),
      (
        Icons.search_outlined,
        'Smart Search',
        'Semantic search across all your documents with AI-powered insights.',
        Colors.teal,
      ),
      (
        Icons.scanner_outlined,
        'OCR & Text Extraction',
        'Extract text from images and scanned documents with high accuracy.',
        Colors.indigo,
      ),
      (
        Icons.share_outlined,
        'Seamless File Sharing',
        'Share documents and folders with flexible permissions and public links.',
        Colors.pink,
      ),
      (
        Icons.sync_outlined,
        'Cross-Platform Sync',
        'Seamless synchronization across all your devices and platforms.',
        Colors.cyan,
      ),
    ];

    return Column(
      children: features
          .map(
            (feature) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildFeatureCard(
                context,
                feature.$1,
                feature.$2,
                feature.$3,
                feature.$4,
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context,
    IconData icon,
    String title,
    String description,
    Color color,
  ) {
    return GlassContainer(
      padding: EdgeInsets.all(isWeb ? 24 : 20),
      blur: 15,
      opacity: 0.08,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: isWeb ? 32 : 28, color: color),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: isWeb ? 18 : 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              fontSize: isWeb ? 14 : 13,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.7),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBuiltBySection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isWeb ? 64 : 24,
        vertical: isWeb ? 60 : 40,
      ),
      child: Column(
        children: [
          Text(
            'Built By',
            style: TextStyle(
              fontSize: isWeb ? 36 : 28,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'A passionate team dedicated to revolutionizing research workflows',
            style: TextStyle(
              fontSize: isWeb ? 18 : 14,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          isWeb ? _buildTeamGridWeb(context) : _buildTeamListMobile(context),
          const SizedBox(height: 48),
          if (onGetStarted != null) ...[
            ModernButton(
              label: 'Get Started Today',
              icon: Icons.rocket_launch_outlined,
              onPressed: () {
                if (scrollController != null) {
                  scrollController!.animateTo(
                    0,
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeInOut,
                  );
                } else if (onGetStarted != null) {
                  onGetStarted!();
                }
              },
              variant: ModernButtonVariant.primary,
              size: isWeb ? ModernButtonSize.large : ModernButtonSize.medium,
            ),
            const SizedBox(height: 16),
            Text(
              'Join thousands of researchers already using ScholarMate',
              style: TextStyle(
                fontSize: isWeb ? 14 : 12,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTeamGridWeb(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildTeamMember(
          context,
          'Barshon Basak',
          'https://github.com/barshon-basak/',
          'https://www.linkedin.com/in/barshon-basak/',
          Icons.psychology_outlined,
          imagePath: 'assets/images/team/Barshon Basak.png',
        ),
        const SizedBox(width: 48),
        _buildTeamMember(
          context,
          'Rayed Riasat Rabbi',
          'https://github.com/rayedriasat',
          'https://www.linkedin.com/in/rayed-riasat-rabbi/',
          Icons.code_outlined,
          imagePath: 'assets/images/team/Rayed Riasat Rabbi.jpg',
        ),
        const SizedBox(width: 48),
        _buildTeamMember(
          context,
          'Jawadul Karim Tanzim',
          'https://github.com/tanzim12911',
          'https://www.linkedin.com/in/jktanzim/',
          Icons.design_services_outlined,
          imagePath: 'assets/images/team/Jawadul Karim Tanzim.jpeg',
        ),
      ],
    );
  }

  Widget _buildTeamListMobile(BuildContext context) {
    return Column(
      children: [
        _buildTeamMember(
          context,
          'Barshon Basak',
          'https://github.com/barshon-basak/',
          'https://www.linkedin.com/in/barshon-basak/',
          Icons.psychology_outlined,
          imagePath: 'assets/images/team/Barshon Basak.png',
        ),
        const SizedBox(height: 32),
        _buildTeamMember(
          context,
          'Rayed Riasat Rabbi',
          'https://github.com/rayedriasat',
          'https://www.linkedin.com/in/rayed-riasat-rabbi/',
          Icons.code_outlined,
          imagePath: 'assets/images/team/Rayed Riasat Rabbi.jpg',
        ),
        const SizedBox(height: 32),
        _buildTeamMember(
          context,
          'Jawadul Karim Tanzim',
          'https://github.com/tanzim12911',
          'https://www.linkedin.com/in/jktanzim/',
          Icons.design_services_outlined,
          imagePath: 'assets/images/team/Jawadul Karim Tanzim.jpeg',
        ),
      ],
    );
  }

  Widget _buildTeamMember(
    BuildContext context,
    String name,
    String githubUrl,
    String linkedinUrl,
    IconData icon, {
    String? imagePath,
  }) {
    return GlassContainer(
      width: isWeb ? 280 : double.infinity,
      padding: EdgeInsets.all(isWeb ? 24 : 20),
      blur: 20,
      opacity: 0.1,
      child: Column(
        children: [
          // Profile Image
          Container(
            width: isWeb ? 80 : 70,
            height: isWeb ? 80 : 70,
            decoration: BoxDecoration(
              gradient: imagePath == null ? AppColors.primaryGradient : null,
              borderRadius: BorderRadius.circular(isWeb ? 40 : 35),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: imagePath != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(isWeb ? 40 : 35),
                    child: Image.asset(
                      imagePath,
                      width: isWeb ? 80 : 70,
                      height: isWeb ? 80 : 70,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        // Debug logging for image loading issues
                        debugPrint('❌ Failed to load team image: $imagePath');
                        debugPrint('Error details: $error');
                        // Fallback to icon if image fails to load
                        return Container(
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(
                              isWeb ? 40 : 35,
                            ),
                          ),
                          child: Icon(
                            icon,
                            size: isWeb ? 40 : 35,
                            color: Colors.white,
                          ),
                        );
                      },
                    ),
                  )
                : Icon(icon, size: isWeb ? 40 : 35, color: Colors.white),
          ),
          const SizedBox(height: 16),

          // Name
          Text(
            name,
            style: TextStyle(
              fontSize: isWeb ? 20 : 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Social Links
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // GitHub Link
              InkWell(
                onTap: () => _launchUrl(githubUrl),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.code,
                    size: isWeb ? 24 : 20,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // LinkedIn Link
              InkWell(
                onTap: () => _launchUrl(linkedinUrl),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.business,
                    size: isWeb ? 24 : 20,
                    color: Colors.blue,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String urlString) async {
    try {
      final Uri url = Uri.parse(urlString);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        debugPrint('Could not launch $urlString');
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
    }
  }
}
