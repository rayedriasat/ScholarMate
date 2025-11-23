import 'package:flutter/material.dart';
import '../widgets/glass/glass_card.dart';
import '../theme/design_tokens.dart';

/// Modern page navigation slider with glass styling
/// Features page input, slider, and navigation buttons
class ModernPageNavigation extends StatefulWidget {
  final int currentPage;
  final int totalPages;
  final Function(int) onPageChanged;

  const ModernPageNavigation({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
  });

  @override
  State<ModernPageNavigation> createState() => _ModernPageNavigationState();
}

class _ModernPageNavigationState extends State<ModernPageNavigation> {
  late TextEditingController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = TextEditingController(
      text: widget.currentPage.toString(),
    );
  }

  @override
  void didUpdateWidget(ModernPageNavigation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentPage != oldWidget.currentPage) {
      _pageController.text = widget.currentPage.toString();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.totalPages == 0) return const SizedBox.shrink();

    return AppGlassCard(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.space4,
        vertical: DesignTokens.space3,
      ),
      child: Row(
        children: [
          // Previous page button
          IconButton(
            icon: const Icon(Icons.chevron_left, size: 24),
            onPressed: widget.currentPage > 1
                ? () => widget.onPageChanged(widget.currentPage - 1)
                : null,
            tooltip: 'Previous page',
          ),

          const SizedBox(width: DesignTokens.space2),

          // Page input
          SizedBox(
            width: 60,
            child: TextField(
              controller: _pageController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.space2,
                  vertical: DesignTokens.space2,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
                ),
              ),
              onSubmitted: (value) {
                final page = int.tryParse(value);
                if (page != null && page >= 1 && page <= widget.totalPages) {
                  widget.onPageChanged(page);
                } else {
                  _pageController.text = widget.currentPage.toString();
                }
              },
            ),
          ),

          const SizedBox(width: DesignTokens.space2),

          Text('of ${widget.totalPages}', style: const TextStyle(fontSize: 14)),

          const SizedBox(width: DesignTokens.space2),

          // Page slider
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 2,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                activeTrackColor: Theme.of(context).primaryColor,
                inactiveTrackColor: Theme.of(
                  context,
                ).primaryColor.withValues(alpha: 0.3),
                thumbColor: Theme.of(context).primaryColor,
              ),
              child: Slider(
                value: widget.currentPage.toDouble(),
                min: 1,
                max: widget.totalPages.toDouble(),
                divisions: widget.totalPages > 1 ? widget.totalPages - 1 : 1,
                onChanged: (value) {
                  widget.onPageChanged(value.toInt());
                },
              ),
            ),
          ),

          const SizedBox(width: DesignTokens.space2),

          // Next page button
          IconButton(
            icon: const Icon(Icons.chevron_right, size: 24),
            onPressed: widget.currentPage < widget.totalPages
                ? () => widget.onPageChanged(widget.currentPage + 1)
                : null,
            tooltip: 'Next page',
          ),
        ],
      ),
    );
  }
}
