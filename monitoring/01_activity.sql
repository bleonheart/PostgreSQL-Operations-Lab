SELECT
    pid,
    usename,
    application_name,
    client_addr,
    state,
    backend_start,
    xact_start,
    query_start,
    CURRENT_TIMESTAMP - query_start AS query_age,
    wait_event_type,
    wait_event,
    LEFT(query, 200) AS query_excerpt
FROM pg_stat_activity
WHERE datname = current_database()
ORDER BY query_start NULLS LAST;
