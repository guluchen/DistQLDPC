# GH-157: reproduction of the four new CC lower bounds (different search order, original labels)

PI decision of 2026-10-29: reproduce the four PLAUSIBLE lower bounds from the GH-157 Tier 5 run in the way GH-152 did
(`optimization/experiments/GH-152/REPRODUCTION.md`): same rules, original qubit labels, a different search order.
Stems are not renamed here.

## Setup

- Binary: the GH-157 Tier 5 binary `c3c315d` (`frozen/server-gh157-c3c315d/distqldpc`, sha256 `b8057d19...6d`), the
  binary that produced the claimed bounds.
- Flags: `-engine=cc -cc-stats -v -cc-rules=excl,pack,orbf,parity,leaf,overlap,charge,mrv -cpu-lim=43200`.
  - Original labels: no `-seed`/`-cc-seed` (cc-seed 0).
  - Different search order: `mrv` branches on the odd row with the fewest free candidates; the original run branched on
    the lowest-index odd row. With `charge` on, the order also changes which nodes are evaluated and pruned.
  - Everything else as in the original run: the same pruning rules including `charge` with its gap gate (r - p <= 0),
    the default `-ub-search` finder, `-cc-dual=on`. `-cc-aut` did not exist on that branch; GH-152 found nothing new for
    these four codes (`TN_360/396/504` already have 36 orbits from the GH-75 family, `TN_648_10` has a trivial group).
- Host: yfclab2, cores 24-27, one process per pinned core, `taskset -c <core> prlimit --as=4294967296 --`, nohup with
  stdin `/dev/null`, runner `runner/queue.py`.
- Run: started 2026-10-29 14:52 CST, 12 h wall limit, finished 2026-10-30 02:52 CST. All 4 runs ended by TIMEOUT (rc 1),
  no science issue, no process left running.
- Timing: `-v` suppresses the live `c d_lb` lines, so lower-bound times come from the runner's timestamped
  `c cc: <half> half level <w> EMPTY nodes ... time ...` lines; lb(t) = min over the searched halves of (largest EMPTY level
  + 1). Each run's final `c d_lb:` line at timeout equals the reproduced value below (`repro/analyze_repro.py`).
- Rule: a level counts as reproduced when it completes EMPTY in this run.

## Result: all four bounds reproduced

| Code | claimed lb (Tier 5, index order) | reproduced lb (mrv, original labels) | status | lb reached at: original -> mrv (s) | deciding level: per-half time and nodes, original -> mrv |
|---|---:|---:|---|---|---|
| TN_360_4_17to24 | 23 | **23** | REPRODUCED | 21103 -> 41464 | 22: X 6960 s / 11.4G -> 16743 s / 22.0G; Z 7588 s / 12.9G -> 13032 s / 18.9G |
| TN_396_4_17to26 | 23 | **23** | REPRODUCED | 21564 -> 35297 | 22: X 10319 s / 18.8G -> 18871 s / 27.2G; Z 4192 s / 7.8G -> 5480 s / 8.6G |
| TN_504_2_17to34 | 24 | **24** | REPRODUCED | 21150 -> 41050 | 23: X 7042 s / 10.5G -> 13060 s / 16.7G; Z 7100 s / 11.0G -> 15434 s / 21.4G |
| TN_648_10_9to32 | 22 | **22** | REPRODUCED | 20712 -> 31744 | 21: X 7917 s / 13.4G -> 12148 s / 17.9G; Z 5226 s / 9.0G -> 8863 s / 13.5G |

- Every level of every run completed EMPTY; no level was non-empty below a claimed bound (no escalation).
- The node counts differ from the original run at every level, so the search trees are genuinely different. At the
  deciding levels `mrv` explores 1.1-2.0x more nodes than the index rule (GH-152 saw 1.2-2.6x without `charge`).
- TN_360 and TN_504 finished the deciding level only 1 736 s and 2 150 s before the 12 h
  limit; a slower session might not have reached them.
- No level beyond the claims finished.

## GF(2) verification of the symmetry used (from the `-v` logs)

| Code | orbit partition (`c cc symbreak`) | dual map |
|---|---|---|
| TN_360 | X and Z: `verified_generators=2 orbits=36` (blockshift L=2, 2dshift-a L=10) | none; both halves searched |
| TN_396 | X and Z: `verified_generators=1 orbits=36` (blockshift L=11) | none; both halves |
| TN_504 | X and Z: `verified_generators=2 orbits=36` (blockshift L=2, 2dshift-a L=14) | none; both halves |
| TN_648_10 | X and Z: `verified_generators=0 orbits=648` (index seeds, no symmetry) | none; both halves |

The orbits are the same as in the original Tier 5 run. TN_648_10 uses no symmetry at all, so its bound rests only on
the canonical CC search plus the `charge` pruning (soundness: MODIFICATIONS.md, GH-157, Lemmas 1-2).

## Status

TN_360 >= 23, TN_396 >= 23, TN_504 >= 24 and TN_648_10 >= 22 are each reproduced by a second CC run with a different
branching order. Both runs use the same engine and the same `charge` rule; an independent check of that rule is its
brute-force test (Part I, `make test-cc`) and the mutant. The PI decides recording and stem renames; no stem is renamed
here. With the verified upper bound 24, TN_360's gap is now 23..24.

## Reproduce

```bash
cd <DistQLDPC worktree at c3c315d>   # binary: frozen/server-gh157-c3c315d/distqldpc
python3 optimization/experiments/GH-157/runner/queue.py --cpus 24-27 \
    --jobs optimization/experiments/GH-157/repro/jobs_mrv.jsonl --out OUT
python3 optimization/experiments/GH-157/repro/analyze_repro.py OUT/logs/*.log
```

Raw: `repro/results.jsonl`, `repro/mrv_logs.tar.gz`, `repro/analysis.md`.
