CREATE OR REPLACE FUNCTION fn_reopen_ticket(p_ticket_id BIGINT, p_agent_id BIGINT, p_reason TEXT DEFAULT NULL)
RETURNS tickets
LANGUAGE plpgsql
AS $$
DECLARE
    v_ticket tickets;
    v_previous_status TEXT;
BEGIN
    SELECT * INTO v_ticket
    FROM tickets
    WHERE id = p_ticket_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'ticket % does not exist', p_ticket_id USING ERRCODE = 'P0002';
    END IF;

    IF v_ticket.status NOT IN ('resolved', 'closed') THEN
        RAISE EXCEPTION 'ticket % cannot be reopened from status %', p_ticket_id, v_ticket.status USING ERRCODE = '22023';
    END IF;

    v_previous_status := v_ticket.status;

    UPDATE tickets
    SET status = 'open',
        resolved_at = NULL,
        reopened_count = reopened_count + 1,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = p_ticket_id
    RETURNING * INTO v_ticket;

    INSERT INTO ticket_status_history (ticket_id, from_status, to_status, changed_by_agent_id, reason)
    VALUES (p_ticket_id, v_previous_status, 'open', p_agent_id, COALESCE(p_reason, 'Ticket reopened'));

    RETURN v_ticket;
END;
$$;
