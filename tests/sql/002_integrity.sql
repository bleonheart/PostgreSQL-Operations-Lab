SELECT test_runtime.assert_true((SELECT COUNT(*) FROM priorities) = 4, 'four reference priorities exist');
SELECT test_runtime.assert_true((SELECT COUNT(*) FROM services) >= 5, 'reference services exist');
SELECT test_runtime.assert_true((SELECT COUNT(*) FROM sla_policies) = 12, 'SLA matrix has three plans by four priorities');

SELECT test_runtime.assert_true(
    NOT EXISTS (
        SELECT 1
        FROM tickets t
        LEFT JOIN organizations o ON o.id = t.organization_id
        WHERE o.id IS NULL
    ),
    'tickets have valid organizations'
);

SELECT test_runtime.assert_true(
    NOT EXISTS (
        SELECT 1
        FROM assignments a
        LEFT JOIN tickets t ON t.id = a.ticket_id
        LEFT JOIN agents ag ON ag.id = a.agent_id
        WHERE t.id IS NULL OR ag.id IS NULL
    ),
    'assignments have valid ticket and agent relationships'
);

DO $$
BEGIN
    BEGIN
        INSERT INTO priorities (code, label, severity, response_target_minutes, resolution_target_minutes)
        VALUES ('INVALID', 'Invalid', 9, 1, 1);
        RAISE EXCEPTION 'expected priorities_severity_check violation';
    EXCEPTION
        WHEN check_violation THEN
            NULL;
    END;
END
$$;
