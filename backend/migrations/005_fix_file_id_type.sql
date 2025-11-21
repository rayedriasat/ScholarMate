-- Fix file_id column type to support Google Drive file IDs

-- Change file_id from UUID to TEXT
ALTER TABLE collaboration_sessions 
ALTER COLUMN file_id TYPE TEXT;

-- Recreate index
DROP INDEX IF EXISTS idx_sessions_file;
CREATE INDEX idx_sessions_file ON collaboration_sessions(file_id);
