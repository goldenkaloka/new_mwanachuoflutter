-- Migration to enhance promotions table
-- Adds support for video promotions and better CTA control

ALTER TABLE promotions 
ADD COLUMN IF NOT EXISTS type TEXT DEFAULT 'banner' CHECK (type IN ('banner', 'video')),
ADD COLUMN IF NOT EXISTS video_url TEXT,
ADD COLUMN IF NOT EXISTS priority INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS button_text TEXT DEFAULT 'Shop Now';

-- Ensure existing rows have the default type
UPDATE promotions SET type = 'banner' WHERE type IS NULL;
