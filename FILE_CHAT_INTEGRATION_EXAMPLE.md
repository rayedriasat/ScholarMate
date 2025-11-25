# File Chat Integration Example

## Step-by-Step Integration Guide

### Step 1: Install Dependencies

```bash
cd frontend
flutter pub add supabase_flutter uuid
flutter pub run build_runner build --delete-conflicting-outputs
```

### Step 2: Update Main App with Provider

```dart
// frontend/lib/main.dart
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/file_chat_service.dart';
import 'database/database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  await Supabase.initialize(
    url: 'YOUR_SUPABASE_URL',
    anonKey: 'YOUR_SUPABASE_ANON_KEY',
  );
  
  final database = AppDatabase();
  
  runApp(
    MultiProvider(
      providers: [
        Provider<AppDatabase>.value(value: database),
        ChangeNotifierProvider(
          create: (_) => FileChatService(
            database: database,
            supabase: Supabase.instance.client,
          ),
        ),
        // ... other providers
      ],
      child: MyApp(),
    ),
  );
}
```

### Step 3: Modify PDF Viewer Screen

```dart
// Example: Modify your existing PDF viewer screen
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/file_chat_panel.dart';
import '../services/auth_service.dart';

class PdfViewerScreen extends StatefulWidget {
  final String fileId;
  final String fileName;
  
  const PdfViewerScreen({
    super.key,
    required this.fileId,
    required this.fileName,
  });

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final currentUser = authService.currentUser;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.fileName),
      ),
      body: Row(
        children: [
          // Existing PDF viewer (takes remaining space)
          Expanded(
            child: YourExistingPdfViewer(
              fileId: widget.fileId,
            ),
          ),
          
          // NEW: File chat panel
          if (currentUser != null)
            FileChatPanel(
              fileId: widget.fileId,
              userId: currentUser.id,
              userName: currentUser.name ?? 'Anonymous',
              userPhotoUrl: currentUser.photoUrl,
            ),
        ],
      ),
    );
  }
}
```

### Step 4: Run Database Migration (Backend)

Execute this SQL in your Supabase SQL Editor:

```sql
-- Copy contents from backend/migrations/010_file_chat_tables.sql
-- Or run via Supabase CLI:
supabase db push
```

### Step 5: Update Backend (if self-hosting)

The router is already added to `main.py`. Just restart your backend:

```bash
cd backend
uv run python run.py
```

### Step 6: Test the Feature

1. **Open a PDF file** in your app
2. **See the chat icon** on the right side (collapsed state)
3. **Click to expand** the chat panel
4. **Send a test message**
5. **Open same file on another device** to test real-time updates

## Minimal Example (Standalone)

If you want to test the chat panel in isolation:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'widgets/file_chat_panel.dart';
import 'services/file_chat_service.dart';
import 'database/database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'YOUR_SUPABASE_URL',
    anonKey: 'YOUR_SUPABASE_ANON_KEY',
  );
  
  final database = AppDatabase();
  
  runApp(
    MultiProvider(
      providers: [
        Provider<AppDatabase>.value(value: database),
        ChangeNotifierProvider(
          create: (_) => FileChatService(
            database: database,
            supabase: Supabase.instance.client,
          ),
        ),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Row(
            children: [
              Expanded(
                child: Center(
                  child: Text('Your PDF Viewer Here'),
                ),
              ),
              FileChatPanel(
                fileId: 'test-file-123',
                userId: 'user-456',
                userName: 'Test User',
                userPhotoUrl: null,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
```

## Troubleshooting

### Chat panel not showing
- Check that `FileChatService` is provided in the widget tree
- Verify user is authenticated (userId is not null)
- Check console for errors

### Messages not syncing
- Verify Supabase URL and keys are correct
- Check network connectivity
- Verify RLS policies are set up correctly
- Check backend logs for errors

### Real-time not working
- Ensure Realtime is enabled in Supabase project settings
- Verify `ALTER PUBLICATION supabase_realtime ADD TABLE file_chat_messages;` was run
- Check browser console for WebSocket errors

### Access control issues
- Verify `file_shares` table exists and has correct data
- Check RLS policies in Supabase
- Ensure user has proper file access

## Environment Variables

Add to your `dart_defines.json`:

```json
{
  "SUPABASE_URL": "https://your-project.supabase.co",
  "SUPABASE_ANON_KEY": "your-anon-key"
}
```

## Next Steps

1. ✅ Integrate chat panel into PDF viewer
2. ✅ Test message sending and receiving
3. ✅ Test offline mode
4. ✅ Test access control with multiple users
5. ✅ Customize UI colors/styling to match your app
6. 🔄 Add pagination for large chat histories (optional)
7. 🔄 Add typing indicators (optional)
8. 🔄 Add message reactions (optional)
