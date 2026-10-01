BEGIN;

CREATE TEMP TABLE perf_tickets_missing_index AS
SELECT id, organization_id, status, priority_id, created_at, updated_at
FROM tickets;

ANALYZE perf_tickets_missing_index;

\echo 'BEFORE: unindexed organization/status lookup'
EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
SELECT id, priority_id, updated_at
FROM perf_tickets_missing_index
WHERE organization_id = 10
  AND status IN ('open', 'pending')
ORDER BY updated_at DESC
LIMIT 50;

CREATE INDEX perf_tickets_missing_index_org_status_updated
    ON perf_tickets_missing_index (organization_id, status, updated_at DESC);
ANALYZE perf_tickets_missing_index;

\echo 'AFTER: composite index added'
EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
SELECT id, priority_id, updated_at
FROM perf_tickets_missing_index
WHERE organization_id = 10
  AND status IN ('open', 'pending')
ORDER BY updated_at DESC
LIMIT 50;

ROLLBACK;
