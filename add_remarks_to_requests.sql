-- Add a remarks/notes field to product_availability_requests.
--
-- Agents can now add optional free-text notes when creating a request.
-- These remarks are displayed alongside the reference link in the main
-- requests table so all users can see the context at a glance.
--
-- Run this in the Supabase SQL Editor.

ALTER TABLE product_availability_requests
  ADD COLUMN IF NOT EXISTS remarks text;
