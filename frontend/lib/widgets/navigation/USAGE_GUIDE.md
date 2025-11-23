# Adaptive Navigation System - Usage Guide

## Quick Start

The adaptive navigation system provides a modern, responsive navigation experience that automatically adapts to different screen sizes.

### Basic Implementation

```dart
import 'package:flutter/material.dart';
import 'widgets/navigation/adaptive_navigation.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: AdaptiveNavigation(
        destinations: [
          AppNavigationDestination(
            id: 'files',
            icon: Icons.folder_outlined,
            activeIcon: Icons.folder,
            label: 'Files',
            screen: FilesScreen(),
          ),
          AppNavigationDestination(
            id: 'ai',
            icon: Icons.psychology_outlined,
            activeIcon: Icons.psychology,
            label: 'AI Assistant',
            screen: AIScreen(),
          ),
        ],
        initialIndex: 0,
      ),
    );
  }
}
```

## Migration from Existing AppNavigation

If you're migrating from the existing `AppNavigation` widget:

### Step 1: Update Imports

```dart
// Before
import '../widgets/app_navigation.dart';

// After
import '../widgets/navigation/adaptive_navigation.dart';
```

### Step 2: Rename Classes

```dart
// Before
NavigationItem(...)

// After
AppNavigationDestination(...)
```

### Step 3: Update Widget Name

```dart
// Before
AppNavigation(
  items: _navigationItems,
  ...
)

// After
AdaptiveNavigation(
  destinations: _navigationDestinations,
  ...
)
```

## Complete Example with State Management

```dart
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  List<AppNavigationDestination> get _destinations {
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

  void _onDestinationSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // Add custom logic here
    debugPrint('Navigated to: ${_destinations[index].label}');
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveNavigation(
      destinations: _destinations,
      initialIndex: _selectedIndex,
      onDestinationSelected: _onDestinationSelected,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Add action
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

## Features

### Responsive Breakpoints

- **Mobile** (< 600px): Bottom navigation bar + drawer
- **Tablet** (600-1024px): Collapsed sidebar (icon-only)
- **Desktop** (> 1024px): Expanded sidebar (with labels at 1200px+)

### Desktop Sidebar

- Automatically expands/collapses based on screen width
- Hover tooltips in collapsed mode
- Smooth animations
- App logo at top
- Settings button at bottom

### Mobile Bottom Bar

- Icon + label tabs
- Smooth color transitions
- Touch-optimized (48dp minimum)
- Safe area support

### Mobile Drawer

- Slide-in animation from left
- User profile header with gradient
- Full navigation list
- Sign out button at bottom

## Customization

### Custom Accent Color

The navigation system automatically uses the theme's primary color for highlighting. To customize:

```dart
MaterialApp(
  theme: ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue, // Your accent color
    ),
  ),
  home: AdaptiveNavigation(...),
)
```

### Custom Floating Action Button

```dart
AdaptiveNavigation(
  destinations: _destinations,
  floatingActionButton: FloatingActionButton.extended(
    onPressed: () {},
    icon: const Icon(Icons.add),
    label: const Text('New'),
  ),
)
```

### Handling Navigation Events

```dart
AdaptiveNavigation(
  destinations: _destinations,
  onDestinationSelected: (index) {
    // Track analytics
    analytics.logEvent('navigation_changed', {'index': index});
    
    // Update state
    setState(() => _selectedIndex = index);
    
    // Custom logic
    if (index == 0) {
      // Refresh files list
      context.read<FileService>().refresh();
    }
  },
)
```

## Integration with Existing Screens

The navigation system works seamlessly with your existing screens. Each destination's `screen` property can be any Flutter widget:

```dart
AppNavigationDestination(
  id: 'files',
  icon: Icons.folder_outlined,
  activeIcon: Icons.folder,
  label: 'Files',
  screen: const FileExplorerScreen(), // Your existing screen
)
```

## Settings Integration

The navigation system includes a built-in settings button. To customize the settings screen, you can:

1. Use the placeholder (current implementation)
2. Replace with your custom settings screen

The settings button is automatically positioned:
- Desktop: Bottom of sidebar
- Mobile: Last item in bottom bar and drawer

## Accessibility

The navigation system includes:
- Semantic labels for screen readers
- Keyboard navigation support
- Touch targets meeting minimum size requirements
- High contrast support through theme
- Reduced motion support (via theme)

## Performance

The navigation system is optimized for performance:
- Minimal rebuilds using `const` constructors
- Efficient layout calculations
- Smooth 200ms animations
- Lazy loading of screens

## Testing

To test the navigation system:

```dart
testWidgets('Navigation switches screens', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: AdaptiveNavigation(
        destinations: [
          AppNavigationDestination(
            id: 'screen1',
            icon: Icons.home,
            label: 'Screen 1',
            screen: const Text('Screen 1'),
          ),
          AppNavigationDestination(
            id: 'screen2',
            icon: Icons.settings,
            label: 'Screen 2',
            screen: const Text('Screen 2'),
          ),
        ],
      ),
    ),
  );

  // Verify initial screen
  expect(find.text('Screen 1'), findsOneWidget);

  // Tap second navigation item
  await tester.tap(find.text('Screen 2'));
  await tester.pumpAndSettle();

  // Verify screen changed
  expect(find.text('Screen 2'), findsOneWidget);
});
```

## Troubleshooting

### Navigation not switching screens

Make sure you're using `onDestinationSelected` callback and updating state:

```dart
onDestinationSelected: (index) {
  setState(() {
    _selectedIndex = index;
  });
}
```

### Drawer not opening on mobile

The drawer is automatically included. To open it programmatically:

```dart
Scaffold.of(context).openDrawer();
```

Or add a menu button in your AppBar:

```dart
AppBar(
  leading: IconButton(
    icon: const Icon(Icons.menu),
    onPressed: () => Scaffold.of(context).openDrawer(),
  ),
)
```

### Accent color not showing

Ensure your theme has a primary color defined:

```dart
ThemeData(
  colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
)
```

## Requirements Satisfied

This implementation satisfies:
- **Requirement 4.1**: Desktop sidebar for >1024px
- **Requirement 4.2**: Collapsed sidebar for 600-1024px
- **Requirement 4.3**: Bottom navigation for <600px
- **Requirement 4.4**: Expandable sections support
- **Requirement 4.5**: Settings at bottom
- **Requirement 4.6**: Modern icons with transitions
- **Requirement 4.7**: Smooth slide-in drawer
- **Requirement 4.8**: Active route highlighting with accent color

## Next Steps

1. Replace existing `AppNavigation` with `AdaptiveNavigation`
2. Test on different screen sizes
3. Customize accent colors if needed
4. Add custom settings screen
5. Integrate with analytics
