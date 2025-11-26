-- Migration 010: File Chat & Notes Feature
-- Creates tables for file-based chat threads and messages with real-time support

-- File chat threads table
CREATE TABLE IF NOT EXISTS file_chat_threads (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    file_id TEXT NOT NULL UNIQUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    message_count INTEGER NOT NULL DEFAULT 0
);

-- File chat messages table
CREATE TABLE IF NOT EXISTS file_chat_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    thread_id UUID NOT NULL REFERENCES file_chat_threads(id) ON DELETE CASCADE,
    file_id TEXT NOT NULL,
    user_id TEXT NOT NULL,
    user_name TEXT NOT NULL,
    user_photo_url TEXT,
    content TEXT NOT NULL,
    timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indices for performance
CREATE INDEX IF NOT EXISTS idx_file_chat_threads_file_id ON file_chat_threads(file_id);
CREATE INDEX IF NOT EXISTS idx_file_chat_messages_thread_id ON file_chat_messages(thread_id);
CREATE INDEX IF NOT EXISTS idx_file_chat_messages_file_id ON file_chat_messages(file_id);
CREATE INDEX IF NOT EXISTS idx_file_chat_messages_timestamp ON file_chat_messages(timestamp);

-- Row Level Security (RLS) policies
-- Note: File access is controlled by Google Drive permissions, not Supabase
-- These policies allow authenticated users to access chat data
-- Backend API validates Drive permissions before serving data
ALTER TABLE file_chat_threads ENABLE ROW LEVEL SECURITY;
ALTER TABLE file_chat_messages ENABLE ROW LEVEL SECURITY;

-- Policy: Authenticated users can view all threads (backend validates Drive access)
CREATE POLICY "Authenticated users can view file chat threads"
ON file_chat_threads FOR SELECT
USING (auth.role() = 'authenticated');

-- Policy: Authenticated users can create threads (backend validates Drive access)
CREATE POLICY "Authenticated users can create file chat threads"
ON file_chat_threads FOR INSERT
WITH CHECK (auth.role() = 'authenticated');

-- Policy: Authenticated users can view all messages (backend validates Drive access)
CREATE POLICY "Authenticated users can view file chat messages"
ON file_chat_messages FOR SELECT
USING (auth.role() = 'authenticated');

-- Policy: Authenticated users can send messages (backend validates Drive access)
CREATE POLICY "Authenticated users can send messages"
ON file_chat_messages FOR INSERT
WITH CHECK (auth.role() = 'authenticated');

-- Function to update thread message count
CREATE OR REPLACE FUNCTION update_thread_message_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE file_chat_threads
        SET message_count = message_count + 1,
            updated_at = NOW()
        WHERE id = NEW.thread_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE file_chat_threads
        SET message_count = GREATEST(message_count - 1, 0),
            updated_at = NOW()
        WHERE id = OLD.thread_id;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Trigger to automatically update message count
CREATE TRIGGER trigger_update_thread_message_count
AFTER INSERT OR DELETE ON file_chat_messages
FOR EACH ROW
EXECUTE FUNCTION update_thread_message_count();

-- Enable realtime for file_chat_messages
ALTER PUBLICATION supabase_realtime ADD TABLE file_chat_messages;

-- Comments for documentation
COMMENT ON TABLE file_chat_threads IS 'Chat threads linked to individual PDF files';
COMMENT ON TABLE file_chat_messages IS 'Messages within file chat threads with real-time support';
COMMENT ON COLUMN file_chat_messages.user_id IS 'Google OAuth sub claim (unique user ID)';
