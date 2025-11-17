import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/indexing_service.dart';

import '../widgets/app_navigation.dart';
import 'file_explorer_screen.dart';
import 'ai_assistant_screen.dart';
import 'notes_screen.dart';
import 'notebook_studio_screen.dart';

/// Home screen shown after successful authentication
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime? _lastBackPressed;
  int _selectedIndex = 0;
  bool _indexingInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Initialize indexing service once
    if (!_indexingInitialized) {
      _indexingInitialized = true;
      _initializeIndexingService();
    }
  }

  Future<void> _initializeIndexingService() async {
    try {
      final indexingService = context.read<IndexingService>();
      await indexingService.refreshJobs();
    } catch (e) {
      debugPrint('Failed to initialize indexing service: $e');
    }
  }

  List<NavigationItem> get _navigationItems {
    return [
      NavigationItem(
        id: 'files',
        icon: Icons.folder_outlined,
        activeIcon: Icons.folder,
        label: 'Files',
        screen: const FileExplorerScreen(),
      ),
      NavigationItem(
        id: 'ai',
        icon: Icons.psychology_outlined,
        activeIcon: Icons.psychology,
        label: 'AI Assistant',
        screen: const AIAssistantScreen(),
      ),
      NavigationItem(
        id: 'notes',
        icon: Icons.note_outlined,
        activeIcon: Icons.note,
        label: 'Notes',
        screen: const NotesScreen(),
      ),
      NavigationItem(
        id: 'notebook',
        icon: Icons.auto_stories_outlined,
        activeIcon: Icons.auto_stories,
        label: 'Notebook Studio',
        screen: const NotebookStudioScreen(),
      ),
    ];
  }

  /// Handle back button press at app level
  Future<bool> _onWillPop() async {
    try {
      // If on Files tab, let FileExplorerScreen handle navigation
      if (_selectedIndex == 0) {
        final shouldExitFromExplorer =
            await FileExplorerNavigationHandler.handleBackNavigation();

        // If FileExplorerScreen says it's at root level, handle double-back-to-exit
        if (shouldExitFromExplorer) {
          final now = DateTime.now();
          if (_lastBackPressed == null ||
              now.difference(_lastBackPressed!) > const Duration(seconds: 2)) {
            _lastBackPressed = now;

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Press back again to exit ScholarMate'),
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                  margin: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              );
            }
            return false;
          }
          return true; // Allow exit on second back press
        }
        return false; // FileExplorerScreen handled the navigation
      } else {
        // On other tabs, go back to Files tab first
        setState(() {
          _selectedIndex = 0;
        });
        return false;
      }
    } catch (e) {
      // If there's any error, allow exit to prevent getting stuck
      debugPrint('Error in back navigation: $e');
      return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final user = authService.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          final shouldPop = await _onWillPop();
          if (shouldPop && mounted) {
            // Use SystemNavigator to exit the app properly
            SystemNavigator.pop();
          }
        }
      },
      child: AppNavigation(
        items: _navigationItems,
        initialIndex: _selectedIndex,
        onIndexChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        floatingActionButton: _selectedIndex == 0
            ? null // FileExplorerScreen has its own FAB
            : null,
      ),
    );
  }
}
