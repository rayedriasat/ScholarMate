# Mobile Metadata Sidebar Fix

## Problem
Clicking the metadata icon (ⓘ) on Android does nothing.

## Root Cause
The metadata sidebar was only configured to show on screens >= 600px wide (desktop/tablet). On mobile phones with narrower screens, the sidebar was hidden even when toggled.

## Solution
Updated `_toggleMetadataSidebar()` to show metadata in a bottom sheet on mobile devices instead of a sidebar.

### Behavior Now:
- **Mobile (< 600px):** Shows metadata in a draggable bottom sheet
- **Desktop/Tablet (>= 600px):** Shows metadata in a sidebar (as before)

## Changes Made
**File:** `frontend/lib/screens/pdf_viewer_screen.dart`

The toggle function now:
1. Checks screen width
2. If mobile: Opens a modal bottom sheet with metadata
3. If desktop: Toggles the sidebar (existing behavior)

## Features of Mobile Bottom Sheet
- ✓ Draggable (swipe up/down to resize)
- ✓ Starts at 90% screen height
- ✓ Can be minimized to 50%
- ✓ Rounded top corners
- ✓ Handle bar for easy dragging
- ✓ Swipe down to dismiss

## Testing
1. Hot restart the app (press `R` in terminal)
2. Open any PDF
3. Tap the info icon (ⓘ) in the toolbar
4. Bottom sheet should slide up with metadata
5. Drag the handle bar to resize
6. Swipe down to close

## Expected Result
On mobile, tapping the info icon now opens a full-screen bottom sheet showing:
- File metadata (title, authors, year, etc.)
- File information (name, size, dates)
- Generated citations (APA, MLA, Chicago, BibTeX)

## No Changes Needed For:
- Desktop/tablet behavior (sidebar still works as before)
- Web version (uses sidebar)
- Metadata extraction logic (unchanged)
