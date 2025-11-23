# Responsive Layout Utilities

This directory contains utilities for building responsive layouts that adapt to different screen sizes.

## Components

### 1. LayoutConfig Model (`lib/models/layout_config.dart`)

A configuration model that calculates responsive properties based on screen width:

```dart
final config = LayoutConfig.fromWidth(800);
print(config.screenSize);      // ScreenSize.tablet
print(config.gridColumns);     // 2
print(config.touchTargetSize); // 48.0
```

**Properties:**
- `screenSize`: Mobile, tablet, or desktop
- `width`: Current screen width
- `gridColumns`: Number of columns for grid layouts (1-6)
- `cardWidth`: Calculated width for grid cards
- `padding`: Responsive padding (16dp mobile, 24dp tablet, 32dp desktop)
- `touchTargetSize`: Platform-specific touch target (48dp mobile, 32dp desktop)

### 2. ResponsiveLayout Widget

A widget that provides LayoutConfig to its builder:

```dart
ResponsiveLayout(
  builder: (context, config) {
    return Text('Columns: ${config.gridColumns}');
  },
)
```

### 3. ResponsiveBuilder Widget

Conditionally renders different layouts for mobile, tablet, and desktop:

```dart
ResponsiveBuilder(
  mobile: MobileLayout(),
  tablet: TabletLayout(),
  desktop: DesktopLayout(),
)
```

### 4. ResponsiveGrid Widget

A grid that automatically adjusts column count based on screen width:

```dart
ResponsiveGrid(
  spacing: 16.0,
  childAspectRatio: 1.5,
  children: [
    Card(child: Text('Item 1')),
    Card(child: Text('Item 2')),
    // ...
  ],
)
```

**Grid Columns by Width:**
- < 600px: 1 column
- 600-900px: 2 columns
- 900-1200px: 3 columns
- 1200-1600px: 4 columns
- 1600-2000px: 5 columns
- > 2000px: 6 columns

### 5. ResponsivePadding Widget

Wraps content with responsive padding:

```dart
ResponsivePadding(
  multiplier: 2.0, // Optional: multiply padding
  child: Text('Padded content'),
)
```

### 6. ResponsiveTouchTarget Widget

Provides platform-specific touch target sizing:

```dart
ResponsiveTouchTarget(
  child: IconButton(
    icon: Icon(Icons.favorite),
    onPressed: () {},
  ),
)
```

## Utility Functions (`lib/utils/responsive_utils.dart`)

Helper functions for responsive design:

```dart
// Check screen size
if (ResponsiveUtils.isMobile(context)) {
  // Mobile-specific code
}

// Get layout config
final config = ResponsiveUtils.getLayoutConfig(context);

// Get grid columns
final columns = ResponsiveUtils.getGridColumns(context);

// Get responsive padding
final padding = ResponsiveUtils.getResponsivePadding(context);

// Get touch target size
final size = ResponsiveUtils.getTouchTargetSize(context);

// Get responsive values
final fontSize = ResponsiveUtils.getValue<double>(
  context,
  mobile: 14.0,
  tablet: 16.0,
  desktop: 18.0,
);
```

## Breakpoints

The system uses two breakpoints defined in `DesignTokens`:

- **Mobile**: < 600px
- **Tablet**: 600px - 1024px
- **Desktop**: > 1024px

## Touch Target Sizes

Following platform conventions and accessibility guidelines:

- **Mobile**: 48dp minimum (easier for touch)
- **Desktop**: 32dp minimum (optimized for mouse)

## Usage Examples

### Example 1: Responsive File Grid

```dart
ResponsiveGrid(
  spacing: 16.0,
  childAspectRatio: 0.8,
  children: files.map((file) => FileCard(file: file)).toList(),
)
```

### Example 2: Adaptive Navigation

```dart
ResponsiveBuilder(
  mobile: BottomNavigationBar(items: navItems),
  desktop: Sidebar(items: navItems),
)
```

### Example 3: Responsive Layout with Config

```dart
ResponsiveLayout(
  builder: (context, config) {
    return GridView.builder(
      padding: config.padding,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: config.gridColumns,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemBuilder: (context, index) => ItemCard(index: index),
    );
  },
)
```

### Example 4: Platform-Specific Touch Targets

```dart
Row(
  children: [
    ResponsiveTouchTarget(
      child: IconButton(
        icon: Icon(Icons.edit),
        onPressed: onEdit,
      ),
    ),
    ResponsiveTouchTarget(
      child: IconButton(
        icon: Icon(Icons.delete),
        onPressed: onDelete,
      ),
    ),
  ],
)
```

## Demo

Run the demo screen to see all components in action:

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => ResponsiveLayoutDemo(),
  ),
);
```

## Testing

The responsive layout utilities are designed to be testable:

```dart
testWidgets('ResponsiveLayout provides correct config', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: ResponsiveLayout(
        builder: (context, config) {
          return Text('Columns: ${config.gridColumns}');
        },
      ),
    ),
  );
  
  // Verify layout config is provided
  expect(find.text('Columns: 1'), findsOneWidget);
});
```

## Requirements Validation

This implementation satisfies the following requirements:

- **4.1**: Responsive navigation based on screen width
- **4.2**: Breakpoint-based layout changes
- **4.3**: Grid column calculation
- **5.7**: Platform-specific touch target sizes (48dp mobile, 32dp desktop)
- **13.8**: Accessibility-compliant touch targets

## Performance Considerations

- Uses `LayoutBuilder` instead of `MediaQuery` where possible to minimize rebuilds
- Caches layout configurations
- Efficient breakpoint calculations
- Minimal widget rebuilds on resize

## Future Enhancements

- Orientation-aware layouts
- Custom breakpoint definitions
- Animation on layout changes
- Responsive typography scale
- Adaptive image loading
