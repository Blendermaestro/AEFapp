-- Migration script to add PDF2 and PDF3 tab support
-- Run this in your Supabase SQL editor to add support for the new PDF tabs

-- Add the new columns for PDF2 and PDF3 tabs to user_settings table
ALTER TABLE user_settings 
ADD COLUMN IF NOT EXISTS pdf2_supervisor TEXT DEFAULT '',
ADD COLUMN IF NOT EXISTS pdf2_date TEXT DEFAULT '',
ADD COLUMN IF NOT EXISTS pdf2_shift TEXT DEFAULT '',
ADD COLUMN IF NOT EXISTS pdf3_supervisor TEXT DEFAULT '',
ADD COLUMN IF NOT EXISTS pdf3_date TEXT DEFAULT '',
ADD COLUMN IF NOT EXISTS pdf3_shift TEXT DEFAULT '',
ADD COLUMN IF NOT EXISTS shift_notes2 JSONB DEFAULT '[""]'::jsonb,
ADD COLUMN IF NOT EXISTS shift_notes3 JSONB DEFAULT '[""]'::jsonb;

-- Add columns for PDF2 and PDF3 names in work_cards table
ALTER TABLE work_cards
ADD COLUMN IF NOT EXISTS pdf2_name1 TEXT DEFAULT '',
ADD COLUMN IF NOT EXISTS pdf2_name2 TEXT DEFAULT '',
ADD COLUMN IF NOT EXISTS pdf3_name1 TEXT DEFAULT '',
ADD COLUMN IF NOT EXISTS pdf3_name2 TEXT DEFAULT '';

-- Verify the columns were added successfully
SELECT 
    column_name, 
    data_type, 
    column_default
FROM information_schema.columns 
WHERE table_name = 'user_settings' 
    AND (column_name LIKE 'pdf%' OR column_name LIKE 'shift_notes%')
ORDER BY column_name;

-- Confirm migration completed
SELECT 'PDF2 and PDF3 columns added successfully!' as message; 