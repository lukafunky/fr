-- ============================================================
-- Fix commenting system by creating proper foreign key relationship
-- ============================================================

-- Drop the existing foreign key constraint if it exists
DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.table_constraints
    WHERE constraint_name = 'post_comments_user_id_fkey'
    AND table_name = 'post_comments'
  ) THEN
    ALTER TABLE post_comments DROP CONSTRAINT post_comments_user_id_fkey;
  END IF;
END $$;

-- Recreate the foreign key with proper naming for PostgREST relationships
ALTER TABLE post_comments
ADD CONSTRAINT post_comments_user_id_fkey
FOREIGN KEY (user_id)
REFERENCES user_profiles(id)
ON DELETE CASCADE;

-- Ensure all users who have made comments have profiles
INSERT INTO public.user_profiles (id, full_name, email, created_at, updated_at)
SELECT DISTINCT
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

-- Verification queries
SELECT 'Foreign key constraint:' as check_type, constraint_name, table_name
FROM information_schema.table_constraints
WHERE constraint_name = 'post_comments_user_id_fkey';

SELECT 'User profiles count:' as check_type, COUNT(*) as count
FROM user_profiles;

SELECT 'Hashtags column:' as check_type, column_name, data_type
FROM information_schema.columns
WHERE table_name = 'social_posts' AND column_name = 'hashtags';
