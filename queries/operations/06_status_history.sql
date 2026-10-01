SELECT
    h.ticket_id,
    h.from_status,
    h.to_status,
    u.display_name AS changed_by,
    h.reason,
    h.changed_at,
    LAG(h.changed_at) OVER (PARTITION BY h.ticket_id ORDER BY h.changed_at) AS previous_change_at
FROM ticket_status_history h
LEFT JOIN agents a ON a.id = h.changed_by_agent_id
LEFT JOIN users u ON u.id = a.user_id
WHERE h.ticket_id = COALESCE(NULLIF(current_setting('app.ticket_id', true), '')::BIGINT, h.ticket_id)
ORDER BY h.ticket_id, h.changed_at;
