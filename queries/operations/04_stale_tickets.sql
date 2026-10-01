SELECT
    t.id,
    o.slug AS organization_slug,
    p.code AS priority,
    t.status,
    t.subject,
    t.updated_at,
    CURRENT_TIMESTAMP - t.updated_at AS time_since_update
FROM tickets t
JOIN organizations o ON o.id = t.organization_id
JOIN priorities p ON p.id = t.priority_id
WHERE t.status IN ('open', 'pending')
  AND t.updated_at < CURRENT_TIMESTAMP - INTERVAL '48 hours'
ORDER BY t.updated_at, p.severity;
