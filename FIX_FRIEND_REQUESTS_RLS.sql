/*
  # Fix Friend Requests RLS Policies

  This fixes the issue where users cannot see received friend requests.
  Run this SQL in your Supabase SQL Editor.
*/

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
