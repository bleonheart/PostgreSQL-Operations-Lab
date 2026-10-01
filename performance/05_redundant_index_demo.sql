BEGIN;

CREATE TEMP TABLE perf_redundant_indexes AS
SELECT id, organization_id, status, updated_at
FROM tickets;

CREATE INDEX perf_redundant_a ON perf_redundant_indexes (organization_id, status);
CREATE INDEX perf_redundant_b ON perf_redundant_indexes (organization_id, status);
ANALYZE perf_redundant_indexes;

\echo 'BEFORE: two equivalent indexes exist'
SELECT indexname, indexdef
FROM pg_indexes
WHERE schemaname LIKE 'pg_temp_%'
  AND tablename = 'perf_redundant_indexes'
ORDER BY indexname;

EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
SELECT id, updated_at
FROM perf_redundant_indexes
WHERE organization_id = 10
  AND status = 'open';

DROP INDEX perf_redundant_b;

\echo 'AFTER: redundant index removed'
SELECT indexname, indexdef
FROM pg_indexes
WHERE schemaname LIKE 'pg_temp_%'
  AND tablename = 'perf_redundant_indexes'
ORDER BY indexname;

EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
SELECT id, updated_at
FROM perf_redundant_indexes
WHERE organization_id = 10
  AND status = 'open';

ROLLBACK;
