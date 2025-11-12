# Citation & Metadata - UI Flow Guide

## 🎨 User Interface Flow

### Feature 1: File Metadata Sidebar

```
┌─────────────────────────────────────────────────────────────────┐
│ PDF Viewer                                          [ℹ] [≡]     │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌─────────────────────────┐  ┌──────────────────────────────┐ │
│  │                         │  │  ℹ File Metadata        [×]  │ │
│  │                         │  ├──────────────────────────────┤ │
│  │                         │  │                              │ │
│  │   PDF Content           │  │  Title                       │ │
│  │                         │  │  ┌────────────────────┐ [📋] │ │
│  │                         │  │  │ Research Paper...  │      │ │
│  │                         │  │  └────────────────────┘      │ │
│  │                         │  │                              │ │
│  │                         │  │  Authors                     │ │
│  │                         │  │  • John Doe          [📋]    │ │
│  │                         │  │  • Jane Smith        [📋]    │ │
│  │                         │  │                              │ │
│  │                         │  │  Publication Year            │ │
│  │                         │  │  ┌────────────────────┐ [📋] │ │
│  │                         │  │  │ 2023               │      │ │
│  │                         │  │  └────────────────────┘      │ │
│  │                         │  │                              │ │
│  │                         │  │  Journal                     │ │
│  │                         │  │  ┌────────────────────┐ [📋] │ │
│  │                         │  │  │ Nature             │      │ │
│  │                         │  │  └────────────────────┘      │ │
│  │                         │  │                              │ │
│  │                         │  │  DOI                         │ │
│  │                         │  │  ┌────────────────────┐ [📋] │ │
│  │                         │  │  │ 10.1234/example    │      │ │
│  │                         │  │  └────────────────────┘      │ │
│  │                         │  │                              │ │
│  │                         │  │  Abstract                    │ │
│  │                         │  │  ┌────────────────────────┐  │ │
│  │                         │  │  │ This paper presents... │  │ │
│  │                         │  │  │ ...                    │  │ │
│  │                         │  │  └────────────────────────┘  │ │
│  │                         │  │                    [Copy]    │ │
│  │                         │  │                              │ │
│  │                         │  │  Keywords                    │ │
│  │                         │  │  [AI] [ML] [Research]        │ │
│  │                         │  │                              │ │
│  └─────────────────────────┘  └──────────────────────────────┘ │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
```

**User Flow**:
1. User opens PDF file
2. Clicks info icon (ℹ) in toolbar
3. Sidebar slides in from right
4. Metadata automatically extracted and displayed
5. User can copy individual fields
6. Click [×] to close sidebar

---

### Feature 2: Citation Generator

#### Step 1: Access Citation Generator

```
┌─────────────────────────────────────────────────────────────────┐
│ Home Screen                                                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │              │  │              │  │              │          │
│  │   📄 Files   │  │   🔍 Search  │  │   💬 AI Chat │          │
│  │              │  │              │  │              │          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
│                                                                   │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │              │  │              │  │              │          │
│  │   📝 Notes   │  │   🏷️ Tags    │  │   📖 Citation│          │
│  │              │  │              │  │   Generator  │ ← Click  │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
```

#### Step 2: Enter Identifier

```
┌─────────────────────────────────────────────────────────────────┐
│ ← Citation Generator                                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │ ℹ Generate formatted citations from DOI, ISBN, PubMed ID,   ││
│  │   arXiv ID, or URL                                           ││
│  └─────────────────────────────────────────────────────────────┘│
│                                                                   │
│  Identifier Type                                                  │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │ DOI                                                      [▼] ││
│  └─────────────────────────────────────────────────────────────┘│
│                                                                   │
│  DOI                                                              │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │ 10.1038/nature12345                                          ││
│  └─────────────────────────────────────────────────────────────┘│
│                                                                   │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │           ✨ Generate Citations                              ││
│  └─────────────────────────────────────────────────────────────┘│
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
```

#### Step 3: View Generated Citations

```
┌─────────────────────────────────────────────────────────────────┐
│ ← Citation Generator                                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  Generated Citations                                              │
│                                                                   │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │ 📄 Source Information                                        ││
│  ├─────────────────────────────────────────────────────────────┤│
│  │ Title:    Example Research Paper                            ││
│  │ Authors:  John Doe et al.                                   ││
│  │ Year:     2023                                              ││
│  │ Journal:  Nature                                            ││
│  │ DOI:      10.1038/nature12345                               ││
│  └─────────────────────────────────────────────────────────────┘│
│                                                                   │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │ " APA                                                   [📋] ││
│  ├─────────────────────────────────────────────────────────────┤│
│  │ ┌─────────────────────────────────────────────────────────┐ ││
│  │ │ Doe, J., Smith, J., & Brown, A. (2023). Example         │ ││
│  │ │ Research Paper. Nature, 123(4), 567-890.                │ ││
│  │ │ https://doi.org/10.1038/nature12345                     │ ││
│  │ └─────────────────────────────────────────────────────────┘ ││
│  └─────────────────────────────────────────────────────────────┘│
│                                                                   │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │ " MLA                                                   [📋] ││
│  ├─────────────────────────────────────────────────────────────┤│
│  │ ┌─────────────────────────────────────────────────────────┐ ││
│  │ │ Doe, John. "Example Research Paper." Nature, vol. 123,  │ ││
│  │ │ no. 4, 2023, pp. 567-890. doi:10.1038/nature12345.      │ ││
│  │ └─────────────────────────────────────────────────────────┘ ││
│  └─────────────────────────────────────────────────────────────┘│
│                                                                   │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │ " Chicago                                               [📋] ││
│  ├─────────────────────────────────────────────────────────────┤│
│  │ ┌─────────────────────────────────────────────────────────┐ ││
│  │ │ Doe, John. "Example Research Paper." Nature 123, no. 4  │ ││
│  │ │ (2023): 567-890. https://doi.org/10.1038/nature12345.   │ ││
│  │ └─────────────────────────────────────────────────────────┘ ││
│  └─────────────────────────────────────────────────────────────┘│
│                                                                   │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │ </> BibTeX                                              [📋] ││
│  ├─────────────────────────────────────────────────────────────┤│
│  │ ┌─────────────────────────────────────────────────────────┐ ││
│  │ │ @article{doe2023,                                        │ ││
│  │ │   title = {Example Research Paper},                     │ ││
│  │ │   author = {John Doe and Jane Smith and Alice Brown},   │ ││
│  │ │   journal = {Nature},                                   │ ││
│  │ │   volume = {123},                                       │ ││
│  │ │   number = {4},                                         │ ││
│  │ │   pages = {567-890},                                    │ ││
│  │ │   year = {2023},                                        │ ││
│  │ │   doi = {10.1038/nature12345},                          │ ││
│  │ │ }                                                        │ ││
│  │ └─────────────────────────────────────────────────────────┘ ││
│  └─────────────────────────────────────────────────────────────┘│
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
```

---

## 📱 Mobile Layout

### Metadata Bottom Sheet (Mobile)

```
┌─────────────────────────────────┐
│ PDF Viewer              [ℹ] [≡] │
├─────────────────────────────────┤
│                                 │
│                                 │
│      PDF Content                │
│                                 │
│                                 │
│                                 │
│                                 │
│                                 │
│                                 │
│                                 │
│                                 │
├─────────────────────────────────┤ ← Swipe up
│ ═══                             │
│ ℹ File Metadata                 │
├─────────────────────────────────┤
│                                 │
│ Title                           │
│ ┌─────────────────────────┐[📋]│
│ │ Research Paper...       │    │
│ └─────────────────────────┘    │
│                                 │
│ Authors                         │
│ • John Doe              [📋]   │
│ • Jane Smith            [📋]   │
│                                 │
│ Publication Year                │
│ ┌─────────────────────────┐[📋]│
│ │ 2023                    │    │
│ └─────────────────────────┘    │
│                                 │
│ [Scroll for more...]            │
│                                 │
└─────────────────────────────────┘
```

---

## 🎯 Interaction Patterns

### 1. Copy to Clipboard

```
User clicks [📋] button
     ↓
Text copied to clipboard
     ↓
Snackbar appears:
┌─────────────────────────────────┐
│ ✓ APA citation copied           │
└─────────────────────────────────┘
```

### 2. Loading State

```
User clicks "Generate Citations"
     ↓
Button shows loading:
┌─────────────────────────────────┐
│  ⟳ Generating...                │
└─────────────────────────────────┘
     ↓
Citations appear (1-3 seconds)
```

### 3. Error Handling

```
Invalid identifier entered
     ↓
Error card appears:
┌─────────────────────────────────┐
│ ⚠ Could not generate citation.  │
│   Please check the identifier.  │
└─────────────────────────────────┘
```

---

## 🔄 Complete User Journey

### Journey 1: View PDF Metadata

```
1. User uploads PDF
   └─> File appears in file list

2. User clicks on PDF
   └─> PDF viewer opens

3. User clicks info icon (ℹ)
   └─> Sidebar slides in
   └─> Loading indicator appears
   └─> Metadata extracted and displayed

4. User reads metadata
   └─> Finds DOI: 10.1234/example

5. User clicks copy button next to DOI
   └─> DOI copied to clipboard
   └─> Snackbar confirms: "DOI copied"

6. User closes sidebar
   └─> Sidebar slides out
```

### Journey 2: Generate Citation

```
1. User navigates to Citation Generator
   └─> From home screen or menu

2. User selects identifier type
   └─> Dropdown shows: DOI, arXiv, ISBN, PMID, URL
   └─> User selects "DOI"

3. User enters DOI
   └─> Types: 10.1038/nature12345

4. User clicks "Generate Citations"
   └─> Button shows loading state
   └─> API fetches metadata (1-2 seconds)
   └─> Citations generated

5. User views all citation formats
   └─> APA, MLA, Chicago, BibTeX

6. User copies APA citation
   └─> Clicks [📋] button
   └─> Citation copied to clipboard
   └─> Snackbar: "APA citation copied"

7. User pastes into document
   └─> Citation ready to use!
```

### Journey 3: Quick Citation from PDF

```
1. User opens PDF with metadata
   └─> PDF viewer opens

2. User clicks info icon
   └─> Metadata sidebar opens
   └─> DOI visible: 10.1234/example

3. User right-clicks on DOI
   └─> Context menu appears
   └─> "Generate Citation" option

4. User clicks "Generate Citation"
   └─> Navigates to Citation Generator
   └─> DOI pre-filled
   └─> Citations auto-generated

5. User copies desired format
   └─> Ready to use!
```

---

## 🎨 Visual States

### Metadata Sidebar States

```
┌─────────────────────┐  ┌─────────────────────┐  ┌─────────────────────┐
│ Loading             │  │ Success             │  │ Error               │
├─────────────────────┤  ├─────────────────────┤  ├─────────────────────┤
│                     │  │                     │  │                     │
│        ⟳            │  │ Title               │  │        ⚠            │
│   Loading...        │  │ ┌─────────────┐[📋] │  │ Failed to load      │
│                     │  │ │ Paper...    │     │  │ metadata            │
│                     │  │ └─────────────┘     │  │                     │
│                     │  │                     │  │  [Retry]            │
│                     │  │ Authors             │  │                     │
└─────────────────────┘  │ • John Doe    [📋]  │  └─────────────────────┘
                         │                     │
                         └─────────────────────┘
```

### Citation Generator States

```
┌─────────────────────┐  ┌─────────────────────┐  ┌─────────────────────┐
│ Empty               │  │ Loading             │  │ Success             │
├─────────────────────┤  ├─────────────────────┤  ├─────────────────────┤
│                     │  │                     │  │                     │
│ Type: [DOI     ▼]   │  │ Type: [DOI     ▼]   │  │ Generated Citations │
│                     │  │                     │  │                     │
│ DOI:                │  │ DOI:                │  │ 📄 Source Info      │
│ ┌─────────────────┐ │  │ ┌─────────────────┐ │  │ Title: Paper...     │
│ │                 │ │  │ │ 10.1234/example │ │  │ Authors: Doe et al. │
│ └─────────────────┘ │  │ └─────────────────┘ │  │                     │
│                     │  │                     │  │ " APA          [📋] │
│ [Generate]          │  │ [⟳ Generating...]   │  │ ┌─────────────────┐ │
│                     │  │                     │  │ │ Doe, J. (2023)..│ │
└─────────────────────┘  └─────────────────────┘  │ └─────────────────┘ │
                                                   │                     │
                                                   │ " MLA          [📋] │
                                                   └─────────────────────┘
```

---

## 🎯 Key UI Elements

### Icons Used
- ℹ (Info) - Metadata sidebar toggle
- 📋 (Copy) - Copy to clipboard
- " (Quote) - Citation formats
- </> (Code) - BibTeX format
- ✨ (Sparkles) - Generate action
- ⟳ (Loading) - Loading state
- ⚠ (Warning) - Error state
- ✓ (Check) - Success state
- × (Close) - Close sidebar
- ▼ (Dropdown) - Select menu

### Color Coding
- **Primary** - Action buttons, active states
- **Success** - Confirmation messages
- **Error** - Error messages, warnings
- **Surface** - Content containers
- **Background** - Main background

---

## 📐 Responsive Breakpoints

```
Mobile (< 600px)
├─ Bottom sheet for metadata
├─ Full-width citation generator
└─ Stacked layout

Tablet (600px - 1024px)
├─ Sidebar for metadata (320px)
├─ Two-column citation generator
└─ Side-by-side layout

Desktop (> 1024px)
├─ Sidebar for metadata (320px)
├─ Wide citation generator
└─ Optimized spacing
```

---

## 🎬 Animation Timing

```
Sidebar slide in/out:    300ms ease-in-out
Button press:            100ms ease
Loading spinner:         1000ms infinite
Snackbar appear:         200ms ease-in
Snackbar disappear:      200ms ease-out
Card expand:             250ms ease
```

This visual guide helps developers understand the complete UI flow and interaction patterns for both features!
