SELECT
    datname,
    xact_commit,
    xact_rollback,
    conflicts,
    deadlocks,
    temp_files,
    temp_bytes,
    blk_read_time,
    blk_write_time
FROM pg_stat_database
WHERE datname = current_database();
