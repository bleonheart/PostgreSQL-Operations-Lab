# Transactions

## Safe update workflow

`queries/operations/07_safe_ticket_update.sql` demonstrates `BEGIN`, row locking with `FOR UPDATE`, a guarded update, verification, and `ROLLBACK`. In an approved change window the final rollback can be replaced with `COMMIT` after verification.

## Isolation

`queries/operations/08_transaction_isolation.sql` opens a `REPEATABLE READ` transaction so repeated reads use one transaction snapshot. PostgreSQL also supports `READ COMMITTED` and `SERIALIZABLE`; the correct choice depends on the consistency requirement and acceptable retry behavior.

## Deadlock reproduction

Use two psql sessions only against disposable lab data.

Session A:

```sql
BEGIN;
UPDATE tickets SET updated_at = CURRENT_TIMESTAMP WHERE id = 1;
SELECT pg_sleep(3);
UPDATE tickets SET updated_at = CURRENT_TIMESTAMP WHERE id = 2;
```

Session B, started immediately after A:

```sql
BEGIN;
UPDATE tickets SET updated_at = CURRENT_TIMESTAMP WHERE id = 2;
SELECT pg_sleep(3);
UPDATE tickets SET updated_at = CURRENT_TIMESTAMP WHERE id = 1;
```

PostgreSQL detects the cycle and aborts one transaction. `monitoring/03_locks.sql` and `pg_stat_activity` provide evidence while blocking is present.

## Prevention

Acquire locks in a consistent object order, keep transactions short, avoid user/network waits inside transactions, index predicates used by updates, and make application transactions retryable when deadlocks are possible.
