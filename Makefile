SHELL := /usr/bin/env bash
.DEFAULT_GOAL := help

POSTGRES_DB ?= postgres_ops
POSTGRES_USER ?= postgres_ops
DATA_SEED ?= 42
DATA_ORGANIZATIONS ?= 50
DATA_USERS_PER_ORG ?= 20
DATA_AGENTS ?= 30
DATA_TICKETS ?= 20000
DATA_INCIDENTS ?= 300
DATA_EVENTS ?= 3000

.PHONY: help up down reset logs migrate seed generate test validate monitor performance backup verify-backup

help:
	@printf '%s\n' \
	  'make up              Start PostgreSQL and initialize schema/reference data' \
	  'make generate        Load deterministic synthetic workload data' \
	  'make test            Run SQL tests in the Docker database' \
	  'make validate        Validate query SQL against the Docker database' \
	  'make performance     Capture EXPLAIN ANALYZE output under .artifacts/' \
	  'make monitor         Show current PostgreSQL activity' \
	  'make backup          Create a custom-format backup under .artifacts/backups' \
	  'make verify-backup BACKUP_FILE=...  Restore-test an archive' \
	  'make reset           Recreate the database volume from scratch' \
	  'make down            Stop containers'

up:
	docker compose up -d db

logs:
	docker compose logs -f db

down:
	docker compose down

reset:
	docker compose down -v
	docker compose up -d db

migrate:
	docker compose exec -T db sh -ec 'for f in /workspace/migrations/*.sql; do psql -U "$$POSTGRES_USER" -d "$$POSTGRES_DB" -X -v ON_ERROR_STOP=1 -f "$$f"; done'

seed:
	docker compose exec -T db sh -ec 'for f in /workspace/seed/*.sql; do psql -U "$$POSTGRES_USER" -d "$$POSTGRES_DB" -X -v ON_ERROR_STOP=1 -f "$$f"; done'

generate:
	docker compose --profile tools run --rm generator \
	  --reset-generated \
	  --seed $(DATA_SEED) \
	  --organizations $(DATA_ORGANIZATIONS) \
	  --users-per-org $(DATA_USERS_PER_ORG) \
	  --agents $(DATA_AGENTS) \
	  --tickets $(DATA_TICKETS) \
	  --incidents $(DATA_INCIDENTS) \
	  --events $(DATA_EVENTS)

test:
	docker compose exec -T db sh -ec 'psql -U "$$POSTGRES_USER" -d "$$POSTGRES_DB" -X -v ON_ERROR_STOP=1 -f /workspace/tests/run.sql'

validate:
	@for dir in reporting operations troubleshooting optimization; do \
	  for file in queries/$$dir/*.sql; do \
	    echo "validating $$file"; \
	    docker compose exec -T db sh -ec 'psql -U "$$POSTGRES_USER" -d "$$POSTGRES_DB" -X -v ON_ERROR_STOP=1 -f "$$1"' sh "/workspace/$$file" >/dev/null; \
	  done; \
	done

monitor:
	docker compose exec -T db sh -ec 'psql -U "$$POSTGRES_USER" -d "$$POSTGRES_DB" -X -v ON_ERROR_STOP=1 -f /workspace/monitoring/01_activity.sql'

performance:
	@mkdir -p .artifacts/performance
	@for file in performance/[0-9][0-9]_*.sql; do \
	  name="$$(basename "$$file" .sql)"; \
	  echo "running $$name"; \
	  docker compose exec -T db sh -ec 'psql -U "$$POSTGRES_USER" -d "$$POSTGRES_DB" -X -v ON_ERROR_STOP=1 -f "$$1"' sh "/workspace/$$file" | tee ".artifacts/performance/$$name.txt"; \
	done

backup:
	bash ./scripts/docker_backup.sh

verify-backup:
	@test -n "$(BACKUP_FILE)" || (echo 'BACKUP_FILE is required' >&2; exit 2)
	bash ./scripts/docker_verify_backup.sh "$(BACKUP_FILE)"
