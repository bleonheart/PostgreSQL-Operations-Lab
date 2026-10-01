#!/usr/bin/env bash
set -Eeuo pipefail
umask 077

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root_dir"

backup_dir="${BACKUP_DIR:-$root_dir/.artifacts/backups}"
mkdir -p "$backup_dir"

database_name="$(docker compose exec -T db sh -ec 'printf %s "$POSTGRES_DB"')"
timestamp="$(date -u +%Y%m%dT%H%M%SZ)"
final_path="${backup_dir%/}/${database_name}_${timestamp}.dump"
temp_path="${final_path}.partial"
trap 'rm -f "$temp_path"' EXIT

docker compose exec -T db sh -ec 'pg_dump -U "$POSTGRES_USER" -d "$POSTGRES_DB" --format=custom --compress=6 --no-owner --no-privileges' > "$temp_path"
docker compose exec -T db pg_restore --list < "$temp_path" >/dev/null
mv "$temp_path" "$final_path"
trap - EXIT
printf '%s\n' "$final_path"
