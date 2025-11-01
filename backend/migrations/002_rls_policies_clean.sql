-- ScholarMate RLS Policies
-- Applied as Supabase migration: 002_rls_policies

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
ALTER TABLE tags ENABLE ROW LEVEL SECURITY;
ALTER TABLE file_tags ENABLE ROW LEVEL SECURITY;
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
                OR (shares.is_public = TRUE AND (shares.expires_at IS NULL OR shares.expires_at > NOW()))
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
-- TAGS TABLE POLICIES
-- ============================================================================

-- Users can read their own tags (using google_sub from JWT)
CREATE POLICY tags_select_own ON tags
    FOR SELECT
    USING (auth.jwt()->>'sub' = user_id);

-- Users can insert their own tags
CREATE POLICY tags_insert_own ON tags
    FOR INSERT
    WITH CHECK (auth.jwt()->>'sub' = user_id);

-- Users can update their own tags
CREATE POLICY tags_update_own ON tags
    FOR UPDATE
    USING (auth.jwt()->>'sub' = user_id);

-- Users can delete their own tags
CREATE POLICY tags_delete_own ON tags
    FOR DELETE
    USING (auth.jwt()->>'sub' = user_id);

-- Service role can do everything
CREATE POLICY tags_service_all ON tags
    FOR ALL
    USING (auth.jwt()->>'role' = 'service_role');

-- ============================================================================
-- FILE_TAGS TABLE POLICIES
-- ============================================================================

-- Users can read their own file tags
CREATE POLICY file_tags_select_own ON file_tags
    FOR SELECT
    USING (auth.jwt()->>'sub' = user_id);

-- Users can insert their own file tags
CREATE POLICY file_tags_insert_own ON file_tags
    FOR INSERT
    WITH CHECK (auth.jwt()->>'sub' = user_id);

-- Users can update their own file tags
CREATE POLICY file_tags_update_own ON file_tags
    FOR UPDATE
    USING (auth.jwt()->>'sub' = user_id);

-- Users can delete their own file tags
CREATE POLICY file_tags_delete_own ON file_tags
    FOR DELETE
    USING (auth.jwt()->>'sub' = user_id);

-- Service role can do everything
CREATE POLICY file_tags_service_all ON file_tags
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