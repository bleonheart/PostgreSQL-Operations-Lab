#!/usr/bin/env bash
set -Eeuo pipefail

for file in /workspace/migrations/*.sql; do
    psql --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" -X -v ON_ERROR_STOP=1 -f "$file"
done

for file in /workspace/seed/*.sql; do
    psql --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" -X -v ON_ERROR_STOP=1 -f "$file"
done
