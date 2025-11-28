-- Migration: Add subscription and payment system
-- Description: Implements subscription management and payment transaction tracking
-- Date: 2025-11-28

-- ============================================================================
-- EXTEND USERS TABLE WITH SUBSCRIPTION FIELDS
-- ============================================================================

-- Add subscription fields to existing users table
ALTER TABLE users ADD COLUMN IF NOT EXISTS subscription_status VARCHAR(20) DEFAULT 'free';
ALTER TABLE users ADD COLUMN IF NOT EXISTS subscription_activated_at TIMESTAMP WITH TIME ZONE;
ALTER TABLE users ADD COLUMN IF NOT EXISTS subscription_expires_at TIMESTAMP WITH TIME ZONE;

-- Add check constraint for subscription status
ALTER TABLE users ADD CONSTRAINT check_subscription_status 
    CHECK (subscription_status IN ('free', 'premium'));

-- Add index for subscription queries
CREATE INDEX IF NOT EXISTS idx_users_subscription_status ON users(subscription_status);
CREATE INDEX IF NOT EXISTS idx_users_subscription_expires ON users(subscription_expires_at);

-- Add comments for documentation
COMMENT ON COLUMN users.subscription_status IS 'User subscription plan: free or premium';
COMMENT ON COLUMN users.subscription_activated_at IS 'Timestamp when premium subscription was activated';
COMMENT ON COLUMN users.subscription_expires_at IS 'Timestamp when premium subscription expires';

-- ============================================================================
-- TRANSACTIONS TABLE
-- ============================================================================

-- Create transactions table for payment history
CREATE TABLE IF NOT EXISTS transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    transaction_id VARCHAR(50) UNIQUE NOT NULL,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    payment_method VARCHAR(20) NOT NULL,
    amount DECIMAL(10, 2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'BDT',
    status VARCHAR(20) NOT NULL,
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    verified_at TIMESTAMP WITH TIME ZONE,
    
    CONSTRAINT check_payment_method 
        CHECK (payment_method IN ('bkash', 'debit_card', 'credit_card')),
    CONSTRAINT check_status 
        CHECK (status IN ('pending', 'success', 'failed')),
    CONSTRAINT check_amount_positive
        CHECK (amount > 0)
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_transactions_user_id ON transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_transactions_transaction_id ON transactions(transaction_id);
CREATE INDEX IF NOT EXISTS idx_transactions_status ON transactions(status);
CREATE INDEX IF NOT EXISTS idx_transactions_created_at ON transactions(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_transactions_user_created ON transactions(user_id, created_at DESC);

-- Enable Row Level Security
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;

-- Add comments for documentation
COMMENT ON TABLE transactions IS 'Payment transaction history for subscription management';
COMMENT ON COLUMN transactions.transaction_id IS 'Unique transaction identifier from payment gateway';
COMMENT ON COLUMN transactions.user_id IS 'Reference to user who made the payment';
COMMENT ON COLUMN transactions.payment_method IS 'Payment method used: bkash, debit_card, or credit_card';
COMMENT ON COLUMN transactions.amount IS 'Payment amount in specified currency';
COMMENT ON COLUMN transactions.currency IS 'Currency code (default: BDT for Bangladeshi Taka)';
COMMENT ON COLUMN transactions.status IS 'Transaction status: pending, success, or failed';
COMMENT ON COLUMN transactions.metadata IS 'Additional payment details stored as JSON';
COMMENT ON COLUMN transactions.created_at IS 'Timestamp when transaction was initiated';
COMMENT ON COLUMN transactions.verified_at IS 'Timestamp when transaction was verified/completed';

-- ============================================================================
-- ROW LEVEL SECURITY POLICIES
-- ============================================================================

-- Note: Since we're using Google sub claims as user_id (not Supabase auth.uid()),
-- RLS policies are disabled for now. Access control is handled at the application level.
-- In production, you should implement proper RLS based on your auth strategy.

-- RLS Policies for transactions table (commented out for development)
-- These can be enabled when proper auth integration is implemented

-- CREATE POLICY "Users can view their own transactions"
--     ON transactions FOR SELECT
--     USING (user_id = current_setting('app.current_user_id', true)::UUID);

-- CREATE POLICY "System can insert transactions"
--     ON transactions FOR INSERT
--     WITH CHECK (true);

-- CREATE POLICY "System can update transactions"
--     ON transactions FOR UPDATE
--     USING (true);

-- ============================================================================
-- TRIGGERS
-- ============================================================================

-- Create updated_at trigger function if it doesn't exist
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Add trigger to users table for updated_at (if not already exists)
DROP TRIGGER IF EXISTS users_updated_at_trigger ON users;
CREATE TRIGGER users_updated_at_trigger
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- MIGRATION VERIFICATION
-- ============================================================================

-- Verify tables exist
DO $$
BEGIN
    -- Check users table has subscription columns
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'users' AND column_name = 'subscription_status'
    ) THEN
        RAISE EXCEPTION 'Migration failed: subscription_status column not added to users table';
    END IF;
    
    -- Check transactions table exists
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_name = 'transactions'
    ) THEN
        RAISE EXCEPTION 'Migration failed: transactions table not created';
    END IF;
    
    RAISE NOTICE 'Migration 006_subscription_system completed successfully';
END $$;
