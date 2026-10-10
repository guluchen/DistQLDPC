# GH-98 Tier0 result: native XOR constraints in the engine (S1)

**Verdict: Tier0 PASS.**
- The self-check build reported no violation in 200 runs.
- `-no-xor -v` traces match frozen95 on all 200 runs (GH-95 rule).
- The science sweep against main 7eadd54 found no unsound bound and no wrong value.
- The maxcdcl oracle found no wrong optimum in 600 random WCNFs. 265 of them had XORs detected.
- The cross-repo benchmark matched.

XOR mode changes the search, so nothing below is a timing claim. Tier1+ timing is left to the coordinator.

- Base: GH-95 engine `ae95b17` (search-identical to main `7eadd54`) plus the evidence commit `3ecd4c0`.
  Branch `experiment/gh-98-native-xor`.
- PROPOSAL.md (`9d402d4`) was committed before any code. The code is commit `9476cd1`. Later commits only add files
  under `optimization/experiments/GH-98/`.
- Host: Mac (Apple M-series), at most 4 jobs in parallel. All three long batches ran under the coordinator timing lock
  (`raw/pipeline.log`): self-check 20:24-20:36, `-no-xor` 20:36-20:48, science 20:48-21:57 CST, 2026-10-10. Short
  steps ran only while the lock was absent.
- Build: `make CXX="c++ -Wno-reserved-user-defined-literal"`. Debug variants add `-DXOR_SELFCHECK` or
  `-DXOR_STATS` to `CXX`.

## Design as built (vs PROPOSAL.md)

The build follows PROPOSAL.md D1-D7. Details:

- **New module `src/engine/Xor.cc`**, included in `Engine.cc` right after `ClauseDB.cc`. It holds detection, the
  propagator template `xorPropagate<MODE>`, restore, GC remap, `solve_()` (wrapper) and the self-check routines.
- **Hooks, each a few lines, CRLF kept** (the count of non-CRLF lines per engine file is unchanged):
  - The XOR block sits between the binary and long-clause loops of `propagate`, `propagateForLK`,
    `simplePropagate` and `simplepropagateForLK`. On conflict or `falseVar`: `qhead = trail.size(); continue;`.
  - `relocAll`: `xorRelocAll`.
  - `removeSatisfied`: XOR clauses are kept.
  - `reduceClause` / `simplereduceClause`: no-op on XOR clauses.
  - `newVar` / `newAuxiVar` grow `xorWatches`.
  - `solve_` was renamed `solveMain_`. `xorDetect()` runs after `simplifyOriginalClauses()`.
- **Clause flag**: `xorc`, one bit taken from `lbd` (24 to 23 bits). `ClauseAllocator::reloc` copies it.
- **Front-end flags**:
  - `distqldpc -no-xor | -xor | -xor-maxk=N`.
  - maxcdcl uses the MiniSat options `-xor/-no-xor` and `-xor-maxk`.
  - XOR mode is the default.
- **Detection line in `-v` output**: `c GH-98 XOR detection: ...` (no timing field, so traces stay deterministic).
- **Micro-optimisation tried and dropped**: `always_inline` on `xorPropagate`. The search was identical and
  GB_144_12_12 no-card took 58.6 / 58.8 s vs 58.4 s, so it made no difference.
- No deviation from the invariants or from the soundness argument.

## Tier0 checks

### Smoke and GH58 regressions (`raw/tests.txt`)
```
$ bash scripts/smoke_test.sh                          -> DistQLDPC smoke validation passed (exit=0)
$ python3 -B scripts/test_partition_soft_literals.py  -> Partition adjacent oracles passed: 11 total inputs, 1024 assignments each. (exit=0)
$ build/test_partition_soft_literals                  -> GH58_PARTITION_ORACLE_PASS cases=80 no_conflict=1 (exit=0)
```
Hosted CI (GCC, ubuntu) on the cross-repo commit passed: run 38051851255, smoke, partition and GH58 oracle.

### Self-check build: 0 failures (`raw/selfcheck_summary.txt`, `raw/selfcheck_traces.tar.gz`)

`scripts/batch.sh <check-build> OUT 20 <repo> none scripts/full200.list 4`: 50 codes x {default, -no-card,
-card-sinz, -card-mto}, `-cpu-lim=20`, XOR on.

| runs | `XOR_SELFCHECK_FAIL` | exit 0 (completed; value = named distance) | exit 1 (all `c status: TIMEOUT`) |
|---:|---:|---:|---:|
| 200 | **0** | 56 (56/56 correct) | 144 |

**After every propagation fixpoint** (no conflict, no `falseVar`) in each of the four routines, every XOR must
satisfy one of these:
- fully assigned with the right parity, or
- both watched variables unassigned.

This rules out a unit or false clause of its CNF expansion. It is exactly the condition "the XOR propagator reached
the clause-propagation fixpoint", and it also includes the 2-watched-variable invariant.

**At every XOR implication**:
- The reason clause has the implied literal at index 0.
- That literal is true.
- All its other literals are false.

**At every XOR conflict**: all literals of the conflict clause are false.

**Table checks**, at detection and every 4096 fixpoints:
- Each pattern clause has the right variables and excluded values.
- It excludes a wrong-parity assignment.
- Each record is in exactly the watch lists of w_0 and w_1.

**Recycled dynamic variables**: none is ever in an XOR.

**Harness validation**: a deliberately broken build (implications skipped in `propagateForLK`) aborted at once with
`XOR_SELFCHECK_FAIL propagateForLK: unit XOR at fixpoint`.

### `-no-xor -v` identity vs frozen95 (`raw/cmp_noxor.txt`, `raw/noxor_traces.tar.gz`)

- **Baseline**: the archived GH-95 Tier0 traces of frozen95 (`GH-95/raw/traces.tar.gz` `cand/`), with the same `-v`
  flags, `-cpu-lim=20` and relative data paths.
- **Comparator**: `GH-95/cmp_traces.py`, unchanged. Completed runs must be byte-identical; timed-out runs must be
  prefix-identical; only `detect_cpu` is normalised.
```
GH95_TRACE_SUMMARY runs=200 identical=65 prefix_ok=135 fail=0
```
No rerun was needed: every timed-out run covered the baseline at the same limit.

maxcdcl `-no-xor` against the GH-95 maxcdcl (`GH-95/scripts/maxcdcl_cmp.sh`, `raw/maxcdcl_cmp_noxor.txt`) was
IDENTICAL on:
- clq-n100e2500g1 (91) and clq-n150e10058g1 (115),
- partition-retired-soft (5),
- the BB_72_12_6, LP_136_32_4 and TN_36_8_4 dumps (6/4/4).

In XOR mode, maxcdcl output differs (detection line, search) and the optimum is the same on all six
(`raw/maxcdcl_cmp_xor.txt`).

### Science sweep, XOR (frozen98) vs main 7eadd54 (`raw/science.json`, `raw/science.log`, `raw/science_posthoc.txt`)

Setup:
- `tier0_science.py` is an unchanged copy of the GH-60/GH-92/GH-99 harness, sha256 `41ee9dfc...`.
- 50 codes x 4 modes, 60 s, `--jobs 4`.
- Baseline: `frozen-main7e/distqldpc` (`6bdcaa25...`). Candidate: `frozen98/cand/distqldpc`.
```
{"both_done": 68, "only_cand_done": 1, "only_base_done": 5, "problems": 0} ALL_OK
POSTHOC_PASS   (timeout in both: 126; candidate final d_lb higher in 0, lower in 0)
```
**Zero unsound bounds**: every completed value equals the named distance, and every emitted `d_lb <= d <= d_ub`.
- Completed only by XOR: TN_144_2_13 no-card (d=13).
- Completed only by main: BB_144_14_14 default/no-card/mto (d=14) and LP_544_80_12 default/mto (d=12).
- These differences come from a different search path and are not timing evidence. They do flag BB_144_14_14 and
  LP_544_80_12 as cells to watch in Tier1/2. The LP_544 card-mto work counts below point the same way.

### maxcdcl fuzz oracle (`scripts/fuzz3.py`, `raw/fuzz_a.json`, `raw/fuzz_b_noelim.json`, `raw/fuzz_xorcount.txt`)

- **Script**: `fuzz3.py` is `fuzz2.py` (the GH-60 corrected oracle, GH-22 contract: unit softs, every `optimal:` must
  equal the brute-force optimum, `s` status checked) with two changes:
  - With probability 0.7 an instance gets 1..n/3 planted XOR families: the full CNF expansion of a random 3-5
    variable parity with random parity value, mixed with 0..2n random clauses.
  - An optional extra solver argument.
- **Binaries**:
  - base: GH-95 maxcdcl (frozen95),
  - cand: frozen98 maxcdcl (XOR on),
  - check: the self-check maxcdcl.

| set | instances | base | cand | check | instances with >= 1 XOR detected (cand) | XORs detected (k3/k4/k5) |
|---|---:|---|---|---|---:|---|
| seed0 980000, default | 400 | 400 done:ok | **400 done:ok** | **400 done:ok** | 169 | 355 (168/104/83) |
| seed0 981000, `-no-elim` | 200 | 200 done:ok | **200 done:ok** | **200 done:ok** | 96 | 181 (80/57/44) |

0 wrong, 0 crashes. Truths: 11 hard-UNSAT, optima 0..9.

### Cross-repo QDistSAT benchmark (`raw/hosted/`)

- `ci/xrepo-gh98` is one commit, `065f9df`: tree `bcc5b7b` (the code of `9476cd1`) on parent 7eadd54, made with
  `git commit-tree`.
- `gh workflow run "QDistSAT cross-repo benchmark" --ref ci/xrepo-gh98` gave run 38051862233: **success, "Scientific
  results match: YES"** (LP_136_32_4 d=4 and BB_108_8_10 d=10, no-card and card-mto).
- Shared-runner times are informational only.

## XOR detection report (`raw/xor_report.md`, from the self-check `-v` traces, default mode)

Totals over 99 CSS-half instances (50 codes; LP_34_20_2 shows only one half):
- **154,242 XORs**: k3 56,082, k4 98,160, k5/k6 0.
- **94.9% of the original clauses** (1,009,608 / 1,063,439) and 96.5% of the original literals are absorbed.

By code:
- Coverage per half runs from 87.5% (LP_136_32_4) to 100% (TN_648_14_50).
- Size-4 candidates are covered 98.7-99.9%. The size-4 originals are therefore essentially all SatELite-merged
  3-input XORs.
- Size-3 candidates are covered 84-99.7%. The rest are other ternaries, for example orbit clauses.
- No 5- or 6-variable XORs occur: SatELite's `grow=0` blocks merging an xor3 with a further xor2.

| case | half 0 XORs (k3/k4) | clauses covered |
|---|---|---:|
| GB_144_12_12 | 463 (182/281) | 95.6% |
| LP_544_80_12 | 2154 (784/1370) | 92.6% |
| TN_144_2_13 | 335 (136/199) | 88.2% |
| LP_340_56_8 | 1201 (472/729) | 91.6% |

## Work counts (informational; `raw/workcounts.md`, `raw/workcounts.tar.gz`)

Counter build (`-DXOR_STATS`), one binary in both modes, `-cpu-lim=30`, 4 runs in parallel. Counters are
process-wide and printed every 2 s of CPU time; the table uses the last line, about 28 s.

What the counters measure:
- **visits**: long-watcher entries examined in `propagateForLK`.
- **inspections**: visits that read clause memory, i.e. whose blocker was not true.
- **XOR visits**: XOR watcher entries examined in `propagateForLK`.

The search differs between the modes, so the progress metric is lookahead calls (`lk`) per CPU second. LP_340_56_8
no-card completes in 1.7 s in both modes, so its row is the whole run.

| case | mode | lk/s | inspections / lkprop | XOR visits / lkprop | XOR impl. / lkprop | visits / lkprop | inspections (total) |
|---|---|---:|---:|---:|---:|---:|---:|
| GB_144_12_12 no-card | no-xor | 24125 | 8.20 | - | - | 179.1 | 0.587e9 |
| GB_144_12_12 no-card | xor | 24325 (+0.8%) | **3.06** | 6.26 | 2.21 | 155.2 | 0.226e9 |
| LP_544_80_12 card-mto | no-xor | 8825 | 6.64 | - | - | 40.8 | 0.801e9 |
| LP_544_80_12 card-mto | xor | 7308 (**-17%**) | **1.81** | 6.42 | 2.36 | 47.9 | 0.190e9 |
| TN_144_2_13 no-card | no-xor | 21409 | 11.82 | - | - | 175.1 | 0.838e9 |
| TN_144_2_13 no-card | xor | 22159 (+3.5%) | **5.24** | 6.47 | 2.15 | 112.7 | 0.378e9 |
| LP_340_56_8 no-card (complete) | no-xor | 12098 | 9.33 | - | - | 25.3 | 0.049e9 |
| LP_340_56_8 no-card (complete) | xor | 13035 | **2.80** | 7.85 | 2.94 | 8.6 | 0.016e9 |

**Reading (diagnostic, not a timing claim)**

1. **The target was hit.** Clause inspections per `propagateForLK` call drop 2.3-3.7x, and long-watcher visits drop
   up to 3x (TN_144, LP_340).
2. **Progress per second barely moves.** Lookahead calls per CPU second change by -17% to +3.5%. The XOR
   propagator does about 6.3-7.9 XOR visits per call, which is as many as the inspections it removes.
3. **Why.** A `sample` of GB_144_12_12 no-card (`raw/gb144_nocard_*.sample.txt`, 15 s each) shows:
   - `propagateForLK` 4867 + `xorPropagate<1>` 2682 samples (XOR mode), against `propagateForLK` 7682
     (clause mode). The lookahead propagation cost is the same.
   - An XOR visit costs about 10 ns.
   - The original XOR clauses are small and cache-resident (about 3k clauses on GB_144), so their inspections were
     cheaper than the "random clause-memory load" model assumed. The expensive inspections are of learnt clauses,
     and XOR mode does not touch those.
4. **Single-case wall times.** These are informal and outside the lock protocol's timing role: GB_144_12_12 no-card
   took 57.9 s (XOR) vs 65.1 s (`-no-xor`), one sample each with different search. **This is not evidence**; Tier1
   decides.

**Suggested Tier1 cells for the coordinator**
- The standard set XOR vs main, including `-card-mto`. LP_544 card-mto shows -17% lookahead progress in the
  counter build and was lost in the science sweep.
- BB_144_14_14 (lost in 3 science modes).
- GB_144_12_12 and TN_144_2_13 no-card, where progress is slightly positive.

## Frozen binaries (read-only, `frozen98/cand/SHA256SUMS`)

| path | sha256 |
|---|---|
| `frozen98/cand/distqldpc` | `2cf4d512b106d505fec9712e7007e660a6b212c2acefb26bdb00ad24f0c9615e` |
| `frozen98/cand/maxcdcl` | `bd8bdf96c8054626d545137786744e1dfcff2dfd77a057e7da5ef530d793a9db` |

Both are built from `9476cd1` with the default `make`. XOR is on by default, and `-no-xor` gives the clause-only
path, which is trace-identical to frozen95.

## Deviations

- **Identity baseline**: the archived GH-95 frozen95 traces were used, not a fresh frozen95 run. They come from the
  same binary with the same flags, limit and comparison rule (same practice as GH-99).
- **Fuzz**: 600 instances (`fuzz3.py`, with planted XOR families) instead of an unchanged `fuzz2.py` copy. The oracle
  contract is unchanged.
- **Work counts**: the search differs between modes, so the counts are compared per lookahead propagation and per
  CPU second. GH-99 instead compared them at an identical `solve_` boundary.
- **Optional full-occurrence watching** for xor2/xor3 was not implemented. It would need per-XOR counters undone on
  every backtrack path, including the direct `assigns` resets of the lookahead and `cancelUntilTrailRecord*`. The
  measurements above also suggest XOR visit cost, not inspection count, is now the limit.
- **XOR-clause handling** (both are pure optimisation/cleanup, sound to skip): satisfied XOR clauses are never removed
  by `removeSatisfied`, and on-the-fly strengthening (`reduceClause`) is skipped for them.
