-- Create users table
CREATE TABLE IF NOT EXISTS public.users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    google_sub TEXT UNIQUE NOT NULL,
    email TEXT NOT NULL,
    name TEXT,
    picture_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index on google_sub for faster lookups
CREATE INDEX IF NOT EXISTS idx_users_google_sub ON public.users(google_sub);

-- Create index on email for faster lookups
CREATE INDEX IF NOT EXISTS idx_users_email ON public.users(email);

-- Create encrypted_tokens table
CREATE TABLE IF NOT EXISTS public.encrypted_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    token_type TEXT NOT NULL,
    encrypted_token TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, token_type)
);

-- Create index on user_id for faster lookups
CREATE INDEX IF NOT EXISTS idx_encrypted_tokens_user_id ON public.encrypted_tokens(user_id);

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to automatically update updated_at on users table
DROP TRIGGER IF EXISTS update_users_updated_at ON public.users;
CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON public.users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Create trigger to automatically update updated_at on encrypted_tokens table
DROP TRIGGER IF EXISTS update_encrypted_tokens_updated_at ON public.encrypted_tokens;
CREATE TRIGGER update_encrypted_tokens_updated_at
    BEFORE UPDATE ON public.encrypted_tokens
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Enable Row Level Security (RLS)
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.encrypted_tokens ENABLE ROW LEVEL SECURITY;

-- Create policies for service role (backend) to access all data
CREATE POLICY "Service role can do everything on users"
    ON public.users
    FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

CREATE POLICY "Service role can do everything on encrypted_tokens"
    ON public.encrypted_tokens
    FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);
