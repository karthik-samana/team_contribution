-- Run this in your Supabase SQL Editor (one-time setup)

-- 1. Create the contributions table
CREATE TABLE contributions (
  id BIGSERIAL PRIMARY KEY,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  name TEXT NOT NULL CHECK (char_length(name) > 0 AND char_length(name) <= 100),
  amount NUMERIC NOT NULL CHECK (amount > 0 AND amount <= 100000),
  upi_ref TEXT DEFAULT '',
  status TEXT DEFAULT 'Pending Verification',
  event_name TEXT NOT NULL
);

-- 2. Enable Row Level Security
ALTER TABLE contributions ENABLE ROW LEVEL SECURITY;

-- 3. Allow anyone to INSERT (contribute)
CREATE POLICY "Anyone can contribute"
  ON contributions FOR INSERT
  WITH CHECK (true);

-- 4. Allow anyone to SELECT (see contributions)
CREATE POLICY "Anyone can view contributions"
  ON contributions FOR SELECT
  USING (true);

-- 5. No UPDATE or DELETE allowed from client side
-- (You can still edit rows directly in the Supabase dashboard)
