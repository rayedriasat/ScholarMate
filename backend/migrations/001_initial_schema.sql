-- ScholarMate Complete Database Schema
-- This migration creates all tables, RLS policies, and indexes for the metadata database
-- Applied as migration: 001_complete_schema

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================================
-- USERS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    google_sub TEXT UNIQUE NOT NULL,
    email TEXT NOT NULL,
    name TEXT,
    picture_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_users_google_sub ON users(google_sub);
CREATE INDEX idx_users_email ON users(email);

-- ============================================================================
-- ENCRYPTED_TOKENS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS encrypted_tokens (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token_type TEXT NOT NULL, -- 'access_token', 'refresh_token', 'id_token'
    encrypted_token TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, token_type)
);

CREATE INDEX idx_encrypted_tokens_user_id ON encrypted_tokens(user_id);
CREATE INDEX idx_encrypted_tokens_user_token_type ON encrypted_tokens(user_id, token_type);

-- ============================================================================
-- FILES TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS files (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    drive_file_id TEXT NOT NULL,
    name TEXT NOT NULL,
    mime_type TEXT NOT NULL,
    size_bytes BIGINT,
    parent_folder_id UUID REFERENCES files(id) ON DELETE CASCADE,
    is_folder BOOLEAN DEFAULT FALSE,
    is_trashed BOOLEAN DEFAULT FALSE,
    drive_modified_time TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, drive_file_id)
);

CREATE INDEX idx_files_user_id ON files(user_id);
CREATE INDEX idx_files_drive_file_id ON files(drive_file_id);
CREATE INDEX idx_files_parent_folder_id ON files(parent_folder_id);
CREATE INDEX idx_files_user_parent ON files(user_id, parent_folder_id);
CREATE INDEX idx_files_is_trashed ON files(is_trashed);

-- ============================================================================
-- ANNOTATIONS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS annotations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    file_id UUID NOT NULL REFERENCES files(id) ON DELETE CASCADE,
    annotation_type TEXT NOT NULL, -- 'highlight', 'underline', 'strikethrough', 'comment'
    page_number INTEGER NOT NULL,
    position_data JSONB NOT NULL, -- Stores coordinates, bounds, etc.
    content TEXT, -- Selected text or comment content
    color TEXT, -- Hex color code
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_annotations_user_id ON annotations(user_id);
CREATE INDEX idx_annotations_file_id ON annotations(file_id);
CREATE INDEX idx_annotations_file_page ON annotations(file_id, page_number);

-- ============================================================================
-- SHARES TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS shares (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    file_id UUID NOT NULL REFERENCES files(id) ON DELETE CASCADE,
    owner_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    shared_with_user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    shared_with_email TEXT NOT NULL, -- Email of the person being shared with
    share_link TEXT UNIQUE, -- For public link sharing
    permission TEXT NOT NULL, -- 'viewer', 'editor'
    is_public BOOLEAN DEFAULT FALSE,
    expires_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_shares_file_id ON shares(file_id);
CREATE INDEX idx_shares_owner_id ON shares(owner_id);
CREATE INDEX idx_shares_shared_with_user_id ON shares(shared_with_user_id);
CREATE INDEX idx_shares_share_link ON shares(share_link);
CREATE INDEX idx_shares_is_public ON shares(is_public);

-- ============================================================================
-- INGESTION_JOBS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS ingestion_jobs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    file_id UUID NOT NULL REFERENCES files(id) ON DELETE CASCADE,
    job_type TEXT NOT NULL, -- 'ocr', 'rag_indexing'
    status TEXT NOT NULL, -- 'pending', 'processing', 'completed', 'failed'
    progress_percent INTEGER DEFAULT 0,
    error_message TEXT,
    metadata JSONB, -- Additional job-specific data
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_ingestion_jobs_user_id ON ingestion_jobs(user_id);
CREATE INDEX idx_ingestion_jobs_file_id ON ingestion_jobs(file_id);
CREATE INDEX idx_ingestion_jobs_status ON ingestion_jobs(status);
CREATE INDEX idx_ingestion_jobs_user_status ON ingestion_jobs(user_id, status);

-- ============================================================================
-- API_KEYS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS api_keys (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    provider TEXT NOT NULL, -- 'openrouter', 'openai', 'anthropic', 'google', 'xai'
    encrypted_key TEXT NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, provider)
);

CREATE INDEX idx_api_keys_user_id ON api_keys(user_id);
CREATE INDEX idx_api_keys_user_provider ON api_keys(user_id, provider);

-- ============================================================================
-- AUDIT_LOGS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    action TEXT NOT NULL, -- 'login', 'logout', 'file_access', 'share_created', etc.
    resource_type TEXT, -- 'file', 'annotation', 'share', etc.
    resource_id UUID,
    ip_address TEXT,
    user_agent TEXT,
    metadata JSONB, -- Additional context
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_audit_logs_user_id ON audit_logs(user_id);
CREATE INDEX idx_audit_logs_action ON audit_logs(action);
CREATE INDEX idx_audit_logs_resource ON audit_logs(resource_type, resource_id);
CREATE INDEX idx_audit_logs_created_at ON audit_logs(created_at);

-- ============================================================================
-- ROW LEVEL SECURITY POLICIES
-- ============================================================================

-- Enable RLS on all tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE encrypted_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE files ENABLE ROW LEVEL SECURITY;
ALTER TABLE annotations ENABLE ROW LEVEL SECURITY;
ALTER TABLE shares ENABLE ROW LEVEL SECURITY;
ALTER TABLE ingestion_jobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE api_keys ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- USERS TABLE POLICIES
-- ============================================================================

-- Users can read their own record
CREATE POLICY users_select_own ON users
    FOR SELECT
    USING (auth.uid()::text = id::text);

-- Users can update their own record
CREATE POLICY users_update_own ON users
    FOR UPDATE
    USING (auth.uid()::text = id::text);

-- Service role can do everything (for backend operations)
CREATE POLICY users_service_all ON users
    FOR ALL
    USING (auth.jwt()->>'role' = 'service_role');

-- ============================================================================
-- ENCRYPTED_TOKENS TABLE POLICIES
-- ============================================================================

-- Users can read their own tokens
CREATE POLICY encrypted_tokens_select_own ON encrypted_tokens
    FOR SELECT
    USING (auth.uid()::text = user_id::text);

-- Users can insert their own tokens
CREATE POLICY encrypted_tokens_insert_own ON encrypted_tokens
    FOR INSERT
    WITH CHECK (auth.uid()::text = user_id::text);

-- Users can update their own tokens
CREATE POLICY encrypted_tokens_update_own ON encrypted_tokens
    FOR UPDATE
    USING (auth.uid()::text = user_id::text);

-- Users can delete their own tokens
CREATE POLICY encrypted_tokens_delete_own ON encrypted_tokens
    FOR DELETE
    USING (auth.uid()::text = user_id::text);

-- Service role can do everything
CREATE POLICY encrypted_tokens_service_all ON encrypted_tokens
    FOR ALL
    USING (auth.jwt()->>'role' = 'service_role');

-- ============================================================================
-- FILES TABLE POLICIES
-- ============================================================================

-- Users can read their own files
CREATE POLICY files_select_own ON files
    FOR SELECT
    USING (auth.uid()::text = user_id::text);

-- Users can read files shared with them
CREATE POLICY files_select_shared ON files
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM shares
            WHERE shares.file_id = files.id
            AND (
                shares.shared_with_user_id::text = auth.uid()::text
                OR (shares.is_public = TRUE AND shares.expires_at > NOW())
            )
        )
    );

-- Users can insert their own files
CREATE POLICY files_insert_own ON files
    FOR INSERT
    WITH CHECK (auth.uid()::text = user_id::text);

-- Users can update their own files
CREATE POLICY files_update_own ON files
    FOR UPDATE
    USING (auth.uid()::text = user_id::text);

-- Users can delete their own files
CREATE POLICY files_delete_own ON files
    FOR DELETE
    USING (auth.uid()::text = user_id::text);

-- Service role can do everything
CREATE POLICY files_service_all ON files
    FOR ALL
    USING (auth.jwt()->>'role' = 'service_role');

-- ============================================================================
-- ANNOTATIONS TABLE POLICIES
-- ============================================================================

-- Users can read their own annotations
CREATE POLICY annotations_select_own ON annotations
    FOR SELECT
    USING (auth.uid()::text = user_id::text);

-- Users can read annotations on files shared with them (if they have editor permission)
CREATE POLICY annotations_select_shared ON annotations
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM shares
            WHERE shares.file_id = annotations.file_id
            AND shares.shared_with_user_id::text = auth.uid()::text
        )
    );

-- Users can insert their own annotations
CREATE POLICY annotations_insert_own ON annotations
    FOR INSERT
    WITH CHECK (auth.uid()::text = user_id::text);

-- Users can update their own annotations
CREATE POLICY annotations_update_own ON annotations
    FOR UPDATE
    USING (auth.uid()::text = user_id::text);

-- Users can delete their own annotations
CREATE POLICY annotations_delete_own ON annotations
    FOR DELETE
    USING (auth.uid()::text = user_id::text);

-- Service role can do everything
CREATE POLICY annotations_service_all ON annotations
    FOR ALL
    USING (auth.jwt()->>'role' = 'service_role');

-- ============================================================================
-- SHARES TABLE POLICIES
-- ============================================================================

-- Users can read shares they own
CREATE POLICY shares_select_owner ON shares
    FOR SELECT
    USING (auth.uid()::text = owner_id::text);

-- Users can read shares where they are the recipient
CREATE POLICY shares_select_recipient ON shares
    FOR SELECT
    USING (auth.uid()::text = shared_with_user_id::text);

-- Users can insert shares for their own files
CREATE POLICY shares_insert_own ON shares
    FOR INSERT
    WITH CHECK (auth.uid()::text = owner_id::text);

-- Users can update shares they own
CREATE POLICY shares_update_own ON shares
    FOR UPDATE
    USING (auth.uid()::text = owner_id::text);

-- Users can delete shares they own
CREATE POLICY shares_delete_own ON shares
    FOR DELETE
    USING (auth.uid()::text = owner_id::text);

-- Service role can do everything
CREATE POLICY shares_service_all ON shares
    FOR ALL
    USING (auth.jwt()->>'role' = 'service_role');

-- ============================================================================
-- INGESTION_JOBS TABLE POLICIES
-- ============================================================================

-- Users can read their own ingestion jobs
CREATE POLICY ingestion_jobs_select_own ON ingestion_jobs
    FOR SELECT
    USING (auth.uid()::text = user_id::text);

-- Users can insert their own ingestion jobs
CREATE POLICY ingestion_jobs_insert_own ON ingestion_jobs
    FOR INSERT
    WITH CHECK (auth.uid()::text = user_id::text);

-- Users can update their own ingestion jobs
CREATE POLICY ingestion_jobs_update_own ON ingestion_jobs
    FOR UPDATE
    USING (auth.uid()::text = user_id::text);

-- Service role can do everything
CREATE POLICY ingestion_jobs_service_all ON ingestion_jobs
    FOR ALL
    USING (auth.jwt()->>'role' = 'service_role');

-- ============================================================================
-- API_KEYS TABLE POLICIES
-- ============================================================================

-- Users can read their own API keys
CREATE POLICY api_keys_select_own ON api_keys
    FOR SELECT
    USING (auth.uid()::text = user_id::text);

-- Users can insert their own API keys
CREATE POLICY api_keys_insert_own ON api_keys
    FOR INSERT
    WITH CHECK (auth.uid()::text = user_id::text);

-- Users can update their own API keys
CREATE POLICY api_keys_update_own ON api_keys
    FOR UPDATE
    USING (auth.uid()::text = user_id::text);

-- Users can delete their own API keys
CREATE POLICY api_keys_delete_own ON api_keys
    FOR DELETE
    USING (auth.uid()::text = user_id::text);

-- Service role can do everything
CREATE POLICY api_keys_service_all ON api_keys
    FOR ALL
    USING (auth.jwt()->>'role' = 'service_role');

-- ============================================================================
-- AUDIT_LOGS TABLE POLICIES
-- ============================================================================

-- Users can read their own audit logs
CREATE POLICY audit_logs_select_own ON audit_logs
    FOR SELECT
    USING (auth.uid()::text = user_id::text);

-- Only service role can insert audit logs
CREATE POLICY audit_logs_insert_service ON audit_logs
    FOR INSERT
    WITH CHECK (auth.jwt()->>'role' = 'service_role');

-- Service role can do everything
CREATE POLICY audit_logs_service_all ON audit_logs
    FOR ALL
    USING (auth.jwt()->>'role' = 'service_role');

-- ============================================================================
-- FUNCTIONS AND TRIGGERS
-- ============================================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply updated_at trigger to all tables with updated_at column
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_encrypted_tokens_updated_at BEFORE UPDATE ON encrypted_tokens
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_files_updated_at BEFORE UPDATE ON files
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_annotations_updated_at BEFORE UPDATE ON annotations
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_shares_updated_at BEFORE UPDATE ON shares
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_ingestion_jobs_updated_at BEFORE UPDATE ON ingestion_jobs
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_api_keys_updated_at BEFORE UPDATE ON api_keys
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
