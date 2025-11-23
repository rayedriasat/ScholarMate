import 'package:flutter/material.dart';
import 'adaptive_navigation.dart';

/// Demo screen showing how to use the AdaptiveNavigation widget
class AdaptiveNavigationDemo extends StatelessWidget {
  const AdaptiveNavigationDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return AdaptiveNavigation(
      destinations: [
        AppNavigationDestination(
          id: 'files',
          icon: Icons.folder_outlined,
          activeIcon: Icons.folder,
          label: 'Files',
          screen: _buildDemoScreen('Files', Icons.folder, Colors.blue),
        ),
        AppNavigationDestination(
          id: 'ai',
          icon: Icons.psychology_outlined,
          activeIcon: Icons.psychology,
          label: 'AI Assistant',
          screen: _buildDemoScreen(
            'AI Assistant',
            Icons.psychology,
            Colors.purple,
          ),
        ),
        AppNavigationDestination(
          id: 'notes',
          icon: Icons.note_outlined,
          activeIcon: Icons.note,
          label: 'Notes',
          screen: _buildDemoScreen('Notes', Icons.note, Colors.orange),
        ),
        AppNavigationDestination(
          id: 'notebook',
          icon: Icons.auto_stories_outlined,
          activeIcon: Icons.auto_stories,
          label: 'Notebook',
          screen: _buildDemoScreen(
            'Notebook',
            Icons.auto_stories,
            Colors.green,
          ),
        ),
      ],
      initialIndex: 0,
      onDestinationSelected: (index) {
        debugPrint('Selected destination: $index');
      },
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          debugPrint('FAB pressed');
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildDemoScreen(String title, IconData icon, Color color) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: color),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            const Text('This is a demo screen', style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
