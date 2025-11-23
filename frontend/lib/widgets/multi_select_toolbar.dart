import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';
import 'glass/glass_card.dart';

/// Multi-select toolbar with batch actions
/// Displays when files are selected, showing action buttons
class MultiSelectToolbar extends StatelessWidget {
  final int selectedCount;
  final VoidCallback onClearSelection;
  final VoidCallback onBulkTag;
  final VoidCallback onBulkDelete;

  const MultiSelectToolbar({
    super.key,
    required this.selectedCount,
    required this.onClearSelection,
    required this.onBulkTag,
    required this.onBulkDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppGlassCard(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.space4,
        vertical: DesignTokens.space3,
      ),
      borderRadius: BorderRadius.circular(DesignTokens.radiusLarge),
      child: Row(
        children: [
          // Close button
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: onClearSelection,
            tooltip: 'Clear selection',
            color: theme.colorScheme.onSurface,
          ),
          const SizedBox(width: DesignTokens.space2),

          // Selected count
          Text(
            '$selectedCount selected',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: DesignTokens.semiBold,
            ),
          ),
          const Spacer(),

          // Tag button
          IconButton(
            icon: const Icon(Icons.label),
            onPressed: onBulkTag,
            tooltip: 'Tag selected files',
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: DesignTokens.space2),

          // Delete button
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: onBulkDelete,
            tooltip: 'Delete selected',
            color: theme.colorScheme.error,
          ),
        ],
      ),
    );
  }
}
