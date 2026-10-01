# Operational Queries

Queries are grouped by the operational question they answer.

| Area | Examples |
| --- | --- |
| `queries/operations/` | unresolved tickets, SLA risk, agent workloads, stale tickets, inactive customers, status history, safe updates, isolation |
| `queries/reporting/` | daily volume, resolution time, reopen ranking, incident categories, service frequency, recursive category hierarchy |
| `queries/troubleshooting/` | duplicate candidates, long transactions, blocking locks |
| `queries/optimization/` | set-based N+1 replacement, JSONB containment filter |

The scripts are executable SQL rather than pseudocode. `scripts/validate_sql.sh` executes the query tree with `ON_ERROR_STOP=1`; mutating examples use `ROLLBACK`.

For ticket-specific history or maintenance, set a psql session parameter first:

```sql
SET app.ticket_id = '123';
```

The repository intentionally keeps reporting and operational SQL close to the schema rather than embedding it in a sample application layer.
