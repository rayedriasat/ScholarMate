# Glass Components

This directory contains glassmorphism UI components for the ScholarMate application. These components provide a modern, glass-like aesthetic with blur effects, transparency, and smooth animations.

## Components

### AppGlassCard

A customizable glass card wrapper component with configurable opacity and blur.

**Features:**
- Configurable blur radius (default: 10px)
- Configurable opacity (default: 10%)
- Optional hover effects with scale and opacity animations
- Optional tap handler
- Customizable padding and dimensions

**Usage:**
```dart
AppGlassCard(
  child: Text('Content'),
  onTap: () => print('Tapped'),
  blur: 15.0,
  opacity: 0.15,
)
```

### GlassButton

Glass button component with three variants and interactive states.

**Variants:**
- `elevated` - Default glass with shadow
- `outlined` - Glass with prominent accent-colored border
- `filled` - Glass with accent color fill

**Features:**
- Hover and pressed state animations
- Disabled state support
- Customizable padding and dimensions
- Scale animation on interaction (200ms duration)

**Usage:**
```dart
GlassButton.elevated(
  onPressed: () => print('Pressed'),
  child: Text('Click Me'),
)

GlassButton.outlined(
  onPressed: () => print('Pressed'),
  child: Text('Outlined'),
)

GlassButton.filled(
  onPressed: () => print('Pressed'),
  child: Text('Filled'),
)
```

### GlassInput

Glass text input field with focus states and floating labels.

**Features:**
- Focus state with accent color border
- Floating label behavior
- Optional prefix and suffix icons
- Helper text and error text support
- Multi-line support
- Obscure text for passwords
- Customizable keyboard type and text input action

**Usage:**
```dart
GlassInput(
  labelText: 'Username',
  hintText: 'Enter your username',
  helperText: 'This is a helper text',
  prefixIcon: Icon(Icons.person),
  onChanged: (value) => print(value),
)

GlassInput(
  labelText: 'Password',
  obscureText: true,
  prefixIcon: Icon(Icons.lock),
)
```

### GlassDialog

Glass dialog component with animated backdrop blur.

**Features:**
- Title and content sections
- Optional action buttons
- Customizable dimensions
- Barrier dismissible option
- Stronger blur effect (1.5x) for better focus
- Dividers between sections

**Usage:**
```dart
GlassDialog.show(
  context: context,
  title: 'Confirm Action',
  content: Text('Are you sure?'),
  actions: [
    GlassButton.outlined(
      onPressed: () => Navigator.pop(context),
      child: Text('Cancel'),
    ),
    GlassButton.filled(
      onPressed: () => Navigator.pop(context),
      child: Text('Confirm'),
    ),
  ],
)
```

### AnimatedGlassDialog

Glass dialog with scale and fade animations on open.

**Features:**
- Scale transition animation (250ms)
- Fade transition animation
- All features of GlassDialog

**Usage:**
```dart
AnimatedGlassDialog.show(
  context: context,
  title: 'Animated Dialog',
  content: Text('This dialog animates in!'),
  actions: [
    GlassButton.elevated(
      onPressed: () => Navigator.pop(context),
      child: Text('Close'),
    ),
  ],
)
```

## Theme Integration

All glass components automatically adapt to the current theme using the `AppThemeProvider` and `GlassThemeConfig`. They respect:

- Current theme mode (light, dark, custom)
- Accent color customization
- Glass blur and opacity settings
- Border colors and widths

## Animation Durations

All components use consistent animation durations from `DesignTokens`:

- Hover effects: 200ms
- Route transitions: 300ms
- Dialog animations: 250ms

## Accessibility

All components support:

- Keyboard navigation
- Focus indicators
- Disabled states
- Screen reader compatibility (through semantic labels in parent widgets)

## Demo

See `glass_components_demo.dart` for a comprehensive demonstration of all components and their variants.

## Requirements Validation

These components satisfy the following requirements from the Modern UI Redesign spec:

- **2.1**: Glass_Card with configurable transparency (default 10% opacity) ✓
- **2.2**: Backdrop blur effect with configurable blur radius (default 10px) ✓
- **2.3**: Subtle border with 1px width and 20% white opacity ✓
- **2.4**: Soft shadow for depth perception ✓
- **2.5**: Glass variants for elevated, outlined, and filled styles ✓
- **2.6**: Glass button components with hover and pressed states ✓
- **2.7**: Glass input fields with focus states and floating labels ✓
- **2.8**: Glass dialog and modal components with animated backdrop blur ✓
