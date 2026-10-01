#!/usr/bin/env bash
set -Eeuo pipefail
: "${DATABASE_URL:?DATABASE_URL is required}"
root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

for directory in reporting operations troubleshooting optimization; do
    for file in "$root_dir"/queries/"$directory"/*.sql; do
        psql "$DATABASE_URL" -X -v ON_ERROR_STOP=1 -f "$file" >/dev/null
    done
done

echo "query SQL validation passed"
