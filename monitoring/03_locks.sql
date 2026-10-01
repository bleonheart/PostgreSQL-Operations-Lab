SELECT
    a.pid,
    a.usename,
    l.locktype,
    l.mode,
    l.granted,
    l.relation::REGCLASS AS relation,
    pg_blocking_pids(a.pid) AS blocking_pids,
    LEFT(a.query, 180) AS query_excerpt
FROM pg_locks l
JOIN pg_stat_activity a ON a.pid = l.pid
WHERE a.datname = current_database()
ORDER BY l.granted, a.pid;
