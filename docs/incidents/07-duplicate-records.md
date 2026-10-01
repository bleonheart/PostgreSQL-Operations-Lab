# Duplicate Records

## Symptoms

Operational reports show multiple tickets that appear equivalent by organization, normalized subject, and creation window.

## Investigation

Run the duplicate-candidate query, inspect all candidate rows, and identify whether they are true duplicates or legitimate repeated requests.

## SQL commands used

```sql
SELECT organization_id,
       lower(trim(subject)) AS normalized_subject,
       date_trunc('hour', created_at) AS created_hour,
       count(*) AS duplicate_count,
       array_agg(id ORDER BY id) AS ticket_ids
FROM tickets
GROUP BY organization_id, lower(trim(subject)), date_trunc('hour', created_at)
HAVING count(*) > 1;
```

## Evidence

Candidate grouping is evidence of similarity, not proof of duplication. Compare request metadata, comments, requester, and timestamps before altering data.

## Root cause

The scenario represents repeated ingestion where the upstream request lacks or fails to reuse a stable idempotency key.

## Resolution

Choose a canonical row only after business-level verification, migrate any dependent records in a transaction, and remove the duplicate using a reviewed script.

## Verification

Re-run the duplicate query and referential-integrity checks; verify dependent comments/history remain attached to the intended canonical ticket.

## Prevention

Introduce a stable external/idempotency identifier with a unique constraint when the ingestion contract supports one.
