# Animation System Integration Examples

## Integrating with Existing Components

### 1. Glass Components with Hover Effects

The animation system integrates seamlessly with the existing glass components:

```dart
import 'package:frontend/widgets/glass/glass_card.dart';
import 'package:frontend/widgets/animations/hover_effect.dart';

// Glass card with hover effect
HoverEffect(
  child: AppGlassCard(
    padding: EdgeInsets.all(16),
    child: Column(
      children: [
        Text('File Name'),
        Text('File Details'),
      ],
    ),
  ),
)
```

### 2. Glass Buttons with Hover

```dart
import 'package:frontend/widgets/glass/glass_button.dart';
import 'package:frontend/widgets/animations/hover_effect.dart';

HoverEffect(
  child: GlassButton(
    onPressed: () {},
    child: Text('Click Me'),
  ),
)
```

### 3. Navigation with Glass Components

```dart
import 'package:frontend/widgets/navigation/adaptive_navigation.dart';
import 'package:frontend/widgets/animations/page_transition.dart';

// Navigate to a screen with glass components
Navigator.of(context).pushWithSlide(
  (context) => Scaffold(
    body: AdaptiveNavigation(
      selectedIndex: 0,
      onDestinationSelected: (index) {},
      destinations: [...],
      child: YourGlassScreen(),
    ),
  ),
);
```

### 4. File Explorer with All Features

```dart
import 'package:frontend/widgets/glass/glass_card.dart';
import 'package:frontend/widgets/animations/hover_effect.dart';
import 'package:frontend/widgets/animations/shimmer_loader.dart';
import 'package:frontend/widgets/animations/page_transition.dart';

class FileExplorerScreen extends StatefulWidget {
  @override
  State<FileExplorerScreen> createState() => _FileExplorerScreenState();
}

class _FileExplorerScreenState extends State<FileExplorerScreen> {
  bool _isLoading = true;
  List<File> _files = [];
  
  @override
  void initState() {
    super.initState();
    _loadFiles();
  }
  
  Future<void> _loadFiles() async {
    // Simulate loading
    await Future.delayed(Duration(seconds: 2));
    setState(() {
      _files = [...]; // Your files
      _isLoading = false;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Files')),
      body: _isLoading
          ? _buildLoadingState()
          : _buildFileGrid(),
    );
  }
  
  Widget _buildLoadingState() {
    return GridView.builder(
      padding: EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: 6,
      itemBuilder: (context, index) => ShimmerFileCard(),
    );
  }
  
  Widget _buildFileGrid() {
    return GridView.builder(
      padding: EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _files.length,
      itemBuilder: (context, index) {
        final file = _files[index];
        return HoverEffect(
          child: AppGlassCard(
            onTap: () {
              Navigator.of(context).pushWithSlide(
                (context) => FileDetailsScreen(file: file),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // File thumbnail
                Container(
                  height: 150,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      image: NetworkImage(file.thumbnailUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                SizedBox(height: 12),
                // File name
                Text(
                  file.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4),
                // File metadata
                Row(
                  children: [
                    Icon(Icons.insert_drive_file, size: 14),
                    SizedBox(width: 4),
                    Text(
                      file.size,
                      style: TextStyle(fontSize: 12),
                    ),
                    SizedBox(width: 12),
                    Icon(Icons.calendar_today, size: 14),
                    SizedBox(width: 4),
                    Text(
                      file.date,
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
```

### 5. Settings Dialog with Glass and Animations

```dart
import 'package:frontend/widgets/glass/glass_dialog.dart';
import 'package:frontend/widgets/animations/page_transition.dart';

void showSettingsDialog(BuildContext context) {
  Navigator.of(context).pushDialogWithScale(
    (context) => GlassDialog(
      title: 'Settings',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Settings content
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            // Save settings
            Navigator.pop(context);
          },
          child: Text('Save'),
        ),
      ],
    ),
  );
}
```

### 6. AI Chat with Shimmer Loading

```dart
import 'package:frontend/widgets/glass/glass_card.dart';
import 'package:frontend/widgets/animations/shimmer_loader.dart';

class AIChatScreen extends StatefulWidget {
  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  bool _isTyping = false;
  List<Message> _messages = [];
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('AI Chat')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isTyping) {
                  // Show typing indicator with shimmer
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        ShimmerCircle(size: 40),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ShimmerTextLine(width: 200, height: 16),
                              SizedBox(height: 8),
                              ShimmerTextLine(width: 150, height: 14),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }
                
                final message = _messages[index];
                return _buildMessageBubble(message);
              },
            ),
          ),
          _buildInputField(),
        ],
      ),
    );
  }
  
  Widget _buildMessageBubble(Message message) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: message.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            CircleAvatar(child: Icon(Icons.smart_toy)),
            SizedBox(width: 12),
          ],
          Flexible(
            child: AppGlassCard(
              padding: EdgeInsets.all(12),
              child: Text(message.text),
            ),
          ),
          if (message.isUser) ...[
            SizedBox(width: 12),
            CircleAvatar(child: Icon(Icons.person)),
          ],
        ],
      ),
    );
  }
  
  Widget _buildInputField() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: GlassInput(
              hintText: 'Type a message...',
              onSubmitted: (text) {
                _sendMessage(text);
              },
            ),
          ),
          SizedBox(width: 12),
          HoverEffect(
            child: IconButton(
              icon: Icon(Icons.send),
              onPressed: () {
                // Send message
              },
            ),
          ),
        ],
      ),
    );
  }
  
  void _sendMessage(String text) {
    setState(() {
      _messages.add(Message(text: text, isUser: true));
      _isTyping = true;
    });
    
    // Simulate AI response
    Future.delayed(Duration(seconds: 2), () {
      setState(() {
        _messages.add(Message(
          text: 'AI response to: $text',
          isUser: false,
        ));
        _isTyping = false;
      });
    });
  }
}
```

### 7. Responsive Layout with Animations

```dart
import 'package:frontend/widgets/layouts/responsive_layout.dart';
import 'package:frontend/widgets/animations/hover_effect.dart';
import 'package:frontend/widgets/animations/page_transition.dart';

class ResponsiveScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _buildMobileLayout(),
      tablet: _buildTabletLayout(),
      desktop: _buildDesktopLayout(),
    );
  }
  
  Widget _buildMobileLayout() {
    return ListView(
      children: [
        // Mobile cards with hover (for web mobile view)
        for (var item in items)
          HoverEffect(
            enabled: false, // Disable on actual mobile
            child: AppGlassCard(
              onTap: () {
                Navigator.of(context).pushWithSlide(
                  (context) => DetailScreen(item: item),
                );
              },
              child: ListTile(
                title: Text(item.title),
                subtitle: Text(item.subtitle),
              ),
            ),
          ),
      ],
    );
  }
  
  Widget _buildTabletLayout() {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return HoverEffect(
          child: AppGlassCard(
            onTap: () {
              Navigator.of(context).pushWithSlide(
                (context) => DetailScreen(item: items[index]),
              );
            },
            child: // Card content
          ),
        );
      },
    );
  }
  
  Widget _buildDesktopLayout() {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return HoverEffect(
          child: AppGlassCard(
            onTap: () {
              Navigator.of(context).pushWithSlide(
                (context) => DetailScreen(item: items[index]),
              );
            },
            child: // Card content
          ),
        );
      },
    );
  }
}
```

## Best Practices for Integration

### 1. Hover Effects
- Apply to all interactive glass components
- Disable on mobile devices (touch-only)
- Use default parameters for consistency

### 2. Page Transitions
- Use `pushWithSlide` for screen navigation
- Use `pushDialogWithScale` for dialogs
- Maintain consistent transition types throughout app

### 3. Loading States
- Always show shimmer during async operations
- Match shimmer skeleton to actual content layout
- Use pre-built components when possible

### 4. Accessibility
- Never override reduced motion preferences
- Test with reduced motion enabled
- Ensure functionality works without animations

### 5. Performance
- Limit simultaneous animations
- Use RepaintBoundary for complex animations
- Profile with Flutter DevTools

## Complete Example App

See `animation_demo.dart` for a complete working example that demonstrates all integration patterns.
