SELECT
    p.code AS priority,
    p.label,
    COUNT(*) AS unresolved_tickets
FROM tickets t
JOIN priorities p ON p.id = t.priority_id
WHERE t.status IN ('open', 'pending')
GROUP BY p.code, p.label, p.severity
ORDER BY p.severity;
