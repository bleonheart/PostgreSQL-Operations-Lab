SELECT
    pid,
    usename,
    state,
    query_start,
    CURRENT_TIMESTAMP - query_start AS query_age,
    wait_event_type,
    wait_event,
    LEFT(query, 250) AS query_excerpt
FROM pg_stat_activity
WHERE datname = current_database()
  AND state <> 'idle'
  AND query_start < CURRENT_TIMESTAMP - INTERVAL '30 seconds'
  AND pid <> pg_backend_pid()
ORDER BY query_start;
