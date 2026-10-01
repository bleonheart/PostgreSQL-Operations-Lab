SELECT
    blocked.pid AS blocked_pid,
    blocked.usename AS blocked_user,
    blocker.pid AS blocker_pid,
    blocker.usename AS blocker_user,
    blocked.wait_event_type,
    blocked.wait_event,
    LEFT(blocked.query, 160) AS blocked_query,
    LEFT(blocker.query, 160) AS blocker_query
FROM pg_stat_activity blocked
JOIN pg_stat_activity blocker ON blocker.pid = ANY(pg_blocking_pids(blocked.pid))
ORDER BY blocked.query_start;
