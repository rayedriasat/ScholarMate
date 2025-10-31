-- Migration: Fix tags user_id to use VARCHAR instead of UUID
-- Description: Changes user_id from UUID to VARCHAR to support Google sub claims
-- Date: 2025-10-31

-- Drop existing RLS policies first
DROP POLICY IF EXISTS "Users can view their own tags" ON tags;
DROP POLICY IF EXISTS "Users can create their own tags" ON tags;
DROP POLICY IF EXISTS "Users can update their own tags" ON tags;
DROP POLICY IF EXISTS "Users can delete their own tags" ON tags;
DROP POLICY IF EXISTS "Users can view their own file tags" ON file_tags;
DROP POLICY IF EXISTS "Users can create their own file tags" ON file_tags;
DROP POLICY IF EXISTS "Users can delete their own file tags" ON file_tags;

-- Disable RLS temporarily
ALTER TABLE tags DISABLE ROW LEVEL SECURITY;
ALTER TABLE file_tags DISABLE ROW LEVEL SECURITY;

-- Alter user_id columns to VARCHAR
ALTER TABLE tags ALTER COLUMN user_id TYPE VARCHAR(255);
ALTER TABLE file_tags ALTER COLUMN user_id TYPE VARCHAR(255);

-- Re-enable RLS (but don't add policies yet - handled at app level)
ALTER TABLE tags ENABLE ROW LEVEL SECURITY;
ALTER TABLE file_tags ENABLE ROW LEVEL SECURITY;

-- Add a permissive policy for now (since we're not using Supabase auth)
-- In production, implement proper RLS based on your auth strategy
CREATE POLICY "Allow all operations on tags" ON tags FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all operations on file_tags" ON file_tags FOR ALL USING (true) WITH CHECK (true);

-- Update comments
COMMENT ON COLUMN tags.user_id IS 'Google sub claim (user ID from Google OAuth)';
COMMENT ON COLUMN file_tags.user_id IS 'Google sub claim (user ID from Google OAuth)';
