SELECT
    a.id AS agent_id,
    u.display_name,
    a.team,
    COUNT(ass.ticket_id) AS active_assignments,
    COUNT(*) FILTER (WHERE t.priority_id = (SELECT id FROM priorities WHERE code = 'P1')) AS p1_assignments,
    MIN(t.updated_at) AS oldest_ticket_update
FROM agents a
JOIN users u ON u.id = a.user_id
LEFT JOIN assignments ass ON ass.agent_id = a.id AND ass.unassigned_at IS NULL
LEFT JOIN tickets t ON t.id = ass.ticket_id AND t.status IN ('open', 'pending')
WHERE a.active
GROUP BY a.id, u.display_name, a.team
ORDER BY active_assignments DESC, a.id;
