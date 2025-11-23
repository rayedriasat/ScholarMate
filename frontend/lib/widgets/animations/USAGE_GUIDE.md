# Animation System Usage Guide

## Quick Start

The animation system provides three main components:

1. **HoverEffect** - For interactive elements
2. **Page Transitions** - For navigation
3. **Shimmer Loaders** - For loading states

All animations automatically respect reduced motion preferences.

## 1. Hover Effects

### Basic Usage

```dart
import 'package:frontend/widgets/animations/hover_effect.dart';

HoverEffect(
  child: YourWidget(),
)
```

### With Custom Parameters

```dart
HoverEffect(
  scale: 1.05,           // Custom scale (default: 1.02)
  opacity: 0.85,         // Custom opacity (default: 0.9)
  duration: Duration(milliseconds: 150),
  curve: Curves.easeInOut,
  child: YourWidget(),
)
```

### Disable Hover Effect Conditionally

```dart
HoverEffect(
  enabled: !isMobile,    // Disable on mobile
  child: YourWidget(),
)
```

### Common Use Cases

#### Hover on Buttons
```dart
HoverEffect(
  child: ElevatedButton(
    onPressed: () {},
    child: Text('Click Me'),
  ),
)
```

#### Hover on Cards
```dart
HoverEffect(
  child: Card(
    child: ListTile(
      title: Text('File Name'),
      subtitle: Text('File Details'),
    ),
  ),
)
```

#### Hover on Glass Components
```dart
HoverEffect(
  child: AppGlassCard(
    child: Text('Glass Card with Hover'),
  ),
)
```

## 2. Page Transitions

### Slide Transition (300ms)

Use for navigating to new screens:

```dart
import 'package:frontend/widgets/animations/page_transition.dart';

// Method 1: Using SlidePageRoute directly
Navigator.of(context).push(
  SlidePageRoute(
    builder: (context) => NewScreen(),
  ),
);

// Method 2: Using extension method (recommended)
Navigator.of(context).pushWithSlide(
  (context) => NewScreen(),
);
```

### Scale Dialog Transition (250ms)

Use for dialogs and modals:

```dart
// Method 1: Using ScaleDialogRoute directly
Navigator.of(context).push(
  ScaleDialogRoute(
    builder: (context) => MyDialog(),
  ),
);

// Method 2: Using extension method (recommended)
Navigator.of(context).pushDialogWithScale(
  (context) => MyDialog(),
);
```

### Custom Duration and Curve

```dart
Navigator.of(context).push(
  SlidePageRoute(
    builder: (context) => NewScreen(),
    duration: Duration(milliseconds: 400),
    curve: Curves.easeInOut,
  ),
);
```

### Named Routes

```dart
// In your route configuration
MaterialApp(
  onGenerateRoute: (settings) {
    if (settings.name == '/details') {
      return SlidePageRoute(
        builder: (context) => DetailsScreen(),
        settings: settings,
      );
    }
    // ... other routes
  },
)
```

## 3. Shimmer Loaders

### Basic Shimmer

```dart
import 'package:frontend/widgets/animations/shimmer_loader.dart';

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
```

### Pre-built Components

#### Text Line Skeleton
```dart
ShimmerTextLine(
  width: 200,
  height: 16,
)
```

#### Card Skeleton
```dart
ShimmerCard(
  width: 300,
  height: 200,
)
```

#### Circle Avatar Skeleton
```dart
ShimmerCircle(
  size: 50,
)
```

#### File Card Skeleton
```dart
ShimmerFileCard(
  width: 300,
)
```

### Custom Colors

```dart
ShimmerLoader(
  baseColor: Colors.blue[200],
  highlightColor: Colors.blue[50],
  child: YourWidget(),
)
```

### Conditional Shimmer

```dart
bool isLoading = true;

ShimmerLoader(
  enabled: isLoading,
  child: YourWidget(),
)
```

### Complete Loading Pattern

```dart
class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  bool _isLoading = true;
  String? _data;
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  Future<void> _loadData() async {
    final data = await fetchData();
    setState(() {
      _data = data;
      _isLoading = false;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Column(
        children: [
          ShimmerTextLine(width: double.infinity, height: 20),
          SizedBox(height: 12),
          ShimmerTextLine(width: 250, height: 16),
          SizedBox(height: 12),
          ShimmerCard(width: double.infinity, height: 200),
        ],
      );
    }
    
    return Column(
      children: [
        Text(_data!),
        // ... actual content
      ],
    );
  }
}
```

## 4. Animation Constants

### Using Constants

```dart
import 'package:frontend/utils/animation_utils.dart';

// Use predefined durations
AnimatedContainer(
  duration: AnimationConstants.hoverDuration,
  curve: AnimationConstants.defaultCurve,
  // ...
)
```

### Available Constants

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

// Scale/Opacity
AnimationConstants.hoverScale     // 1.02
AnimationConstants.hoverOpacity   // 0.9
```

## 5. Accessibility Support

### Check Reduced Motion

```dart
bool reducedMotion = AnimationConstants.isReducedMotionEnabled(context);

if (reducedMotion) {
  // Show content without animation
} else {
  // Show animated content
}
```

### Get Adjusted Duration

```dart
// Returns Duration.zero if reduced motion is enabled
Duration duration = AnimationConstants.getAnimationDuration(
  context,
  AnimationConstants.hoverDuration,
);
```

### Get Adjusted Curve

```dart
// Returns Curves.linear if reduced motion is enabled
Curve curve = AnimationConstants.getAnimationCurve(
  context,
  AnimationConstants.defaultCurve,
);
```

### Custom Animation with Reduced Motion Support

```dart
class MyAnimatedWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final duration = AnimationConstants.getAnimationDuration(
      context,
      Duration(milliseconds: 300),
    );
    
    return AnimatedContainer(
      duration: duration,
      // ... other properties
    );
  }
}
```

## 6. Integration Examples

### File Explorer with Hover and Shimmer

```dart
class FileExplorer extends StatelessWidget {
  final bool isLoading;
  final List<File> files;
  
  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
        ),
        itemCount: 6,
        itemBuilder: (context, index) => ShimmerFileCard(),
      );
    }
    
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
      ),
      itemCount: files.length,
      itemBuilder: (context, index) {
        return HoverEffect(
          child: FileCard(file: files[index]),
        );
      },
    );
  }
}
```

### Navigation with Custom Transitions

```dart
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return SlidePageRoute(
              builder: (context) => HomeScreen(),
              settings: settings,
            );
          case '/details':
            return SlidePageRoute(
              builder: (context) => DetailsScreen(),
              settings: settings,
            );
          default:
            return null;
        }
      },
    );
  }
}
```

### Settings Dialog with Scale Transition

```dart
void showSettingsDialog(BuildContext context) {
  Navigator.of(context).pushDialogWithScale(
    (context) => Dialog(
      child: SettingsContent(),
    ),
  );
}
```

## 7. Best Practices

### Do's ✓

- Use HoverEffect on all interactive elements (buttons, cards, links)
- Use SlidePageRoute for screen navigation
- Use ScaleDialogRoute for dialogs and modals
- Use shimmer loaders for all async content loading
- Always respect reduced motion preferences
- Use animation constants for consistency

### Don'ts ✗

- Don't create custom animation durations without good reason
- Don't ignore reduced motion preferences
- Don't animate too many elements simultaneously
- Don't use animations that distract from content
- Don't forget to test with reduced motion enabled

## 8. Testing

### Test Reduced Motion

```dart
testWidgets('respects reduced motion', (tester) async {
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(disableAnimations: true),
      child: MyAnimatedWidget(),
    ),
  );
  
  // Verify animation is disabled
});
```

### Test Animation Duration

```dart
testWidgets('hover animation has correct duration', (tester) async {
  await tester.pumpWidget(HoverEffect(child: Container()));
  
  // Verify duration is 200ms
  expect(
    AnimationConstants.hoverDuration,
    Duration(milliseconds: 200),
  );
});
```

## 9. Demo

Run the demo to see all animations in action:

```dart
import 'package:frontend/widgets/animations/animation_demo.dart';

// In your app
Navigator.of(context).push(
  MaterialPageRoute(
    builder: (context) => AnimationDemo(),
  ),
);
```

## 10. Troubleshooting

### Animations not working?

1. Check if reduced motion is enabled in system settings
2. Verify you're using the correct import paths
3. Ensure you're wrapping widgets correctly
4. Check console for any errors

### Performance issues?

1. Limit number of simultaneous animations
2. Use RepaintBoundary for complex animated widgets
3. Consider disabling animations on low-end devices
4. Profile with Flutter DevTools

### Shimmer not visible?

1. Ensure child widget has a visible background color
2. Check that shimmer is enabled
3. Verify baseColor and highlightColor have sufficient contrast
4. Make sure widget has non-zero dimensions
