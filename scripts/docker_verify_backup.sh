#!/usr/bin/env bash
set -Eeuo pipefail

if [[ $# -ne 1 ]]; then
    echo "usage: $0 BACKUP_FILE" >&2
    exit 2
fi

backup_file="$1"
if [[ ! -r "$backup_file" ]]; then
    echo "backup file is not readable: $backup_file" >&2
    exit 2
fi

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root_dir"

docker compose cp "$backup_file" db:/tmp/postgresql_ops_verify.dump >/dev/null
docker compose exec -T db sh -ec '
verify_db="postgresql_ops_verify_$$"
cleanup() {
    dropdb -U "$POSTGRES_USER" --if-exists "$verify_db" >/dev/null 2>&1 || true
    rm -f /tmp/postgresql_ops_verify.dump
}
trap cleanup EXIT
pg_restore --list /tmp/postgresql_ops_verify.dump >/dev/null
createdb -U "$POSTGRES_USER" "$verify_db"
pg_restore -U "$POSTGRES_USER" -d "$verify_db" --exit-on-error --no-owner --no-privileges /tmp/postgresql_ops_verify.dump
psql -U "$POSTGRES_USER" -d "$verify_db" -X -Atqc "SELECT to_regclass('\''public.tickets'\'') IS NOT NULL" | grep -qx t
'
echo "restore verification passed"
