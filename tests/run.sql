BEGIN;

CREATE SCHEMA IF NOT EXISTS test_runtime;

CREATE OR REPLACE FUNCTION test_runtime.assert_true(condition BOOLEAN, message TEXT)
RETURNS VOID
LANGUAGE plpgsql
AS $$
BEGIN
    IF condition IS DISTINCT FROM TRUE THEN
        RAISE EXCEPTION 'assertion failed: %', message;
    END IF;
END;
$$;

\ir sql/001_schema.sql
\ir sql/002_integrity.sql
\ir sql/003_views.sql
\ir sql/004_routines.sql

ROLLBACK;
\echo 'all database tests passed'
