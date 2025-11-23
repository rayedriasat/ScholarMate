import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';
import 'glass/glass_card.dart';

/// Empty state component with glass container and helpful message
/// Displays when folders are empty or no search results found
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  /// Empty folder state
  factory EmptyState.emptyFolder({Widget? action}) {
    return EmptyState(
      icon: Icons.folder_open,
      title: 'No files yet',
      message: 'Upload files or create folders to get started',
      action: action,
    );
  }

  /// No search results state
  factory EmptyState.noSearchResults({Widget? action}) {
    return EmptyState(
      icon: Icons.search_off,
      title: 'No results found',
      message: 'Try adjusting your search or filters',
      action: action,
    );
  }

  /// Error state
  factory EmptyState.error({required String errorMessage, Widget? action}) {
    return EmptyState(
      icon: Icons.error_outline,
      title: 'Something went wrong',
      message: errorMessage,
      action: action,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSmallScreen =
        MediaQuery.of(context).size.width < DesignTokens.mobileBreakpoint;

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(
          isSmallScreen ? DesignTokens.space6 : DesignTokens.space8,
        ),
        child: AppGlassCard(
          padding: EdgeInsets.all(
            isSmallScreen ? DesignTokens.space6 : DesignTokens.space8,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Illustration circle with icon
                Container(
                  width: isSmallScreen ? 100 : 120,
                  height: isSmallScreen ? 100 : 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        theme.colorScheme.primaryContainer,
                        theme.colorScheme.secondaryContainer,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    size: isSmallScreen ? 50 : 60,
                    color: theme.colorScheme.primary,
                  ),
                ),
                SizedBox(
                  height: isSmallScreen
                      ? DesignTokens.space6
                      : DesignTokens.space8,
                ),

                // Title
                Text(
                  title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: DesignTokens.semiBold,
                    color: theme.colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: DesignTokens.space3),

                // Message
                Text(
                  message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),

                // Action button
                if (action != null) ...[
                  const SizedBox(height: DesignTokens.space6),
                  action!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
