import 'package:flutter/material.dart';
import 'responsive_layout.dart';
import '../../theme/design_tokens.dart';

/// Demo screen showing responsive layout utilities in action
class ResponsiveLayoutDemo extends StatelessWidget {
  const ResponsiveLayoutDemo({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Responsive Layout Demo')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Example 1: ResponsiveLayout with LayoutConfig
            _buildSection(
              title: '1. ResponsiveLayout with LayoutConfig',
              child: ResponsiveLayout(
                builder: (context, config) {
                  return Container(
                    padding: config.padding,
                    color: Colors.blue.withOpacity(0.1),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Screen Size: ${config.screenSize}'),
                        Text('Width: ${config.width.toStringAsFixed(0)}px'),
                        Text('Grid Columns: ${config.gridColumns}'),
                        Text(
                          'Card Width: ${config.cardWidth.toStringAsFixed(0)}px',
                        ),
                        Text('Touch Target: ${config.touchTargetSize}dp'),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Example 2: ResponsiveBuilder
            _buildSection(
              title: '2. ResponsiveBuilder (Different layouts)',
              child: ResponsiveBuilder(
                mobile: _buildLayoutCard('Mobile Layout', Colors.green),
                tablet: _buildLayoutCard('Tablet Layout', Colors.orange),
                desktop: _buildLayoutCard('Desktop Layout', Colors.purple),
              ),
            ),

            // Example 3: ResponsiveGrid
            _buildSection(
              title: '3. ResponsiveGrid (Auto columns)',
              child: SizedBox(
                height: 300,
                child: ResponsiveGrid(
                  spacing: DesignTokens.space4,
                  childAspectRatio: 1.5,
                  children: List.generate(
                    12,
                    (index) => Container(
                      decoration: BoxDecoration(
                        color: Colors.primaries[index % Colors.primaries.length]
                            .withOpacity(0.3),
                        borderRadius: BorderRadius.circular(
                          DesignTokens.radiusMedium,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'Item ${index + 1}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Example 4: ResponsivePadding
            _buildSection(
              title: '4. ResponsivePadding (Auto padding)',
              child: ResponsivePadding(
                child: Container(
                  color: Colors.amber.withOpacity(0.2),
                  child: const Text(
                    'This container has responsive padding that adjusts based on screen size.',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),

            // Example 5: ResponsiveTouchTarget
            _buildSection(
              title: '5. ResponsiveTouchTarget (Platform-specific)',
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ResponsiveTouchTarget(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.favorite),
                    ),
                  ),
                  ResponsiveTouchTarget(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.star),
                    ),
                  ),
                  ResponsiveTouchTarget(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.thumb_up),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          child,
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildLayoutCard(String text, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        border: Border.all(color: color, width: 2),
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }
}
