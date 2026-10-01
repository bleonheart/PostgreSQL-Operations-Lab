WITH customer_activity AS (
    SELECT
        o.id,
        o.slug,
        o.name,
        MAX(u.last_seen_at) AS last_user_seen_at,
        MAX(t.created_at) AS last_ticket_at
    FROM organizations o
    LEFT JOIN users u ON u.organization_id = o.id
    LEFT JOIN tickets t ON t.organization_id = o.id
    WHERE o.slug <> 'internal-support'
    GROUP BY o.id, o.slug, o.name
)
SELECT *
FROM customer_activity
WHERE GREATEST(
    COALESCE(last_user_seen_at, '-infinity'::TIMESTAMPTZ),
    COALESCE(last_ticket_at, '-infinity'::TIMESTAMPTZ)
) < CURRENT_TIMESTAMP - INTERVAL '60 days'
ORDER BY last_user_seen_at NULLS FIRST;
