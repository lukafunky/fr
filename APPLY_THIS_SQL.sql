-- ===================================================================
-- RUN THIS SQL IN YOUR SUPABASE SQL EDITOR
-- ===================================================================
-- This will add the hashtags column to social_posts table
-- Go to: Supabase Dashboard > SQL Editor > New Query
-- Copy and paste this entire content, then click "Run"
-- ===================================================================

-- Add hashtags column to social_posts table
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'social_posts' AND column_name = 'hashtags'
  ) THEN
    ALTER TABLE social_posts ADD COLUMN hashtags text[] DEFAULT '{}';
  END IF;
END $$;

-- Create index on hashtags for efficient searching
CREATE INDEX IF NOT EXISTS idx_social_posts_hashtags ON social_posts USING GIN (hashtags);

-- Update existing posts to extract hashtags from caption
UPDATE social_posts
SET hashtags = (
  SELECT array_agg(DISTINCT lower(substring(match FROM 2)))
  FROM regexp_matches(caption, '#[\w\u0080-\uFFFF]+', 'g') AS match
)
WHERE hashtags = '{}' AND caption ~ '#[\w\u0080-\uFFFF]+';

-- ===================================================================
-- VERIFICATION QUERIES (Run these after the above to verify)
-- ===================================================================

-- Check if the hashtags column was added successfully
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'social_posts' AND column_name = 'hashtags';

-- Check if any posts have hashtags
SELECT id, caption, hashtags
FROM social_posts
LIMIT 5;
