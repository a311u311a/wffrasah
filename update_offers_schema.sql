-- Add expiry_date column to offers table
-- Run this in the Supabase SQL Editor

ALTER TABLE public.offers 
ADD COLUMN IF NOT EXISTS expiry_date TIMESTAMP WITH TIME ZONE;
