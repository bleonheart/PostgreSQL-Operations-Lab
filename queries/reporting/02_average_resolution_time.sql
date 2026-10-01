SELECT
    p.code AS priority,
    ROUND(AVG(EXTRACT(EPOCH FROM (t.resolved_at - t.created_at)) / 60.0), 2) AS avg_resolution_minutes,
    percentile_cont(0.5) WITHIN GROUP (ORDER BY EXTRACT(EPOCH FROM (t.resolved_at - t.created_at)) / 60.0) AS median_resolution_minutes
FROM tickets t
JOIN priorities p ON p.id = t.priority_id
WHERE t.resolved_at IS NOT NULL
GROUP BY p.code, p.severity
ORDER BY p.severity;
