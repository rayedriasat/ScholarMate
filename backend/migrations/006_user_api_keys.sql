-- User API Keys and Usage Tracking Migration
-- Adds support for per-user AI provider API keys with encryption and usage tracking

-- ============================================================================
-- USER_API_KEYS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS user_api_keys (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    provider TEXT NOT NULL CHECK (provider IN ('groq', 'openai', 'anthropic', 'cohere', 'google', 'openrouter')),
    encrypted_key TEXT NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    is_validated BOOLEAN DEFAULT FALSE,
    validation_error TEXT,
    last_validated_at TIMESTAMPTZ,
    priority INTEGER DEFAULT 0, -- Higher priority = preferred provider
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, provider)
);

CREATE INDEX idx_user_api_keys_user_id ON user_api_keys(user_id);
CREATE INDEX idx_user_api_keys_user_provider ON user_api_keys(user_id, provider);
CREATE INDEX idx_user_api_keys_is_active ON user_api_keys(is_active);
CREATE INDEX idx_user_api_keys_priority ON user_api_keys(user_id, priority DESC);

-- ============================================================================
-- API_USAGE_LOGS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS api_usage_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    provider TEXT NOT NULL,
    endpoint TEXT NOT NULL, -- 'chat', 'embedding', 'rag_query'
    request_tokens INTEGER DEFAULT 0,
    response_tokens INTEGER DEFAULT 0,
    total_tokens INTEGER DEFAULT 0,
    cost_estimate DECIMAL(10, 6) DEFAULT 0, -- Estimated cost in USD
    status TEXT NOT NULL CHECK (status IN ('success', 'error', 'rate_limit')),
    error_message TEXT,
    metadata JSONB, -- Additional context (model, temperature, etc.)
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_api_usage_logs_user_id ON api_usage_logs(user_id);
CREATE INDEX idx_api_usage_logs_provider ON api_usage_logs(provider);
CREATE INDEX idx_api_usage_logs_user_provider ON api_usage_logs(user_id, provider);
CREATE INDEX idx_api_usage_logs_created_at ON api_usage_logs(created_at);
CREATE INDEX idx_api_usage_logs_status ON api_usage_logs(status);

-- ============================================================================
-- TRIGGERS
-- ============================================================================

-- Apply updated_at trigger to user_api_keys
CREATE TRIGGER update_user_api_keys_updated_at BEFORE UPDATE ON user_api_keys
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

-- Function to get user's active API keys ordered by priority
CREATE OR REPLACE FUNCTION get_user_active_keys(p_user_id UUID)
RETURNS TABLE (
    provider TEXT,
    encrypted_key TEXT,
    priority INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        user_api_keys.provider,
        user_api_keys.encrypted_key,
        user_api_keys.priority
    FROM user_api_keys
    WHERE user_api_keys.user_id = p_user_id
        AND user_api_keys.is_active = TRUE
        AND user_api_keys.is_validated = TRUE
    ORDER BY user_api_keys.priority DESC, user_api_keys.created_at ASC;
END;
$$ LANGUAGE plpgsql;

-- Function to get usage statistics for a user
CREATE OR REPLACE FUNCTION get_user_usage_stats(
    p_user_id UUID,
    p_start_date TIMESTAMPTZ DEFAULT NOW() - INTERVAL '30 days',
    p_end_date TIMESTAMPTZ DEFAULT NOW()
)
RETURNS TABLE (
    provider TEXT,
    total_requests BIGINT,
    total_tokens BIGINT,
    total_cost DECIMAL,
    success_rate DECIMAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        api_usage_logs.provider,
        COUNT(*)::BIGINT as total_requests,
        SUM(api_usage_logs.total_tokens)::BIGINT as total_tokens,
        SUM(api_usage_logs.cost_estimate) as total_cost,
        ROUND(
            (COUNT(*) FILTER (WHERE api_usage_logs.status = 'success')::DECIMAL / 
            NULLIF(COUNT(*), 0)) * 100, 
            2
        ) as success_rate
    FROM api_usage_logs
    WHERE api_usage_logs.user_id = p_user_id
        AND api_usage_logs.created_at BETWEEN p_start_date AND p_end_date
    GROUP BY api_usage_logs.provider
    ORDER BY total_requests DESC;
END;
$$ LANGUAGE plpgsql;
