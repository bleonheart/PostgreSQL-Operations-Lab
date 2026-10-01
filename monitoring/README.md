# Monitoring Queries

These queries use PostgreSQL-native statistics views and are read-only. Run a file with:

```bash
psql "$DATABASE_URL" -X -v ON_ERROR_STOP=1 -f monitoring/01_activity.sql
```

| File | Purpose |
| --- | --- |
| `01_activity.sql` | Session and query activity |
| `02_long_running_queries.sql` | Active queries over 30 seconds |
| `03_locks.sql` | Granted/waiting locks and blockers |
| `04_database_and_table_sizes.sql` | Database/table/index growth |
| `05_index_usage.sql` | Index scan counts and sizes |
| `06_connection_usage.sql` | Connection saturation |
| `07_transaction_activity.sql` | Commits, rollbacks, deadlocks, temp I/O |

Statistics are cumulative and should be interpreted relative to uptime, workload, and any statistics reset.
