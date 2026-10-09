# Mandatory original crash regression passes on candidate

Actual CI run 37867998817, job 113619258158, completed successfully. The new
test step executes the pinned original 300-byte input, independently enumerates
1024 assignments (216 hard-feasible, optimum 5), checks every complete optimal
cost label, and preserves Main's existing rc/status relationship. Raw job log
excerpt fetched through the GitHub connector:

```text
+2026-10-09T01:04:59.4096626Z HEAD is now at 344cfa1 Merge bb335f683dd144701e5438adf3eb3501078c8578 into 24572d6d09cce9a4a5faa58300a89e0feba9da6a
2026-10-09T01:05:16.5671325Z c initCost: 0, fixedBySearch: 0, optimal: 5, maxsat: 8, hardConflicts: 12
2026-10-09T01:05:16.5675639Z s UNSATISFIABLE
2026-10-09T01:05:16.5675962Z Partition regression passed: all 1024 assignments checked; optimum 5.
```

This is an actual candidate compile/regression result, not a source-only claim.
The legacy UNSATISFIABLE trailer means the final improving bound is exhausted;
the optimal-cost field remains 5. No status semantics were changed. Original
24572d6 failure remains recorded. Server targeted/full native correctness
validation is still pending; this does not establish full Tier0 or performance.
