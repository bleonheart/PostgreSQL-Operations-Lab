#!/usr/bin/env bash
set -Eeuo pipefail

: "${DATABASE_URL:?DATABASE_URL is required}"

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
output_dir="${PERFORMANCE_OUTPUT_DIR:-${root_dir}/.artifacts/performance}"
mkdir -p "$output_dir"

for file in "$root_dir"/performance/[0-9][0-9]_*.sql; do
    name="$(basename "$file" .sql)"
    psql "$DATABASE_URL" -X -v ON_ERROR_STOP=1 -f "$file" | tee "$output_dir/${name}.txt"
done
