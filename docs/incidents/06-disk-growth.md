# Disk Growth

## Symptoms

Database storage grows faster than expected or a specific table/index becomes disproportionately large.

## Investigation

Measure database, table, and index sizes; compare live/dead tuple counts and inspect high-volume event/audit tables before considering maintenance.

## SQL commands used

```sql
SELECT pg_size_pretty(pg_database_size(current_database()));

SELECT relname,
       pg_size_pretty(pg_total_relation_size(relid)) AS total_size,
       n_live_tup,
       n_dead_tup
FROM pg_stat_user_tables
ORDER BY pg_total_relation_size(relid) DESC;
```

## Evidence

Size functions identify which relations consume space. Dead-tuple counts, workload retention, and index sizes help separate normal data growth from bloat or unbounded retention.

## Root cause

A common lab cause is continued accumulation of append-heavy `system_events` or `audit_logs` without an explicit retention policy.

## Resolution

Apply an approved retention/archive policy to data that is genuinely disposable, then vacuum normally. Use invasive rewrite operations only when evidence justifies them and maintenance impact is understood.

## Verification

Track relation size and row counts after retention work, and confirm normal writes continue without errors.

## Prevention

Define retention at design time, monitor size trends, partition very high-volume history when justified, and capacity-plan before storage becomes critical.
