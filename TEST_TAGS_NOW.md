# Quick Tag Testing Guide

## Test the Fixes Now

### 1. Backend Test (Recommended First)
```bash
cd backend
uv run python test_tags.py
```

Expected output:
- ✓ All tests pass
- ✓ No duplicate tags created
- ✓ Case-insensitive detection works

### 2. Web Testing

#### Start Backend
```bash
cd backend
uv run python run.py
```

#### Start Frontend (Web)
```bash
cd frontend
flutter run -d chrome
```

#### Test Scenarios

**Scenario 1: Create Tag**
1. Navigate to Tag Management (from menu)
2. Click "+" button
3. Enter name: "Research"
4. Select color
5. Click "Create"
6. ✅ Verify: Only 1 tag appears in list

**Scenario 2: Duplicate Prevention**
1. Click "+" button again
2. Enter name: "Research" (same as before)
3. Click "Create"
4. ✅ Verify: No duplicate created, still only 1 tag

**Scenario 3: Case Variations**
1. Try creating: "research" (lowercase)
2. Try creating: "RESEARCH" (uppercase)
3. Try creating: "  Research  " (with spaces)
4. ✅ Verify: Still only 1 tag, no duplicates

**Scenario 4: Tag Files**
1. Go to File Explorer
2. Right-click a file → "Manage Tags"
3. Select "Research" tag
4. Click "Apply"
5. ✅ Verify: Tag appears on file
6. Open tag dialog again
7. ✅ Verify: "Research" is checked

**Scenario 5: Update Tag**
1. Go to Tag Management
2. Click menu (⋮) on "Research" tag
3. Click "Rename"
4. Change to "Academic Research"
5. Click "Save"
6. ✅ Verify: Tag name updated everywhere

**Scenario 6: Delete Tag**
1. Click menu (⋮) on tag
2. Click "Delete"
3. Confirm deletion
4. ✅ Verify: Tag removed from list and files

**Scenario 7: Refresh Test**
1. Create a tag
2. Refresh browser (F5)
3. ✅ Verify: Tag still appears (persisted)

### 3. Mobile Testing (Android)

#### Start Backend
```bash
cd backend
uv run python run.py
```

#### Start Frontend (Android)
```bash
cd frontend
flutter run -d <device-id>
```

#### Test Offline Sync
1. Create tag "Offline Test" while online
2. Turn off WiFi/mobile data
3. Create tag "Offline Tag"
4. ✅ Verify: Tag created locally
5. Turn on WiFi/mobile data
6. Wait a few seconds
7. ✅ Verify: "Offline Tag" synced to backend

### 4. Check Backend Logs

```bash
# In backend directory
tail -f logs/app.log
```

Look for:
- "Created tag" messages
- "Tag already exists" messages (for duplicates)
- No error messages

### 5. Check Supabase

1. Open Supabase dashboard
2. Go to Table Editor → `tags`
3. ✅ Verify: No duplicate tag names for same user
4. ✅ Verify: Tag names are normalized (no extra spaces)

## Common Issues

### Issue: Tags not appearing
**Solution**: 
- Check backend is running
- Check browser console for errors
- Verify user is authenticated

### Issue: Duplicate tags still created
**Solution**:
- Clear browser cache
- Restart backend
- Check backend logs for errors

### Issue: Tags not syncing
**Solution**:
- Check network connectivity
- Verify backend URL in config
- Check CORS settings

## Success Criteria

✅ No duplicate tags created
✅ Case-insensitive duplicate detection works
✅ Tags sync between frontend and backend
✅ Tags persist after page refresh
✅ Offline tags sync when online
✅ Tag updates work correctly
✅ Tag deletion works correctly
✅ File-tag associations work

## Report Issues

If tests fail:
1. Note which scenario failed
2. Check browser console errors
3. Check backend logs
4. Include error messages
5. Note platform (web/mobile)
