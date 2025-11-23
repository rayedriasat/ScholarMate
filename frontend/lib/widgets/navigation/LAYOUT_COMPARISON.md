# Adaptive Navigation - Layout Comparison

## Visual Layout Guide

### Desktop Layout (> 1024px)

```
┌─────────────────────────────────────────────────────────┐
│  ┌──────┐                                                │
│  │ Logo │  ← App logo (gradient, clickable)             │
│  └──────┘                                                │
│                                                           │
│  ┌──────┐                                                │
│  │ 📁  │  ← Files (active, highlighted)                 │
│  └──────┘                                                │
│                                                           │
│  ┌──────┐                                                │
│  │ 🧠  │  ← AI Assistant                                │
│  └──────┘                                                │
│                                                           │
│  ┌──────┐                                                │
│  │ 📝  │  ← Notes                                        │
│  └──────┘                                                │
│                                                           │
│  ┌──────┐                                                │
│  │ 📚  │  ← Notebook                                     │
│  └──────┘                                                │
│                                                           │
│     ⋮                                                     │
│                                                           │
│  ┌──────┐                                                │
│  │ ⚙️  │  ← Settings (at bottom)                        │
│  └──────┘                                                │
└─────────────────────────────────────────────────────────┘
     72px width (collapsed)
```

### Desktop Expanded Layout (> 1200px)

```
┌──────────────────────────────────────────────────────────┐
│  ┌────────────────────────┐                              │
│  │  🎓  ScholarMate       │  ← App logo with text        │
│  └────────────────────────┘                              │
│                                                           │
│  ┌────────────────────────┐                              │
│  │  📁  Files             │  ← Active (highlighted)      │
│  └────────────────────────┘                              │
│                                                           │
│  ┌────────────────────────┐                              │
│  │  🧠  AI Assistant      │                              │
│  └────────────────────────┘                              │
│                                                           │
│  ┌────────────────────────┐                              │
│  │  📝  Notes             │                              │
│  └────────────────────────┘                              │
│                                                           │
│  ┌────────────────────────┐                              │
│  │  📚  Notebook Studio   │                              │
│  └────────────────────────┘                              │
│                                                           │
│           ⋮                                               │
│                                                           │
│  ┌────────────────────────┐                              │
│  │  ⚙️  Settings          │  ← At bottom                │
│  └────────────────────────┘                              │
└──────────────────────────────────────────────────────────┘
          240px width (expanded)
```

### Mobile Layout (< 600px)

```
┌─────────────────────────────────────────────────────────┐
│                                                           │
│                   Main Content Area                       │
│                                                           │
│                                                           │
│                                                           │
│                                                           │
│                                                           │
│                                                           │
│                                                           │
│                                                           │
└─────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────┐
│  📁      🧠      📝      📚      ⚙️                      │
│ Files    AI    Notes  Notebook Settings                  │
└─────────────────────────────────────────────────────────┘
              Bottom Navigation Bar
```

### Mobile Drawer (< 600px)

```
┌──────────────────────────┐
│ ┌──────────────────────┐ │
│ │  🎓  ScholarMate     │ │  ← Gradient header
│ │                      │ │
│ │  👤  John Doe        │ │  ← User info
│ │  john@example.com    │ │
│ └──────────────────────┘ │
│                          │
│  📁  Files               │  ← Active (highlighted)
│                          │
│  🧠  AI Assistant        │
│                          │
│  📝  Notes               │
│                          │
│  📚  Notebook Studio     │
│                          │
│  ─────────────────────   │
│                          │
│  ⚙️  Settings            │
│                          │
│         ⋮                │
│                          │
│  ─────────────────────   │
│  🚪  Sign Out            │  ← At bottom
└──────────────────────────┘
```

## Responsive Breakpoints

### Mobile (< 600px)
- **Navigation**: Bottom bar (5 items max)
- **Drawer**: Slide-in from left
- **Touch Targets**: 48dp minimum
- **Layout**: Single column, full width

### Tablet (600-1024px)
- **Navigation**: Collapsed sidebar (icon-only)
- **Width**: 72px
- **Tooltips**: Shown on hover
- **Layout**: Optimized for medium screens

### Desktop (1024-1200px)
- **Navigation**: Collapsed sidebar (icon-only)
- **Width**: 72px
- **Tooltips**: Shown on hover
- **Layout**: Multi-column supported

### Desktop Large (> 1200px)
- **Navigation**: Expanded sidebar (with labels)
- **Width**: 240px
- **Tooltips**: Not needed (labels visible)
- **Layout**: Full multi-column layouts

## Component Behavior

### Desktop Sidebar

**Collapsed Mode (72px)**:
- Icon-only display
- Hover tooltips for labels
- Compact spacing
- Accent color highlight for active

**Expanded Mode (240px)**:
- Icon + label display
- No tooltips needed
- Comfortable spacing
- Accent color highlight for active

### Mobile Bottom Bar

**Features**:
- Icon + label for each tab
- Smooth color transitions
- Touch-optimized spacing
- Safe area support
- Maximum 5 items recommended

### Mobile Drawer

**Features**:
- Gradient header with app logo
- User profile section
- Full navigation list
- Settings option
- Sign out button
- Slide-in animation

## Color Highlighting

### Active State
- **Background**: Accent color at 10% opacity
- **Icon**: Full accent color
- **Text**: Full accent color
- **Font Weight**: Semi-bold (600)

### Inactive State
- **Background**: Transparent
- **Icon**: onSurfaceVariant color
- **Text**: onSurfaceVariant color
- **Font Weight**: Regular (400)

### Hover State (Desktop)
- **Animation**: 200ms smooth transition
- **Scale**: 1.02x (subtle)
- **Opacity**: 0.9 (subtle)

## Spacing

### Desktop Sidebar
- **Padding**: 12px horizontal, 4px vertical per item
- **Icon Size**: 24px
- **Border Radius**: 12px (large)
- **Gap between items**: 4px

### Mobile Bottom Bar
- **Padding**: 8px vertical
- **Icon Size**: 24px
- **Label Font Size**: 12px
- **Gap between icon and label**: 4px

### Mobile Drawer
- **Header Padding**: 16px all sides
- **Item Padding**: 16px horizontal, 12px vertical
- **Icon Size**: 24px
- **Border Radius**: 12px (large)

## Animation Timing

All animations use consistent timing:

```dart
Duration: 200ms
Curve: Curves.easeOut
```

**Animated Properties**:
- Background color
- Icon color
- Text color
- Scale (hover)
- Opacity (hover)

## Accessibility

### Semantic Labels
```dart
// Desktop sidebar (collapsed)
Tooltip(message: 'Files', child: Icon(...))

// Mobile bottom bar
Semantics(label: 'Files', child: Column(...))

// Mobile drawer
Semantics(label: 'Files', child: ListTile(...))
```

### Touch Targets
- **Mobile**: 48dp minimum (meets WCAG guidelines)
- **Desktop**: 32dp minimum (appropriate for mouse)

### Keyboard Navigation
- Tab through navigation items
- Enter/Space to activate
- Arrow keys for navigation (future enhancement)

## Theme Integration

The navigation system uses theme colors:

```dart
// Accent color (for active state)
theme.colorScheme.primary

// Background
theme.colorScheme.surface

// Inactive icons/text
theme.colorScheme.onSurfaceVariant

// Dividers
theme.dividerColor

// Gradient (header)
[theme.colorScheme.primary, theme.colorScheme.secondary]
```

## Platform Detection

```dart
final width = MediaQuery.of(context).size.width;

if (width >= 1024) {
  // Desktop: Sidebar
  return DesktopSidebar(...);
} else {
  // Mobile: Bottom bar + drawer
  return Scaffold(
    bottomNavigationBar: MobileBottomBar(...),
    drawer: MobileDrawer(...),
  );
}
```

## Best Practices

1. **Keep navigation items to 4-5**: More items clutter the UI
2. **Use clear, concise labels**: "Files" not "File Explorer"
3. **Provide both icon and label**: Better accessibility
4. **Use active icons**: Different icon for active state
5. **Test on all screen sizes**: Verify responsive behavior
6. **Respect theme colors**: Don't hardcode colors
7. **Add semantic labels**: For screen reader support
8. **Use consistent spacing**: Follow design tokens

## Common Patterns

### Adding a new destination

```dart
AppNavigationDestination(
  id: 'unique_id',
  icon: Icons.icon_outlined,
  activeIcon: Icons.icon,
  label: 'Label',
  screen: YourScreen(),
)
```

### Handling navigation

```dart
onDestinationSelected: (index) {
  setState(() => _selectedIndex = index);
  // Custom logic
}
```

### Customizing accent color

```dart
ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.blue, // Your color
  ),
)
```
