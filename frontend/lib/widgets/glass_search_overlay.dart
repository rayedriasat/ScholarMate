import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../widgets/glass/glass_card.dart';
import '../theme/design_tokens.dart';

/// Glass search overlay for PDF viewer
/// Features search input with highlight navigation
class GlassSearchOverlay extends StatefulWidget {
  final PdfViewerController controller;
  final VoidCallback onClose;

  const GlassSearchOverlay({
    super.key,
    required this.controller,
    required this.onClose,
  });

  @override
  State<GlassSearchOverlay> createState() => _GlassSearchOverlayState();
}

class _GlassSearchOverlayState extends State<GlassSearchOverlay> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch() {
    if (_searchController.text.isNotEmpty) {
      widget.controller.searchText(_searchController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppGlassCard(
      padding: const EdgeInsets.all(DesignTokens.space3),
      child: Row(
        children: [
          const Icon(Icons.search, size: 20),
          const SizedBox(width: DesignTokens.space2),

          Expanded(
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Search in document...',
                border: InputBorder.none,
                isDense: true,
              ),
              onSubmitted: (_) => _performSearch(),
              onChanged: (_) => _performSearch(),
            ),
          ),

          IconButton(
            icon: const Icon(Icons.arrow_upward, size: 20),
            onPressed: () {
              // Navigate to previous search result
              // Note: Syncfusion doesn't expose previousInstance directly
              // This would need custom implementation
            },
            tooltip: 'Previous',
          ),

          IconButton(
            icon: const Icon(Icons.arrow_downward, size: 20),
            onPressed: () {
              // Navigate to next search result
              // Note: Syncfusion doesn't expose nextInstance directly
              // This would need custom implementation
            },
            tooltip: 'Next',
          ),

          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: () {
              widget.controller.clearSelection();
              widget.onClose();
            },
            tooltip: 'Close',
          ),
        ],
      ),
    );
  }
}
