# Adaptive Navigation System

Modern, responsive navigation system that adapts to different screen sizes with glassmorphism aesthetics.

## Components

### AdaptiveNavigation

Main wrapper component that automatically switches between desktop sidebar and mobile bottom navigation based on screen size.

**Features:**
- Automatic layout switching at breakpoints
- Desktop sidebar (>1024px)
- Mobile bottom navigation (<1024px)
- Mobile drawer for extended navigation
- Smooth transitions between layouts
- Accent color highlighting for active routes

**Breakpoints:**
- Mobile: < 600px (single column, bottom nav)
- Tablet: 600-1024px (collapsed sidebar)
- Desktop: > 1024px (expanded sidebar at 1200px+)

### DesktopSidebar

Sidebar navigation for desktop and web platforms.

**Features:**
- Expandable/collapsible based on screen width
- Icon-only mode (72px width) for tablet
- Full mode with labels (240px width) for desktop
- Smooth animations on hover
- Accent color highlighting
- App logo at top
- Settings at bottom

### MobileBottomBar

Bottom navigation bar for mobile devices.

**Features:**
- Icon + label tabs
- Smooth color transitions
- Accent color for active tab
- Touch-optimized (48dp minimum)
- Safe area support

### MobileDrawer

Slide-in drawer for mobile navigation.

**Features:**
- Slide-in animation from left
- User profile header with gradient
- Full navigation list
- Settings option
- Sign out button at bottom
- Accent color highlighting

## Usage

### Basic Example

```dart
import 'package:flutter/material.dart';
import 'widgets/navigation/adaptive_navigation.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AdaptiveNavigation(
      destinations: [
        NavigationDestination(
          id: 'files',
          icon: Icons.folder_outlined,
          activeIcon: Icons.folder,
          label: 'Files',
          screen: FilesScreen(),
        ),
        NavigationDestination(
          id: 'ai',
          icon: Icons.psychology_outlined,
          activeIcon: Icons.psychology,
          label: 'AI Assistant',
          screen: AIScreen(),
        ),
        NavigationDestination(
          id: 'notes',
          icon: Icons.note_outlined,
          activeIcon: Icons.note,
          label: 'Notes',
          screen: NotesScreen(),
        ),
      ],
      initialIndex: 0,
      onDestinationSelected: (index) {
        print('Selected: $index');
      },
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: Icon(Icons.add),
      ),
    );
  }
}
```

### With Custom Handling

```dart
class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;

  void _onDestinationSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // Custom logic here
    print('Navigated to: $index');
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveNavigation(
      destinations: _buildDestinations(),
      initialIndex: _selectedIndex,
      onDestinationSelected: _onDestinationSelected,
    );
  }
}
```

## Navigation Destination Model

```dart
NavigationDestination(
  id: 'unique_id',           // Unique identifier
  icon: Icons.icon_outlined,  // Inactive icon
  activeIcon: Icons.icon,     // Active icon (optional)
  label: 'Label',             // Display label
  screen: YourScreen(),       // Screen widget
)
```

## Responsive Behavior

### Desktop (>1024px)
- Sidebar navigation on the left
- Expanded labels at 1200px+
- Icon-only mode at 1024-1200px
- Hover tooltips in icon-only mode
- 72px width (collapsed) or 240px width (expanded)

### Mobile (<1024px)
- Bottom navigation bar with 4-5 tabs
- Drawer accessible via menu button
- Full-width content area
- Touch-optimized interactions

## Styling

The navigation system uses:
- **Design Tokens** for consistent spacing and sizing
- **Theme colors** for dynamic theming
- **Accent color** for active state highlighting
- **Smooth animations** (200ms duration)
- **Material 3** design principles

## Accessibility

- Semantic labels on all interactive elements
- Keyboard navigation support
- Touch targets meet minimum size (48dp mobile, 32dp desktop)
- Screen reader compatible
- High contrast support through theme

## Integration with Existing App

To integrate with the existing `home_screen.dart`:

1. Replace `AppNavigation` with `AdaptiveNavigation`
2. Convert `NavigationItem` to `NavigationDestination`
3. Update imports

Example migration:

```dart
// Before
import '../widgets/app_navigation.dart';

AppNavigation(
  items: _navigationItems,
  // ...
)

// After
import '../widgets/navigation/adaptive_navigation.dart';

AdaptiveNavigation(
  destinations: _navigationDestinations,
  // ...
)
```

## Demo

Run the demo to see the navigation system in action:

```dart
import 'widgets/navigation/adaptive_navigation_demo.dart';

void main() {
  runApp(MaterialApp(
    home: AdaptiveNavigationDemo(),
  ));
}
```

## Requirements Validated

This implementation satisfies the following requirements:

- **4.1**: Desktop sidebar for screens >1024px
- **4.2**: Collapsed sidebar for 600-1024px
- **4.3**: Bottom navigation for <600px
- **4.4**: Expandable sections support
- **4.5**: User profile and settings at bottom
- **4.6**: Modern flat icons with transitions
- **4.7**: Smooth slide-in drawer animation
- **4.8**: Active route highlighting with accent color

## Design Properties

- **Property 11**: Platform-specific navigation (bottom bar on mobile, sidebar on desktop)
- Uses accent color from theme for highlighting
- Smooth 200ms animations
- Responsive breakpoints at 600px and 1024px
