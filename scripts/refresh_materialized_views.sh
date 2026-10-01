#!/usr/bin/env bash
set -Eeuo pipefail
: "${DATABASE_URL:?DATABASE_URL is required}"
psql "$DATABASE_URL" -X -v ON_ERROR_STOP=1 -c 'REFRESH MATERIALIZED VIEW CONCURRENTLY mv_daily_ticket_metrics;'
