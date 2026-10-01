CREATE OR REPLACE VIEW v_open_ticket_worklist AS
SELECT
    t.id AS ticket_id,
    o.slug AS organization_slug,
    t.subject,
    t.status,
    p.code AS priority,
    p.severity,
    c.name AS category,
    s.name AS service,
    a.id AS assigned_agent_id,
    t.created_at,
    t.updated_at,
    t.created_at + make_interval(mins => sp.resolution_target_minutes) AS resolution_due_at,
    CASE
        WHEN CURRENT_TIMESTAMP >= t.created_at + make_interval(mins => sp.resolution_target_minutes) THEN 'breached'
        WHEN CURRENT_TIMESTAMP >= t.created_at + make_interval(mins => (sp.resolution_target_minutes * 0.8)::INTEGER) THEN 'at_risk'
        ELSE 'within_target'
    END AS sla_state
FROM tickets t
JOIN organizations o ON o.id = t.organization_id
JOIN priorities p ON p.id = t.priority_id
JOIN categories c ON c.id = t.category_id
LEFT JOIN services s ON s.id = t.service_id
JOIN sla_policies sp ON sp.plan = o.plan AND sp.priority_id = t.priority_id AND sp.active
LEFT JOIN assignments ass ON ass.ticket_id = t.id AND ass.unassigned_at IS NULL
LEFT JOIN agents a ON a.id = ass.agent_id
WHERE t.status IN ('open', 'pending');

CREATE MATERIALIZED VIEW IF NOT EXISTS mv_daily_ticket_metrics AS
SELECT
    date_trunc('day', created_at)::DATE AS day,
    organization_id,
    COUNT(*) AS created_count,
    COUNT(*) FILTER (WHERE resolved_at IS NOT NULL) AS resolved_count,
    AVG(EXTRACT(EPOCH FROM (resolved_at - created_at)) / 60.0) FILTER (WHERE resolved_at IS NOT NULL) AS avg_resolution_minutes
FROM tickets
GROUP BY 1, 2
WITH NO DATA;

CREATE UNIQUE INDEX IF NOT EXISTS uq_mv_daily_ticket_metrics_day_org
    ON mv_daily_ticket_metrics (day, organization_id);
