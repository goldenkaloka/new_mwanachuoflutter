-- Add updated_at column to seller_requests table
-- This column is needed by the approve_seller_request RPC function

ALTER TABLE seller_requests
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

-- Create a trigger to automatically update updated_at on row updates
CREATE OR REPLACE FUNCTION update_seller_requests_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop trigger if it exists
DROP TRIGGER IF EXISTS seller_requests_updated_at_trigger ON seller_requests;

-- Create trigger
CREATE TRIGGER seller_requests_updated_at_trigger
  BEFORE UPDATE ON seller_requests
  FOR EACH ROW
  EXECUTE FUNCTION update_seller_requests_updated_at();

-- Update existing rows to have updated_at = created_at
UPDATE seller_requests
SET updated_at = created_at
WHERE updated_at IS NULL;

