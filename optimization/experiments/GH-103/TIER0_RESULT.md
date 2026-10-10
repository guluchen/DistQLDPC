# GH-103 Tier0 result — search-identical lookahead bookkeeping speedups

**Verdict: PASS.** No trace, result or statistic differs from the GH-95 reference (frozen95, search-identical
to main 7eadd54). Tier1 timing is left to the coordinator.

- Candidate code: branch `experiment/gh-103-lk-bookkeeping`, code-final commit `87f7d71` (C1 keyed heap +
  C4 uncheckedEnqueueForLK fast path; C2, C3, C6 reverted, see ATTEMPTS.md). Later commits add only files under
  `optimization/experiments/GH-103/`. Source diff vs GH-95 `ae95b17`: `src/solver/mtl/KeyedHeap.h` (new),
  `src/solver/Solver.h` (+include, member type, one declaration), `src/engine/State.cc` (constructor arg),
  `src/engine/Lookahead.cc` (uncheckedEnqueueForLK split). CRLF preserved in the engine files.
- Frozen candidate: `frozen103/cand/distqldpc` sha256 `4fd05e204595493336099bec2c7b0ff5c87d71f4ee0b037b5c8073475e65bc9f`,
  `frozen103/cand/maxcdcl` sha256 `c5a46f3eaf13bc2976a4dd4f69f47854976c5458ee969ed2670baac1f66ca0a3` (+ dSYM),
  chmod a-w, built with `make CXX="c++ -Wno-reserved-user-defined-literal"` (flags unchanged). All Tier0 runs used
  the frozen binaries.
- Reference: `frozen95/cand/distqldpc` (`de88d7ff…`); its `-v` traces are GH-95's `raw/traces.tar.gz` `cand/`
  (same binary, same flags, same data); a local rebuild of `b3f40b4` has a byte-identical `__text`.
- All solver processes ran under the 2 GB cap (`coord/memlimit.py`, macOS group-RSS poll); no MEMOUT
  (largest group RSS in the trace batch 235 MB).

## Checks

### Smoke and GH58 regressions (`raw/smoke.txt`, `raw/tests.txt`)
```
$ bash scripts/smoke_test.sh <frozen103>/distqldpc        -> DistQLDPC smoke validation passed (exit=0)
$ python3 -B scripts/test_partition_soft_literals.py --binary <frozen103>/maxcdcl
Partition adjacent oracles passed: 11 total inputs, 1024 assignments each.
$ c++ ... tests/test_partition_soft_literals.cc build/*.o -lz && build/test_partition_soft_literals
GH58_PARTITION_ORACLE_PASS cases=80 no_conflict=1   (exit=0)
```
(`scripts/smoke_test.sh` does not quote its binary argument, so it was given a symlink path without spaces.)

### `-v` traces: 50 codes x {default, -no-card, -card-sinz, -card-mto}, `-cpu-lim=20`
GH-95 runner semantics (stdout+stderr in one file, exit status recorded), 4 parallel jobs, under the timing lock
(two holds: 01:46:50-01:52:52 and 01:52:52-01:58:53). GH-95 comparison rule (`cmp_traces.py`): completed runs
byte-identical (only `detect_cpu=` normalised) with equal exit status; timed-out runs: reference child trace
minus its last line must be a prefix of the candidate's, parent header equal.
```
GH95_TRACE_SUMMARY runs=200 identical=65 prefix_ok=135 fail=0
```
| mode | identical (completed) | prefix_ok (timed out) | fail |
|---|---:|---:|---:|
| default | 16 | 34 | 0 |
| -no-card | 16 | 34 | 0 |
| -card-sinz | 17 | 33 | 0 |
| -card-mto | 16 | 34 | 0 |

Timed-out runs covered 227-411 reference child lines (median 261); no candidate run got less far, so no
-cpu-lim=30 reruns were needed. Per-run verdicts `raw/cmp_full.txt`, traces `raw/traces.tar.gz`.

### Per-commit quick check (`raw/quick_builds.txt`)
GH-95 `quick.list` (13 runs) for every build (C1, C1+C2, +C4, +C3, +C6, C4 only, final C1+C4):
`runs=13 identical=11 prefix_ok=2 fail=0` each (PK_31 times out in both).

### maxcdcl oracle (`raw/maxcdcl_cmp.txt`, `raw/dumps_cmp.txt`, `-cpu-lim=60`, frozen95 vs frozen103 maxcdcl)
```
clq-n100e2500g1              IDENTICAL base[optimal: 91 ] cand[optimal: 91 ] exit=20
clq-n150e10058g1             IDENTICAL base[optimal: 115 ] cand[optimal: 115 ] exit=20
partition-retired-soft.wcnf  IDENTICAL base[optimal: 5 ] cand[optimal: 5 ] exit=20
BB_72_12_6.wcnf              IDENTICAL base[optimal: 6 ] cand[optimal: 6 ] exit=20
LP_136_32_4.wcnf             IDENTICAL base[optimal: 4 ] cand[optimal: 4 ] exit=20
TN_36_8_4.wcnf               IDENTICAL base[optimal: 4 ] cand[optimal: 4 ] exit=20
```
The three `-dump-wcnf ... -dump-only` dumps written by frozen103 are byte-identical to GH-95's baseline dumps.

### Cross-repo QDistSAT benchmark (`raw/xrepo_summary.md`, `raw/xrepo_result.json`)
Branch `ci/xrepo-gh103` = one commit `65f6c9f` (`git commit-tree`, tree `0a61f28` = code-final `87f7d71`,
parent `7eadd54`). Push CI run 38072170246 success; `gh workflow run "QDistSAT cross-repo benchmark"` run
38072180551: **success, "Scientific results match: YES"** (LP_136_32_4 and BB_108_8_10, no-card and card-mto:
d=4/4/10/10 in both).

## Agent timing evidence (not the formal Tier1; see ATTEMPTS.md)
Whole-solve child user CPU with 1 ms sampling, identical search, under the lock:
GB_144_12_12 no-card 65.51 s (base, 4 runs) -> 64.40 s (final, 3 runs), **-1.7%**;
LP_544_80_12 card-mto 51.07 s -> 49.44 s, **-3.2%**. Repeat spread <= 0.3%.
Per function: pickAuxiVar self samples -10..-13%; uncheckedEnqueueForLK's call cost (2-3% of runtime) mostly
removed (fast path inlined into propagateForLK); lookbackResetTrail unchanged.

## Deviations
- The frozen95 reference traces were reused from GH-95's archive instead of being rerun (same binary/flags/data).
- `-joint -no-card` was not rerun (not in the GH-103 Tier0 list); it is covered by the 13-run quick check
  (LP_136_32_4 joint identical).
- Harness bug during setup (2026-10-10 ~22:59): the first version of `prof.py` matched the solving child by
  basename and attached `sample` for 3 s to the coordinator's GH-89 Tier3 child (frozen89, GB_144_12_12) while
  GH-89 held the lock. Fixed to match the exact binary path; no other foreign process was touched.
