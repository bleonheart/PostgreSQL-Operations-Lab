#!/usr/bin/env bash
set -Eeuo pipefail

: "${PGHOST:?PGHOST is required}"
: "${PGUSER:?PGUSER is required}"
: "${BACKUP_FILE:?BACKUP_FILE is required}"
PGPORT="${PGPORT:-5432}"
verify_db="postgresql_ops_verify_$(date -u +%Y%m%d%H%M%S)_$$"

cleanup() {
    dropdb --host="$PGHOST" --port="$PGPORT" --username="$PGUSER" --if-exists "$verify_db" >/dev/null 2>&1 || true
}
trap cleanup EXIT

pg_restore --list "$BACKUP_FILE" >/dev/null
createdb --host="$PGHOST" --port="$PGPORT" --username="$PGUSER" "$verify_db"
pg_restore --host="$PGHOST" --port="$PGPORT" --username="$PGUSER" --dbname="$verify_db" --exit-on-error --no-owner --no-privileges "$BACKUP_FILE"

psql --host="$PGHOST" --port="$PGPORT" --username="$PGUSER" --dbname="$verify_db" -X -v ON_ERROR_STOP=1 <<'SQL'
DO $$
DECLARE
    missing TEXT[];
BEGIN
    SELECT array_agg(expected.name)
    INTO missing
    FROM (VALUES ('organizations'), ('users'), ('tickets'), ('incidents'), ('audit_logs')) AS expected(name)
    WHERE to_regclass('public.' || expected.name) IS NULL;

    IF missing IS NOT NULL THEN
        RAISE EXCEPTION 'restore verification failed; missing relations: %', missing;
    END IF;
END
$$;

SELECT COUNT(*) AS organization_count FROM organizations;
SELECT COUNT(*) AS ticket_count FROM tickets;
SQL

echo "restore verification succeeded in temporary database $verify_db"
