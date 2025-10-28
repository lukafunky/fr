/*
  # Friend Requests System Migration

  Run this SQL in your Supabase SQL Editor to add friend request functionality.

  1. New Tables
    - `friend_requests`
      - `id` (uuid, primary key)
      - `sender_id` (uuid, references auth.users) - user who sent the request
      - `receiver_id` (uuid, references auth.users) - user who receives the request
      - `status` (text) - 'pending', 'accepted', 'rejected'
      - `created_at` (timestamptz)
      - `updated_at` (timestamptz)
      - Unique constraint on (sender_id, receiver_id)
      - Check constraint to prevent self-friending

  2. Indexes
    - Index on sender_id for efficient lookup of sent requests
    - Index on receiver_id for efficient lookup of received requests
    - Index on status for filtering by request status
    - Composite index on (receiver_id, status) for pending requests lookup

  3. Security
    - Enable RLS on friend_requests table
    - Users can view their own sent and received friend requests
    - Users can create friend requests where they are the sender
    - Users can update requests where they are the receiver (accepting/rejecting)
    - Users can delete requests where they are the sender (canceling)

  4. Triggers
    - Automatically update updated_at timestamp on changes
*/

-- Create friend_requests table
CREATE TABLE IF NOT EXISTS friend_requests (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  sender_id uuid REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  receiver_id uuid REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  status text NOT NULL DEFAULT 'pending',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(sender_id, receiver_id),
  CHECK (sender_id != receiver_id),
  CHECK (status IN ('pending', 'accepted', 'rejected'))
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_friend_requests_sender_id ON friend_requests(sender_id);
CREATE INDEX IF NOT EXISTS idx_friend_requests_receiver_id ON friend_requests(receiver_id);
CREATE INDEX IF NOT EXISTS idx_friend_requests_status ON friend_requests(status);
CREATE INDEX IF NOT EXISTS idx_friend_requests_receiver_status ON friend_requests(receiver_id, status);

-- Enable Row Level Security
ALTER TABLE friend_requests ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view sent friend requests" ON friend_requests;
DROP POLICY IF EXISTS "Users can view received friend requests" ON friend_requests;
DROP POLICY IF EXISTS "Users can send friend requests" ON friend_requests;
DROP POLICY IF EXISTS "Users can update received friend requests" ON friend_requests;
DROP POLICY IF EXISTS "Users can cancel sent friend requests" ON friend_requests;

-- RLS Policies for friend_requests

-- Users can view their own sent requests
CREATE POLICY "Users can view sent friend requests"
  ON friend_requests FOR SELECT
  TO authenticated
  USING (auth.uid() = sender_id);

-- Users can view their own received requests
CREATE POLICY "Users can view received friend requests"
  ON friend_requests FOR SELECT
  TO authenticated
  USING (auth.uid() = receiver_id);

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

-- Users can delete their sent requests (cancel)
CREATE POLICY "Users can cancel sent friend requests"
  ON friend_requests FOR DELETE
  TO authenticated
  USING (auth.uid() = sender_id);

-- Trigger to automatically update updated_at (reuse existing function)
DROP TRIGGER IF EXISTS update_friend_requests_updated_at ON friend_requests;
CREATE TRIGGER update_friend_requests_updated_at
  BEFORE UPDATE ON friend_requests
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Function to get friendship status between two users
CREATE OR REPLACE FUNCTION get_friendship_status(user_id_1 uuid, user_id_2 uuid)
RETURNS text AS $$
DECLARE
  request_status text;
BEGIN
  -- Check if there's a friend request in either direction
  SELECT status INTO request_status
  FROM friend_requests
  WHERE (sender_id = user_id_1 AND receiver_id = user_id_2)
     OR (sender_id = user_id_2 AND receiver_id = user_id_1)
  LIMIT 1;

  RETURN COALESCE(request_status, 'none');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
