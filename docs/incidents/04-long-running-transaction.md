# Long-Running Transaction

## Symptoms

A backend has an old `xact_start`, may be idle in transaction, and can retain row versions or locks longer than intended.

## Investigation

Inspect transaction age, session state, wait events, and query text. Distinguish a legitimately long analytical transaction from an abandoned application transaction.

## SQL commands used

```sql
SELECT pid, usename, state, xact_start,
       CURRENT_TIMESTAMP - xact_start AS transaction_age,
       wait_event_type, wait_event, query
FROM pg_stat_activity
WHERE xact_start IS NOT NULL
ORDER BY xact_start;
```

## Evidence

The oldest `xact_start` values and session state provide direct evidence. Pair them with lock information and table dead-tuple growth before claiming impact.

## Root cause

The controlled scenario leaves a transaction open after work completes or while waiting outside the database.

## Resolution

End the abandoned transaction through the owning application or controlled session. If intervention is required, prefer cancellation before termination and document the decision.

## Verification

Confirm the backend transaction disappears, blocked sessions recover, and subsequent vacuum activity is no longer constrained by that transaction horizon.

## Prevention

Use transaction timeouts where appropriate, commit/rollback in all application error paths, and avoid network or user interaction while a transaction is open.
