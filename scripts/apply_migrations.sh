#!/usr/bin/env bash
set -Eeuo pipefail
: "${DATABASE_URL:?DATABASE_URL is required}"
root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
for file in "$root_dir"/migrations/*.sql; do
    psql "$DATABASE_URL" -X -v ON_ERROR_STOP=1 -f "$file"
done
