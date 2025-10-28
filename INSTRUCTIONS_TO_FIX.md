# Instructions to Fix Comments and Hashtags

## Problem
The database migration to add the `hashtags` column to the `social_posts` table was created but not applied to your Supabase database. This is causing the error: "Could not find the 'hashtags' column of 'social_posts' in the schema cache"

## Solution

### Step 1: Apply the Database Migration

1. **Go to your Supabase Dashboard**
   - Navigate to: https://supabase.com/dashboard
   - Select your project

2. **Open the SQL Editor**
   - Click on "SQL Editor" in the left sidebar
   - Click "New query"

3. **Run the Migration SQL**
   - Open the file: `APPLY_THIS_SQL.sql` (in your project root)
   - Copy ALL the SQL content from that file
   - Paste it into the SQL Editor
   - Click "Run" or press Ctrl/Cmd + Enter

4. **Verify the Migration**
   - After running, you should see a success message
   - The verification queries at the bottom will show if the column was added

### Step 2: Refresh Your Application

1. After applying the SQL, refresh your application in the browser
2. Try creating a post with hashtags (e.g., "Great party! #festival #music")
3. Try commenting on a post
4. Try editing your bio in your profile

## What Was Fixed

### 1. Comments System
- The comment system now properly maps user names from user profiles
- Comments will display the correct user name and avatar
- All authenticated users can comment on posts

### 2. Hashtags Display
- Hashtags are extracted from post captions automatically
- They're stored separately in the database
- They display as styled blue tags below the post content
- Examples: #party, #festival, #concert

### 3. Bio Field
- The bio field in the user profile is correctly configured
- It should save and display without issues
- If you're still having issues with the bio, please describe exactly what happens when you try to type in it

## Files Modified

1. `src/lib/social.ts` - Updated to handle hashtags and fix comment user names
2. `src/components/SocialFeed/PostCard.tsx` - Added hashtag display
3. `supabase/migrations/20251020150000_add_hashtags_to_social_posts.sql` - New migration file

## If Problems Persist

If after applying the SQL you still have issues:

1. **Clear browser cache** and reload
2. **Check browser console** for any error messages (F12 > Console tab)
3. **Verify the migration ran** by running this query in Supabase SQL Editor:
   ```sql
   SELECT column_name FROM information_schema.columns
   WHERE table_name = 'social_posts';
   ```
   You should see 'hashtags' in the list

4. **For bio field issues**: Take a screenshot showing exactly what happens when you try to edit your bio, and describe the behavior

## Need Help?

If you need assistance:
1. Share the exact error message from the browser console
2. Confirm whether the SQL migration ran successfully
3. Describe what specific functionality is not working
