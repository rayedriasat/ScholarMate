-- Collaboration annotations table for real-time annotation syncing

CREATE TABLE IF NOT EXISTS collaboration_annotations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id TEXT NOT NULL REFERENCES collaboration_sessions(session_id) ON DELETE CASCADE,
    annotation_id TEXT NOT NULL,
    user_id TEXT NOT NULL,
    user_name TEXT NOT NULL,
    user_color TEXT NOT NULL,
    annotation_type TEXT NOT NULL,
    page_number INTEGER NOT NULL,
    bounds JSONB NOT NULL,
    color TEXT,
    opacity REAL,
    text_content TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(session_id, annotation_id)
);

-- Indexes 
CREATE INDEX IF NOT EXISTS idx_collab_annotations_session ON collaboration_annotations(session_id);
CREATE INDEX IF NOT EXISTS idx_collab_annotations_user ON collaboration_annotations(user_id);

-- Enable Row Level Security
ALTER TABLE collaboration_annotations ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Users can read annotations in their sessions"
    ON collaboration_annotations FOR SELECT
    USING (
        session_id IN (
            SELECT session_id FROM session_participants
            WHERE user_id = current_setting('request.jwt.claims', true)::json->>'sub'
        )
    );

CREATE POLICY "Users can create annotations in their sessions"
    ON collaboration_annotations FOR INSERT
    WITH CHECK (
        session_id IN (
            SELECT session_id FROM session_participants
            WHERE user_id = current_setting('request.jwt.claims', true)::json->>'sub'
        )
    );

CREATE POLICY "Users can update their own annotations"
    ON collaboration_annotations FOR UPDATE
    USING (user_id = current_setting('request.jwt.claims', true)::json->>'sub');

CREATE POLICY "Users can delete their own annotations"
    ON collaboration_annotations FOR DELETE
    USING (user_id = current_setting('request.jwt.claims', true)::json->>'sub');

-- Enable Realtime for live annotation syncing
ALTER PUBLICATION supabase_realtime ADD TABLE collaboration_annotations;
