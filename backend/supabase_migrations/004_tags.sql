-- Migration: Add tags and file_tags tables
-- Description: Implements tag management system for organizing files
-- Date: 2025-10-31

-- Create tags table
CREATE TABLE IF NOT EXISTS tags (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id VARCHAR(255) NOT NULL,
    name VARCHAR(50) NOT NULL,
    color VARCHAR(7) NOT NULL DEFAULT '#2196F3',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, name)
);

-- Create file_tags junction table
CREATE TABLE IF NOT EXISTS file_tags (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id VARCHAR(255) NOT NULL,
    file_id VARCHAR(255) NOT NULL,
    tag_id UUID NOT NULL REFERENCES tags(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(file_id, tag_id)
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_tags_user_id ON tags(user_id);
CREATE INDEX IF NOT EXISTS idx_tags_name ON tags(name);
CREATE INDEX IF NOT EXISTS idx_file_tags_user_id ON file_tags(user_id);
CREATE INDEX IF NOT EXISTS idx_file_tags_file_id ON file_tags(file_id);
CREATE INDEX IF NOT EXISTS idx_file_tags_tag_id ON file_tags(tag_id);

-- Enable Row Level Security
ALTER TABLE tags ENABLE ROW LEVEL SECURITY;
ALTER TABLE file_tags ENABLE ROW LEVEL SECURITY;

-- RLS Policies for tags table
-- Note: Since we're using Google sub claims as user_id (not Supabase auth.uid()),
-- RLS policies are disabled for now. Access control is handled at the application level.
-- In production, you should implement proper RLS based on your auth strategy.

-- Temporarily disable RLS for development
-- CREATE POLICY "Users can view their own tags"
--     ON tags FOR SELECT
--     USING (user_id = current_setting('app.current_user_id', true));

-- CREATE POLICY "Users can create their own tags"
--     ON tags FOR INSERT
--     WITH CHECK (user_id = current_setting('app.current_user_id', true));

-- CREATE POLICY "Users can update their own tags"
--     ON tags FOR UPDATE
--     USING (user_id = current_setting('app.current_user_id', true));

-- CREATE POLICY "Users can delete their own tags"
--     ON tags FOR DELETE
--     USING (user_id = current_setting('app.current_user_id', true));

-- RLS Policies for file_tags table
-- CREATE POLICY "Users can view their own file tags"
--     ON file_tags FOR SELECT
--     USING (user_id = current_setting('app.current_user_id', true));

-- CREATE POLICY "Users can create their own file tags"
--     ON file_tags FOR INSERT
--     WITH CHECK (user_id = current_setting('app.current_user_id', true));

-- CREATE POLICY "Users can delete their own file tags"
--     ON file_tags FOR DELETE
--     USING (user_id = current_setting('app.current_user_id', true));

-- Create updated_at trigger for tags
CREATE OR REPLACE FUNCTION update_tags_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tags_updated_at_trigger
    BEFORE UPDATE ON tags
    FOR EACH ROW
    EXECUTE FUNCTION update_tags_updated_at();

-- Add comments for documentation
COMMENT ON TABLE tags IS 'User-defined tags for organizing files';
COMMENT ON TABLE file_tags IS 'Junction table linking files to tags';
COMMENT ON COLUMN tags.color IS 'Hex color code for tag display (e.g., #2196F3)';
COMMENT ON COLUMN file_tags.file_id IS 'Google Drive file ID';
