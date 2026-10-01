# Backup and Restore

## Backup strategy

`backup/backup.sh` creates a PostgreSQL custom-format archive using `pg_dump`, validates the archive catalog with `pg_restore --list`, and only then renames the temporary file into its final timestamped name. File permissions are restricted with `umask 077`.

Authentication uses standard PostgreSQL environment variables and `.pgpass` support. The scripts do not place passwords on command lines.

## Retention

`backup/cleanup.sh` deletes only `*.dump` files directly inside the configured backup directory and refuses the filesystem root. `RETENTION_DAYS` defaults to 14 and must be a non-negative integer.

## Restore safety

`backup/restore.sh` requires an explicitly named target database. It refuses PostgreSQL template/system databases, refuses a non-empty target, validates the archive before restore, and avoids ownership/privilege replay for portability.

Restoring over `PGDATABASE` is refused unless `ALLOW_SOURCE_DATABASE_RESTORE=1` is deliberately set.

## Verification

`backup/verify_restore.sh` creates a temporary database, restores the archive, checks required relations, prints basic row counts, and removes the verification database through an exit trap.

## Recovery procedure

1. Confirm the incident scope and preserve the existing database state when feasible.
2. Select the intended backup and run `pg_restore --list` or `verify_restore.sh` before destructive recovery actions.
3. Restore into an isolated database first.
4. Run application-specific validation, row-count comparisons, and integrity checks.
5. Schedule the cutover separately from the restore itself.
6. Record backup identity, restore commands, validation evidence, and any data-loss window in the incident record.

This lab demonstrates logical backup/restore. It does not configure WAL archiving or point-in-time recovery.
