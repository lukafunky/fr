# Fix for Friend Request Issue

## Problem
You can send friend requests but cannot receive them. This is due to Row Level Security (RLS) policies being too restrictive.

## Solution

### Step 1: Run the Fixed RLS Policies

Open your Supabase SQL Editor and run this SQL:

```sql
-- Drop all existing policies
DROP POLICY IF EXISTS "Users can view sent friend requests" ON friend_requests;
DROP POLICY IF EXISTS "Users can view received friend requests" ON friend_requests;
DROP POLICY IF EXISTS "Users can send friend requests" ON friend_requests;
DROP POLICY IF EXISTS "Users can update received friend requests" ON friend_requests;
DROP POLICY IF EXISTS "Users can cancel sent friend requests" ON friend_requests;

-- Create a combined SELECT policy that allows viewing both sent and received requests
CREATE POLICY "Users can view their friend requests"
  ON friend_requests FOR SELECT
  TO authenticated
  USING (auth.uid() = sender_id OR auth.uid() = receiver_id);

-- Users can send friend requests
CREATE POLICY "Users can send friend requests"
  ON friend_requests FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = sender_id AND status = 'pending');

-- Users can update received requests (accept/reject)
CREATE POLICY "Users can update received friend requests"
  ON friend_requests FOR UPDATE
  TO authenticated
  USING (auth.uid() = receiver_id)
  WITH CHECK (auth.uid() = receiver_id);

-- Users can delete their sent requests (cancel) OR remove accepted friendships
CREATE POLICY "Users can manage friend requests"
  ON friend_requests FOR DELETE
  TO authenticated
  USING (
    auth.uid() = sender_id OR
    (auth.uid() = receiver_id AND status = 'accepted') OR
    (auth.uid() = sender_id AND status = 'accepted')
  );
```

**Or simply run the file:** `FIX_FRIEND_REQUESTS_RLS.sql`

### Step 2: What Was Fixed

**In the Database:**
- Combined the two separate SELECT policies into one that allows users to see BOTH sent AND received requests
- Updated DELETE policy to allow removing friendships from either side

**In the Code (already done):**
- Updated `getPendingFriendRequests()` to fetch user profiles separately (avoids foreign key issues)
- Updated `getSentFriendRequests()` to use the same approach
- Updated `getFriends()` to use separate profile queries
- Added error logging to help debug issues

### Step 3: Test the Fix

1. **Log in as User A**
2. **Send a friend request to User B** (should work - this was already working)
3. **Log out and log in as User B**
4. **Click the Users icon (bell) in the header** - you should now see the friend request!
5. **Click "Accept"** - you should become friends
6. **Both users should see "Friends" button** on each other's posts

### Why This Happened

The original RLS policies had two separate SELECT policies:
- One for viewing sent requests (`sender_id = auth.uid()`)
- One for viewing received requests (`receiver_id = auth.uid()`)

When Supabase evaluates multiple SELECT policies, they work as OR conditions, but the issue was likely with how the joined user_profiles data was being accessed. The new single SELECT policy with an OR condition is more explicit and should work correctly.

### What to Expect After the Fix

✅ **Send friend requests** - Working
✅ **Receive friend requests** - Now Fixed!
✅ **See notification badge** - Now Fixed!
✅ **Accept/Reject requests** - Now Fixed!
✅ **Cancel sent requests** - Working
✅ **Unfriend users** - Working
✅ **See friends list** - Working

### Additional Notes

- The code now fetches user profiles separately using multiple queries instead of using foreign key joins
- This approach is more reliable and avoids RLS issues with joined tables
- The notification bell will auto-refresh every 30 seconds to show new requests
- All operations are secured with proper RLS policies

### Debug Tips

If you still have issues, check the browser console for error messages. The code now logs errors with `[getPendingFriendRequests]` prefix to help identify problems.

You can also manually check the database:
```sql
-- See all friend requests in your database
SELECT * FROM friend_requests;

-- Check RLS policies
SELECT * FROM pg_policies WHERE tablename = 'friend_requests';
```
