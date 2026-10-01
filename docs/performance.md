# Performance

Performance evidence is generated locally instead of committing benchmark numbers that depend on hardware, data volume, cache state, and PostgreSQL settings.

```bash
make generate DATA_TICKETS=50000
make performance
```

Generated plans and catalog output are written to `.artifacts/performance/`.

## Example 1 — missing composite index

1. **Original query:** `performance/01_missing_index_demo.sql` filters an intentionally unindexed temporary ticket copy by organization and unresolved status, then orders by latest update.
2. **Observed query plan:** the first `EXPLAIN (ANALYZE, BUFFERS, VERBOSE)` is captured at runtime. On a sufficiently populated data set it may use a sequential scan plus sort, but the generated plan is the evidence.
3. **Problem:** no index can narrow the organization/status predicate while supporting the requested order.
4. **Change made:** add `(organization_id, status, updated_at DESC)` and run `ANALYZE`.
5. **Improved plan:** the second runtime plan is written to the same artifact for direct comparison. Review scan type, sort nodes, actual rows, and buffers rather than assuming an index scan must win on every data size.
6. **Why it helps:** the index aligns equality predicates with the requested ordering, reducing candidate rows and sort work when the planner estimates index access is cheaper.

## Example 2 — composite index ordering

1. **Original query:** `performance/02_composite_index_ordering.sql` searches by `organization_id` while the first candidate index begins with `status`.
2. **Observed query plan:** the first runtime plan shows whether PostgreSQL can profitably use `(status, organization_id, created_at DESC)` for that predicate on the generated data.
3. **Problem:** the filter does not constrain the leading B-tree column, so the index may be poorly aligned with the access pattern.
4. **Change made:** replace the index with `(organization_id, status, created_at DESC)` and re-analyze.
5. **Improved plan:** capture the second plan and compare access path, filtering, ordering, and buffers with the first.
6. **Why it helps:** `organization_id` becomes the leading search key while `status` remains useful for queries that additionally filter by state.

## Example 3 — N+1-style access

1. **Original query:** the anti-pattern is one ticket-list query followed by separate organization, priority, assignment, and agent lookups for each returned ticket.
2. **Observed query plan:** each individual lookup can be cheap and may use an index, so a single plan does not reveal the aggregate client-side cost. The evidence is the repeated query pattern itself; the lab intentionally avoids inventing a timing claim.
3. **Problem:** repeated client/server round trips and repeated statement execution grow with the number of ticket rows.
4. **Change made:** `performance/03_n_plus_one_comparison.sql` expresses the required relationships as one set-based query with joins.
5. **Improved plan:** `EXPLAIN (ANALYZE, BUFFERS, VERBOSE)` captures PostgreSQL's complete join plan for the single statement.
6. **Why it helps:** PostgreSQL can optimize the full join graph in one execution while the client receives the required ticket context without issuing per-row lookup queries.

## Example 4 — redundant index

1. **Original query:** `performance/05_redundant_index_demo.sql` creates two equivalent `(organization_id, status)` indexes on a temporary ticket table and runs the same lookup.
2. **Observed query plan:** the first plan shows that the optimizer only needs one suitable index for the read path; catalog output shows both equivalent definitions exist.
3. **Problem:** the duplicate index consumes storage and adds maintenance work to writes without representing a distinct access path.
4. **Change made:** drop one duplicate index.
5. **Improved plan:** rerun the same query plan and inspect the catalog again. The goal is retained read access with one index, not a fabricated speedup.
6. **Why it helps:** removing a genuinely redundant index reduces index storage and future write/vacuum maintenance while preserving the represented lookup pattern.

## Index inventory

`performance/04_index_inventory.sql` reports scan counts and index sizes from `pg_stat_user_indexes`. A low `idx_scan` value alone is not evidence that an index should be removed: uptime, statistics resets, write cost, uniqueness enforcement, rare operational paths, and recovery procedures also matter.
