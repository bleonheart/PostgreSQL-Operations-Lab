BEGIN ISOLATION LEVEL REPEATABLE READ;

SELECT COUNT(*) AS open_ticket_snapshot
FROM tickets
WHERE status = 'open';

SELECT txid_current() AS transaction_id;

ROLLBACK;
