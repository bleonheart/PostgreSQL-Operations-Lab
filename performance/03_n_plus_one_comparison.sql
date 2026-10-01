\echo 'SET-BASED REPLACEMENT FOR N+1 ACCESS'
EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
SELECT
    t.id,
    t.subject,
    o.name AS organization,
    p.code AS priority,
    a.id AS assigned_agent_id,
    u.display_name AS assigned_agent
FROM tickets t
JOIN organizations o ON o.id = t.organization_id
JOIN priorities p ON p.id = t.priority_id
LEFT JOIN assignments ass ON ass.ticket_id = t.id AND ass.unassigned_at IS NULL
LEFT JOIN agents a ON a.id = ass.agent_id
LEFT JOIN users u ON u.id = a.user_id
WHERE t.status IN ('open', 'pending')
ORDER BY t.updated_at
LIMIT 100;
