# Fix Scan Document Theme Issue

## Context
The "Scan Document" screen (specifically the Web UI for selecting images) was hardcoding `Colors.white` for text and `AppColors.surface` (dark) or transparent backgrounds. This caused the screen to appear "washed away" or invisible in Light Mode, where the background is white and the text was also forced to white.

## Changes
1.  **theme/app_colors.dart**: (No changes, just reference)
2.  **screens/document_scanner_screen.dart**:
    - Added `AnimatedBackground` import.
    - Wrapped the `Scaffold` in the `build` method with a `Stack` containing `Positioned.fill(child: AnimatedBackground())`.
    - This ensures a consistent, theme-aware background in both Light and Dark modes, preventing "washed out" visuals when `scaffoldBackgroundColor` is transparent.
    - Updated `_buildWebUI` text and container colors to be theme-aware (using `colorScheme`).

## Verification
- Start the app in Dark Mode.
- Navigate to File Explorer -> '+' -> 'Scan document'.
- Verify that the background is the standard app animated background (dark slate with orbs).
- Verify that the glass containers (instructions, buttons) are clearly visible against the background.
- Switch to Light Mode and verify visibility is still good.
