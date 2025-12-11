# Fix Extracted Document Detail Theme

## Context
The "Extracted Document Detail" screen, similar to the scanner screen, was suffering from "washed away" visuals (poor contrast, transparent background blending with nothing) in certain themes, particularly Dark Mode. This was because it relied on `Scaffold`'s default background (often transparent in this app's architecture) without an underlying `AnimatedBackground`.

## Changes
1.  **frontend/screens/extracted_document_detail_screen.dart**:
    - Added `AnimatedBackground` import.
    - Wrapped the entire `Scaffold` in a `Stack` with `AnimatedBackground` as the bottom layer.
    - This ensures that the glass-morphic containers (`GlassContainer`) used throughout the screen have a rich, visible background to contrast against, making text and elements readable.

## Verification
- **Prerequisite**: Have at least one extracted document (use the new "Scan & Extract" feature if needed).
- **Steps**:
    - Navigate to "Scan" tab (Extracted Documents).
    - Click on any document card to open the detail view.
    - Verify that the background is the standard animated app background.
    - Verify that all sections (Summary, Extracted Info, Tags) are clearly visible and readable.
    - Toggle between Light and Dark mode to ensure consistency.
