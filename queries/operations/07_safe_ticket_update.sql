BEGIN;

SELECT id, status, priority_id, updated_at
FROM tickets
WHERE id = COALESCE(NULLIF(current_setting('app.ticket_id', true), '')::BIGINT, -1)
FOR UPDATE;

UPDATE tickets
SET priority_id = (SELECT id FROM priorities WHERE code = 'P2'),
    updated_at = CURRENT_TIMESTAMP
WHERE id = COALESCE(NULLIF(current_setting('app.ticket_id', true), '')::BIGINT, -1)
  AND status IN ('open', 'pending');

SELECT id, status, priority_id, updated_at
FROM tickets
WHERE id = COALESCE(NULLIF(current_setting('app.ticket_id', true), '')::BIGINT, -1);

ROLLBACK;
