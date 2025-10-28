-- ============================================================
-- STEP 1: Create missing user profiles (fixes commenting issue)
-- ============================================================

INSERT INTO public.user_profiles (id, full_name, email, created_at, updated_at)
SELECT
  au.id,
  COALESCE(au.raw_user_meta_data->>'full_name', au.email, 'User') as full_name,
  au.email,
  au.created_at,
  NOW()
FROM auth.users au
WHERE NOT EXISTS (
  SELECT 1 FROM public.user_profiles up WHERE up.id = au.id
)
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- STEP 2: Add hashtags column to social_posts table
-- ============================================================

-- Add hashtags column if it doesn't exist
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
  SELECT array_agg(DISTINCT lower(regexp_replace(match[1], '^#', '')))
  FROM regexp_matches(caption, '#[\w\u0080-\uFFFF]+', 'g') AS match
)
WHERE (hashtags IS NULL OR hashtags = '{}') AND caption ~ '#[\w\u0080-\uFFFF]+';

-- ============================================================
-- VERIFICATION QUERIES
-- ============================================================

-- Check that hashtags column was added
SELECT
  column_name,
  data_type,
  column_default
FROM information_schema.columns
WHERE table_name = 'social_posts' AND column_name = 'hashtags';

-- Check user profiles were created
SELECT
  COUNT(*) as total_users_with_profiles
FROM user_profiles;

-- Check sample posts with hashtags
SELECT
  id,
  caption,
  hashtags,
  created_at
FROM social_posts
ORDER BY created_at DESC
LIMIT 5;
