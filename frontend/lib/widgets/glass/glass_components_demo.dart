import 'package:flutter/material.dart';
import 'glass_components.dart';
import '../../theme/design_tokens.dart';

/// Demo screen showcasing all glass components
/// This is for development and testing purposes
class GlassComponentsDemo extends StatefulWidget {
  const GlassComponentsDemo({super.key});

  @override
  State<GlassComponentsDemo> createState() => _GlassComponentsDemoState();
}

class _GlassComponentsDemoState extends State<GlassComponentsDemo> {
  final TextEditingController _textController = TextEditingController();
  String _inputValue = '';

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _showGlassDialog() {
    GlassDialog.show(
      context: context,
      title: 'Glass Dialog Example',
      content: const Text(
        'This is a glass dialog with animated backdrop blur. '
        'It demonstrates the glassmorphism effect in a modal context.',
      ),
      actions: [
        GlassButton.outlined(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        GlassButton.filled(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Confirm'),
        ),
      ],
    );
  }

  void _showAnimatedDialog() {
    AnimatedGlassDialog.show(
      context: context,
      title: 'Animated Glass Dialog',
      content: const Text(
        'This dialog has a scale and fade animation on open.',
      ),
      actions: [
        GlassButton.elevated(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Glass Components Demo')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(DesignTokens.space6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Glass Cards Section
            const Text(
              'Glass Cards',
              style: TextStyle(fontSize: 24, fontWeight: DesignTokens.semiBold),
            ),
            const SizedBox(height: DesignTokens.space4),
            AppGlassCard(
              child: const Text(
                'Basic Glass Card\n\n'
                'This is a glass card with default settings. '
                'It features a subtle blur effect, transparency, '
                'and a soft border.',
              ),
            ),
            const SizedBox(height: DesignTokens.space4),
            AppGlassCard(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Glass card tapped!')),
                );
              },
              child: const Text(
                'Tappable Glass Card\n\n'
                'This card has an onTap handler and hover effect. '
                'Try hovering over it!',
              ),
            ),
            const SizedBox(height: DesignTokens.space4),
            AppGlassCard(
              enableHover: false,
              blur: 20,
              opacity: 0.2,
              child: const Text(
                'Custom Glass Card\n\n'
                'This card has custom blur (20) and opacity (0.2) values, '
                'with hover effect disabled.',
              ),
            ),
            const SizedBox(height: DesignTokens.space8),

            // Glass Buttons Section
            const Text(
              'Glass Buttons',
              style: TextStyle(fontSize: 24, fontWeight: DesignTokens.semiBold),
            ),
            const SizedBox(height: DesignTokens.space4),
            Row(
              children: [
                Expanded(
                  child: GlassButton.elevated(
                    onPressed: () {},
                    child: const Text('Elevated'),
                  ),
                ),
                const SizedBox(width: DesignTokens.space2),
                Expanded(
                  child: GlassButton.outlined(
                    onPressed: () {},
                    child: const Text('Outlined'),
                  ),
                ),
                const SizedBox(width: DesignTokens.space2),
                Expanded(
                  child: GlassButton.filled(
                    onPressed: () {},
                    child: const Text('Filled'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: DesignTokens.space4),
            Row(
              children: [
                Expanded(
                  child: GlassButton.elevated(
                    onPressed: null,
                    child: const Text('Disabled'),
                  ),
                ),
                const SizedBox(width: DesignTokens.space2),
                Expanded(
                  child: GlassButton.outlined(
                    onPressed: null,
                    child: const Text('Disabled'),
                  ),
                ),
                const SizedBox(width: DesignTokens.space2),
                Expanded(
                  child: GlassButton.filled(
                    onPressed: null,
                    child: const Text('Disabled'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: DesignTokens.space8),

            // Glass Inputs Section
            const Text(
              'Glass Inputs',
              style: TextStyle(fontSize: 24, fontWeight: DesignTokens.semiBold),
            ),
            const SizedBox(height: DesignTokens.space4),
            GlassInput(
              controller: _textController,
              labelText: 'Username',
              hintText: 'Enter your username',
              helperText: 'This is a helper text',
              onChanged: (value) {
                setState(() {
                  _inputValue = value;
                });
              },
            ),
            const SizedBox(height: DesignTokens.space4),
            GlassInput(
              labelText: 'Password',
              hintText: 'Enter your password',
              obscureText: true,
              prefixIcon: const Icon(Icons.lock),
            ),
            const SizedBox(height: DesignTokens.space4),
            GlassInput(
              labelText: 'Email',
              hintText: 'Enter your email',
              errorText: 'Invalid email format',
              prefixIcon: const Icon(Icons.email),
            ),
            const SizedBox(height: DesignTokens.space4),
            GlassInput(
              labelText: 'Search',
              hintText: 'Search...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _textController.clear();
                  setState(() {
                    _inputValue = '';
                  });
                },
              ),
            ),
            const SizedBox(height: DesignTokens.space4),
            GlassInput(
              labelText: 'Multi-line',
              hintText: 'Enter multiple lines...',
              maxLines: 4,
              minLines: 2,
            ),
            const SizedBox(height: DesignTokens.space4),
            if (_inputValue.isNotEmpty)
              AppGlassCard(child: Text('Current input value: $_inputValue')),
            const SizedBox(height: DesignTokens.space8),

            // Glass Dialogs Section
            const Text(
              'Glass Dialogs',
              style: TextStyle(fontSize: 24, fontWeight: DesignTokens.semiBold),
            ),
            const SizedBox(height: DesignTokens.space4),
            Row(
              children: [
                Expanded(
                  child: GlassButton.elevated(
                    onPressed: _showGlassDialog,
                    child: const Text('Show Glass Dialog'),
                  ),
                ),
                const SizedBox(width: DesignTokens.space2),
                Expanded(
                  child: GlassButton.filled(
                    onPressed: _showAnimatedDialog,
                    child: const Text('Show Animated Dialog'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
