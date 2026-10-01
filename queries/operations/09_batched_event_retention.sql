BEGIN;

WITH candidates AS (
    SELECT id
    FROM system_events
    WHERE created_at < CURRENT_TIMESTAMP - INTERVAL '180 days'
      AND severity IN ('debug', 'info')
    ORDER BY id
    LIMIT 1000
    FOR UPDATE SKIP LOCKED
), deleted AS (
    DELETE FROM system_events e
    USING candidates c
    WHERE e.id = c.id
    RETURNING e.id, e.created_at
)
SELECT COUNT(*) AS would_delete,
       MIN(created_at) AS oldest_deleted_event,
       MAX(created_at) AS newest_deleted_event
FROM deleted;

ROLLBACK;
