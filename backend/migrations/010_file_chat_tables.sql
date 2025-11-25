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
ALTER TABLE file_chat_threads ENABLE ROW LEVEL SECURITY;
ALTER TABLE file_chat_messages ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view threads for files they have access to
CREATE POLICY "Users can view file chat threads they have access to"
ON file_chat_threads FOR SELECT
USING (
    file_id IN (
        SELECT file_id FROM file_shares 
        WHERE shared_with_user_id = auth.uid()::text
    )
);

-- Policy: Users can create threads for files they have access to
CREATE POLICY "Users can create file chat threads for accessible files"
ON file_chat_threads FOR INSERT
WITH CHECK (
    file_id IN (
        SELECT file_id FROM file_shares 
        WHERE shared_with_user_id = auth.uid()::text
    )
);

-- Policy: Users can view messages for files they have access to
CREATE POLICY "Users can view file chat messages they have access to"
ON file_chat_messages FOR SELECT
USING (
    file_id IN (
        SELECT file_id FROM file_shares 
        WHERE shared_with_user_id = auth.uid()::text
    )
);

-- Policy: Users can send messages to files they have access to
CREATE POLICY "Users can send messages to accessible files"
ON file_chat_messages FOR INSERT
WITH CHECK (
    file_id IN (
        SELECT file_id FROM file_shares 
        WHERE shared_with_user_id = auth.uid()::text
    )
);

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
