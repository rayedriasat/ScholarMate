-- Collaboration tables for real-time PDF sessions

-- Collaboration sessions table
CREATE TABLE IF NOT EXISTS collaboration_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id TEXT UNIQUE NOT NULL,
    file_id UUID NOT NULL,
    file_name TEXT NOT NULL,
    owner_id TEXT NOT NULL,
    default_role TEXT NOT NULL DEFAULT 'editor',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE,
    CONSTRAINT valid_role CHECK (default_role IN ('owner', 'editor', 'viewer'))
);

-- Session participants table
CREATE TABLE IF NOT EXISTS session_participants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id TEXT NOT NULL REFERENCES collaboration_sessions(session_id) ON DELETE CASCADE,
    user_id TEXT NOT NULL,
    user_name TEXT NOT NULL,
    user_email TEXT NOT NULL,
    user_color TEXT NOT NULL,
    role TEXT NOT NULL DEFAULT 'editor',
    cursor_position JSONB,
    last_seen TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT valid_participant_role CHECK (role IN ('owner', 'editor', 'viewer')),
    UNIQUE(session_id, user_id)
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_sessions_session_id ON collaboration_sessions(session_id);
CREATE INDEX IF NOT EXISTS idx_sessions_owner ON collaboration_sessions(owner_id);
CREATE INDEX IF NOT EXISTS idx_sessions_file ON collaboration_sessions(file_id);
CREATE INDEX IF NOT EXISTS idx_participants_session ON session_participants(session_id);
CREATE INDEX IF NOT EXISTS idx_participants_user ON session_participants(user_id);

-- Enable Row Level Security
ALTER TABLE collaboration_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE session_participants ENABLE ROW LEVEL SECURITY;

-- RLS Policies for collaboration_sessions
-- Anyone can read sessions they're part of
CREATE POLICY "Users can read their sessions"
    ON collaboration_sessions FOR SELECT
    USING (
        owner_id = current_setting('request.jwt.claims', true)::json->>'sub'
        OR session_id IN (
            SELECT session_id FROM session_participants
            WHERE user_id = current_setting('request.jwt.claims', true)::json->>'sub'
        )
    );

-- Only owners can create sessions
CREATE POLICY "Users can create sessions"
    ON collaboration_sessions FOR INSERT
    WITH CHECK (owner_id = current_setting('request.jwt.claims', true)::json->>'sub');

-- Only owners can delete sessions
CREATE POLICY "Owners can delete sessions"
    ON collaboration_sessions FOR DELETE
    USING (owner_id = current_setting('request.jwt.claims', true)::json->>'sub');

-- RLS Policies for session_participants
-- Anyone can read participants in their sessions
CREATE POLICY "Users can read session participants"
    ON session_participants FOR SELECT
    USING (
        session_id IN (
            SELECT session_id FROM session_participants
            WHERE user_id = current_setting('request.jwt.claims', true)::json->>'sub'
        )
    );

-- Users can join sessions (insert themselves)
CREATE POLICY "Users can join sessions"
    ON session_participants FOR INSERT
    WITH CHECK (user_id = current_setting('request.jwt.claims', true)::json->>'sub');

-- Users can update their own participant record
CREATE POLICY "Users can update their participant data"
    ON session_participants FOR UPDATE
    USING (user_id = current_setting('request.jwt.claims', true)::json->>'sub');

-- Users can leave sessions (delete themselves)
CREATE POLICY "Users can leave sessions"
    ON session_participants FOR DELETE
    USING (user_id = current_setting('request.jwt.claims', true)::json->>'sub');

-- Enable Realtime for live collaboration
ALTER PUBLICATION supabase_realtime ADD TABLE session_participants;

-- Cleanup expired sessions (run periodically)
CREATE OR REPLACE FUNCTION cleanup_expired_sessions()
RETURNS void AS $$
BEGIN
    DELETE FROM collaboration_sessions
    WHERE expires_at IS NOT NULL AND expires_at < NOW();
END;
$$ LANGUAGE plpgsql;
