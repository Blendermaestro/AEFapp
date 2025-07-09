-- Feedback and Bug Report System Setup
-- Run this in your Supabase SQL editor to add feedback functionality

-- Create feedback table with GDPR compliance fields
CREATE TABLE IF NOT EXISTS feedback (
    id BIGSERIAL PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    sender_name TEXT NOT NULL,
    feedback_type TEXT NOT NULL CHECK (feedback_type IN ('bug', 'feedback', 'suggestion')),
    related_table TEXT NOT NULL CHECK (related_table IN ('PDF', 'PDF2', 'PDF3', 'Excel', 'Settings', 'Auth', 'General')),
    subject TEXT NOT NULL,
    description TEXT NOT NULL,
    user_email TEXT,
    status TEXT DEFAULT 'open' CHECK (status IN ('open', 'in_progress', 'resolved', 'closed')),
    priority TEXT DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'critical')),
    consent_timestamp TIMESTAMPTZ NOT NULL,
    data_retention_until TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE feedback ENABLE ROW LEVEL SECURITY;

-- Create policies for feedback table
CREATE POLICY "Users can view their own feedback" ON feedback
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own feedback" ON feedback
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own feedback" ON feedback
    FOR UPDATE USING (auth.uid() = user_id);

-- Create index for better performance
CREATE INDEX IF NOT EXISTS idx_feedback_user_id ON feedback(user_id);
CREATE INDEX IF NOT EXISTS idx_feedback_created_at ON feedback(created_at);
CREATE INDEX IF NOT EXISTS idx_feedback_status ON feedback(status);

-- Create trigger to automatically update updated_at
CREATE TRIGGER update_feedback_updated_at 
    BEFORE UPDATE ON feedback 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- GDPR Data Retention: Function to automatically delete expired feedback
CREATE OR REPLACE FUNCTION cleanup_expired_feedback()
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    DELETE FROM feedback 
    WHERE data_retention_until < NOW();
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    
    -- Log the cleanup operation
    INSERT INTO feedback_cleanup_log (cleanup_date, deleted_count)
    VALUES (NOW(), deleted_count);
    
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;

-- Create table to log cleanup operations (for GDPR compliance tracking)
CREATE TABLE IF NOT EXISTS feedback_cleanup_log (
    id BIGSERIAL PRIMARY KEY,
    cleanup_date TIMESTAMPTZ DEFAULT NOW(),
    deleted_count INTEGER NOT NULL
);

-- Schedule automatic cleanup (run daily via pg_cron if available)
-- Note: This requires pg_cron extension. If not available, run manually or via external scheduler
-- SELECT cron.schedule('feedback_cleanup', '0 2 * * *', 'SELECT cleanup_expired_feedback();');

-- Confirm setup
SELECT 'GDPR-compliant feedback table setup completed successfully!' as message; 