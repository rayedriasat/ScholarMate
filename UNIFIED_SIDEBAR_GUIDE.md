# Unified PDF Tools Sidebar

## What Changed

I've created a **unified sidebar** that combines all PDF tools in one place, similar to how VS Code/Kiro works!

## Features

### One Button for Everything
- Look for the **dashboard icon** (☷) in the PDF viewer toolbar
- Click it to open the unified sidebar with ALL features:
  - 📑 **Annotations** - View and manage all your highlights, notes, etc.
  - ℹ️ **Metadata** - File info, citations (APA, MLA, Chicago, BibTeX)
  - 🔊 **Read Aloud** - Text-to-speech controls

### Collapsible Bar
- The sidebar has a **40px handle bar** on the left edge
- Click the bar to collapse/expand without closing
- When collapsed: Shows vertical "PDF Tools" text
- When expanded: Shows full content with tabs

### Tab Navigation
- Switch between features using tabs at the top
- Each tab shows different tools
- All in one convenient location

## How to Use

1. **Open PDF** in the viewer
2. **Click the dashboard icon** (☷) in the toolbar (top right area)
3. **Unified sidebar appears** with 3 tabs
4. **Switch tabs** to access different features
5. **Click the handle bar** on the left to collapse/expand
6. **Click dashboard icon again** to close completely

## Restart Required

Since this is a new widget, you need to restart the app:

```bash
# Stop current app (Ctrl+C)
flutter run -d chrome  # or -d windows
```

Or press `R` (capital R) in the terminal for hot restart.

## Benefits

✅ Less clutter - One button instead of multiple  
✅ More screen space - Collapsible design  
✅ Better organization - All tools in tabs  
✅ Familiar UX - Works like VS Code sidebar  
✅ Theme-aware - Adapts to dark/light mode
