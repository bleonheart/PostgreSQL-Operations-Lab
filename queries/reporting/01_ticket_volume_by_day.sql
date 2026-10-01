SELECT
    date_trunc('day', created_at)::DATE AS day,
    COUNT(*) AS ticket_count,
    COUNT(*) FILTER (WHERE priority_id = (SELECT id FROM priorities WHERE code = 'P1')) AS p1_count
FROM tickets
GROUP BY 1
ORDER BY 1;
