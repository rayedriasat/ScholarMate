# Manual Citation Feature

## Overview
Added a Manual Citation entry option to the Citation Generator, allowing users to manually input citation details for any source type (similar to Grammarly's citation tool).

## Location
Inside the Citation Generator screen, accessible via two tabs:
- **Auto Tab**: Existing automatic citation generation from DOI, ISBN, PubMed ID, arXiv ID, or URL
- **Manual Tab**: New manual entry form for custom citations

## Features

### Source Types Supported
1. **Journal Article** - Title, Authors, Journal Name, Volume, Issue, Year, Pages, DOI
2. **Book** - Title, Authors/Editors, Publisher, Year, ISBN
3. **Website** - Page Title, Authors, Website Name, URL, Access Date, Year
4. **Conference Paper** - Title, Authors, Conference Name, Year, Pages, DOI
5. **Thesis/Dissertation** - Title, Authors, Institution, Year, URL
6. **Report** - Title, Authors, Institution/Organization, Year, URL
7. **Newspaper Article** - Title, Authors, Newspaper Name, Year, Pages, URL
8. **Other** - Title, Authors, Publisher/Source, Year, URL

### Dynamic Form Fields
- Form fields change based on selected source type
- Required fields marked with asterisk (*)
- Input validation for required fields
- Year validation (must be between 1000 and current year + 1)

### User Actions
- **Clear Button**: Clears all form fields and resets the form
- **Generate Citations Button**: Generates formatted citations in APA, MLA, Chicago, and BibTeX formats
- **Copy to Clipboard**: Each generated citation includes a copy icon for easy copying

### UI/UX Features
- Clean, minimal design with Material Design 3 components
- Scrollable form for long content
- Icon-based visual cues for different field types
- Error messages displayed in colored cards
- Loading states during citation generation
- Tab-based navigation between Auto and Manual modes

## Technical Implementation

### Files Modified
- `frontend/lib/screens/citation_generator_screen.dart`

### Key Components
1. **TabController**: Manages switching between Auto and Manual tabs
2. **Dynamic Form Builder**: `_buildManualFormFields()` generates appropriate fields based on source type
3. **Manual Citation Generator**: `_generateManualCitation()` converts form input to PDFMetadata and generates citations
4. **Form Validation**: Ensures required fields are filled before generation

### Backend Integration
Uses existing `MetadataService.generateCitationFromMetadata()` method to generate citations from manually entered metadata.

## Usage Example

1. Open Citation Generator from the app
2. Switch to "Manual" tab
3. Select source type (e.g., "Journal Article")
4. Fill in required fields:
   - Title: "Machine Learning in Healthcare"
   - Authors: "John Smith, Jane Doe"
   - Journal Name: "Nature Medicine"
   - Volume: "28"
   - Issue: "3"
   - Year: "2024"
   - Pages: "123-145"
   - DOI: "10.1234/example"
5. Click "Generate Citations"
6. Copy desired citation format using the copy icon

## Benefits
- No need for DOI or other identifiers
- Supports sources without digital identifiers
- Flexible for various source types
- User-friendly interface
- Consistent with existing citation generator design
