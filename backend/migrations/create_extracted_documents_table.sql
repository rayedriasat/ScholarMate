-- Create extracted_documents table for storing AI-extracted document data
CREATE TABLE IF NOT EXISTS extracted_documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id TEXT NOT NULL,
    document_type TEXT NOT NULL,
    extracted_data JSONB NOT NULL DEFAULT '{}'::jsonb,
    summary TEXT NOT NULL,
    image_url TEXT,
    tags TEXT[] NOT NULL DEFAULT ARRAY[]::TEXT[],
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Create indexes for efficient querying
CREATE INDEX IF NOT EXISTS idx_extracted_documents_user_id ON extracted_documents(user_id);
CREATE INDEX IF NOT EXISTS idx_extracted_documents_user_type ON extracted_documents(user_id, document_type);
CREATE INDEX IF NOT EXISTS idx_extracted_documents_created_at ON extracted_documents(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_extracted_documents_tags ON extracted_documents USING GIN(tags);

-- Create updated_at trigger
CREATE OR REPLACE FUNCTION update_extracted_documents_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_extracted_documents_updated_at
    BEFORE UPDATE ON extracted_documents
    FOR EACH ROW
    EXECUTE FUNCTION update_extracted_documents_updated_at();

-- Add RLS (Row Level Security) policies
ALTER TABLE extracted_documents ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only see their own extracted documents
CREATE POLICY extracted_documents_select_policy ON extracted_documents
    FOR SELECT
    USING (user_id = current_setting('request.jwt.claims', true)::json->>'sub');

-- Policy: Users can only insert their own extracted documents
CREATE POLICY extracted_documents_insert_policy ON extracted_documents
    FOR INSERT
    WITH CHECK (user_id = current_setting('request.jwt.claims', true)::json->>'sub');

-- Policy: Users can only update their own extracted documents
CREATE POLICY extracted_documents_update_policy ON extracted_documents
    FOR UPDATE
    USING (user_id = current_setting('request.jwt.claims', true)::json->>'sub');

-- Policy: Users can only delete their own extracted documents
CREATE POLICY extracted_documents_delete_policy ON extracted_documents
    FOR DELETE
    USING (user_id = current_setting('request.jwt.claims', true)::json->>'sub');

-- Grant permissions
GRANT ALL ON extracted_documents TO authenticated;
GRANT ALL ON extracted_documents TO service_role;

-- Add comments for documentation
COMMENT ON TABLE extracted_documents IS 'Stores AI-extracted structured data from scanned documents';
COMMENT ON COLUMN extracted_documents.id IS 'Unique identifier for the extracted document';
COMMENT ON COLUMN extracted_documents.user_id IS 'User ID (Google sub claim) who owns this document';
COMMENT ON COLUMN extracted_documents.document_type IS 'Type of document (Hospital, Appointment, ID Card, Bill, Prescription, etc.)';
COMMENT ON COLUMN extracted_documents.extracted_data IS 'JSON object containing extracted key-value pairs';
COMMENT ON COLUMN extracted_documents.summary IS 'AI-generated 1-2 line summary of the document';
COMMENT ON COLUMN extracted_documents.image_url IS 'Google Drive file ID or URL to the original scanned image';
COMMENT ON COLUMN extracted_documents.tags IS 'Array of auto-generated tags for categorization';
COMMENT ON COLUMN extracted_documents.created_at IS 'Timestamp when the document was created';
COMMENT ON COLUMN extracted_documents.updated_at IS 'Timestamp when the document was last updated';
