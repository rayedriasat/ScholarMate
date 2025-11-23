# Animation System

This directory contains the animation system components for the Modern UI Redesign. All animations respect the user's reduced motion accessibility preferences.

## Components

### 1. HoverEffect Widget
Applies scale and opacity animations on hover.

**Usage:**
```dart
HoverEffect(
  child: Container(
    padding: EdgeInsets.all(16),
    child: Text('Hover over me'),
  ),
)
```

**Properties:**
- `scale`: Scale factor on hover (default: 1.02)
- `opacity`: Opacity on hover (default: 0.9)
- `duration`: Animation duration (default: 200ms)
- `curve`: Animation curve (default: Curves.easeOut)
- `enabled`: Enable/disable hover effects (default: true)

### 2. Page Transitions

#### SlidePageRoute
Custom page route with slide and fade transition (300ms).

**Usage:**
```dart
Navigator.of(context).push(
  SlidePageRoute(
    builder: (context) => MyNewScreen(),
  ),
);

// Or using the extension method:
Navigator.of(context).pushWithSlide((context) => MyNewScreen());
```

#### ScaleDialogRoute
Custom dialog route with scale and fade transition (250ms).

**Usage:**
```dart
Navigator.of(context).push(
  ScaleDialogRoute(
    builder: (context) => MyDialog(),
  ),
);

// Or using the extension method:
Navigator.of(context).pushDialogWithScale((context) => MyDialog());
```

### 3. Shimmer Loader
Loading skeleton with shimmer animation for async content.

**Usage:**
```dart
// Basic shimmer
ShimmerLoader(
  child: Container(
    width: 200,
    height: 20,
    decoration: BoxDecoration(
      color: Colors.grey[300],
      borderRadius: BorderRadius.circular(4),
    ),
  ),
)

// Pre-built shimmer components
ShimmerTextLine(width: 200, height: 16)
ShimmerCard(width: 300, height: 200)
ShimmerCircle(size: 40)
ShimmerFileCard(width: 300)
```

**Properties:**
- `duration`: Shimmer cycle duration (default: 1500ms)
- `baseColor`: Base color of shimmer gradient
- `highlightColor`: Highlight color of shimmer gradient
- `enabled`: Enable/disable shimmer animation (default: true)

## Animation Constants

All animation durations and curves are defined in `lib/utils/animation_utils.dart`:

```dart
// Durations
AnimationConstants.hoverDuration          // 200ms
AnimationConstants.routeTransitionDuration // 300ms
AnimationConstants.dialogDuration         // 250ms
AnimationConstants.shimmerDuration        // 1500ms
AnimationConstants.listItemDuration       // 300ms

// Curves
AnimationConstants.defaultCurve   // Curves.easeOut
AnimationConstants.dialogCurve    // Curves.easeInOut
AnimationConstants.springCurve    // Curves.elasticOut

// Scale constants
AnimationConstants.hoverScale     // 1.02
AnimationConstants.hoverOpacity   // 0.9
```

## Accessibility Support

All animations automatically respect the user's reduced motion preferences:

```dart
// Check if reduced motion is enabled
bool reducedMotion = AnimationConstants.isReducedMotionEnabled(context);

// Get animation duration (returns Duration.zero if reduced motion is enabled)
Duration duration = AnimationConstants.getAnimationDuration(
  context,
  AnimationConstants.hoverDuration,
);

// Get animation curve (returns Curves.linear if reduced motion is enabled)
Curve curve = AnimationConstants.getAnimationCurve(
  context,
  AnimationConstants.defaultCurve,
);
```

When reduced motion is enabled:
- HoverEffect: Returns child without animation
- SlidePageRoute: Uses fade only (no slide)
- ScaleDialogRoute: Uses fade only (no scale)
- ShimmerLoader: Returns child without shimmer

## Requirements Validation

This animation system validates the following requirements:

- **7.1**: Hover effects with 200ms duration ✓
- **7.2**: Hover effects with 1.02x scale and opacity change ✓
- **7.3**: Route transitions with 300ms slide and fade ✓
- **7.4**: Dialog animations with 250ms scale and fade ✓
- **7.5**: Shimmer loading skeletons for async content ✓
- **7.8**: Reduced motion accessibility support ✓
- **13.4**: Respects system reduced motion preferences ✓

## Examples

See `animation_demo.dart` for a complete demonstration of all animation components.
