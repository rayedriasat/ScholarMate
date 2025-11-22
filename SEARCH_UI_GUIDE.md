# Advanced Search - UI Guide

## Visual Walkthrough

### 1. Accessing Search

**From File Explorer:**
```
┌─────────────────────────────────────┐
│  Files                    🔍 🔄 📊  │ ← Tap search icon
├─────────────────────────────────────┤
│                                     │
│  📁 Research Papers                 │
│  📄 Machine Learning.pdf            │
│  📄 Neural Networks.pdf             │
│                                     │
└─────────────────────────────────────┘
```

### 2. Search Screen - Empty State

```
┌─────────────────────────────────────┐
│  ← Advanced Search                  │
├─────────────────────────────────────┤
│  ┌───────────────────────────────┐  │
│  │ 🔍 Search files and content...│  │
│  └───────────────────────────────┘  │
│                                     │
│  ☑ Include content search           │
│  Semantic search in documents       │
│                                     │
│                    [Search]         │
├─────────────────────────────────────┤
│                                     │
│           🔍                        │
│                                     │
│    Enter a search query to          │
│         find files                  │
│                                     │
│  Search by filename, keywords,      │
│         or phrases                  │
│                                     │
└─────────────────────────────────────┘
```

### 3. Search Screen - With Query

```
┌─────────────────────────────────────┐
│  ← Advanced Search                  │
├─────────────────────────────────────┤
│  ┌───────────────────────────────┐  │
│  │ machine learning          ✕   │  │
│  └───────────────────────────────┘  │
│                                     │
│  ☑ Include content search           │
│  Semantic search in documents       │
│                                     │
│                    [Search]         │
└─────────────────────────────────────┘
```

### 4. Search Results

```
┌─────────────────────────────────────┐
│  ← Advanced Search                  │
├─────────────────────────────────────┤
│  ┌───────────────────────────────┐  │
│  │ machine learning          ✕   │  │
│  └───────────────────────────────┘  │
│                                     │
│  ☑ Include content search           │
│                    [Search]         │
├─────────────────────────────────────┤
│  15 results                  245ms  │
├─────────────────────────────────────┤
│  ┌─────────────────────────────┐   │
│  │ 📄 Machine Learning.pdf     │   │
│  │ [EXACT] ████████████ 100%   │   │
│  │                             │   │
│  │ Exact match: Machine        │   │
│  │ Learning.pdf                │   │
│  │                             │   │
│  │ 💾 2.5 MB                   │   │
│  └─────────────────────────────┘   │
│                                     │
│  ┌─────────────────────────────┐   │
│  │ 📄 Introduction to ML.pdf   │   │
│  │ [SEMANTIC] ██████░░░ 75%    │   │
│  │ Page 5                      │   │
│  │                             │   │
│  │ Machine learning is a       │   │
│  │ subset of artificial        │   │
│  │ intelligence that...        │   │
│  │                             │   │
│  │ 💾 1.8 MB                   │   │
│  └─────────────────────────────┘   │
│                                     │
│  ┌─────────────────────────────┐   │
│  │ 📄 Deep Learning Paper.pdf  │   │
│  │ [PARTIAL] ████████░░ 80%    │   │
│  │                             │   │
│  │ Partial match: Deep         │   │
│  │ Learning Paper.pdf          │   │
│  │                             │   │
│  │ 💾 3.2 MB                   │   │
│  └─────────────────────────────┘   │
│                                     │
└─────────────────────────────────────┘
```

### 5. No Results State

```
┌─────────────────────────────────────┐
│  ← Advanced Search                  │
├─────────────────────────────────────┤
│  ┌───────────────────────────────┐  │
│  │ quantum physics           ✕   │  │
│  └───────────────────────────────┘  │
│                                     │
│  ☑ Include content search           │
│                    [Search]         │
├─────────────────────────────────────┤
│  0 results                   123ms  │
├─────────────────────────────────────┤
│                                     │
│           🔍                        │
│                                     │
│       No results found              │
│                                     │
│  Try different keywords or          │
│   enable content search             │
│                                     │
└─────────────────────────────────────┘
```

### 6. Loading State

```
┌─────────────────────────────────────┐
│  ← Advanced Search                  │
├─────────────────────────────────────┤
│  ┌───────────────────────────────┐  │
│  │ neural networks           ✕   │  │
│  └───────────────────────────────┘  │
│                                     │
│  ☑ Include content search           │
│                [Searching...]       │
├─────────────────────────────────────┤
│                                     │
│             ⏳                      │
│                                     │
│         Searching...                │
│                                     │
└─────────────────────────────────────┘
```

### 7. Error State

```
┌─────────────────────────────────────┐
│  ← Advanced Search                  │
├─────────────────────────────────────┤
│  ┌───────────────────────────────┐  │
│  │ test query                ✕   │  │
│  └───────────────────────────────┘  │
│                                     │
│  ☑ Include content search           │
│                    [Search]         │
├─────────────────────────────────────┤
│                                     │
│             ⚠️                      │
│                                     │
│    Search failed: Network error     │
│                                     │
│           [Retry]                   │
│                                     │
└─────────────────────────────────────┘
```

## UI Components

### Search Input

**Features:**
- Placeholder text: "Search files and content..."
- Search icon (🔍) on left
- Clear button (✕) on right (when text entered)
- Submit on Enter key
- Auto-focus on screen open

### Options Toggle

**Include content search:**
- ☑ Enabled: Searches both filenames and content
- ☐ Disabled: Searches filenames only (faster)
- Subtitle: "Semantic search in documents"

### Search Button

**States:**
- Normal: "Search" with search icon
- Loading: "Searching..." with spinner
- Disabled: When query is empty

### Results Header

**Shows:**
- Result count: "15 results"
- Search time: "245ms"
- Background color to separate from results

### Result Card

**Layout:**
```
┌─────────────────────────────────┐
│ 📄 File Name                    │
│ [MATCH TYPE] ████████░░ 85%     │
│ Page 5                          │
│                                 │
│ ┌─────────────────────────────┐ │
│ │ Content snippet showing     │ │
│ │ matched text from the       │ │
│ │ document...                 │ │
│ └─────────────────────────────┘ │
│                                 │
│ 💾 2.5 MB                       │
└─────────────────────────────────┘
```

**Components:**
1. **File Icon** - Based on MIME type
2. **File Name** - Bold, 2 lines max
3. **Match Type Badge** - Color-coded
4. **Relevance Bar** - Progress indicator + percentage
5. **Page Number** - For content matches
6. **Snippet Box** - Light background, 3 lines max
7. **Metadata** - File size, date

### Match Type Badges

**Colors:**
```
[EXACT]     - Green background
[PARTIAL]   - Blue background
[SEMANTIC]  - Purple background
[FUZZY]     - Orange background
```

**Style:**
- Small caps text
- Rounded corners
- Border with matching color
- Transparent background

### Relevance Indicator

**Progress Bar:**
- Width: 60px
- Height: 4px
- Filled portion shows relevance
- Color based on score:
  - 80-100%: Green
  - 60-79%: Blue
  - 40-59%: Orange
  - 0-39%: Grey

**Percentage:**
- Small text next to bar
- Shows exact score

### File Icons

**By Type:**
- 📄 PDF: `Icons.picture_as_pdf`
- 🖼️ Image: `Icons.image`
- 📝 Text: `Icons.description`
- 📁 Other: `Icons.insert_drive_file`

### Empty States

**No Query:**
- Large search icon
- Primary text: "Enter a search query to find files"
- Secondary text: "Search by filename, keywords, or phrases"

**No Results:**
- Search-off icon
- Primary text: "No results found"
- Secondary text: "Try different keywords or enable content search"

**Error:**
- Error icon (red)
- Error message
- Retry button

## Color Scheme

### Light Mode

**Background:**
- Screen: White
- Search bar: Light grey
- Result cards: White with shadow
- Snippet box: Very light grey

**Text:**
- Primary: Dark grey/black
- Secondary: Medium grey
- Disabled: Light grey

**Accents:**
- Primary: Blue
- Success: Green
- Warning: Orange
- Error: Red

### Dark Mode

**Background:**
- Screen: Dark grey
- Search bar: Darker grey
- Result cards: Dark grey with subtle border
- Snippet box: Slightly lighter grey

**Text:**
- Primary: White
- Secondary: Light grey
- Disabled: Medium grey

**Accents:**
- Primary: Light blue
- Success: Light green
- Warning: Light orange
- Error: Light red

## Interactions

### Tap Actions

**Search Input:**
- Tap → Focus and show keyboard
- Type → Update text
- Enter → Perform search
- Clear button → Clear text

**Toggle:**
- Tap → Toggle semantic search on/off

**Search Button:**
- Tap → Perform search
- Disabled when query empty

**Result Card:**
- Tap → Open file in PDF Viewer
- Navigate to specific page if available

### Gestures

**Scroll:**
- Vertical scroll through results
- Pull to refresh (future)

**Swipe:**
- Back gesture → Return to Files

## Responsive Design

### Mobile (< 600px)

- Full-width search bar
- Stacked layout
- Larger touch targets
- Simplified metadata

### Tablet (600-1200px)

- Wider search bar
- More metadata visible
- Larger result cards

### Desktop (> 1200px)

- Centered search bar (max width)
- Grid layout for results (future)
- Hover effects
- Keyboard shortcuts

## Accessibility

**Screen Reader:**
- Labeled search input
- Announced result count
- Described match types
- Readable snippets

**Keyboard Navigation:**
- Tab through elements
- Enter to search
- Arrow keys in results (future)

**High Contrast:**
- Clear borders
- Sufficient color contrast
- Visible focus indicators

## Animation

**Transitions:**
- Fade in results: 200ms
- Loading spinner: Continuous
- Card tap: Scale 0.95 → 1.0

**States:**
- Smooth loading → results
- Smooth empty → results
- Smooth error → retry

## Best Practices

**Do:**
- ✓ Show loading state immediately
- ✓ Display search time
- ✓ Highlight match types
- ✓ Show relevant snippets
- ✓ Provide clear error messages

**Don't:**
- ✗ Search on every keystroke (too many requests)
- ✗ Hide search options
- ✗ Show raw error messages
- ✗ Truncate file names too aggressively

## Future UI Enhancements

**Planned:**
- [ ] Search suggestions as you type
- [ ] Recent searches dropdown
- [ ] Filter chips (file type, date)
- [ ] Sort dropdown (relevance, date, name)
- [ ] Grid view option
- [ ] Bulk actions on results
- [ ] Share search results
- [ ] Save search button

---

This UI guide provides a complete visual reference for the Advanced Search feature. The design prioritizes clarity, speed, and ease of use while maintaining consistency with the rest of ScholarMate.
