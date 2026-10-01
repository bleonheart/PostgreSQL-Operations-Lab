SELECT
    t.id,
    o.slug AS organization_slug,
    t.subject,
    t.reopened_count,
    RANK() OVER (ORDER BY t.reopened_count DESC, t.updated_at DESC) AS reopen_rank
FROM tickets t
JOIN organizations o ON o.id = t.organization_id
WHERE t.reopened_count >= 2
ORDER BY reopen_rank, t.id;
