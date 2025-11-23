# Integration Example - Replacing AppNavigation with AdaptiveNavigation

## Current Implementation (home_screen.dart)

The current `home_screen.dart` uses the old `AppNavigation` widget. Here's how to migrate to the new `AdaptiveNavigation` system.

## Step-by-Step Migration

### Step 1: Update Imports

Replace the old import:

```dart
// OLD - Remove this
import '../widgets/app_navigation.dart';

// NEW - Add this
import '../widgets/navigation/adaptive_navigation.dart';
```

### Step 2: Update Navigation Items

Change from `NavigationItem` to `AppNavigationDestination`:

```dart
// OLD
List<NavigationItem> get _navigationItems {
  return [
    NavigationItem(
      id: 'files',
      icon: Icons.folder_outlined,
      activeIcon: Icons.folder,
      label: 'Files',
      screen: const FileExplorerScreen(),
    ),
    // ... more items
  ];
}

// NEW
List<AppNavigationDestination> get _navigationDestinations {
  return [
    AppNavigationDestination(
      id: 'files',
      icon: Icons.folder_outlined,
      activeIcon: Icons.folder,
      label: 'Files',
      screen: const FileExplorerScreen(),
    ),
    // ... more items
  ];
}
```

### Step 3: Update Widget Usage

Replace `AppNavigation` with `AdaptiveNavigation`:

```dart
// OLD
return PopScope(
  canPop: false,
  onPopInvokedWithResult: (didPop, result) async {
    // ... back navigation logic
  },
  child: AppNavigation(
    items: _navigationItems,
    initialIndex: _selectedIndex,
    onIndexChanged: (index) {
      setState(() {
        _selectedIndex = index;
      });
    },
  ),
);

// NEW
return PopScope(
  canPop: false,
  onPopInvokedWithResult: (didPop, result) async {
    // ... back navigation logic
  },
  child: AdaptiveNavigation(
    destinations: _navigationDestinations,
    initialIndex: _selectedIndex,
    onDestinationSelected: (index) {
      setState(() {
        _selectedIndex = index;
      });
    },
  ),
);
```

## Complete Updated home_screen.dart

Here's the complete updated version:

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/indexing_service.dart';

import '../widgets/navigation/adaptive_navigation.dart';
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

  List<AppNavigationDestination> get _navigationDestinations {
    return [
      AppNavigationDestination(
        id: 'files',
        icon: Icons.folder_outlined,
        activeIcon: Icons.folder,
        label: 'Files',
        screen: const FileExplorerScreen(),
      ),
      AppNavigationDestination(
        id: 'ai',
        icon: Icons.psychology_outlined,
        activeIcon: Icons.psychology,
        label: 'AI Assistant',
        screen: const AIAssistantScreen(),
      ),
      AppNavigationDestination(
        id: 'notes',
        icon: Icons.note_outlined,
        activeIcon: Icons.note,
        label: 'Notes',
        screen: const NotesScreen(),
      ),
      AppNavigationDestination(
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
      child: AdaptiveNavigation(
        destinations: _navigationDestinations,
        initialIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}
```

## Key Changes Summary

1. **Import**: Changed from `app_navigation.dart` to `navigation/adaptive_navigation.dart`
2. **Class Name**: Changed from `NavigationItem` to `AppNavigationDestination`
3. **Property Name**: Changed from `items` to `destinations`
4. **Callback Name**: Changed from `onIndexChanged` to `onDestinationSelected`
5. **Getter Name**: Changed from `_navigationItems` to `_navigationDestinations`

## Benefits of Migration

### Responsive Design
- Automatic layout switching based on screen size
- Desktop sidebar (>1024px)
- Mobile bottom navigation (<1024px)
- Tablet collapsed sidebar (600-1024px)

### Modern UI
- Glassmorphism aesthetics
- Smooth animations (200ms)
- Accent color highlighting
- Material 3 design

### Better UX
- Expandable sidebar on large screens
- Mobile drawer for extended navigation
- Touch-optimized interactions
- Keyboard navigation support

### Accessibility
- Semantic labels for screen readers
- Proper touch target sizes
- High contrast support
- Reduced motion support

## Testing After Migration

1. **Desktop (>1024px)**:
   - Verify sidebar appears on the left
   - Check sidebar expands at 1200px+
   - Test hover tooltips in collapsed mode
   - Verify accent color highlighting

2. **Tablet (600-1024px)**:
   - Verify collapsed sidebar (icon-only)
   - Check hover tooltips work
   - Test navigation switching

3. **Mobile (<600px)**:
   - Verify bottom navigation bar
   - Test drawer slide-in animation
   - Check touch targets (48dp minimum)
   - Verify safe area support

4. **All Sizes**:
   - Test navigation switching
   - Verify active state highlighting
   - Check smooth animations
   - Test settings button

## Rollback Plan

If you need to rollback to the old navigation:

1. Revert the import change
2. Change `AppNavigationDestination` back to `NavigationItem`
3. Change `destinations` back to `items`
4. Change `onDestinationSelected` back to `onIndexChanged`
5. Rename getter back to `_navigationItems`

The old `AppNavigation` widget is still available in `widgets/app_navigation.dart`.

## Next Steps

After successful migration:

1. Test on all target platforms
2. Verify responsive behavior
3. Customize accent colors if needed
4. Add custom settings screen
5. Remove old `AppNavigation` widget (optional)
6. Update any documentation

## Support

If you encounter issues:

1. Check the USAGE_GUIDE.md for detailed instructions
2. Review the adaptive_navigation_demo.dart for examples
3. Verify all imports are correct
4. Check that design tokens are available
5. Ensure theme is properly configured
