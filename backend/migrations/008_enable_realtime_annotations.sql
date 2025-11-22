-- Enable Supabase Realtime for annotations table
-- Run this in Supabase Dashboard → SQL Editor

-- Enable realtime replication for annotations table
ALTER PUBLICATION supabase_realtime ADD TABLE annotations;

-- Verify it's enabled
SELECT * FROM pg_publication_tables 
WHERE pubname = 'supabase_realtime' AND tablename = 'annotations';

-- Expected output: Should show one row with tablename = 'annotations'
