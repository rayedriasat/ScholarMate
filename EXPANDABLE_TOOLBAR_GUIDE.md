# Expandable Toolbar - Like VS Code!

## What I Did

Created an **expandable toolbar** that works exactly like VS Code/Kiro:

### Before (Old Way)
- All buttons visible all the time
- Cluttered toolbar
- Takes up space

### After (New Way)
- **ONE button** (three dots `⋯`) shows by default
- Click it → All tool buttons appear
- Click again → Buttons hide

## How It Works

1. **Default state**: Only the expand button (⋯) is visible
2. **Click the button**: All these tools appear:
   - 📱 Split View (web only)
   - 🔄 Refresh PDF
   - 💾 Save annotations
   - 🎨 Annotation toolbar
   - 📑 Unified sidebar (annotations, metadata, TTS)
   - 💬 AI Chat
   - 👥 Collaboration
   - ℹ️ Metadata & Citations
3. **Click again**: All buttons hide, back to just the expand button

## Visual Design

- **Collapsed**: Shows `⋯` (three dots) icon in grey
- **Expanded**: Shows `✕` (close) icon in blue
- **Theme-aware**: Adapts to dark/light mode
- **Smooth**: No animation needed, instant toggle

## To See It

Restart your Flutter app:
```bash
# Press R (capital R) in terminal for hot restart
# Or stop and run again:
flutter run -d chrome  # or -d windows
```

Then:
1. Open a PDF
2. Look at the toolbar (top right)
3. You'll see just ONE button with three dots (⋯)
4. Click it → All tools appear!
5. Click again → Tools hide!

## Benefits

✅ Clean interface - No clutter  
✅ More screen space for PDF  
✅ All tools still accessible  
✅ Familiar UX - Like VS Code  
✅ One click to show/hide everything
