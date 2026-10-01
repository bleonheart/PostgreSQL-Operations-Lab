SELECT
    pid,
    usename,
    application_name,
    client_addr,
    state,
    xact_start,
    query_start,
    CURRENT_TIMESTAMP - xact_start AS transaction_age,
    wait_event_type,
    wait_event,
    LEFT(query, 200) AS query_excerpt
FROM pg_stat_activity
WHERE xact_start IS NOT NULL
  AND pid <> pg_backend_pid()
ORDER BY xact_start;
