# Connection Exhaustion

## Symptoms

New clients fail to connect or connection utilization approaches the configured PostgreSQL limit.

## Investigation

Compare active connection count with `max_connections`, group sessions by application/state, and look for leaked or idle connections.

## SQL commands used

```sql
WITH s AS (
  SELECT setting::int AS max_connections FROM pg_settings WHERE name = 'max_connections'
)
SELECT count(*) AS used, s.max_connections,
       s.max_connections - count(*) AS available
FROM pg_stat_activity CROSS JOIN s
GROUP BY s.max_connections;

SELECT application_name, state, count(*)
FROM pg_stat_activity
GROUP BY application_name, state
ORDER BY count(*) DESC;
```

## Evidence

Connection counts by application and state identify whether capacity is consumed by expected concurrency, idle pools, or a specific client source.

## Root cause

The lab scenario models a client pool opening more concurrent sessions than its intended allocation or failing to release them.

## Resolution

Reduce or recycle the offending client pool and restore headroom. Increasing `max_connections` is not the first response because each backend consumes server resources.

## Verification

Confirm new connections succeed, utilization returns below the operational threshold, and the offending application session count stabilizes.

## Prevention

Bound pool sizes, set idle timeouts carefully, reserve operational headroom, and monitor connection usage by application.
