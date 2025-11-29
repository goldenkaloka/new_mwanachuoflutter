-- Create notification_analytics table for tracking push notification engagement
CREATE TABLE IF NOT EXISTS notification_analytics (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  notification_id TEXT NOT NULL,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  event_type TEXT NOT NULL CHECK (event_type IN ('delivery', 'tap', 'dismiss', 'conversion')),
  notification_type TEXT,
  target_screen TEXT,
  conversion_action TEXT,
  is_automatic_dismiss BOOLEAN DEFAULT false,
  metadata JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_notification_analytics_user_id 
  ON notification_analytics(user_id);

CREATE INDEX IF NOT EXISTS idx_notification_analytics_notification_id 
  ON notification_analytics(notification_id);

CREATE INDEX IF NOT EXISTS idx_notification_analytics_created_at 
  ON notification_analytics(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_notification_analytics_event_type 
  ON notification_analytics(event_type);

-- Enable Row Level Security
ALTER TABLE notification_analytics ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only view their own analytics
CREATE POLICY "Users can view own analytics"
  ON notification_analytics
  FOR SELECT
  USING (auth.uid() = user_id);

-- Policy: System can insert analytics (authenticated users)
CREATE POLICY "Authenticated users can insert analytics"
  ON notification_analytics
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Optional: Grant access to service role for admin queries
-- GRANT ALL ON notification_analytics TO service_role;
