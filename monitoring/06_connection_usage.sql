WITH settings AS (
    SELECT setting::INTEGER AS max_connections
    FROM pg_settings
    WHERE name = 'max_connections'
), usage AS (
    SELECT COUNT(*)::INTEGER AS used_connections
    FROM pg_stat_activity
)
SELECT
    used_connections,
    max_connections,
    max_connections - used_connections AS available_connections,
    ROUND(used_connections * 100.0 / NULLIF(max_connections, 0), 2) AS utilization_percent
FROM usage
CROSS JOIN settings;
