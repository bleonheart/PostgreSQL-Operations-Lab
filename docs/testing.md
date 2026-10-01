# Testing

`tests/run.sql` creates an assertion helper in a transaction, loads focused test files, then rolls everything back.

Coverage includes:

- required relations and indexes;
- reference-data cardinality;
- foreign-key relationship integrity;
- expected constraint rejection;
- open-ticket view semantics;
- materialized daily metrics;
- assignment procedure behavior;
- ticket reopen function behavior and status-history creation.

CI starts an empty PostgreSQL service, applies migrations twice to exercise practical idempotency, loads reference seed data twice, generates deterministic synthetic data, refreshes reporting state, runs tests, and executes all operational query files.

Bash scripts are checked with `bash -n` and ShellCheck. Python is compiled with `py_compile`. Docker Compose is validated with `docker compose config`.
