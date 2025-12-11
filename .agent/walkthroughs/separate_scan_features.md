# Implement Separation of Scan and Extract Features

## Context
The user requested to separate the "Scan Document" and "Scan & Extract" features.
- "Scan Document" (via File Explorer) should only support saving as Markdown (or PDF) and NOT data extraction.
- "Scan & Extract" (via Navbar -> Scan) should specifically handle scanning for data extraction.

## Changes
1.  **frontend/screens/document_scanner_screen.dart**:
    - Added `isExtractionMode` flag to the constructor.
    - Updated `_showOCRPreview` to conditionally show action buttons:
        - Default mode: Shows 'Markdown', 'Save as PDF'. 'Extract Data' is HIDDEN.
        - Extraction mode: Shows ONLY 'Extract Data' as the primary action.
    - Updated AppBar title to reflect the mode ("Scan Document" vs "Scan & Extract").
    - Wrapped `Scaffold` in `AnimatedBackground` (from previous step, but relevant for UI consistency).

2.  **frontend/screens/extracted_documents_screen.dart**:
    - Added a `FloatingActionButton` labeled "Scan & Extract".
    - This FAB launches `DocumentScannerScreen` with `isExtractionMode: true`.
    - Added necessary import for `DocumentScannerScreen`.

## Verification
1.  **Standard Scan**:
    - Go to File Explorer -> '+' -> 'Scan document'.
    - Take/Pick an image -> Process.
    - Verify dialog options: Only "Markdown" and "Save as PDF" should be visible. "Extract Data" should be GONE.
2.  **Extraction Scan**:
    - Go to "Scan" tab (Extracted Documents).
    - Click new "Scan & Extract" FAB.
    - Take/Pick an image -> Process.
    - Verify dialog options: Only "Extract Data" should be visible (options to save as markdown/pdf hidden).
    - Verify AppBar title says "Scan & Extract".
