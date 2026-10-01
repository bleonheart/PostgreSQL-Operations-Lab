# Table Lock

## Symptoms

A statement waits while its session remains active, and `wait_event_type` reports a lock-related wait.

## Investigation

Find blocked sessions and their blockers with `pg_blocking_pids`, then inspect transaction age and the blocker query before taking action.

## SQL commands used

```sql
SELECT blocked.pid AS blocked_pid,
       blocker.pid AS blocker_pid,
       blocked.wait_event_type,
       blocked.wait_event,
       blocked.query AS blocked_query,
       blocker.query AS blocker_query
FROM pg_stat_activity blocked
JOIN pg_stat_activity blocker ON blocker.pid = ANY(pg_blocking_pids(blocked.pid));
```

## Evidence

A non-empty blocker relationship from `pg_blocking_pids` identifies the blocking backend. Transaction start time and query text establish whether the blocker is active, idle in transaction, or performing expected work.

## Root cause

In the lab reproduction, two sessions contend for incompatible locks on the same rows or relation while one transaction remains open.

## Resolution

Allow the legitimate transaction to complete when possible. In an incident, cancel or terminate a backend only after confirming ownership and impact; then correct the transaction behavior that held the lock.

## Verification

`pg_blocking_pids` should return no blocker for the affected session and the waiting statement should complete or fail explicitly.

## Prevention

Keep transactions short, lock objects in consistent order, avoid interactive pauses inside transactions, and monitor old transactions.
