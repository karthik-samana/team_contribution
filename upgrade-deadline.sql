-- ================================================================
-- UPGRADE: Add deadline feature to existing setup
-- Run this in Supabase SQL Editor (one-time)
-- ================================================================

-- 1. Add deadline and theme columns to settings
ALTER TABLE settings ADD COLUMN IF NOT EXISTS deadline TIMESTAMPTZ DEFAULT NULL;
ALTER TABLE settings ADD COLUMN IF NOT EXISTS theme TEXT DEFAULT 'amadeus';

-- 2. Update the public view to include deadline and theme
CREATE OR REPLACE VIEW public_settings AS
SELECT id, event_name, target_amount, message, is_active,
       upi_id, upi_number, payee_name, deadline, theme, updated_at
FROM settings;

-- Re-grant access
GRANT SELECT ON public_settings TO anon;

-- 3. Update the update_settings function to support deadline
CREATE OR REPLACE FUNCTION update_settings(
  pwd TEXT,
  p_event_name TEXT DEFAULT NULL,
  p_target_amount NUMERIC DEFAULT NULL,
  p_message TEXT DEFAULT NULL,
  p_is_active BOOLEAN DEFAULT NULL,
  p_upi_id TEXT DEFAULT NULL,
  p_upi_number TEXT DEFAULT NULL,
  p_payee_name TEXT DEFAULT NULL,
  p_new_password TEXT DEFAULT NULL,
  p_deadline TEXT DEFAULT NULL,
  p_theme TEXT DEFAULT NULL
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF NOT (SELECT verify_admin(pwd)) THEN
    RETURN json_build_object('success', false, 'message', 'Invalid password');
  END IF;

  IF p_deadline = '' THEN
    UPDATE settings SET deadline = NULL, updated_at = NOW() WHERE id = 1;
  ELSIF p_deadline IS NOT NULL THEN
    UPDATE settings SET deadline = p_deadline::timestamptz, updated_at = NOW() WHERE id = 1;
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
    theme = COALESCE(p_theme, theme),
    updated_at = NOW()
  WHERE id = 1;

  RETURN json_build_object('success', true, 'message', 'Settings updated successfully');
END;
$$;
