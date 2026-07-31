-- Stage 15: Restore Postgres-level table/sequence/function grants for the
-- Supabase-managed `anon` and `authenticated` roles.
--
-- Context: the public schema was reset via `DROP SCHEMA public CASCADE;
-- CREATE SCHEMA public;` run directly over the Postgres pooler connection
-- (see apply_schema.py). That statement recreates the schema from nothing,
-- which wipes the default privileges Supabase's own project bootstrapping
-- normally grants to anon/authenticated on every table in `public`. Without
-- these GRANTs, PostgREST returns `permission denied for table X` (Postgres
-- error 42501) for every request BEFORE row level security is even
-- evaluated — RLS policies never get a chance to run. service_role was
-- unaffected because its bypass-RLS + broad privileges live on the role
-- itself, not on this schema's ACL.
--
-- This is idempotent — safe to re-run after every future schema reset.

BEGIN;

GRANT USAGE ON SCHEMA public TO anon, authenticated, service_role;

GRANT ALL ON ALL TABLES IN SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL ROUTINES IN SCHEMA public TO anon, authenticated, service_role;

-- Make sure tables/sequences/functions created by FUTURE migrations get the
-- same grants automatically, without needing to remember this step again.
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON ROUTINES TO anon, authenticated, service_role;

COMMIT;
