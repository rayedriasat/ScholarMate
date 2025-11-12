# Migration Checklist - Fix "Failed to load keys" Error

## ✅ Quick Checklist

- [ ] **Step 1:** Open Supabase SQL Editor
  - Link: https://supabase.com/dashboard/project/rqyzgfgdsedvohxyyqho/sql/new
  
- [ ] **Step 2:** Copy SQL
  - File: `backend/migration_to_apply.sql`
  - Or from: `FIX_ERROR_APPLY_MIGRATION.md`
  
- [ ] **Step 3:** Paste SQL into editor
  
- [ ] **Step 4:** Click "Run" button
  
- [ ] **Step 5:** See "Success" message
  
- [ ] **Step 6:** Verify tables created
  - Go to: Table Editor
  - Check for: `user_api_keys` ✓
  - Check for: `api_usage_logs` ✓
  
- [ ] **Step 7:** Refresh Flutter app
  - Hot reload or restart
  
- [ ] **Step 8:** Test API Keys screen
  - Settings → API Keys
  - Should load without error ✓
  
- [ ] **Step 9:** Add first API key
  - Tap "+ Add Key"
  - Select provider (GROQ recommended - free)
  - Paste key
  - Save
  
- [ ] **Step 10:** Verify key saved
  - Should see key in list
  - Status: Validated ✓

## 🎯 Expected Result

After completing all steps:
- ✅ No more "Failed to load keys" error
- ✅ Can add API keys
- ✅ Can view usage statistics
- ✅ Can manage multiple providers

## 📞 Need Help?

See detailed guide: `FIX_ERROR_APPLY_MIGRATION.md`

## 🚀 Quick Links

- **SQL Editor:** https://supabase.com/dashboard/project/rqyzgfgdsedvohxyyqho/sql/new
- **Table Editor:** https://supabase.com/dashboard/project/rqyzgfgdsedvohxyyqho/editor
- **GROQ (Free Keys):** https://console.groq.com
- **OpenAI:** https://platform.openai.com
- **Anthropic:** https://console.anthropic.com
