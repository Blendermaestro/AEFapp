-- Migration script to add missing columns to existing work_cards table
-- Run this in your Supabase SQL editor to fix the data loss issue

-- Add the missing columns to work_cards table
ALTER TABLE work_cards 
ADD COLUMN IF NOT EXISTS work_site_conditions JSONB DEFAULT '[""]'::jsonb,
ADD COLUMN IF NOT EXISTS supervisor_risk_notes JSONB DEFAULT '[""]'::jsonb;

-- Confirm the columns were added
SELECT 'Missing columns added successfully!' as message; 