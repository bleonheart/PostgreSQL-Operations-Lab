SELECT
    ticket_id,
    organization_slug,
    priority,
    status,
    assigned_agent_id,
    resolution_due_at,
    resolution_due_at - CURRENT_TIMESTAMP AS time_remaining,
    sla_state
FROM v_open_ticket_worklist
WHERE sla_state IN ('at_risk', 'breached')
ORDER BY resolution_due_at, severity;
