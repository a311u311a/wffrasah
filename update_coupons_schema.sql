-- Add expiry_date column to coupons table
-- Run this in the Supabase SQL Editor

ALTER TABLE public.coupons 
ADD COLUMN IF NOT EXISTS expiry_date TIMESTAMP WITH TIME ZONE;
