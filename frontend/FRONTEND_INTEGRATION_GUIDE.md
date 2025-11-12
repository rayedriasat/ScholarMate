# Frontend Integration Guide - API Key Management

## Quick Integration (5 minutes)

### Step 1: Add to Your Settings Screen

```dart
import 'package:flutter/material.dart';
import 'widgets/api_key_settings_tile.dart';

class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Settings')),
      body: ListView(
        children: [
          // ... other settings ...
          
          // Add this line:
          ApiKeySettingsTile(
            userId: 'your-user-id',  // Get from auth service
            baseUrl: 'http://localhost:8000',  // Your backend URL
          ),
          
          // ... more settings ...
        ],
      ),
    );
  }
}
```

### Step 2: Add Provider Selection to Chat/RAG Screen

```dart
import 'package:flutter/material.dart';
import 'services/api_key_service.dart';
import 'models/api_key.dart';

class ChatScreen extends StatefulWidget {
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  String? _selectedProvider;
  List<ApiKeyModel> _userKeys = [];
  
  @override
  void initState() {
    super.initState();
    _loadUserKeys();
  }
  
  Future<void> _loadUserKeys() async {
    final apiKeyService = ApiKeyService(
      baseUrl: 'http://localhost:8000',
      userId: 'your-user-id',
    );
    
    final keys = await apiKeyService.getUserKeys();
    setState(() {
      _userKeys = keys.where((k) => k.isActive && k.isValidated).toList();
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat'),
        actions: [
          // Provider selector dropdown
          if (_userKeys.isNotEmpty)
            DropdownButton<String>(
              value: _selectedProvider,
              hint: Text('Auto'),
              items: [
                DropdownMenuItem(value: null, child: Text('Auto')),
                ..._userKeys.map((key) => DropdownMenuItem(
                  value: key.provider,
                  child: Text(key.provider.toUpperCase()),
                )),
              ],
              onChanged: (value) => setState(() => _selectedProvider = value),
            ),
        ],
      ),
      body: Column(
        children: [
          // ... chat messages ...
          
          // Send message with preferred provider
          TextField(
            onSubmitted: (text) => _sendMessage(text),
          ),
        ],
      ),
    );
  }
  
  Future<void> _sendMessage(String text) async {
    // Send to RAG endpoint with preferred_provider
    final response = await http.post(
      Uri.parse('http://localhost:8000/api/ai/chat-rag'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'question': text,
        'user_id': 'your-user-id',
        'preferred_provider': _selectedProvider,  // Can be null for auto
      }),
    );
    
    // Handle response...
  }
}
```

## Files Created

### Models
- `frontend/lib/models/api_key.dart` - Data models for API keys, providers, and usage stats

### Services
- `frontend/lib/services/api_key_service.dart` - Service for API key CRUD operations

### Screens
- `frontend/lib/screens/api_key_management_screen.dart` - Full-featured API key management UI

### Widgets
- `frontend/lib/widgets/api_key_settings_tile.dart` - Simple settings tile to navigate to key management

## Features

### API Key Management Screen
✅ List all user's API keys  
✅ Add new API keys with validation  
✅ Edit key priority  
✅ Toggle key active/inactive  
✅ Delete keys  
✅ View usage statistics  
✅ Provider information and docs links  
✅ Masked key display for security  
✅ Validation status indicators  

### Add Key Dialog
✅ Provider selection dropdown  
✅ API key input with show/hide toggle  
✅ Priority setting (0-100)  
✅ Optional validation before saving  
✅ Format hints for each provider  
✅ Link to provider documentation  

### Usage Statistics
✅ Total requests per provider  
✅ Total tokens used  
✅ Estimated costs  
✅ Success rates  
✅ Last 30 days by default  

## Configuration

### Get User ID
```dart
// From your auth service
final userId = await authService.getCurrentUserId();
```

### Set Backend URL
```dart
// Development
const baseUrl = 'http://localhost:8000';

// Production
const baseUrl = 'https://your-backend.com';

// From environment
final baseUrl = const String.fromEnvironment('BACKEND_URL', 
  defaultValue: 'http://localhost:8000');
```

## Usage Examples

### Navigate to API Key Management
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => ApiKeyManagementScreen(
      userId: currentUserId,
      baseUrl: backendUrl,
    ),
  ),
);
```

### Check if User Has Keys
```dart
final apiKeyService = ApiKeyService(
  baseUrl: backendUrl,
  userId: currentUserId,
);

final keys = await apiKeyService.getUserKeys();
final hasValidKeys = keys.any((k) => k.isActive && k.isValidated);

if (!hasValidKeys) {
  // Show prompt to add API key
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Add API Key'),
      content: Text('Add an API key to use AI features'),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ApiKeyManagementScreen(
                  userId: currentUserId,
                  baseUrl: backendUrl,
                ),
              ),
            );
          },
          child: Text('Add Key'),
        ),
      ],
    ),
  );
}
```

### Use Specific Provider for Query
```dart
// Let user choose provider
String? preferredProvider = await showDialog<String>(
  context: context,
  builder: (context) => SimpleDialog(
    title: Text('Choose AI Provider'),
    children: [
      SimpleDialogOption(
        child: Text('Auto (Recommended)'),
        onPressed: () => Navigator.pop(context, null),
      ),
      ...userKeys.map((key) => SimpleDialogOption(
        child: Text(key.provider.toUpperCase()),
        onPressed: () => Navigator.pop(context, key.provider),
      )),
    ],
  ),
);

// Send query with preferred provider
final response = await http.post(
  Uri.parse('$baseUrl/api/ai/chat-rag'),
  body: jsonEncode({
    'question': question,
    'user_id': userId,
    'preferred_provider': preferredProvider,
  }),
);
```

## Error Handling

```dart
try {
  await apiKeyService.saveKey(
    provider: 'openai',
    apiKey: apiKey,
    priority: 10,
  );
  
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('API key saved successfully')),
  );
} catch (e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Error: $e'),
      backgroundColor: Colors.red,
    ),
  );
}
```

## Testing

### Test API Key Service
```dart
void main() {
  test('Get providers', () async {
    final service = ApiKeyService(
      baseUrl: 'http://localhost:8000',
      userId: 'test-user',
    );
    
    final providers = await service.getProviders();
    expect(providers.length, greaterThan(0));
    expect(providers.any((p) => p.name == 'groq'), true);
  });
}
```

### Test UI
```dart
void main() {
  testWidgets('API Key Management Screen', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ApiKeyManagementScreen(
          userId: 'test-user',
          baseUrl: 'http://localhost:8000',
        ),
      ),
    );
    
    expect(find.text('API Key Management'), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
  });
}
```

## Customization

### Change Theme
```dart
// In your theme
ThemeData(
  // ... other theme settings ...
  
  // Card style for key cards
  cardTheme: CardTheme(
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),
  
  // Button style
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  ),
)
```

### Add Custom Provider Icons
```dart
// In _buildKeyCard method
Widget _getProviderIcon(String provider) {
  switch (provider) {
    case 'groq':
      return Image.asset('assets/groq_logo.png', width: 24);
    case 'openai':
      return Image.asset('assets/openai_logo.png', width: 24);
    case 'anthropic':
      return Image.asset('assets/anthropic_logo.png', width: 24);
    default:
      return Icon(Icons.key);
  }
}
```

## Next Steps

1. ✅ Add `ApiKeySettingsTile` to your settings screen
2. ✅ Test adding an API key
3. ✅ Add provider selection to chat/RAG screens
4. ✅ Test queries with different providers
5. ✅ Monitor usage statistics
6. ✅ Add user documentation (link to HOW_TO_GET_API_KEYS.md)

## User Documentation

Point users to: `frontend/HOW_TO_GET_API_KEYS.md` for instructions on:
- How to get API keys from each provider
- Security best practices
- Cost estimates
- Troubleshooting

## Support

If you encounter issues:
1. Check backend is running: `curl http://localhost:8000/api/health`
2. Verify migration applied: Check Supabase for `user_api_keys` table
3. Test API directly: `curl http://localhost:8000/api/keys/providers`
4. Check logs in backend console

---

**That's it!** Your users can now manage their own API keys and choose which AI provider to use for each query! 🎉
