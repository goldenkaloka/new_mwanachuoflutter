-- Enhanced Notification Preferences with Categories, Actions, and Grouping
-- This migration extends the existing notification_preferences table

-- Add new columns for enhanced preferences
ALTER TABLE notification_preferences
ADD COLUMN IF NOT EXISTS quiet_hours_start TIME DEFAULT NULL,
ADD COLUMN IF NOT EXISTS quiet_hours_end TIME DEFAULT NULL,
ADD COLUMN IF NOT EXISTS group_notifications BOOLEAN DEFAULT true,
ADD COLUMN IF NOT EXISTS group_by_category BOOLEAN DEFAULT true,
ADD COLUMN IF NOT EXISTS sound_enabled BOOLEAN DEFAULT true,
ADD COLUMN IF NOT EXISTS vibration_enabled BOOLEAN DEFAULT true,
ADD COLUMN IF NOT EXISTS badge_enabled BOOLEAN DEFAULT true,
ADD COLUMN IF NOT EXISTS in_app_banner_enabled BOOLEAN DEFAULT true,
ADD COLUMN IF NOT EXISTS category_preferences JSONB DEFAULT '{
  "message": {"enabled": true, "sound": true, "vibration": true, "priority": "high"},
  "review": {"enabled": true, "sound": true, "vibration": true, "priority": "medium"},
  "order": {"enabled": true, "sound": true, "vibration": true, "priority": "high"},
  "promotion": {"enabled": true, "sound": false, "vibration": false, "priority": "low"},
  "seller_request": {"enabled": true, "sound": true, "vibration": true, "priority": "high"},
  "listing": {"enabled": true, "sound": false, "vibration": false, "priority": "low"}
}'::jsonb;

-- Create notification_actions table for custom notification actions
CREATE TABLE IF NOT EXISTS notification_actions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  notification_id TEXT NOT NULL,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  action_type TEXT NOT NULL CHECK (action_type IN ('reply', 'view', 'dismiss', 'snooze', 'mark_read')),
  action_label TEXT,
  action_url TEXT,
  metadata JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create notification_groups table for grouping related notifications
CREATE TABLE IF NOT EXISTS notification_groups (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  group_key TEXT NOT NULL, -- e.g., "message_conversation_123" or "review_product_456"
  category TEXT NOT NULL, -- 'message', 'review', 'order', etc.
  title TEXT NOT NULL,
  summary TEXT,
  unread_count INT DEFAULT 0,
  latest_notification_id TEXT,
  latest_notification_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, group_key)
);

-- Create notification_group_members table to link notifications to groups
CREATE TABLE IF NOT EXISTS notification_group_members (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  group_id UUID NOT NULL REFERENCES notification_groups(id) ON DELETE CASCADE,
  notification_id TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(group_id, notification_id)
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_notification_actions_user_id 
  ON notification_actions(user_id);
CREATE INDEX IF NOT EXISTS idx_notification_actions_notification_id 
  ON notification_actions(notification_id);

CREATE INDEX IF NOT EXISTS idx_notification_groups_user_id 
  ON notification_groups(user_id);
CREATE INDEX IF NOT EXISTS idx_notification_groups_category 
  ON notification_groups(category);
CREATE INDEX IF NOT EXISTS idx_notification_groups_updated_at 
  ON notification_groups(updated_at DESC);

CREATE INDEX IF NOT EXISTS idx_notification_group_members_group_id 
  ON notification_group_members(group_id);
CREATE INDEX IF NOT EXISTS idx_notification_group_members_notification_id 
  ON notification_group_members(notification_id);

-- Enable Row Level Security
ALTER TABLE notification_actions ENABLE ROW LEVEL SECURITY;
ALTER TABLE notification_groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE notification_group_members ENABLE ROW LEVEL SECURITY;

-- RLS Policies for notification_actions
CREATE POLICY "Users can view own notification actions"
  ON notification_actions
  FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own notification actions"
  ON notification_actions
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- RLS Policies for notification_groups
CREATE POLICY "Users can view own notification groups"
  ON notification_groups
  FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own notification groups"
  ON notification_groups
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own notification groups"
  ON notification_groups
  FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own notification groups"
  ON notification_groups
  FOR DELETE
  USING (auth.uid() = user_id);

-- RLS Policies for notification_group_members
CREATE POLICY "Users can view own notification group members"
  ON notification_group_members
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM notification_groups
      WHERE notification_groups.id = notification_group_members.group_id
      AND notification_groups.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can insert own notification group members"
  ON notification_group_members
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM notification_groups
      WHERE notification_groups.id = notification_group_members.group_id
      AND notification_groups.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can delete own notification group members"
  ON notification_group_members
  FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM notification_groups
      WHERE notification_groups.id = notification_group_members.group_id
      AND notification_groups.user_id = auth.uid()
    )
  );

-- Function to update notification group when new notification is added
CREATE OR REPLACE FUNCTION update_notification_group()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE notification_groups
  SET 
    unread_count = unread_count + 1,
    latest_notification_id = NEW.notification_id,
    latest_notification_at = NOW(),
    updated_at = NOW()
  WHERE id = NEW.group_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to auto-update notification groups
CREATE TRIGGER trigger_update_notification_group
  AFTER INSERT ON notification_group_members
  FOR EACH ROW
  EXECUTE FUNCTION update_notification_group();

-- Function to mark notification group as read
CREATE OR REPLACE FUNCTION mark_notification_group_read(group_id_param UUID)
RETURNS void AS $$
BEGIN
  UPDATE notification_groups
  SET unread_count = 0
  WHERE id = group_id_param AND user_id = auth.uid();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

