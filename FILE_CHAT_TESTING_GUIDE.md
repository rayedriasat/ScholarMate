# File Chat Testing Guide

## Test Scenarios

### ✅ Test 1: Basic Chat Functionality

**Objective**: Verify chat panel appears and messages can be sent

**Steps**:
1. Open a PDF file in the app
2. Verify chat icon appears on right side (collapsed state)
3. Click chat icon to expand panel
4. Type "Test message" in input field
5. Click send button or press Enter
6. Verify message appears in chat list
7. Verify message shows your name and timestamp

**Expected Result**:
- Chat panel expands smoothly
- Message appears immediately
- Timestamp shows "Just now"
- Message is right-aligned (current user)

---

### ✅ Test 2: Real-time Updates

**Objective**: Verify messages sync in real-time between users

**Setup**: Two devices/browsers with different users

**Steps**:
1. **Device A**: Open PDF file, expand chat
2. **Device B**: Open same PDF file, expand chat
3. **Device A**: Send message "Hello from A"
4. **Device B**: Verify message appears automatically
5. **Device B**: Send message "Hello from B"
6. **Device A**: Verify message appears automatically

**Expected Result**:
- Messages appear instantly (< 1 second)
- No page refresh needed
- Messages show correct sender name/avatar
- Messages are left-aligned for other users

---

### ✅ Test 3: Offline Mode

**Objective**: Verify offline message queuing and sync

**Steps**:
1. Open PDF file, expand chat
2. Disable network (airplane mode or disconnect WiFi)
3. Send message "Offline message 1"
4. Send message "Offline message 2"
5. Verify messages show pending icon (clock)
6. Enable network
7. Wait 2-3 seconds
8. Verify pending icons disappear (messages synced)

**Expected Result**:
- Messages appear immediately in UI (optimistic update)
- Clock icon shows pending status
- Messages sync automatically when online
- No duplicate messages

---

### ✅ Test 4: Access Control

**Objective**: Verify only authorized users can access chat

**Setup**: Two users (Owner and Guest)

**Steps**:
1. **Owner**: Upload/open a PDF file
2. **Owner**: Share file with Guest (Editor or Viewer role)
3. **Guest**: Open shared file
4. **Guest**: Verify chat panel is visible
5. **Guest**: Send message "I have access"
6. **Owner**: Verify Guest's message appears
7. **Owner**: Revoke Guest's access (unshare file)
8. **Guest**: Refresh or reopen file
9. **Guest**: Verify chat panel is not accessible

**Expected Result**:
- Guest can see and send messages when shared
- Guest loses access immediately after unshare
- No error messages, just no chat panel

---

### ✅ Test 5: Message History

**Objective**: Verify chat history persists and loads correctly

**Steps**:
1. Open PDF file, send 5 messages
2. Close file
3. Reopen same file
4. Expand chat panel
5. Verify all 5 messages are visible
6. Verify messages are in correct order (oldest to newest)
7. Verify scroll position is at bottom (latest message)

**Expected Result**:
- All messages load from cache/server
- Correct chronological order
- Auto-scroll to latest message
- No loading delay (cached locally)

---

### ✅ Test 6: Multiple Files

**Objective**: Verify chat threads are isolated per file

**Steps**:
1. Open File A, send message "Message for A"
2. Open File B, send message "Message for B"
3. Return to File A
4. Verify only "Message for A" is visible
5. Return to File B
6. Verify only "Message for B" is visible

**Expected Result**:
- Each file has separate chat thread
- No message leakage between files
- Message counts are independent

---

### ✅ Test 7: UI Responsiveness

**Objective**: Verify UI handles edge cases gracefully

**Steps**:
1. Send very long message (500+ characters)
2. Verify message wraps correctly in bubble
3. Send 50 messages rapidly
4. Verify scroll performance is smooth
5. Collapse and expand panel multiple times
6. Verify animation is smooth
7. Resize window (web/desktop)
8. Verify panel adapts correctly

**Expected Result**:
- Long messages wrap without overflow
- Smooth scrolling with many messages
- Smooth collapse/expand animation
- Responsive to window size changes

---

### ✅ Test 8: User Avatars

**Objective**: Verify user avatars display correctly

**Steps**:
1. User with photo URL: Verify avatar shows photo
2. User without photo: Verify avatar shows initial letter
3. Send message from both users
4. Verify avatars appear correctly in message list

**Expected Result**:
- Photo avatars load and display
- Initial avatars show first letter of name
- Avatars are circular and properly sized

---

### ✅ Test 9: Timestamp Formatting

**Objective**: Verify timestamps display correctly

**Steps**:
1. Send message, verify shows "Just now"
2. Wait 2 minutes, verify shows "2m ago"
3. Wait 1 hour, verify shows "1h ago"
4. Send message yesterday, verify shows date

**Expected Result**:
- Relative time for recent messages
- Absolute date for old messages
- Updates automatically (no refresh needed)

---

### ✅ Test 10: Empty State

**Objective**: Verify empty chat state displays correctly

**Steps**:
1. Open new PDF file (no messages)
2. Expand chat panel
3. Verify empty state message appears
4. Send first message
5. Verify empty state disappears

**Expected Result**:
- Empty state shows helpful message
- No errors or blank screen
- Smooth transition to message list

---

## Performance Tests

### Load Test: Many Messages

**Steps**:
1. Create file with 1000+ messages (use script or API)
2. Open file and expand chat
3. Measure load time
4. Scroll through messages
5. Send new message

**Expected Result**:
- Load time < 2 seconds
- Smooth scrolling
- No UI freezing
- New message appears instantly

### Stress Test: Rapid Messages

**Steps**:
1. Send 10 messages in 5 seconds
2. Verify all messages appear
3. Verify correct order
4. Verify no duplicates

**Expected Result**:
- All messages delivered
- Correct chronological order
- No race conditions

---

## Automated Testing (Optional)

### Unit Tests

```dart
// test/services/file_chat_service_test.dart
void main() {
  group('FileChatService', () {
    test('sends message successfully', () async {
      // Test implementation
    });
    
    test('handles offline mode', () async {
      // Test implementation
    });
    
    test('syncs pending messages', () async {
      // Test implementation
    });
  });
}
```

### Widget Tests

```dart
// test/widgets/file_chat_panel_test.dart
void main() {
  testWidgets('expands and collapses correctly', (tester) async {
    // Test implementation
  });
  
  testWidgets('displays messages correctly', (tester) async {
    // Test implementation
  });
}
```

---

## Bug Report Template

If you find issues, report with this format:

```
**Issue**: [Brief description]

**Steps to Reproduce**:
1. [Step 1]
2. [Step 2]
3. [Step 3]

**Expected Behavior**: [What should happen]

**Actual Behavior**: [What actually happens]

**Environment**:
- Platform: [Android/iOS/Web/Windows]
- Flutter version: [version]
- Network: [Online/Offline]

**Screenshots**: [If applicable]

**Console Logs**: [Any error messages]
```

---

## Test Checklist

Use this checklist to verify all features:

- [ ] Chat panel appears on PDF viewer
- [ ] Panel expands/collapses smoothly
- [ ] Messages can be sent
- [ ] Messages appear in real-time
- [ ] Offline messages queue correctly
- [ ] Offline messages sync when online
- [ ] Access control works (share/unshare)
- [ ] Message history persists
- [ ] Multiple files have separate chats
- [ ] Long messages wrap correctly
- [ ] User avatars display correctly
- [ ] Timestamps format correctly
- [ ] Empty state displays correctly
- [ ] Performance is acceptable (1000+ messages)
- [ ] No console errors
- [ ] Works on all platforms (Android, iOS, Web, Desktop)

---

## Success Criteria

✅ **Feature is ready for production when**:
- All test scenarios pass
- No critical bugs
- Performance is acceptable
- Works on all target platforms
- Documentation is complete
- Users can collaborate seamlessly

---

## Next Steps After Testing

1. ✅ Fix any bugs found
2. ✅ Optimize performance if needed
3. ✅ Add analytics tracking (optional)
4. ✅ Deploy to production
5. ✅ Monitor real-world usage
6. ✅ Gather user feedback
7. ✅ Plan future enhancements
