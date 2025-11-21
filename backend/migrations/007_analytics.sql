-- Analytics tables for tracking reading sessions and page reads

-- Reading sessions table
CREATE TABLE IF NOT EXISTS reading_sessions (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    file_id TEXT NOT NULL,
    file_name TEXT NOT NULL,
    start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP,
    duration_seconds INTEGER DEFAULT 0,
    pages_read INTEGER DEFAULT 0,
    total_pages INTEGER,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Page read history table
CREATE TABLE IF NOT EXISTS page_read_history (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    file_id TEXT NOT NULL,
    page_number INTEGER NOT NULL,
    first_read_at TIMESTAMP NOT NULL,
    last_read_at TIMESTAMP NOT NULL,
    read_count INTEGER DEFAULT 1,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_reading_sessions_user_id ON reading_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_reading_sessions_file_id ON reading_sessions(file_id);
CREATE INDEX IF NOT EXISTS idx_reading_sessions_start_time ON reading_sessions(start_time);
CREATE INDEX IF NOT EXISTS idx_page_read_history_user_id ON page_read_history(user_id);
CREATE INDEX IF NOT EXISTS idx_page_read_history_file_id ON page_read_history(file_id);
CREATE INDEX IF NOT EXISTS idx_page_read_history_user_file ON page_read_history(user_id, file_id);
