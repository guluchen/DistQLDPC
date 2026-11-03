# GH-183 cross-check of the PLAUSIBLE lower bounds (relabeled seeds)

Configuration that found the bounds: frozen GH-183 binary d26070d, `-engine=cc -cc-stats -cc-rules=excl,pack,orbf,parity,leaf,overlap,tiebreak,mrv -cc-roworder=bfs`, with `-seed=1..3`.
- `-seed=N` relabels qubits and rows: a different search order and different orbit representatives.
- 28800 s per run; yfclab2 cores 24-32, one process per pinned core, 4 GB cap.

Verdict rule: REPRODUCED if some seed reaches the bound with every level it ran ending EMPTY. Every run below did.

| Code | Bound | Seed 1 | Seed 2 | Seed 3 | Levels run | Verdict |
|---|---:|---|---|---|---|---|
| BB_756_16_30to34 | 32 | 32 @ 12334 s | 32 @ 12360 s | 32 @ 12924 s | 2..30, all EMPTY | REPRODUCED |
| BB_864_4_30to40 | 32 | 32 @ 10797 s | 32 @ 11645 s | 32 @ 11084 s | 2..30, all EMPTY | REPRODUCED |
| TN_496_2_23to30 | 24 | 24 @ 12393 s | 24 @ 9640 s | 24 @ 11147 s | ..23, all EMPTY | REPRODUCED |

Notes:
- **BB parity:** on these BB halves every column weight is odd, so every logical has even weight. The parity rule therefore skips odd levels: level 30 EMPTY certifies lb 32.
- **Status:** all runs ended in TIMEOUT at 28800 s, with no trap, no withdrawn bound and no science problem.
- **Scope:** this is an independent search order of the same implementation, not an independent implementation. The stems are unchanged; renames need the PI.
