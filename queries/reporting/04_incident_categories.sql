SELECT
    c.name AS category,
    COUNT(*) AS incident_count,
    COUNT(*) FILTER (WHERE i.severity <= 2) AS high_severity_count
FROM incidents i
LEFT JOIN categories c ON c.id = i.category_id
GROUP BY c.name
HAVING COUNT(*) > 0
ORDER BY incident_count DESC, category;
