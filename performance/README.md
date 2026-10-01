# Performance Labs

Run `make performance` after loading synthetic data. Each SQL file emits real local evidence with `EXPLAIN (ANALYZE, BUFFERS, VERBOSE)` where plan comparison is relevant. Output is captured under `.artifacts/performance/`.

See [`docs/performance.md`](../docs/performance.md) for the original query, observed-plan method, diagnosed problem, change, improved-plan method, and rationale for each lab.
