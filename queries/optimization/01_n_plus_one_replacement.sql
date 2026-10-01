SELECT
    t.id,
    t.subject,
    t.status,
    o.name AS organization,
    p.code AS priority,
    c.name AS category,
    s.name AS service,
    a.id AS assigned_agent_id,
    au.display_name AS assigned_agent
FROM tickets t
JOIN organizations o ON o.id = t.organization_id
JOIN priorities p ON p.id = t.priority_id
JOIN categories c ON c.id = t.category_id
LEFT JOIN services s ON s.id = t.service_id
LEFT JOIN assignments ass ON ass.ticket_id = t.id AND ass.unassigned_at IS NULL
LEFT JOIN agents a ON a.id = ass.agent_id
LEFT JOIN users au ON au.id = a.user_id
WHERE t.status IN ('open', 'pending')
ORDER BY t.updated_at
LIMIT 100;
