#!/usr/bin/env bash
set -Eeuo pipefail

: "${PGHOST:?PGHOST is required}"
: "${PGUSER:?PGUSER is required}"
: "${BACKUP_FILE:?BACKUP_FILE is required}"
: "${RESTORE_DATABASE:?RESTORE_DATABASE is required}"
PGPORT="${PGPORT:-5432}"

if [[ ! -r "$BACKUP_FILE" ]]; then
    echo "backup file is not readable: $BACKUP_FILE" >&2
    exit 2
fi

if [[ "$RESTORE_DATABASE" =~ ^(postgres|template0|template1)$ ]]; then
    echo "refusing to restore into a protected database: $RESTORE_DATABASE" >&2
    exit 2
fi

if [[ -n "${PGDATABASE:-}" && "$RESTORE_DATABASE" == "$PGDATABASE" && "${ALLOW_SOURCE_DATABASE_RESTORE:-0}" != "1" ]]; then
    echo "refusing to restore over PGDATABASE without ALLOW_SOURCE_DATABASE_RESTORE=1" >&2
    exit 2
fi

pg_restore --list "$BACKUP_FILE" >/dev/null

object_count="$(psql --host="$PGHOST" --port="$PGPORT" --username="$PGUSER" --dbname="$RESTORE_DATABASE" -X -Atqc "SELECT count(*) FROM pg_class WHERE relnamespace = 'public'::regnamespace AND relkind IN ('r','p','v','m','S');")"
if [[ "$object_count" != "0" ]]; then
    echo "restore target is not empty; refusing to overwrite existing objects" >&2
    exit 3
fi

pg_restore \
    --host="$PGHOST" \
    --port="$PGPORT" \
    --username="$PGUSER" \
    --dbname="$RESTORE_DATABASE" \
    --exit-on-error \
    --no-owner \
    --no-privileges \
    "$BACKUP_FILE"
