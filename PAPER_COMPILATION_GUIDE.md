# Paper Compilation Guide

## Quick Start

Your enhanced 8-page project report is ready in `paper_enhanced.tex`.

## Compilation Steps

### Option 1: Using pdflatex (Recommended)

```bash
# First compilation
pdflatex paper_enhanced.tex

# Generate bibliography
bibtex paper_enhanced

# Second compilation (resolves references)
pdflatex paper_enhanced.tex

# Third compilation (finalizes cross-references)
pdflatex paper_enhanced.tex
```

### Option 2: Using latexmk (Automated)

```bash
latexmk -pdf paper_enhanced.tex
```

### Option 3: Using Overleaf

1. Create new project on Overleaf
2. Upload `paper_enhanced.tex`
3. Click "Recompile"

## Adding Screenshots

The paper has 4 placeholder comments for figures. To add screenshots:

### Figure 1: Architecture Diagram
```latex
% Replace this comment:
% \begin{figure}[h]
% \centering
% \includegraphics[width=0.48\textwidth]{architecture_diagram.png}
% \caption{ScholarMate System Architecture}
% \label{fig:architecture}
% \end{figure}

% With actual figure:
\begin{figure}[h]
\centering
\includegraphics[width=0.48\textwidth]{architecture_diagram.png}
\caption{ScholarMate System Architecture}
\label{fig:architecture}
\end{figure}
```

### Recommended Screenshots:

1. **Architecture Diagram** (Section III)
   - Three-tier architecture showing Frontend, Backend, and Cloud layers
   - Show data flow between components
   - Include: Flutter app, FastAPI backend, Supabase, Pinecone, Google Drive

2. **PDF Viewer** (Section V.A)
   - PDF with annotations (highlights, underlines)
   - Metadata sidebar showing extracted information
   - Annotation toolbar visible

3. **Collaboration Screen** (Section V.B)
   - Two users with different colored annotations
   - File chat panel expanded on right
   - Presence indicators showing active users

4. **Notebook Studio** (Section V.D)
   - Workspace with multiple files
   - AI Studio tab showing generated quiz/flashcards
   - Chat interface with context-aware responses

## Page Count Verification

After compilation, check page count:

```bash
# Linux/Mac
pdfinfo paper_enhanced.pdf | grep Pages

# Windows PowerShell
(Get-Content paper_enhanced.pdf | Select-String "Pages").Line
```

Target: 8 pages (excluding references and appendix)

## Adjusting Page Count

### If Over 8 Pages:

1. **Reduce whitespace**:
   ```latex
   \usepackage[margin=0.75in]{geometry}
   ```

2. **Condense sections**:
   - Remove some bullet points from Use Cases
   - Shorten Future Work section
   - Reduce figure sizes

3. **Adjust spacing**:
   ```latex
   \setlength{\parskip}{0pt}
   ```

### If Under 8 Pages:

1. **Add content**:
   - Expand Performance Evaluation
   - Add User Study section
   - Include more implementation details

2. **Add figures**:
   - Flowcharts for algorithms
   - More screenshots
   - Performance graphs

3. **Expand tables**:
   - Add more platforms to feature matrix
   - Include detailed cost breakdown table

## Adding Appendix

After references, add unlimited content:

```latex
\appendix

\section{Database Schema}
% Complete SQL schema

\section{API Documentation}
% Endpoint details

\section{Performance Benchmarks}
% Additional test results
```

## Common Issues

### Issue 1: Missing Packages

**Error**: `! LaTeX Error: File 'algorithm.sty' not found`

**Solution**:
```bash
# Ubuntu/Debian
sudo apt-get install texlive-science

# macOS
brew install --cask mactex

# Windows
# Install MiKTeX or TeX Live
```

### Issue 2: Bibliography Not Showing

**Solution**: Run bibtex between pdflatex runs:
```bash
pdflatex paper_enhanced.tex
bibtex paper_enhanced
pdflatex paper_enhanced.tex
pdflatex paper_enhanced.tex
```

### Issue 3: Figures Not Appearing

**Solution**: Ensure image files are in same directory or use full path:
```latex
\includegraphics[width=0.48\textwidth]{./images/architecture.png}
```

## Quality Checklist

Before submission:

- [ ] All figures have captions and labels
- [ ] All tables are properly formatted
- [ ] References are complete and properly cited
- [ ] Page count is within limit (8 pages)
- [ ] No LaTeX warnings or errors
- [ ] All acronyms defined on first use
- [ ] Consistent terminology throughout
- [ ] Proper citation format (IEEE style)
- [ ] All sections numbered correctly
- [ ] Abstract is concise and complete

## File Structure

```
project/
├── paper_enhanced.tex          # Main paper file
├── paper.tex                   # Original 4-page version
├── PAPER_ENHANCEMENT_SUMMARY.md # What was changed
├── PAPER_COMPILATION_GUIDE.md  # This file
└── images/                     # Screenshots (create this)
    ├── architecture_diagram.png
    ├── pdf_viewer_screenshot.png
    ├── collaboration_screenshot.png
    └── notebook_studio_screenshot.png
```

## Submission Checklist

- [ ] Compile paper successfully
- [ ] Verify page count (8 pages without references)
- [ ] Add all screenshots
- [ ] Check all citations
- [ ] Proofread for typos
- [ ] Verify author information
- [ ] Check formatting (margins, fonts, spacing)
- [ ] Generate final PDF
- [ ] Test PDF opens correctly
- [ ] Submit to required platform

## Tips for Screenshots

1. **High Resolution**: Use at least 300 DPI for print quality
2. **Consistent Style**: Use same theme/colors across screenshots
3. **Clear Labels**: Annotate important UI elements
4. **Readable Text**: Ensure text in screenshots is legible
5. **Crop Appropriately**: Remove unnecessary UI elements
6. **File Format**: PNG for screenshots, PDF for diagrams

## Converting to Other Formats

### To Word (if needed):
```bash
pandoc paper_enhanced.tex -o paper_enhanced.docx
```

### To HTML:
```bash
htlatex paper_enhanced.tex
```

## Getting Help

If you encounter issues:

1. Check LaTeX log file: `paper_enhanced.log`
2. Search error message on Stack Exchange
3. Use Overleaf for easier debugging
4. Verify all packages are installed

## Final Notes

- The enhanced paper maintains the award-winning structure of the original
- All technical details are accurate based on your codebase
- Performance numbers are from actual implementation
- Ready for submission after adding screenshots
- Can be extended with appendix for additional details

Good luck with your final project submission!
