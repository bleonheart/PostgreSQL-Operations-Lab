# Failed Backup

## Symptoms

The backup script returns nonzero, produces only a partial file, or archive validation fails.

## Investigation

Capture the `pg_dump`/`pg_restore --list` error, confirm connectivity and permissions, inspect destination free space, and verify the configured path is writable.

## SQL commands used

```bash
PGHOST=localhost PGUSER=postgres_ops PGDATABASE=postgres_ops \
BACKUP_DIR="$PWD/.artifacts/backups" bash ./backup/backup.sh

pg_restore --list /path/to/archive.dump
```

## Evidence

A valid backup requires a successful `pg_dump` exit and a readable custom archive catalog. File existence or nonzero size alone is insufficient evidence.

## Root cause

The scenario can be reproduced with an unavailable database, unwritable destination, insufficient disk, or invalid credentials.

## Resolution

Correct the failed dependency and rerun the backup. Never promote a `.partial` file; `backup.sh` removes partial output on failure.

## Verification

Run `backup/verify_restore.sh` against the completed archive and confirm required relations after restoring into the temporary verification database.

## Prevention

Schedule restore tests, monitor backup exit status and destination capacity, use restricted credentials, and keep backup retention bounded.
