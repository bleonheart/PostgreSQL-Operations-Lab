CREATE OR REPLACE PROCEDURE sp_assign_ticket(p_ticket_id BIGINT, p_agent_id BIGINT)
LANGUAGE plpgsql
AS $$
BEGIN
    PERFORM 1 FROM tickets WHERE id = p_ticket_id FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'ticket % does not exist', p_ticket_id USING ERRCODE = 'P0002';
    END IF;

    PERFORM 1 FROM agents WHERE id = p_agent_id AND active;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'agent % does not exist or is inactive', p_agent_id USING ERRCODE = '22023';
    END IF;

    UPDATE assignments
    SET unassigned_at = CURRENT_TIMESTAMP
    WHERE ticket_id = p_ticket_id
      AND unassigned_at IS NULL;

    INSERT INTO assignments (ticket_id, agent_id)
    VALUES (p_ticket_id, p_agent_id);
END;
$$;
