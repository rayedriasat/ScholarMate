import 'package:flutter/material.dart';
import 'hover_effect.dart';
import 'page_transition.dart';
import 'shimmer_loader.dart';
import '../../utils/animation_utils.dart';

/// Demo screen showcasing all animation system components
class AnimationDemo extends StatefulWidget {
  const AnimationDemo({Key? key}) : super(key: key);

  @override
  State<AnimationDemo> createState() => _AnimationDemoState();
}

class _AnimationDemoState extends State<AnimationDemo> {
  bool _showShimmer = true;

  @override
  Widget build(BuildContext context) {
    final reducedMotion = AnimationConstants.isReducedMotionEnabled(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Animation System Demo'),
        actions: [
          if (reducedMotion)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Chip(
                label: Text('Reduced Motion Enabled'),
                backgroundColor: Colors.orange,
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Hover Effect Demo
          _buildSection(
            'Hover Effects',
            'Scale and opacity animations on hover (200ms)',
            Column(
              children: [
                HoverEffect(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Hover over me!',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: HoverEffect(
                        child: ElevatedButton(
                          onPressed: () {},
                          child: const Text('Button 1'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: HoverEffect(
                        child: ElevatedButton(
                          onPressed: () {},
                          child: const Text('Button 2'),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Page Transition Demo
          _buildSection(
            'Page Transitions',
            'Slide and fade transitions (300ms)',
            Column(
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      SlidePageRoute(
                        builder: (context) =>
                            const _DemoPage(title: 'Slide Transition'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Open with Slide Transition'),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      ScaleDialogRoute(
                        builder: (context) => const _DemoDialog(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Open Dialog with Scale Transition'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Shimmer Loader Demo
          _buildSection(
            'Shimmer Loading Skeletons',
            'Animated loading placeholders (1500ms cycle)',
            Column(
              children: [
                Row(
                  children: [
                    const Text('Show Shimmer:'),
                    const SizedBox(width: 12),
                    Switch(
                      value: _showShimmer,
                      onChanged: (value) {
                        setState(() {
                          _showShimmer = value;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_showShimmer) ...[
                  const ShimmerTextLine(width: double.infinity, height: 20),
                  const SizedBox(height: 12),
                  const ShimmerTextLine(width: 250, height: 16),
                  const SizedBox(height: 12),
                  const ShimmerTextLine(width: 180, height: 16),
                  const SizedBox(height: 24),
                  Row(
                    children: const [
                      ShimmerCircle(size: 50),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ShimmerTextLine(width: double.infinity, height: 18),
                            SizedBox(height: 8),
                            ShimmerTextLine(width: 150, height: 14),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const ShimmerCard(width: double.infinity, height: 150),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text(
                        'Content Loaded!',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Pre-built Shimmer Components
          _buildSection(
            'Pre-built Shimmer Components',
            'Ready-to-use shimmer skeletons',
            const Column(children: [ShimmerFileCard(width: double.infinity)]),
          ),

          const SizedBox(height: 32),

          // Animation Constants Info
          _buildSection(
            'Animation Constants',
            'Centralized animation configuration',
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildConstantRow('Hover Duration', '200ms'),
                  _buildConstantRow('Route Transition', '300ms'),
                  _buildConstantRow('Dialog Duration', '250ms'),
                  _buildConstantRow('Shimmer Duration', '1500ms'),
                  const Divider(),
                  _buildConstantRow('Hover Scale', '1.02x'),
                  _buildConstantRow('Hover Opacity', '0.9'),
                  const Divider(),
                  _buildConstantRow(
                    'Reduced Motion',
                    reducedMotion ? 'Enabled' : 'Disabled',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String description, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          description,
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
        const SizedBox(height: 16),
        content,
      ],
    );
  }

  Widget _buildConstantRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontFamily: 'monospace')),
        ],
      ),
    );
  }
}

class _DemoPage extends StatelessWidget {
  final String title;

  const _DemoPage({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, size: 100, color: Colors.green),
            const SizedBox(height: 24),
            Text(
              'Page opened with $title!',
              style: const TextStyle(fontSize: 20),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DemoDialog extends StatelessWidget {
  const _DemoDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.info, size: 60, color: Colors.blue),
            const SizedBox(height: 16),
            const Text(
              'Dialog with Scale Transition',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'This dialog appeared with a scale and fade animation (250ms).',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
}
