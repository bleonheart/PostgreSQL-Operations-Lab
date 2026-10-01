# Backup and Restore Utilities

The scripts use PostgreSQL native custom-format backups. Credentials are read through standard PostgreSQL environment variables or `.pgpass`; passwords are never passed as command-line arguments.

## Create a backup

```bash
export PGHOST=localhost PGPORT=5432 PGUSER=postgres_ops PGDATABASE=postgres_ops
export BACKUP_DIR="$PWD/.artifacts/backups"
bash ./backup/backup.sh
```

`backup.sh` writes to a temporary file, validates the archive with `pg_restore --list`, atomically renames it, then applies retention cleanup.

## Restore

Create an empty target database first, then set `BACKUP_FILE` and `RESTORE_DATABASE`. `restore.sh` refuses protected databases, refuses a non-empty target, and refuses the source database unless explicitly overridden.

## Verify

`verify_restore.sh` creates an isolated temporary database, restores the archive, checks required relations, prints basic row counts, and drops the temporary database on exit.
