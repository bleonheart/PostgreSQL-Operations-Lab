#!/usr/bin/env bash
set -Eeuo pipefail
umask 077

: "${PGHOST:?PGHOST is required}"
: "${PGUSER:?PGUSER is required}"
: "${PGDATABASE:?PGDATABASE is required}"
: "${BACKUP_DIR:?BACKUP_DIR is required}"

PGPORT="${PGPORT:-5432}"
RETENTION_DAYS="${RETENTION_DAYS:-14}"

if ! [[ "$RETENTION_DAYS" =~ ^[0-9]+$ ]]; then
    echo "RETENTION_DAYS must be a non-negative integer" >&2
    exit 2
fi

mkdir -p "$BACKUP_DIR"
timestamp="$(date -u +%Y%m%dT%H%M%SZ)"
final_path="${BACKUP_DIR%/}/${PGDATABASE}_${timestamp}.dump"
temp_path="${final_path}.partial"
trap 'rm -f "$temp_path"' EXIT

pg_dump \
    --host="$PGHOST" \
    --port="$PGPORT" \
    --username="$PGUSER" \
    --dbname="$PGDATABASE" \
    --format=custom \
    --compress=6 \
    --no-owner \
    --no-privileges \
    --file="$temp_path"

pg_restore --list "$temp_path" >/dev/null
mv "$temp_path" "$final_path"
trap - EXIT

BACKUP_DIR="$BACKUP_DIR" RETENTION_DAYS="$RETENTION_DAYS" bash "$(dirname "$0")/cleanup.sh"
printf '%s\n' "$final_path"
