DO $$
DECLARE
    v_org_id BIGINT;
    v_user_id BIGINT;
    v_agent_user_id BIGINT;
    v_agent_id BIGINT;
    v_priority_id SMALLINT;
    v_category_id INTEGER;
    v_service_id BIGINT;
    v_ticket_id BIGINT;
    v_ticket tickets;
BEGIN
    SELECT id INTO v_priority_id FROM priorities WHERE code = 'P3';
    SELECT id INTO v_category_id FROM categories ORDER BY id LIMIT 1;
    SELECT id INTO v_service_id FROM services ORDER BY id LIMIT 1;

    INSERT INTO organizations (slug, name, plan)
    VALUES ('test-routines-org', 'Synthetic Test Routines Org', 'standard')
    RETURNING id INTO v_org_id;

    INSERT INTO users (organization_id, external_ref, email, display_name)
    VALUES (v_org_id, 'test-requester', 'test-requester@example.invalid', 'Synthetic Test Requester')
    RETURNING id INTO v_user_id;

    INSERT INTO users (organization_id, external_ref, email, display_name)
    VALUES (v_org_id, 'test-agent-user', 'test-agent@example.invalid', 'Synthetic Test Agent')
    RETURNING id INTO v_agent_user_id;

    INSERT INTO agents (user_id, team)
    VALUES (v_agent_user_id, 'test-team')
    RETURNING id INTO v_agent_id;

    INSERT INTO tickets (
        organization_id, requester_user_id, priority_id, category_id, service_id,
        status, subject, description, created_at, updated_at, resolved_at
    )
    VALUES (
        v_org_id, v_user_id, v_priority_id, v_category_id, v_service_id,
        'resolved', 'Synthetic routine test ticket', 'Synthetic test data only.',
        CURRENT_TIMESTAMP - INTERVAL '2 hours', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP - INTERVAL '1 hour'
    )
    RETURNING id INTO v_ticket_id;

    CALL sp_assign_ticket(v_ticket_id, v_agent_id);
    PERFORM test_runtime.assert_true(
        (SELECT COUNT(*) FROM assignments WHERE ticket_id = v_ticket_id AND unassigned_at IS NULL) = 1,
        'assignment procedure creates one active assignment'
    );

    SELECT * INTO v_ticket FROM fn_reopen_ticket(v_ticket_id, v_agent_id, 'Synthetic routine test');
    PERFORM test_runtime.assert_true(v_ticket.status = 'open', 'reopen function sets status to open');
    PERFORM test_runtime.assert_true(v_ticket.reopened_count = 1, 'reopen function increments reopened count');
    PERFORM test_runtime.assert_true(
        EXISTS (
            SELECT 1 FROM ticket_status_history
            WHERE ticket_id = v_ticket_id AND from_status = 'resolved' AND to_status = 'open'
        ),
        'reopen function records status history'
    );
END
$$;
