SELECT
    organization_id,
    lower(trim(subject)) AS normalized_subject,
    date_trunc('hour', created_at) AS created_hour,
    COUNT(*) AS duplicate_count,
    array_agg(id ORDER BY id) AS ticket_ids
FROM tickets
GROUP BY organization_id, lower(trim(subject)), date_trunc('hour', created_at)
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC, created_hour DESC;
