BEGIN;

CREATE TEMP TABLE perf_tickets_index_order AS
SELECT id, organization_id, status, created_at
FROM tickets;

CREATE INDEX perf_status_org_created
    ON perf_tickets_index_order (status, organization_id, created_at DESC);
ANALYZE perf_tickets_index_order;

\echo 'INDEX ORDER A: status first for an organization-only predicate'
EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
SELECT id, status, created_at
FROM perf_tickets_index_order
WHERE organization_id = 10
ORDER BY created_at DESC
LIMIT 50;

DROP INDEX perf_status_org_created;
CREATE INDEX perf_org_status_created
    ON perf_tickets_index_order (organization_id, status, created_at DESC);
ANALYZE perf_tickets_index_order;

\echo 'INDEX ORDER B: organization first for the same predicate'
EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
SELECT id, status, created_at
FROM perf_tickets_index_order
WHERE organization_id = 10
ORDER BY created_at DESC
LIMIT 50;

ROLLBACK;
