# Testing Searchable PDF Generation

## Quick Test Guide

### Prerequisites
- ✅ Backend running with Tesseract
- ✅ Flutter app running on device/emulator
- ✅ User logged in
- ✅ Camera permissions granted

### Test 1: Single Page Scan

1. **Scan a document:**
   - Navigate to file explorer
   - Tap FAB (+) → Scan document
   - Capture a page with clear text (e.g., a book page, printed document)
   - Tap "Done"

2. **Verify OCR:**
   - OCR preview should show extracted text
   - Check text accuracy
   - Tap "Save"

3. **Wait for upload:**
   - "Creating PDF..." dialog appears
   - "Uploading to Drive..." dialog appears
   - Success message shown

4. **Open the PDF:**
   - Find the scanned file in file list
   - Tap to open
   - PDF should display the scanned image

5. **Test search:**
   - In PDF viewer, use search function
   - Search for a word you know is in the document
   - Word should be found (even though text is invisible)

### Test 2: Multi-Page Scan

1. **Scan multiple pages:**
   - Tap FAB (+) → Scan document
   - Capture 2-3 pages
   - Tap "Done"

2. **Verify OCR:**
   - Preview should show all pages
   - Each page should have extracted text
   - Tap "Save"

3. **Open the PDF:**
   - PDF should have multiple pages
   - Swipe to navigate between pages
   - Each page should show correct image

4. **Test search across pages:**
   - Search for text from page 1
   - Search for text from page 2
   - Both should be found

### Test 3: Image Quality

1. **Scan a detailed document:**
   - Use a document with small text or fine details
   - Capture the image
   - Save as PDF

2. **Check quality:**
   - Open PDF
   - Zoom in on the image
   - Text should be clear and readable
   - No excessive pixelation

### Test 4: Gallery Import

1. **Use existing images:**
   - Tap FAB (+) → Scan document
   - Tap gallery icon
   - Select an image with text
   - Tap "Done"

2. **Verify:**
   - OCR should extract text from gallery image
   - PDF should be created successfully

### Expected Console Output

When everything works correctly, you should see:

```
🔵 _processAndSave called with X images
🔵 Getting services from context...
🔵 Showing processing dialog...
🔵 Starting OCR processing...
🔵 OCR processing complete: true
🔵 Showing OCR preview...
🔵 User chose to save: true
🔵 Creating searchable PDF: Scanned_xxxxx.pdf
🔵 Creating searchable PDF...
🔵 PDF created: /path/to/temp/Scanned_xxxxx.pdf
🔵 Uploading PDF to Drive...
🔵 Upload complete, caching metadata...
```

### Common Issues

#### PDF is empty/blank
- Check console for errors
- Verify images were captured correctly
- Check if PDF creation step completed

#### Can't search text in PDF
- Verify OCR extracted text (check preview)
- Try searching for exact words from document
- Check PDF viewer supports text search

#### Upload fails
- Check network connectivity
- Verify Drive permissions
- Check backend is accessible

#### Poor OCR quality
- Ensure good lighting when capturing
- Keep camera steady
- Use high contrast documents (black text on white)

### Success Criteria

✅ PDF file created (not just image)
✅ PDF opens in viewer
✅ Image quality is good
✅ Text is searchable (even though invisible)
✅ Multi-page PDFs work correctly
✅ File uploads to Drive successfully
✅ File appears in file list

### File Verification

Check the uploaded file:
1. File extension should be `.pdf`
2. File size should be reasonable (200KB - 2MB depending on pages)
3. File should open in any PDF reader
4. Metadata should show it's a PDF document

### Advanced Testing

#### Test with Different Content
- Handwritten text (may have lower accuracy)
- Printed text (should have high accuracy)
- Mixed content (text + images)
- Different languages (if language data installed)

#### Test Edge Cases
- Very long documents (10+ pages)
- Low light images
- Blurry images
- Tilted/skewed images

#### Performance Testing
- Time to create PDF
- Time to upload
- File size vs quality
- Memory usage

### Debugging

If something doesn't work:

1. **Check console output** - Look for 🔵 and ❌ messages
2. **Check backend logs** - Verify OCR processing
3. **Check file system** - Verify PDF was created in temp directory
4. **Check Drive** - Verify file was uploaded
5. **Check PDF content** - Open PDF in external viewer

### Sample Test Document

For consistent testing, use a document with:
- Clear, printed text
- Good contrast (black on white)
- Standard font size (12pt+)
- No handwriting
- Good lighting
- Flat surface (no curves/wrinkles)

Example text to search for:
- Common words: "the", "and", "is"
- Specific words from your document
- Numbers if present
- Proper nouns

### Success!

If all tests pass:
✅ Searchable PDF generation is working
✅ OCR text is properly embedded
✅ Multi-page support is functional
✅ Upload and caching work correctly
✅ Feature is production-ready!

## Next Steps

After successful testing:
1. Test with real-world documents
2. Test on different devices
3. Test with different network conditions
4. Gather user feedback
5. Monitor file sizes and performance
6. Consider implementing future improvements (see PDF_GENERATION_FIX.md)
