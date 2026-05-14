-- ================================================================
-- ADMIN SETUP — Run this in Supabase SQL Editor (one-time)
-- Run this AFTER setup.sql
-- ================================================================

-- 1. Settings table (stores event config + admin password)
CREATE TABLE settings (
  id INT PRIMARY KEY DEFAULT 1 CHECK (id = 1),
  event_name TEXT NOT NULL DEFAULT 'Team Contribution',
  target_amount NUMERIC NOT NULL DEFAULT 5000,
  message TEXT DEFAULT '',
  is_active BOOLEAN DEFAULT true,
  admin_password TEXT NOT NULL DEFAULT 'admin123',
  upi_id TEXT NOT NULL DEFAULT 'skar1234@ybl',
  upi_number TEXT DEFAULT '9347134395',
  payee_name TEXT DEFAULT 'Team Contribution',
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Enable RLS on settings (no direct client access)
ALTER TABLE settings ENABLE ROW LEVEL SECURITY;

-- 3. Public view (excludes password — this is what the public page reads)
CREATE OR REPLACE VIEW public_settings AS
SELECT id, event_name, target_amount, message, is_active,
       upi_id, upi_number, payee_name, updated_at
FROM settings;

-- Grant read access on the view to anonymous users
GRANT SELECT ON public_settings TO anon;

-- 4. Insert default settings
INSERT INTO settings (
  event_name, target_amount, message, is_active,
  admin_password, upi_id, upi_number, payee_name
) VALUES (
  'Celebrating Puneeth & Hari Priya',
  5000,
  'As Puneeth and Hari Priya begin a new chapter in their journey, we would like to come together and express our gratitude for all the memories, support, collaboration, and positivity they brought to the team.

Working with both of them has truly been special — from solving challenges together to sharing everyday moments that made work enjoyable. Their presence, dedication, and kindness have left a lasting impact on all of us.

This page is a small effort from the team to share our wishes, memories, and contributions as a token of appreciation.

Wishing Puneeth and Hari Priya continued success, happiness, growth, and exciting opportunities ahead. You both will always be remembered fondly and genuinely missed.

Thank you for everything, and all the very best for what''s next!',
  true,
  'admin123',
  'skar1234@ybl',
  '9347134395',
  'Team Contribution'
);

-- ================================================================
-- ADMIN RPC FUNCTIONS (password-protected, run server-side)
-- ================================================================

-- 5. Verify admin password
CREATE OR REPLACE FUNCTION verify_admin(pwd TEXT)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
AS $$
  SELECT EXISTS (SELECT 1 FROM settings WHERE id = 1 AND admin_password = pwd);
$$;

-- 6. Update settings
CREATE OR REPLACE FUNCTION update_settings(
  pwd TEXT,
  p_event_name TEXT DEFAULT NULL,
  p_target_amount NUMERIC DEFAULT NULL,
  p_message TEXT DEFAULT NULL,
  p_is_active BOOLEAN DEFAULT NULL,
  p_upi_id TEXT DEFAULT NULL,
  p_upi_number TEXT DEFAULT NULL,
  p_payee_name TEXT DEFAULT NULL,
  p_new_password TEXT DEFAULT NULL
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF NOT (SELECT verify_admin(pwd)) THEN
    RETURN json_build_object('success', false, 'message', 'Invalid password');
  END IF;

  UPDATE settings SET
    event_name = COALESCE(p_event_name, event_name),
    target_amount = COALESCE(p_target_amount, target_amount),
    message = COALESCE(p_message, message),
    is_active = COALESCE(p_is_active, is_active),
    upi_id = COALESCE(p_upi_id, upi_id),
    upi_number = COALESCE(p_upi_number, upi_number),
    payee_name = COALESCE(p_payee_name, payee_name),
    admin_password = COALESCE(p_new_password, admin_password),
    updated_at = NOW()
  WHERE id = 1;

  RETURN json_build_object('success', true, 'message', 'Settings updated successfully');
END;
$$;

-- 7. Update contribution status (verify / pending)
CREATE OR REPLACE FUNCTION update_contribution_status(
  pwd TEXT,
  contrib_id BIGINT,
  new_status TEXT
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF NOT (SELECT verify_admin(pwd)) THEN
    RETURN json_build_object('success', false, 'message', 'Invalid password');
  END IF;

  UPDATE contributions SET status = new_status WHERE id = contrib_id;
  RETURN json_build_object('success', true, 'message', 'Status updated');
END;
$$;

-- 8. Delete a contribution
CREATE OR REPLACE FUNCTION delete_contribution(
  pwd TEXT,
  contrib_id BIGINT
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF NOT (SELECT verify_admin(pwd)) THEN
    RETURN json_build_object('success', false, 'message', 'Invalid password');
  END IF;

  DELETE FROM contributions WHERE id = contrib_id;
  RETURN json_build_object('success', true, 'message', 'Contribution deleted');
END;
$$;

-- 9. Get all contributions (admin view — includes id, upi_ref, all events)
CREATE OR REPLACE FUNCTION admin_get_contributions(pwd TEXT)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF NOT (SELECT verify_admin(pwd)) THEN
    RETURN json_build_object('success', false, 'message', 'Invalid password');
  END IF;

  RETURN json_build_object('success', true, 'data', (
    SELECT COALESCE(json_agg(row_to_json(c)), '[]'::json)
    FROM (
      SELECT id, created_at, name, amount, upi_ref, status, event_name
      FROM contributions
      ORDER BY created_at DESC
    ) c
  ));
END;
$$;
