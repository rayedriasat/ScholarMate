-- Migration 011: Fix File Chat RLS Policies
-- Fixes RLS policies to work with Google OAuth (not Supabase Auth)

-- Drop existing policies
DROP POLICY IF EXISTS "Authenticated users can view file chat threads" ON file_chat_threads;
DROP POLICY IF EXISTS "Authenticated users can create file chat threads" ON file_chat_threads;
DROP POLICY IF EXISTS "Authenticated users can view file chat messages" ON file_chat_messages;
DROP POLICY IF EXISTS "Authenticated users can send messages" ON file_chat_messages;

-- Create permissive policies (backend validates Google Drive access)
-- Since we use Google OAuth (not Supabase Auth), we can't use auth.role()
-- Instead, we allow all operations and rely on backend API validation

-- Threads: Allow all operations (backend validates Drive permissions)
CREATE POLICY "Allow all operations on file chat threads"
ON file_chat_threads
FOR ALL
USING (true)
WITH CHECK (true);

-- Messages: Allow all operations (backend validates Drive permissions)
CREATE POLICY "Allow all operations on file chat messages"
ON file_chat_messages
FOR ALL
USING (true)
WITH CHECK (true);

-- Note: This is secure because:
-- 1. Backend API validates Google Drive permissions before serving data
-- 2. file_id links to Google Drive files (user must have Drive access)
-- 3. Supabase is only used as a realtime sync layer, not primary auth
