# Missing Index

## Symptoms

A frequently executed lookup performs disproportionate work as table size grows, and its plan cannot narrow rows using an appropriate index.

## Investigation

Confirm the predicate and ordering used by the real query, inspect existing indexes, and run the query plan against representative synthetic data.

## SQL commands used

```sql
SELECT indexname, indexdef
FROM pg_indexes
WHERE schemaname = 'public' AND tablename = 'tickets';

EXPLAIN (ANALYZE, BUFFERS)
SELECT id, priority_id, updated_at
FROM tickets
WHERE organization_id = 10
  AND status IN ('open', 'pending')
ORDER BY updated_at DESC
LIMIT 50;
```

## Evidence

Use the plan plus the index inventory. A sequential scan is not automatically wrong; it becomes relevant when the filtered result is selective and the measured plan shows excessive work for the workload.

## Root cause

The access pattern is not represented by a suitable index or the existing index has an unusable leading-column order.

## Resolution

Create the narrowest justified index for the operational path, preferably reproducing the change first on a temporary table or non-production environment.

## Verification

Re-run the identical plan, confirm identical query results, and compare actual rows and buffer work. Inspect `pg_stat_user_indexes` later under sustained workload.

## Prevention

Design indexes from concrete query patterns, review composite ordering, and periodically inspect unused or redundant indexes before adding more.
