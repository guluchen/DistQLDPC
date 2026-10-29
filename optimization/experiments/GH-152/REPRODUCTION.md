# GH-152: reproduction of the six new CC lower bounds (different search order, original labels)

PI decision (B) of 2026-10-28: reproduce the six PLAUSIBLE lower bounds from the GH-152 Tier 5 run before recording
them. The reproduction keeps the original qubit labels and changes only the search order. Stems are not renamed here.

## Setup

- Binary: the GH-152 evaluated binary dfd0717 (`frozen/server-gh152-dfd0717/distqldpc`, sha256 802729d7...). It is the
  same binary that produced the claimed bounds.
- Flags: `-engine=cc -cc-stats -v -cc-aut=on -cc-rules=excl,pack,orbf,parity,leaf,overlap,mrv -cpu-lim=43200`.
  - Original labels: no `-seed`/`-cc-seed`, so cc-seed is 0.
  - Different search order: the `mrv` rule branches on the odd row with the fewest free candidates. The original run
    branched on the lowest-index odd row.
  - Everything else is the same as the original run: all six pruning rules, the default `-ub-search` finder, and
    `-cc-dual=on`.
- Second order: none exists. `-seed`/`-cc-seed` is the only other order control, and it relabels qubits and rows. No
  flag reseeds the choice of orbit representative without relabelling, so only the `mrv` order was run.
- Host: yfclab2, cores 72-77, one process per pinned core, `taskset -c <core> prlimit --as=4294967296 --`, nohup with
  stdin `/dev/null`.
- Run: started 2026-10-28 22:48 CST, 12 h wall limit, finished 2026-10-29 10:50 CST. All 6 runs ended by TIMEOUT
  (rc 1) with no science issue. Maximum RSS was 40-43 MB. No process is left running.
- Timing: `-v` suppresses the live `c d_lb` lines, so lower-bound times come from the runner's timestamped
  `c cc: <half> half level <w> EMPTY nodes ... time ...` lines. lb(t) = min over the searched halves of (largest EMPTY
  level + 1). Each run's final line, `c d_lb: ...` at timeout, equals the last value in the table below.
- Rule: a level counts as reproduced when it completes EMPTY in this run.

## Result: all six bounds reproduced

| Code | claimed lb (original run, default order) | reproduced lb (mrv, original labels) | status | lb reached at: original -> mrv (s) | deciding level: per-half time and nodes, original -> mrv |
|---|---:|---:|---|---|---|
| TN_288_2_9to24 | 22 | **22** | REPRODUCED | 20888 -> 41377 | 21: X 8905 s / 25.1G -> 18448 s / 56.3G; Z 5867 s / 16.0G -> 11775 s / 36.8G |
| TN_324_4_9to25 | 22 | **22** | REPRODUCED | 15034 -> 21428 | 21: X 6648 s / 18.6G -> 7626 s / 22.8G; Z 3697 s / 10.1G -> 7618 s / 23.2G |
| TN_432_8_9to29 | 23 | **23** | REPRODUCED | 17206 -> 31033 | 22: X 6146 s / 15.6G -> 12794 s / 34.3G; Z 5186 s / 12.2G -> 9197 s / 25.1G |
| TN_496_2_17to30 | 23 | **23** | REPRODUCED | 16819 -> 17151 | 22 (X only, verified dual map): 10992 s / 26.5G -> 12206 s / 34.1G |
| TN_540_4_9to34 | 23 | **23** | REPRODUCED | 10757 -> 18618 | 22: X 4401 s / 10.2G -> 7554 s / 19.9G; Z 2883 s / 7.1G -> 5546 s / 14.4G |
| TN_576_2_9to37 | 24 | **24** | REPRODUCED | 14303 -> 31140 | 23: X 5909 s / 14.0G -> 13265 s / 34.1G; Z 3516 s / 8.2G -> 8444 s / 21.1G |

- Every level of every run completed EMPTY. No level was non-empty below a claimed bound, so there is no escalation.
- The node counts differ from the original run at every level, which confirms a genuinely different search tree. At the
  deciding levels, `mrv` explores 1.2-2.6x more nodes than the index rule.
- One more half-level finished beyond the claims: TN_540 Z level 23 EMPTY at 36399 s. The X half did not finish level
  23, so the lb stays at 23.

## Time per level (mrv run; level: half status nodes level-time @ elapsed)

| Code | 18 | 19 | 20 | 21 | 22 | 23 |
|---|---|---|---|---|---|---|
| TN_288 | X 349 s, Z 247 s (@821) | X 1301, Z 890 (@3012) | X 4899, Z 3243 (@11155) | X 18448, Z 11775 (@41377) | - | - |
| TN_324 | X 194, Z 176 (@526) | X 652, Z 616 (@1794) | X 2229, Z 2161 (@6184) | X 7626, Z 7618 (@21428) | - | - |
| TN_432 | X 102, Z 70 (@242) | X 315, Z 235 (@792) | X 1072, Z 788 (@2652) | X 3705, Z 2686 (@9043) | X 12794, Z 9197 (@31033) | - |
| TN_496 | X 90 (@131) | X 317 (@448) | X 1022 (@1470) | X 3475 (@4945) | X 12206 (@17151) | - |
| TN_540 | X 61, Z 46 (@156) | X 201, Z 154 (@511) | X 666, Z 489 (@1667) | X 2240, Z 1610 (@5517) | X 7554, Z 5546 (@18618) | Z 17782 (@36399), X unfinished |
| TN_576 | X 35, Z 26 (@90) | X 109, Z 81 (@280) | X 354, Z 257 (@891) | X 1192, Z 815 (@2898) | X 3918, Z 2614 (@9430) | X 13265, Z 8444 (@31140) |

Full per-level node counts: `repro/analysis.md`; raw: `repro/results.jsonl`, `repro/mrv_logs.tar.gz`.

## GF(2) verification of the symmetry used (from the `-v` logs)

| Code | orbit partition (`c cc symbreak`) | dual map |
|---|---|---|
| TN_288 | X and Z: `verified_generators=1 orbits=36` (Tanner generator `tanner-aut #1`, group complete) | none; both halves searched |
| TN_324 | X and Z: `verified_generators=1 orbits=36` | none; both halves |
| TN_432 | X and Z: `verified_generators=2 orbits=36` | none; both halves |
| TN_496 | X: `verified_generators=2 orbits=16` | `Tanner swap map: verified as XZ-dual map: X half only`, then `dual map 'tanner-swap (cc-aut)' verified: dX = dZ` |
| TN_540 | X and Z: `verified_generators=2 orbits=36` | none; both halves |
| TN_576 | X and Z: `verified_generators=1 orbits=36` | none; both halves |

`verified_generators` counts the candidates that passed `find_half_symmetry`'s two GF(2) row-space checks. Only those
candidates build the orbits. The swap map passed `verify_dual_perm` and the driver's own echelon re-check (see the
GH-152 proof in `MODIFICATIONS.md`). The orbit partitions are the same as in the original run and the independent
Python audit (`S1/orbit_audit_python.txt`).

## Status

The six bounds TN_288 >= 22, TN_324 >= 22, TN_432 >= 23, TN_496 >= 23, TN_540 >= 23 and TN_576 >= 24 are each
reproduced by a second CC run with a different branching order. Both runs rest on the same GF(2)-verified symmetry and
the same engine; that common basis is what the earlier relabelled cross-check would have varied. The PI decides
recording and stem renames; no stem is renamed here.

## Reproduce

From a worktree of this branch on yfclab2:
`python3 -I optimization/experiments/GH-152/repro/repro_queue.py --bin BIN --cpus 72-77 --jobs optimization/experiments/GH-152/repro/jobs_mrv.jsonl --out OUT`
Then: `python3 -I optimization/experiments/GH-152/repro/analyze_repro.py OUT/logs`.
