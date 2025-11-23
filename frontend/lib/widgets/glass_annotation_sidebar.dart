import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../widgets/glass/glass_card.dart';
import '../theme/design_tokens.dart';

/// Glass annotation sidebar for PDF viewer
/// Features annotation tools and collapsible annotation list with author avatars
class GlassAnnotationSidebar extends StatelessWidget {
  final PdfViewerController controller;
  final List<Annotation> annotations;
  final VoidCallback onClose;
  final Function(Annotation) onAnnotationTap;
  final Function(Annotation) onAnnotationDelete;

  const GlassAnnotationSidebar({
    super.key,
    required this.controller,
    required this.annotations,
    required this.onClose,
    required this.onAnnotationTap,
    required this.onAnnotationDelete,
  });

  @override
  Widget build(BuildContext context) {
    return AppGlassCard(
      padding: const EdgeInsets.all(DesignTokens.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Text(
                'Annotations',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: onClose,
              ),
            ],
          ),

          const SizedBox(height: DesignTokens.space4),

          // Annotation tools
          Wrap(
            spacing: DesignTokens.space2,
            runSpacing: DesignTokens.space2,
            children: [
              _buildAnnotationToolButton(
                context,
                icon: Icons.highlight,
                label: 'Highlight',
                onPressed: () {
                  controller.annotationMode = PdfAnnotationMode.highlight;
                },
              ),
              _buildAnnotationToolButton(
                context,
                icon: Icons.format_underlined,
                label: 'Underline',
                onPressed: () {
                  controller.annotationMode = PdfAnnotationMode.underline;
                },
              ),
              _buildAnnotationToolButton(
                context,
                icon: Icons.format_strikethrough,
                label: 'Strike',
                onPressed: () {
                  controller.annotationMode = PdfAnnotationMode.strikethrough;
                },
              ),
              _buildAnnotationToolButton(
                context,
                icon: Icons.waves,
                label: 'Squiggly',
                onPressed: () {
                  controller.annotationMode = PdfAnnotationMode.squiggly;
                },
              ),
            ],
          ),

          const SizedBox(height: DesignTokens.space4),
          const Divider(),
          const SizedBox(height: DesignTokens.space4),

          // Annotation list
          Expanded(
            child: annotations.isEmpty
                ? const Center(
                    child: Text(
                      'No annotations yet',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: annotations.length,
                    itemBuilder: (context, index) {
                      final annotation = annotations[index];
                      return _buildAnnotationListItem(context, annotation);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnotationToolButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.space2,
          vertical: DesignTokens.space1,
        ),
      ),
    );
  }

  Widget _buildAnnotationListItem(BuildContext context, Annotation annotation) {
    return Container(
      margin: const EdgeInsets.only(bottom: DesignTokens.space2),
      child: AppGlassCard(
        padding: const EdgeInsets.all(DesignTokens.space3),
        onTap: () => onAnnotationTap(annotation),
        child: Row(
          children: [
            // Author avatar
            CircleAvatar(
              radius: 16,
              backgroundColor: annotation.color.withValues(alpha: 0.3),
              child: Text(
                annotation.author?.substring(0, 1).toUpperCase() ?? 'A',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: annotation.color,
                ),
              ),
            ),

            const SizedBox(width: DesignTokens.space2),

            // Annotation info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    annotation.author ?? 'Unknown',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Page ${annotation.pageNumber}',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),

            // Delete button
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 16),
              onPressed: () => onAnnotationDelete(annotation),
            ),
          ],
        ),
      ),
    );
  }
}
