# Migration Failure

## Symptoms

A numbered migration exits nonzero and later schema objects are not applied.

## Investigation

Run psql with `ON_ERROR_STOP=1`, capture the first PostgreSQL error, inspect current catalog state, and determine whether the migration was transactional or partially applied.

## SQL commands used

```bash
DATABASE_URL='postgresql://...' bash ./scripts/apply_migrations.sh
```

```sql
SELECT to_regclass('public.tickets');
SELECT conname FROM pg_constraint WHERE conrelid = 'tickets'::regclass;
```

## Evidence

The first failing statement plus catalog inspection establish the actual partial state. Later errors can be secondary effects and should not replace the first failure as evidence.

## Root cause

Typical causes include incompatible pre-existing data, object-name conflicts, missing privileges, or a dependency applied out of order.

## Resolution

Fix the migration or prerequisite data in a tested environment, restore from backup when rollback is unsafe, and re-run only after the current state is understood.

## Verification

Apply the full migration set from a clean database and re-apply it to exercise the repository’s practical idempotency guards. Run database tests afterward.

## Prevention

Test migrations against clean and representative databases, fail on the first SQL error, keep migrations reviewable, and back up before risky production changes.
