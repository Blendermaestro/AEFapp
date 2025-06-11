-- Supabase Database Setup for Work Card App
-- This script will drop and recreate all tables and policies

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view their own work cards" ON work_cards;
DROP POLICY IF EXISTS "Users can insert their own work cards" ON work_cards;
DROP POLICY IF EXISTS "Users can update their own work cards" ON work_cards;
DROP POLICY IF EXISTS "Users can delete their own work cards" ON work_cards;
DROP POLICY IF EXISTS "Users can view their own settings" ON user_settings;
DROP POLICY IF EXISTS "Users can insert their own settings" ON user_settings;
DROP POLICY IF EXISTS "Users can update their own settings" ON user_settings;
DROP POLICY IF EXISTS "Users can delete their own settings" ON user_settings;

-- Drop existing triggers if they exist
DROP TRIGGER IF EXISTS update_work_cards_updated_at ON work_cards;
DROP TRIGGER IF EXISTS update_user_settings_updated_at ON user_settings;

-- Drop existing tables if they exist
DROP TABLE IF EXISTS work_cards CASCADE;
DROP TABLE IF EXISTS user_settings CASCADE;

-- Drop function if it exists
DROP FUNCTION IF EXISTS update_updated_at_column();

-- Create work_cards table
CREATE TABLE work_cards (
    id BIGSERIAL PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    profession_name TEXT NOT NULL,
    pdf_name1 TEXT DEFAULT '',
    pdf_name2 TEXT DEFAULT '',
    excel_name1 TEXT DEFAULT '',
    excel_name2 TEXT DEFAULT '',
    tasks JSONB DEFAULT '[]'::jsonb,
    equipment TEXT DEFAULT '',
    equipment_location TEXT DEFAULT '',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create user_settings table
CREATE TABLE user_settings (
    id BIGSERIAL PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL UNIQUE,
    pdf_supervisor TEXT DEFAULT '',
    pdf_date TEXT DEFAULT '',
    pdf_shift TEXT DEFAULT '',
    excel_supervisor TEXT DEFAULT '',
    excel_date TEXT DEFAULT '',
    excel_shift TEXT DEFAULT '',
    global_notice TEXT DEFAULT '',
    shift_notes JSONB DEFAULT '[""]'::jsonb,
    comments JSONB DEFAULT '[""]'::jsonb,
    extra_work JSONB DEFAULT '[""]'::jsonb,
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable Row Level Security for both tables
ALTER TABLE work_cards ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_settings ENABLE ROW LEVEL SECURITY;

-- Create policies for work_cards table
CREATE POLICY "Users can view their own work cards" ON work_cards
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own work cards" ON work_cards
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own work cards" ON work_cards
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own work cards" ON work_cards
    FOR DELETE USING (auth.uid() = user_id);

-- Create policies for user_settings table
CREATE POLICY "Users can view their own settings" ON user_settings
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own settings" ON user_settings
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own settings" ON user_settings
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own settings" ON user_settings
    FOR DELETE USING (auth.uid() = user_id);

-- Create indexes for better performance
CREATE INDEX idx_work_cards_user_id ON work_cards(user_id);
CREATE INDEX idx_work_cards_created_at ON work_cards(created_at);
CREATE INDEX idx_user_settings_user_id ON user_settings(user_id);

-- Create function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers to automatically update updated_at
CREATE TRIGGER update_work_cards_updated_at 
    BEFORE UPDATE ON work_cards 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_settings_updated_at 
    BEFORE UPDATE ON user_settings 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Confirm setup
SELECT 'Supabase database setup completed successfully!' as message; 