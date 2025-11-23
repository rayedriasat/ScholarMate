# Responsive Layout - Quick Usage Guide

## 🎯 When to Use What

### Use `ResponsiveLayout` when:
- You need access to layout configuration
- You want to make decisions based on screen size
- You need grid columns, padding, or touch target sizes

```dart
ResponsiveLayout(
  builder: (context, config) {
    return Text('Screen: ${config.screenSize}, Columns: ${config.gridColumns}');
  },
)
```

### Use `ResponsiveBuilder` when:
- You have completely different layouts for mobile/tablet/desktop
- You want simple conditional rendering

```dart
ResponsiveBuilder(
  mobile: MobileView(),
  tablet: TabletView(),    // Optional, falls back to mobile
  desktop: DesktopView(),  // Optional, falls back to tablet/mobile
)
```

### Use `ResponsiveGrid` when:
- You want an auto-adjusting grid
- You're displaying a collection of items
- You want automatic column calculation

```dart
ResponsiveGrid(
  spacing: 16.0,
  childAspectRatio: 1.0,
  children: items.map((item) => ItemCard(item)).toList(),
)
```

### Use `ResponsivePadding` when:
- You want automatic responsive padding
- You want consistent spacing across screen sizes

```dart
ResponsivePadding(
  multiplier: 2.0,  // Optional: 2x the default padding
  child: YourContent(),
)
```

### Use `ResponsiveTouchTarget` when:
- You have interactive buttons or icons
- You want platform-appropriate touch targets
- You need accessibility compliance

```dart
ResponsiveTouchTarget(
  child: IconButton(
    icon: Icon(Icons.favorite),
    onPressed: () {},
  ),
)
```

### Use `ResponsiveUtils` when:
- You need quick checks in build methods
- You want to get responsive values
- You're not using a widget-based approach

```dart
if (ResponsiveUtils.isMobile(context)) {
  return MobileLayout();
}

final padding = ResponsiveUtils.getResponsivePadding(context);
```

## 📱 Screen Size Reference

```
Mobile:  < 600px   →  1 column,  48dp touch, 16dp padding
Tablet:  600-1024  →  2-3 cols,  48dp touch, 24dp padding
Desktop: > 1024px  →  3-6 cols,  32dp touch, 32dp padding
```

## 🎨 Common Patterns

### Pattern 1: Responsive File Grid

```dart
ResponsiveGrid(
  spacing: 16.0,
  childAspectRatio: 0.75,
  children: files.map((file) => FileCard(file: file)).toList(),
)
```

### Pattern 2: Adaptive Layout with Sidebar

```dart
ResponsiveLayout(
  builder: (context, config) {
    if (config.isDesktop) {
      return Row(
        children: [
          SizedBox(width: 250, child: Sidebar()),
          Expanded(child: MainContent()),
        ],
      );
    }
    return MainContent(); // Mobile: no sidebar
  },
)
```

### Pattern 3: Responsive Card Width

```dart
ResponsiveLayout(
  builder: (context, config) {
    return SizedBox(
      width: config.cardWidth,
      child: Card(...),
    );
  },
)
```

### Pattern 4: Platform-Specific Actions

```dart
Row(
  children: [
    ResponsiveTouchTarget(child: IconButton(...)),
    ResponsiveTouchTarget(child: IconButton(...)),
    ResponsiveTouchTarget(child: IconButton(...)),
  ],
)
```

### Pattern 5: Responsive Typography

```dart
ResponsiveLayout(
  builder: (context, config) {
    final fontSize = config.isMobile ? 14.0 : 16.0;
    return Text('Hello', style: TextStyle(fontSize: fontSize));
  },
)
```

## ⚡ Performance Tips

1. **Cache LayoutConfig**: If you use it multiple times
   ```dart
   final config = LayoutConfig.fromWidth(width);
   // Reuse config instead of recalculating
   ```

2. **Use const constructors**: When possible
   ```dart
   const ResponsivePadding(child: Text('Hello'))
   ```

3. **Prefer LayoutBuilder**: Over MediaQuery for scoped rebuilds
   ```dart
   // ResponsiveLayout uses LayoutBuilder internally ✅
   ```

4. **Avoid nested ResponsiveLayout**: One per screen is usually enough
   ```dart
   // ❌ Don't nest unnecessarily
   ResponsiveLayout(
     builder: (_, config1) => ResponsiveLayout(
       builder: (_, config2) => ...
     ),
   )
   ```

## 🧪 Testing Examples

### Test Responsive Grid

```dart
testWidgets('ResponsiveGrid shows correct columns', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ResponsiveGrid(
          children: List.generate(10, (i) => Text('Item $i')),
        ),
      ),
    ),
  );
  
  // Verify items are displayed
  expect(find.text('Item 0'), findsOneWidget);
});
```

### Test ResponsiveBuilder

```dart
testWidgets('ResponsiveBuilder shows mobile layout', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: ResponsiveBuilder(
        mobile: Text('Mobile'),
        desktop: Text('Desktop'),
      ),
    ),
  );
  
  // On default test size (800x600), should show mobile
  expect(find.text('Mobile'), findsOneWidget);
});
```

## 🔍 Debugging

### Check Current Layout Config

```dart
ResponsiveLayout(
  builder: (context, config) {
    print('Screen: ${config.screenSize}');
    print('Width: ${config.width}');
    print('Columns: ${config.gridColumns}');
    print('Touch Target: ${config.touchTargetSize}');
    return YourWidget();
  },
)
```

### Visualize Breakpoints

```dart
ResponsiveLayout(
  builder: (context, config) {
    return Container(
      color: config.isMobile ? Colors.red.withOpacity(0.1) :
             config.isTablet ? Colors.blue.withOpacity(0.1) :
             Colors.green.withOpacity(0.1),
      child: YourContent(),
    );
  },
)
```

## 📚 Related Files

- `lib/models/layout_config.dart` - Core configuration model
- `lib/widgets/layouts/responsive_layout.dart` - Widget components
- `lib/utils/responsive_utils.dart` - Utility functions
- `lib/theme/design_tokens.dart` - Breakpoint constants
- `lib/widgets/layouts/responsive_layout_demo.dart` - Live examples

## 🎓 Best Practices

1. ✅ Use `ResponsiveLayout` for most cases
2. ✅ Wrap interactive elements with `ResponsiveTouchTarget`
3. ✅ Use `ResponsiveGrid` for collections
4. ✅ Test on multiple screen sizes
5. ✅ Consider tablet as a separate case when needed
6. ❌ Don't hardcode breakpoints - use DesignTokens
7. ❌ Don't nest ResponsiveLayout unnecessarily
8. ❌ Don't forget about landscape orientation

## 🚀 Quick Start Checklist

- [ ] Import responsive layout widgets
- [ ] Wrap your grid with `ResponsiveGrid`
- [ ] Use `ResponsiveLayout` for custom layouts
- [ ] Add `ResponsiveTouchTarget` to buttons
- [ ] Test on mobile, tablet, and desktop sizes
- [ ] Check touch targets are appropriate size
- [ ] Verify padding looks good on all sizes

---

**Need Help?** Check the demo: `responsive_layout_demo.dart`
