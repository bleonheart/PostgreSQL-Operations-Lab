SELECT id, subject, metadata->>'channel' AS channel, created_at
FROM tickets
WHERE metadata @> '{"channel":"api"}'::JSONB
ORDER BY created_at DESC
LIMIT 100;
