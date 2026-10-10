# GH-99 Tier0 result: S0, skip base-satisfied watchers in lookahead propagation

**Verdict: Tier0 PASS for both variants.** S0-exact keeps the search identical to GH-95 and main 7eadd54: every `-v`
trace matches under the GH-95 rule, and the flag-off build (`-no-lkskip`) matches too. S0-fast passed a science sweep
with no unsound bound and a 300-instance maxcdcl oracle with no wrong optimum. The self-check builds of both variants
reported no violation in 400 runs. Tier1+ timing is left to the coordinator. Nothing below is a timing claim.

- Base: GH-95 engine `ae95b17`, search-identical to main `7eadd54`. Branch `experiment/gh-99-lk-base-satisfied`.
  Final code commit `ed7a4df`; later commits add only files under `optimization/experiments/GH-99/`.
- Host: Mac (Apple M-series, 12 CPUs), at most 4 jobs in parallel. Every batch longer than 10 minutes ran under the
  coordinator timing lock (`pipeline.log`: lock taken and released per batch, 17:28 to 19:24 CST, 2026-10-10).
- Build: `make CXX="c++ -Wno-reserved-user-defined-literal"`, with an extra `-D` for the variants below. Compiler
  flags are otherwise unchanged.

## Variants and switches

| switch | effect |
|---|---|
| (build default) `DISTQLDPC_LKSKIP_DEFAULT=1` | S0-exact |
| `-DDISTQLDPC_LKSKIP_DEFAULT=2` | S0-fast as default (the frozen fast binary) |
| `distqldpc -no-lkskip` / `-lkskip=exact` / `-lkskip=fast` | runtime mode 0 / 1 / 2 in either binary |
| `distqldpc -lkskip-min=N` (default 16) | watch lists shorter than N are scanned without skip metadata |
| `maxcdcl -lkskip=<0..2> -lkskip-min=N` | same, as MiniSat options |
| `-DLKSKIP_SELFCHECK` | debug: shadow copies of every recorded watcher, checked before each skip; aborts with `LKSKIP_SELFCHECK_FAIL` |
| `-DLKSKIP_STATS` | counters on stderr per `solve_` (`c LKSKIP_STATS ...`); mode 0 counts the original loop |

The front-end only changes `src/core/distqldpc.cc`, where it adds the flags and two help lines. All other code is in
`src/engine/*` and the GH-99 block of `src/solver/Solver.h`. CRLF line endings in the engine files are kept: the
count of non-CRLF lines per file is unchanged. `Solver.h` and `distqldpc.cc` were LF files and stay LF.

## Final design and changes since PROPOSAL.md

PROPOSAL.md (`862a6e3`) was committed before any code. Measurements made during implementation led to four changes.
None of them changes the invariants or the equivalence argument.

1. **Exact mode: one validity level per run, not per literal.** The first implementation dropped a literal's whole
   record whenever its highest blocker level `lmax` was undone. Counters showed most recorded blockers sit many levels
   below `D`: on GB_144, 456M of 800M absorptions had `D - level > 10`. Each run now stores `(start, len, level)`. A
   run is valid while `lkLevelStamp[level] <= m.stamp`, where `m.stamp` is `lkStampCounter` at the end of the
   literal's last scan; undoing a level renews its stamp to a larger counter value. Invalid runs are dropped one at a
   time.
2. **Main propagate keeps runs (exact mode).** In the proposal, `propagate()` invalidated each literal it processed.
   That caused 4.9M of 5.4M literal resets on GB_144. `propagate_exact()` is `propagate()` verbatim plus the same run
   handling as the lookahead loop: valid runs are skipped and moved as blocks. Mode 0 and mode 2 still use the
   original `propagate()`.
3. **Level checks only when the base changed (both modes).** A blocker-true watcher that is not recorded gets a
   level check only if the literal's base (decision level `D`, `lkLevelStamp[D]`, `trailRecord`) differs from the one
   at its last scan. With the same base, such a blocker is a lookahead-level literal. Watchers whose blocker is
   rewritten to a true literal are always checked. This cut level checks by 7-38% and lost no absorptions (7.999e8
   vs 8.009e8 on GB_144). `-DLKSKIP_ABSORB_ALWAYS` restores checking on every scan.
4. **`lkSkipMin` threshold and one cache line of metadata per literal.**
   - The first full exact identity batch (v1, `37e9b23`) passed for correctness. But 20 of its timed-out runs got
     less far than the baseline in 20 s: they were consistent prefixes, mostly `-card-sinz` and LP_544/LP_1768. The
     `-no-lkskip` batch run under the same conditions had none.
   - Stats and `sample` profiles showed why. These cases average about 7 watchers per scanned list, and per-scan
     metadata access cost more than the cheap blocker-true visits it saved.
   - Fix: lists shorter than `lkSkipMin` (16) are scanned without reading any metadata. In exact mode a list never
     keeps runs while it is shorter than `lkSkipMin`; this is enforced at the end of every tracked scan and every
     `propagate_exact` scan. In fast mode an untracked scan from position 0 copies a valid prefix onto itself.
   - The per-literal metadata, including inline run storage, was packed into one 64-byte struct.
   - With this version only 4 runs were shorter than the baseline in 20 s, all consistent prefixes, and all four
     passed at 30 s (see below).

### Invalidation table (final)

| event | action |
|---|---|
| `cancelUntil(L)` | renew `lkLevelStamp[l]` for every undone level `l > L` (exact: runs at those levels die; fast: prefix dies if `lmax` undone) |
| `cancelUntilBeginning` (part of level 0 undone) | global epoch++ |
| `detachClause` (strict or lazy) of a long clause | invalidate both watch lists `~c[0]`, `~c[1]`; covers removeClause, reduceDB*, removeSatisfied, simplify, removeLearntClauses, reduceClause, iset removal, SimpSolver strengthening, and the later `cleanAll` |
| `relocAll` (garbage collection) | global epoch++ |
| `simplePropagate`, `simplepropagateForLK`, `cancelUntilTrailRecord{,1,2}` | global epoch++ |
| `newAuxiVar` recycling a dynamic variable (lists cleared) | global epoch++ |
| `Solver::solve_()` entry (after elimination and clause additions) | global epoch++ |
| main `propagate` | exact: `propagate_exact` keeps runs in place; fast: original loop, prefix copied onto itself |
| `attachClause`, watcher moves `watches[~c[1]].push` | append only, nothing to do |
| safety net (release builds) | runs or prefix extending past the list end trigger a reset; never expected to fire, and in self-check builds this is a hard failure instead |

## Tier0 checks

### Smoke and GH58 regressions (final exact build, `raw/tests.txt`)

```
$ bash scripts/smoke_test.sh                          -> DistQLDPC smoke validation passed (exit=0)
$ python3 -B scripts/test_partition_soft_literals.py  -> Partition adjacent oracles passed: 11 total inputs, 1024 assignments each. (exit=0)
$ build/test_partition_soft_literals                  -> GH58_PARTITION_ORACLE_PASS cases=80 no_conflict=1 (exit=0)
```

Hosted CI (GCC, ubuntu) on the cross-repo commit: success (run 38041525373).

### Self-check build: 0 failures (`raw/selfcheck_summary.txt`, `raw/selfcheck_traces.tar.gz`)

Command: `scripts/batch.sh <check-build> OUT 20 <repo> -lkskip=exact|-lkskip=fast scripts/full200.list 4`. That is
50 codes x {default, -no-card, -card-sinz, -card-mto}, `-cpu-lim=20`.

| mode | runs | `LKSKIP_SELFCHECK_FAIL` | exit 0 (completed) | exit 1 (all `c status: TIMEOUT`) |
|---|---:|---:|---:|---:|
| exact | 200 | **0** | 60 | 140 |
| fast | 200 | **0** | 62 | 138 |

The self-check is stronger than a blocker assertion. Before skipping, it compares every recorded watcher (cref and
blocker) with its shadow copy taken when it was recorded. It also asserts that the blocker is true at a level
`<= decisionLevel()`. Together these are exactly the equivalence condition of the proposal. As an extra
(informational) check, the exact-mode self-check traces match frozen95: 60 identical, 109 prefix, and 31 shorter
consistent prefixes. The self-check build is slower. There was 0 real mismatch (`raw/cmp_check_exact_informational.txt`).

### Flag-off identity: `-no-lkskip -v` vs frozen95 (`raw/cmp_noskip.txt`)

Baseline traces are the GH-95 Tier0 traces of the frozen95 binary (`de88d7ff...`), taken from
`GH-95/raw/traces.tar.gz` `cand/`. They use the same `-v` flags, `-cpu-lim=20`, and relative data paths. The
comparison uses `GH-95/cmp_traces.py` unchanged: completed runs byte-identical, timed-out runs prefix-identical, only
`detect_cpu` normalised.

```
GH95_TRACE_SUMMARY runs=200 identical=65 prefix_ok=135 fail=0
```

### S0-exact identity: default `-v` vs frozen95 (`raw/cmp_exact.txt`, traces in `raw/traces.tar.gz`)

```
$ cmp_traces.py ref95/cand t0/exact full200.list t0/exact_rerun30
GH95_TRACE_SUMMARY runs=200 identical=65 prefix_ok=135 fail=0
```

At 20 s, 4 timed-out runs got less far than the baseline, each a consistent prefix: LP_544_80_12 default and mto,
TN_288_2_24 sinz, TN_540_4_40 sinz. Following the GH-95 rule, they were rerun at `-cpu-lim=30` and then covered the
whole baseline trace (`PREFIX_OK ... (candidate rerun)`). Per mode: default 16 identical / 34 prefix, -no-card 16/34,
-card-sinz 17/33, -card-mto 16/34. These counts equal GH-95's.

### maxcdcl

- **Full-output identity of the exact maxcdcl vs the GH-95 maxcdcl** (`raw/maxcdcl_cmp.txt`, GH-95
  `maxcdcl_cmp.sh`): IDENTICAL on clq-n100e2500g1 (91), clq-n150e10058g1 (115), partition-retired-soft (5), and the
  BB_72_12_6, LP_136_32_4 and TN_36_8_4 dumps (6/4/4).
- **Fuzz oracle** (`scripts/fuzz2.py`, an unchanged copy of the GH-60 corrected oracle, GH-22 contract: unit softs,
  every `optimal:` equals the brute-force optimum). 300 seeded instances (seed0 990000, n = 8..20):
  - base GH-95 maxcdcl, cand fast maxcdcl, check exact maxcdcl: each **300/300 done:ok**, 0 wrong, 0 crashes.
  - Truths: 19 hard-UNSAT; optima 0..8 (`raw/fuzz2.json`).

### S0-fast science sweep (`raw/science.json`, `raw/science.log`, `raw/science_posthoc.txt`)

Command: `tier0_science.py` (an unchanged copy of the GH-60/GH-92 harness, sha256 `41ee9dfc...`), 50 codes x 4
modes, 60 s, `--jobs 4`. Baseline: frozen main 7eadd54 (`6bdcaa25...`). Candidate: frozen99/fast. Run under the lock
from 18:16 to 19:24.

```
{"both_done": 71, "only_cand_done": 4, "only_base_done": 2, "problems": 0} ALL_OK
POSTHOC_PASS  (125/125 candidate timeouts emitted a d_lb)
```

Every completed value equals the named distance, and every emitted `d_lb <= d <= d_ub`: **zero unsound bounds**.
- Completed only by fast: GB_144_12_12 default/mto/sinz (d=12) and LP_544_80_12 no-card (d=12).
- Completed only by base: LP_544_80_12 default/mto (d=12).
- These completion differences reflect fast mode's different search path and are not timing evidence.

### Cross-repo QDistSAT benchmark (`raw/hosted/`)

`ci/xrepo-gh99` is one commit `315e86e`: tree `711b4d1` (code of `ed7a4df`) on parent 7eadd54, built with
`git commit-tree`. Running `gh workflow run "QDistSAT cross-repo benchmark" --ref ci/xrepo-gh99` gave run
38041525374: **success, "Scientific results match: YES"** (LP_136_32_4 d=4, BB_108_8_10 d=10, no-card and card-mto).
Shared-runner times are informational only. An earlier dispatch on the v1 tree (run 38039067367) also matched.

## Work counts (informational; `raw/workcounts.tar.gz`)

Counter build (`-DLKSKIP_STATS`), `-cpu-lim=30`, one binary in all three modes. In exact mode the search is
identical, so mode 0 and mode 1 are compared at the same `solve_` boundary (the last one reached). As a cross-check,
mode-1 `visits + skipped` equals mode-0 `visits` exactly in every case. "Visits" counts long-watcher entries examined
by the `propagateForLK` loop.

| case | mode 0 visits | exact visits (% of mode 0) | exact skipped | exact level checks | theoretical floor (non-base visits) |
|---|---:|---:|---:|---:|---:|
| GB_144_12_12 no-card | 6.64e9 | 1.14e9 (**17.1%**) | 5.50e9 | 0.44e9 | 7.6% |
| LP_544_80_12 card-mto | 4.16e9 | 2.03e9 (**48.9%**) | 2.12e9 | 0.17e9 | 28.4% |
| TN_144_2_13 no-card | 0.155e9 | 0.110e9 (**70.9%**) | 0.045e9 | 0.020e9 | 44.3% |
| LP_340_56_8 no-card | 0.134e9 | 0.125e9 (**93.6%**) | 0.009e9 | 0.009e9 | 72.2% |

- Main propagate also skips: 2.5e8 watchers on GB_144 and 5.0e7 on LP_544.
- Fast mode follows a different search path, so it is reported as a ratio within its own run. Unscanned visits made
  up 19.4% / 43.0% / 67.8% / 91.5% of its `visits + skipped` on GB_144 / LP_544 / TN_144 / LP_340.
- The `lkSkipMin=16` threshold trades coverage for less metadata traffic. With `-lkskip-min=0`, exact reached
  12.8% / 30.3% / 49.8% / 74.2% of mode-0 visits, close to the floor.

**Engineering note for the coordinator (diagnostic, not a timing claim).**
- Blocker-true visits are cheap (L1-resident `assigns`, sequential watch lists); the bulk of `propagateForLK` cost is
  clause inspection, which S0 does not touch. This matches the GH-34 lesson in the hot-loop profile.
- Short `sample` profiles taken while diagnosing the v1 slowdown suggest the effect is small: a few points of the
  `propagateForLK` share on GB_144, and roughly neutral on LP_544 card-mto. Profile noise is about 1-2 points.
- `-lkskip-min` is the main tuning knob if Tier1 shows a regression on short-list cases (sinz, LP_544).
- **Suggested Tier1 cells:** exact vs main on the standard set, plus `-lkskip-min=32`. Fast should only be timed if
  exact shows a gain.

## Frozen binaries (read-only)

| path | sha256 |
|---|---|
| `frozen99/exact/distqldpc` | `2ed8f23c22beb98b62c6133e8052dac06d30ff8b524411c9f079dbd3f568caab` |
| `frozen99/exact/maxcdcl` | `921198678699965e4efc4e9680f5496e9737d27e31d23442fef721412b6eeabd` |
| `frozen99/fast/distqldpc` | `2d3b73ae64d82406c0a2666935114f0a94d8b8ba1739bef1371178af17da1994` |
| `frozen99/fast/maxcdcl` | `c34cf23d8eb348d328fc12bd649503f4dd1ab78820819183c5296ae3ece94ae4` |

Both are built from `ed7a4df`; they differ only in `DISTQLDPC_LKSKIP_DEFAULT`, and each supports all modes through
its flags. Each directory has a `SHA256SUMS`.

## Deviations

- The identity baselines are the archived GH-95 frozen95 traces, not a fresh frozen95 run. They are the same binary
  with the same flags, limit and rule.
- Four exact runs needed the GH-95 `-cpu-lim=30` rerun.
- Design changes 1-4 above were made after PROPOSAL.md, driven by counters and the v1 identity batch. They are
  documented here; PROPOSAL.md was left unchanged.
- The `-joint` mode is not part of the 4-mode matrix requested for this task.
- `fuzz2.py`, `brute.c`, `tier0_science.py` and `posthoc_science.py` are unchanged copies from GH-60/GH-92.
