# Migrations

Numbered files under `migrations/` define application order. Each migration uses psql `\ir` to include the canonical definition from `schema/`, `functions/`, or `procedures/`.

```text
001 extensions and tables
002 constraints and foreign keys
003 indexes
004 views and materialized views
005 functions
006 procedures
```

The files are written to be safely re-applied where practical: tables/indexes/extensions use `IF NOT EXISTS`, constraints are guarded through `pg_constraint`, and routines use `CREATE OR REPLACE`.

For local Docker initialization the official PostgreSQL entrypoint executes `docker/init/00-bootstrap.sh`, which applies migrations and reference seed data only on a fresh volume. For existing environments use `scripts/apply_migrations.sh` explicitly.

A production migration system would also store an immutable migration ledger and avoid editing migrations already applied to shared environments. This portfolio keeps canonical SQL easy to inspect while still exercising ordered migration behavior in CI.
