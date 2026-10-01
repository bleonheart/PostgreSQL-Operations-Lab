SELECT test_runtime.assert_true(
    (SELECT COUNT(*) FROM v_open_ticket_worklist) = (SELECT COUNT(*) FROM tickets WHERE status IN ('open', 'pending')),
    'worklist view returns one row per unresolved ticket'
);

SELECT test_runtime.assert_true(
    NOT EXISTS (SELECT 1 FROM v_open_ticket_worklist WHERE sla_state NOT IN ('within_target', 'at_risk', 'breached')),
    'worklist SLA state is valid'
);

SELECT test_runtime.assert_true(
    (SELECT COUNT(*) FROM mv_daily_ticket_metrics) = (
        SELECT COUNT(*)
        FROM (
            SELECT date_trunc('day', created_at)::DATE, organization_id
            FROM tickets
            GROUP BY 1, 2
        ) expected
    ),
    'materialized daily metrics match ticket day/organization groups'
);
