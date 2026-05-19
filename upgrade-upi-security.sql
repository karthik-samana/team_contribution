-- ================================================================
-- UPGRADE: Secure UPI Settings with Email OTP
-- Run this in Supabase SQL Editor (one-time)
-- SAFE: Does NOT delete or modify any existing data
-- ================================================================

-- Step 1: Update update_settings to STOP allowing UPI changes via admin password
-- UPI fields are kept in the signature for backwards compatibility but are IGNORED
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

  -- NOTE: p_upi_id, p_upi_number, p_payee_name are intentionally IGNORED here
  -- UPI settings can ONLY be changed via update_upi_secure (requires @amadeus.com email OTP)
  UPDATE settings SET
    event_name = COALESCE(p_event_name, event_name),
    target_amount = COALESCE(p_target_amount, target_amount),
    message = COALESCE(p_message, message),
    is_active = COALESCE(p_is_active, is_active),
    admin_password = COALESCE(p_new_password, admin_password),
    theme = COALESCE(p_theme, theme),
    updated_at = NOW()
  WHERE id = 1;

  RETURN json_build_object('success', true, 'message', 'Settings updated successfully');
END;
$$;

-- Step 2: Create secure UPI update function
-- Requires authenticated user with @amadeus.com email (via Supabase Auth OTP)
CREATE OR REPLACE FUNCTION update_upi_secure(
  p_upi_id TEXT DEFAULT NULL,
  p_upi_number TEXT DEFAULT NULL,
  p_payee_name TEXT DEFAULT NULL
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  user_email TEXT;
BEGIN
  -- Get the authenticated user's email from the JWT token
  user_email := auth.jwt() ->> 'email';

  -- Reject if not authenticated or not @amadeus.com
  IF user_email IS NULL THEN
    RETURN json_build_object('success', false, 'message', 'Authentication required. Please verify with email OTP first.');
  END IF;

  IF NOT (user_email LIKE '%@amadeus.com') THEN
    RETURN json_build_object('success', false, 'message', 'Only @amadeus.com email addresses can update UPI settings.');
  END IF;

  -- Update only the UPI-related fields
  UPDATE settings SET
    upi_id = COALESCE(p_upi_id, upi_id),
    upi_number = COALESCE(p_upi_number, upi_number),
    payee_name = COALESCE(p_payee_name, payee_name),
    updated_at = NOW()
  WHERE id = 1;

  RETURN json_build_object('success', true, 'message', 'UPI settings updated securely.');
END;
$$;
