import 'package:flutter/material.dart';
import '../../models/layout_config.dart';

/// A widget that builds different layouts based on screen size breakpoints
/// Uses LayoutBuilder to detect screen width and provides LayoutConfig
class ResponsiveLayout extends StatelessWidget {
  /// Builder function that receives the layout configuration
  final Widget Function(BuildContext context, LayoutConfig config) builder;

  const ResponsiveLayout({Key? key, required this.builder}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final config = LayoutConfig.fromWidth(constraints.maxWidth);
        return builder(context, config);
      },
    );
  }
}

/// A widget that conditionally renders different layouts for mobile, tablet, and desktop
class ResponsiveBuilder extends StatelessWidget {
  /// Widget to display on mobile screens (<600px)
  final Widget mobile;

  /// Widget to display on tablet screens (600-1024px)
  /// If null, uses mobile layout
  final Widget? tablet;

  /// Widget to display on desktop screens (>1024px)
  /// If null, uses tablet or mobile layout
  final Widget? desktop;

  const ResponsiveBuilder({
    Key? key,
    required this.mobile,
    this.tablet,
    this.desktop,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      builder: (context, config) {
        switch (config.screenSize) {
          case ScreenSize.mobile:
            return mobile;
          case ScreenSize.tablet:
            return tablet ?? mobile;
          case ScreenSize.desktop:
            return desktop ?? tablet ?? mobile;
        }
      },
    );
  }
}

/// A grid widget that automatically adjusts column count based on screen width
class ResponsiveGrid extends StatelessWidget {
  /// Children to display in the grid
  final List<Widget> children;

  /// Spacing between grid items
  final double spacing;

  /// Aspect ratio of grid items (width/height)
  final double childAspectRatio;

  /// Optional custom column count override
  final int? columnCount;

  const ResponsiveGrid({
    Key? key,
    required this.children,
    this.spacing = 16.0,
    this.childAspectRatio = 1.0,
    this.columnCount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      builder: (context, config) {
        final columns = columnCount ?? config.gridColumns;
        return GridView.builder(
          padding: config.padding,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            childAspectRatio: childAspectRatio,
          ),
          itemCount: children.length,
          itemBuilder: (context, index) => children[index],
        );
      },
    );
  }
}

/// A widget that wraps content with responsive padding
class ResponsivePadding extends StatelessWidget {
  final Widget child;

  /// Optional custom padding multiplier (default: 1.0)
  final double multiplier;

  const ResponsivePadding({
    Key? key,
    required this.child,
    this.multiplier = 1.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      builder: (context, config) {
        return Padding(padding: config.padding * multiplier, child: child);
      },
    );
  }
}

/// A widget that provides platform-specific touch target sizing
class ResponsiveTouchTarget extends StatelessWidget {
  final Widget child;

  /// Optional minimum size override
  final double? minSize;

  const ResponsiveTouchTarget({Key? key, required this.child, this.minSize})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      builder: (context, config) {
        final size = minSize ?? config.touchTargetSize;
        return SizedBox(
          width: size,
          height: size,
          child: Center(child: child),
        );
      },
    );
  }
}
