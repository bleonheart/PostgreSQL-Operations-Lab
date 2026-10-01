SELECT
    s.name AS service,
    COUNT(i.id) AS incident_count,
    COUNT(i.id) FILTER (WHERE i.started_at >= CURRENT_TIMESTAMP - INTERVAL '30 days') AS incidents_last_30_days,
    MAX(i.started_at) AS latest_incident
FROM services s
LEFT JOIN incidents i ON i.service_id = s.id
GROUP BY s.id, s.name
ORDER BY incident_count DESC, s.name;
