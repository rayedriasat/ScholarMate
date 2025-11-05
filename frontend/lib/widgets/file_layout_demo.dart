import 'package:flutter/material.dart';
import '../screens/file_explorer_enhanced.dart';

/// Demo widget showing the enhanced file explorer with layout options
class FileLayoutDemo extends StatelessWidget {
  const FileLayoutDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('File Explorer Layouts'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: const FileExplorerEnhanced(),
    );
  }
}

/// Widget to demonstrate different layout options
class LayoutOptionsShowcase extends StatefulWidget {
  const LayoutOptionsShowcase({super.key});

  @override
  State<LayoutOptionsShowcase> createState() => _LayoutOptionsShowcaseState();
}

class _LayoutOptionsShowcaseState extends State<LayoutOptionsShowcase> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Layout Options'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'File Explorer Layout Options',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            const Text(
              'The enhanced file explorer now supports three different view layouts:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),

            _buildLayoutOption(
              'List View',
              'Traditional list layout with full file details, tags, and metadata',
              Icons.view_list,
              Colors.blue,
            ),

            _buildLayoutOption(
              'Grid View',
              'Compact grid layout perfect for browsing many files quickly',
              Icons.grid_view,
              Colors.green,
            ),

            _buildLayoutOption(
              'Compact View',
              'Dense list view showing essential information in minimal space',
              Icons.view_agenda,
              Colors.orange,
            ),

            const SizedBox(height: 24),

            const Text(
              'Features:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),

            _buildFeature('Search functionality with real-time filtering'),
            _buildFeature('Multiple sort options (name, date, size, type)'),
            _buildFeature('Multi-select with bulk operations'),
            _buildFeature(
              'Responsive grid (2 columns on mobile, 4 on desktop)',
            ),
            _buildFeature('Breadcrumb navigation for folders'),
            _buildFeature('Pull-to-refresh support'),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FileLayoutDemo(),
                    ),
                  );
                },
                child: const Text('Try Enhanced File Explorer'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLayoutOption(
    String title,
    String description,
    IconData icon,
    Color color,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeature(String feature) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(Icons.check_circle, size: 16, color: Colors.green[600]),
          const SizedBox(width: 8),
          Expanded(child: Text(feature, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}
