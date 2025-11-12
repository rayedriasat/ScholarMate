# Citation & Metadata Feature - Deployment Checklist

## 📋 Pre-Deployment Checklist

### Backend Verification

- [ ] **Files Created**
  - [ ] `backend/app/models/metadata.py`
  - [ ] `backend/app/services/metadata_service.py`
  - [ ] `backend/app/routers/metadata.py`
  - [ ] `backend/app/main.py` (modified to include metadata router)

- [ ] **Backend Tests**
  - [ ] Start backend: `cd backend && uv run python run.py`
  - [ ] Check health: `curl http://localhost:8000/api/health`
  - [ ] View API docs: Open `http://localhost:8000/docs`
  - [ ] Verify metadata endpoints appear in Swagger UI
  - [ ] No Python errors in console

- [ ] **API Endpoint Tests**
  - [ ] POST `/api/metadata/extract` returns 200
  - [ ] POST `/api/metadata/citation/generate` returns 200
  - [ ] POST `/api/metadata/citation/from-metadata` returns 200
  - [ ] All endpoints require authentication (401 without token)

### Frontend Verification

- [ ] **Files Created**
  - [ ] `frontend/lib/models/pdf_metadata.dart`
  - [ ] `frontend/lib/services/metadata_service.dart`
  - [ ] `frontend/lib/widgets/file_metadata_sidebar.dart`
  - [ ] `frontend/lib/screens/citation_generator_screen.dart`

- [ ] **No Compilation Errors**
  - [ ] Run: `cd frontend && flutter analyze`
  - [ ] All files pass analysis
  - [ ] No errors or warnings

- [ ] **Provider Setup**
  - [ ] MetadataService added to Provider in `main.dart`
  - [ ] ProxyProvider depends on AuthService
  - [ ] getToken function returns valid JWT

### Integration Points

- [ ] **PDF Viewer Integration**
  - [ ] Metadata button added to PDF viewer toolbar
  - [ ] Button toggles sidebar visibility
  - [ ] Sidebar displays on right side (desktop)
  - [ ] Bottom sheet on mobile (optional)

- [ ] **Navigation Integration**
  - [ ] Citation Generator accessible from main menu
  - [ ] Or accessible from home screen
  - [ ] Or accessible from drawer
  - [ ] Navigation works correctly

### External API Access

- [ ] **Internet Connectivity**
  - [ ] Backend can access external APIs
  - [ ] CrossRef API accessible: `https://api.crossref.org`
  - [ ] arXiv API accessible: `http://export.arxiv.org`
  - [ ] Open Library API accessible: `https://openlibrary.org`
  - [ ] PubMed API accessible: `https://eutils.ncbi.nlm.nih.gov`

- [ ] **CORS Configuration**
  - [ ] Frontend URL added to backend CORS origins
  - [ ] CORS allows credentials
  - [ ] CORS allows all methods and headers

---

## 🧪 Testing Checklist

### Metadata Extraction Tests

- [ ] **Test with Various PDFs**
  - [ ] Academic paper with full metadata
  - [ ] PDF with minimal metadata
  - [ ] PDF with no metadata
  - [ ] Large PDF (> 10MB)
  - [ ] Small PDF (< 1MB)

- [ ] **UI Tests**
  - [ ] Sidebar opens when clicking info icon
  - [ ] Sidebar closes when clicking X
  - [ ] Loading indicator shows during extraction
  - [ ] Metadata displays correctly
  - [ ] All fields render properly
  - [ ] Copy buttons work for each field
  - [ ] Links are clickable (DOI, PMID, arXiv)

- [ ] **Error Handling**
  - [ ] Error message shows for failed extraction
  - [ ] Retry button works
  - [ ] Graceful handling of missing metadata
  - [ ] Non-PDF files show appropriate message

### Citation Generation Tests

- [ ] **Test All Identifier Types**
  - [ ] DOI: `10.1038/nature12345`
  - [ ] arXiv: `2301.12345`
  - [ ] ISBN: `978-0-262-03384-8`
  - [ ] PMID: `12345678`
  - [ ] URL with DOI: `https://doi.org/10.1234/example`
  - [ ] URL with arXiv: `https://arxiv.org/abs/2301.12345`

- [ ] **Citation Format Tests**
  - [ ] APA format generates correctly
  - [ ] MLA format generates correctly
  - [ ] Chicago format generates correctly
  - [ ] BibTeX format generates correctly
  - [ ] All formats are properly formatted
  - [ ] Copy buttons work for each format

- [ ] **UI Tests**
  - [ ] Dropdown shows all identifier types
  - [ ] Input field updates hint text
  - [ ] Generate button shows loading state
  - [ ] Source information displays
  - [ ] Citation cards render properly
  - [ ] Scrolling works for long citations

- [ ] **Error Handling**
  - [ ] Invalid identifier shows error
  - [ ] Network error shows error message
  - [ ] Timeout handled gracefully
  - [ ] Empty input shows validation error
  - [ ] API failure shows retry option

### Cross-Platform Tests

- [ ] **Desktop (Windows/Mac/Linux)**
  - [ ] Sidebar layout works
  - [ ] Proper width (320px)
  - [ ] Scrolling works
  - [ ] Copy to clipboard works

- [ ] **Web**
  - [ ] All features work in browser
  - [ ] CORS configured correctly
  - [ ] Clipboard API works
  - [ ] Responsive layout

- [ ] **Mobile (Android/iOS)**
  - [ ] Bottom sheet works (if implemented)
  - [ ] Touch interactions work
  - [ ] Scrolling smooth
  - [ ] Copy to clipboard works

- [ ] **Tablet**
  - [ ] Sidebar or bottom sheet works
  - [ ] Layout optimized
  - [ ] All interactions work

### Performance Tests

- [ ] **Metadata Extraction**
  - [ ] Completes in < 2 seconds
  - [ ] No UI blocking
  - [ ] Memory usage acceptable

- [ ] **Citation Generation**
  - [ ] Completes in < 5 seconds
  - [ ] Loading indicator shows
  - [ ] No UI blocking
  - [ ] Network timeout handled

- [ ] **UI Responsiveness**
  - [ ] Animations smooth (60fps)
  - [ ] No lag when opening sidebar
  - [ ] Scrolling smooth
  - [ ] Button presses responsive

### Security Tests

- [ ] **Authentication**
  - [ ] All endpoints require valid JWT
  - [ ] Invalid token returns 401
  - [ ] Expired token handled
  - [ ] No token returns 401

- [ ] **Authorization**
  - [ ] Users can only access their files
  - [ ] File ID validation works
  - [ ] No unauthorized access

- [ ] **Input Validation**
  - [ ] SQL injection prevented
  - [ ] XSS prevented
  - [ ] Invalid identifiers rejected
  - [ ] Malformed requests handled

---

## 🚀 Deployment Steps

### 1. Backend Deployment

- [ ] **Code Review**
  - [ ] All new files reviewed
  - [ ] No hardcoded credentials
  - [ ] Error handling complete
  - [ ] Logging configured

- [ ] **Environment Variables**
  - [ ] BACKEND_URL set correctly
  - [ ] CORS_ORIGINS includes production URL
  - [ ] LOG_LEVEL set appropriately
  - [ ] All required env vars set

- [ ] **Deploy Backend**
  - [ ] Push code to repository
  - [ ] Deploy to production server
  - [ ] Verify deployment successful
  - [ ] Check logs for errors

- [ ] **Verify Production Backend**
  - [ ] Health check: `https://your-backend.com/api/health`
  - [ ] API docs: `https://your-backend.com/docs`
  - [ ] Test metadata endpoint
  - [ ] Test citation endpoint

### 2. Frontend Deployment

- [ ] **Code Review**
  - [ ] All new files reviewed
  - [ ] No hardcoded values
  - [ ] Error handling complete
  - [ ] UI/UX polished

- [ ] **Configuration**
  - [ ] BACKEND_URL points to production
  - [ ] dart_defines.json updated
  - [ ] Build configuration correct

- [ ] **Build & Deploy**
  - [ ] Build for target platforms
  - [ ] Test builds locally
  - [ ] Deploy to production
  - [ ] Verify deployment successful

- [ ] **Verify Production Frontend**
  - [ ] App loads correctly
  - [ ] Login works
  - [ ] Metadata extraction works
  - [ ] Citation generation works
  - [ ] No console errors

### 3. Integration Verification

- [ ] **End-to-End Tests**
  - [ ] Upload PDF → View metadata
  - [ ] Generate citation from DOI
  - [ ] Copy citation to clipboard
  - [ ] All features work together

- [ ] **User Acceptance**
  - [ ] Test with real users
  - [ ] Gather feedback
  - [ ] Fix critical issues
  - [ ] Document known issues

---

## 📊 Monitoring Checklist

### Backend Monitoring

- [ ] **Logs**
  - [ ] Check for errors in logs
  - [ ] Monitor API response times
  - [ ] Track failed requests
  - [ ] Monitor external API calls

- [ ] **Metrics**
  - [ ] API endpoint usage
  - [ ] Average response time
  - [ ] Error rate
  - [ ] External API success rate

### Frontend Monitoring

- [ ] **Error Tracking**
  - [ ] Monitor crash reports
  - [ ] Track JavaScript errors
  - [ ] Monitor API failures
  - [ ] Track user feedback

- [ ] **Usage Analytics**
  - [ ] Track feature usage
  - [ ] Monitor user engagement
  - [ ] Identify popular citation formats
  - [ ] Track error patterns

---

## 📝 Documentation Checklist

- [ ] **User Documentation**
  - [ ] Feature announcement prepared
  - [ ] User guide created
  - [ ] Screenshots/videos prepared
  - [ ] FAQ updated

- [ ] **Developer Documentation**
  - [ ] API documentation complete
  - [ ] Integration guide available
  - [ ] Code examples provided
  - [ ] Architecture documented

- [ ] **Support Documentation**
  - [ ] Troubleshooting guide created
  - [ ] Common issues documented
  - [ ] Support team trained
  - [ ] Escalation process defined

---

## ✅ Final Verification

### Pre-Launch

- [ ] All tests passing
- [ ] No critical bugs
- [ ] Performance acceptable
- [ ] Security verified
- [ ] Documentation complete
- [ ] Team trained
- [ ] Rollback plan ready

### Launch

- [ ] Deploy backend
- [ ] Deploy frontend
- [ ] Verify production
- [ ] Monitor for issues
- [ ] Announce to users
- [ ] Gather feedback

### Post-Launch

- [ ] Monitor metrics
- [ ] Address issues quickly
- [ ] Collect user feedback
- [ ] Plan improvements
- [ ] Update documentation
- [ ] Celebrate success! 🎉

---

## 🐛 Known Issues & Limitations

### Current Limitations

- [ ] **Documented**
  - [ ] Citation generation requires internet
  - [ ] External API rate limits may apply
  - [ ] Some PDFs may have incomplete metadata
  - [ ] Limited to 4 citation formats

### Future Improvements

- [ ] Batch citation generation
- [ ] More citation formats
- [ ] Offline citation database
- [ ] Metadata editing
- [ ] Citation history
- [ ] Export to .bib files

---

## 📞 Support Contacts

### Technical Issues
- Backend: [Backend Team Contact]
- Frontend: [Frontend Team Contact]
- DevOps: [DevOps Team Contact]

### External APIs
- CrossRef: https://www.crossref.org/support/
- arXiv: https://arxiv.org/help/
- Open Library: https://openlibrary.org/help
- PubMed: https://www.ncbi.nlm.nih.gov/home/about/contact/

---

## 🎯 Success Criteria

### Metrics to Track

- [ ] **Adoption**
  - [ ] % of users using metadata feature
  - [ ] % of users using citation generator
  - [ ] Daily active users

- [ ] **Performance**
  - [ ] Average metadata extraction time < 2s
  - [ ] Average citation generation time < 5s
  - [ ] Error rate < 1%

- [ ] **User Satisfaction**
  - [ ] Positive feedback > 80%
  - [ ] Feature requests tracked
  - [ ] Bug reports < 5 per week

---

## 📅 Timeline

### Week 1: Integration
- [ ] Integrate into PDF viewer
- [ ] Add to navigation
- [ ] Internal testing

### Week 2: Testing
- [ ] QA testing
- [ ] Bug fixes
- [ ] Performance optimization

### Week 3: Deployment
- [ ] Deploy to staging
- [ ] User acceptance testing
- [ ] Deploy to production

### Week 4: Monitoring
- [ ] Monitor metrics
- [ ] Gather feedback
- [ ] Plan improvements

---

## ✨ Congratulations!

Once all items are checked, your Citation Generator and File Metadata features are ready for production! 🚀

Remember to:
- Monitor closely after launch
- Respond quickly to issues
- Gather user feedback
- Iterate and improve

Good luck with your deployment! 🎉
