INSERT INTO priorities (code, label, severity, response_target_minutes, resolution_target_minutes)
VALUES
    ('P1', 'Critical', 1, 15, 240),
    ('P2', 'High', 2, 60, 480),
    ('P3', 'Normal', 3, 240, 1440),
    ('P4', 'Low', 4, 480, 2880)
ON CONFLICT (code) DO UPDATE SET
    label = EXCLUDED.label,
    severity = EXCLUDED.severity,
    response_target_minutes = EXCLUDED.response_target_minutes,
    resolution_target_minutes = EXCLUDED.resolution_target_minutes;

INSERT INTO categories (code, name)
VALUES
    ('access', 'Access'),
    ('billing', 'Billing'),
    ('performance', 'Performance'),
    ('reliability', 'Reliability'),
    ('integration', 'Integration')
ON CONFLICT (code) DO NOTHING;

INSERT INTO categories (parent_id, code, name)
VALUES
    ((SELECT id FROM categories WHERE code = 'access'), 'access-auth', 'Authentication'),
    ((SELECT id FROM categories WHERE code = 'access'), 'access-permissions', 'Permissions'),
    ((SELECT id FROM categories WHERE code = 'performance'), 'performance-latency', 'Latency'),
    ((SELECT id FROM categories WHERE code = 'performance'), 'performance-query', 'Query Performance'),
    ((SELECT id FROM categories WHERE code = 'reliability'), 'reliability-outage', 'Service Outage'),
    ((SELECT id FROM categories WHERE code = 'integration'), 'integration-api', 'API Integration')
ON CONFLICT (code) DO NOTHING;

INSERT INTO services (service_key, name, tier)
VALUES
    ('auth-api', 'Authentication API', 'critical'),
    ('ticket-api', 'Ticket API', 'critical'),
    ('reporting', 'Reporting Service', 'core'),
    ('notifications', 'Notification Service', 'core'),
    ('exports', 'Data Export Service', 'supporting')
ON CONFLICT (service_key) DO UPDATE SET
    name = EXCLUDED.name,
    tier = EXCLUDED.tier;

INSERT INTO sla_policies (name, plan, priority_id, response_target_minutes, resolution_target_minutes)
SELECT
    initcap(plan) || ' ' || p.code,
    plan,
    p.id,
    CASE plan
        WHEN 'premium' THEN GREATEST(5, p.response_target_minutes / 2)
        WHEN 'starter' THEN p.response_target_minutes * 2
        ELSE p.response_target_minutes
    END,
    CASE plan
        WHEN 'premium' THEN GREATEST(30, p.resolution_target_minutes / 2)
        WHEN 'starter' THEN p.resolution_target_minutes * 2
        ELSE p.resolution_target_minutes
    END
FROM priorities p
CROSS JOIN (VALUES ('starter'), ('standard'), ('premium')) AS plans(plan)
ON CONFLICT (plan, priority_id) DO UPDATE SET
    name = EXCLUDED.name,
    response_target_minutes = EXCLUDED.response_target_minutes,
    resolution_target_minutes = EXCLUDED.resolution_target_minutes,
    active = TRUE;

REFRESH MATERIALIZED VIEW mv_daily_ticket_metrics;
