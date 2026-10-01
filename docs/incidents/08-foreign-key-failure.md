# Foreign-Key Failure

## Symptoms

An insert or update fails with PostgreSQL foreign-key violation SQLSTATE `23503`.

## Investigation

Read the exact constraint name from the error, inspect the referenced key, and determine whether the parent is missing, the child value is wrong, or operations occurred in the wrong order.

## SQL commands used

```sql
SELECT conname, pg_get_constraintdef(oid)
FROM pg_constraint
WHERE conname = 'tickets_organization_fk';

SELECT id, slug
FROM organizations
WHERE id = 12345;
```

## Evidence

The PostgreSQL error identifies the violated constraint; direct lookup of the referenced key confirms whether the parent exists.

## Root cause

The controlled scenario inserts a ticket using a nonexistent organization/requester/dimension identifier or deletes a protected parent before its dependents are handled.

## Resolution

Correct the input or operation order. Do not disable foreign keys to make the write succeed.

## Verification

Retry the intended write with a valid parent and run orphan checks from `tests/sql/002_integrity.sql`.

## Prevention

Validate identifiers at service boundaries, use transactions for related writes, and keep foreign keys enabled as the final integrity guard.
