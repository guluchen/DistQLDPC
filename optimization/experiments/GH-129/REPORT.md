# GH-129: frontier branching in MaxCDCL ("MaxSAT absorbs CC", step 2)

- Date: 2026-10-17. Issue #129 (hub #15). Baseline: main **abd1770**. Branch `experiment/gh-129-frontier-branching`; candidate code commit **d1f3f41** (this report and the raw data are committed on top of it).
- Hypothesis: CC's growth rule ("extend the cluster only through an unsatisfied check"), used as MaxCDCL's decision rule inside each CSS-half probe, makes MaxCDCL find low-weight logicals and refute caps faster without changing the formula.
- Prior records read: GH-121 (`S0_S1_REPORT.md`, `V2_DIAGNOSIS.md` on `experiment/gh-121-pib`: the half's parity rows were passed to the engine from `run_css_half()`; perturbing the lookahead/decision state hurt TN solution finding; default-seed timings are dominated by seed luck), GH-124 S1 report (CC engine Tier 0-5), `docs/OPTIMIZATION_LOOP_POLICY.md`.
- No PR, no merge, no external solver. Mac: Apple M6, at most 2 solver processes at a time, 2 GB RSS cap per process, `caffeinate -i -s`. yfclab2: cores 64-123 only, every process `taskset -c <core> prlimit --as=4294967296 --`, one per core.

## Summary

- **Implementation (S0).** `-frontier=off|on|postsol|presol` (default off). With `on`, each MaxCDCL decision first looks for an *odd* parity row of the half (true qubits of odd parity, at least one unassigned qubit), takes the one with the fewest unassigned qubits (ties: row index) and decides its unassigned qubit with the highest activity to 1; with no odd row, main's `pickBranchLit()` decides. The row state is updated lazily from the main trail at each decision. Only the decision order changes. Default path: `-v` logs byte-identical to frozen main abd1770 on 14 tier0+tier1 codes x 2 modes (Mac 28/28; yfclab2 28/28 vs main 398054e up to the printed cpu-time field).
- **Correctness: no mismatch anywhere.** S0 tier0-3 both modes (250 runs, 84 of them with the `-frontier-check` state verifier: 0 failures), 96 random small CSS codes (n 10-144, d 1-10) x {on, off} x 2 modes against `-engine=cc` (0 mismatches), 260 server panel runs (252 correct, 8 timeouts, 0 wrong), 52 Tier 5 runs (every answer and bound consistent with the stems), 102 Mac quick-check runs.
- **S0 work counts (Mac, single default-seed runs, ratio on / off):** conflicts geomean tier0 0.65-0.70, tier1 0.39-0.42, tier2 0.32-0.35, tier3 0.28-0.37; wall tier1 0.42 / 0.47, tier2 0.44 / 0.40, tier3 0.35 / 0.48 (card-mto / no-card). Large on BB/GB/LP (BB_144_14_14 0.22-0.24, GB_144_12_12 card-mto 0.10, LP_544_80_12 no-card 0.09), weak or negative on TN (TN_144_2_13 no-card 1.61, TN_200_10_10 no-card 1.39). `postsol` ~ main, `presol` worse than `on`; no variant promoted.
- **S1 seed panel (yfclab2, 5 seeds, seed-median ratio cand / main):** Tier 1 **0.606 / 0.431** (no-card / card-mto) PASS; Tier 2 **0.500 / 0.488** PASS; Tier 3 **0.557 / 0.376** but **FAIL** (TN_200_10_10 1.53 / 1.30 > 1.25; TN_144_2_13 1.04 / 1.12); Tier 4 **1.673 / 1.234 FAIL** (TN_250_10_15; candidate 4 timeouts at 5000 s against main's 1).
- **Tier 5 (6 h, default seed):** solved cells cand 4, main 7, CC 16 (of 52). The candidate solves LP_714_100_16 and LP_1020_136_16 in both modes 1.6-2.3x sooner than main (3055-4511 s against 5321-8752 s), reaches lb 17 on LP_1768_224_22 (main 9), finds ub 32 on LP_1054_140_20 / LP_1428_184_24 (main none) and BB_360_12_24 ub 24 at 479 / 1204 s (main's recorded run also ends with ub 24, time not recorded; an earlier main probe needed about 4.5 h for it); but loses TN_180_2_17 (lb 9, main solved no-card at 9837 s and had lb 17 / ub 19 in card-mto) and TN_216_4_18 (main solved both modes; cand lb 9 / 17), and reaches lb 17 on the other TN codes 1.0-2.9x later. Time to main's final lb (30 cells): BB 0.40-1.28, LP 0.43-0.76, TN 0.86-2.87.
- **Mac tier0-2 quick check (3 serial runs vs the recorded Mac main table):** geomean tier0 0.83 / 0.88, tier1 0.50 / 0.44, tier2 0.41 / 0.45 (no-card / card-mto); all answers correct.
- **Gate verdicts:** Tier 0 PASS, Tier 1 PASS, Tier 2 PASS, **Tier 3 FAIL, Tier 4 FAIL**, Tier 5 (informational) FAIL (4 cells worse than main: TN_180 and TN_216 both modes). **Not adopted.** The flag stays off by default on the branch.
- **Recommendation:** do not merge `-frontier=on` as a default. The rule is a strong solution-finding heuristic (2-4x fewer conflicts to a solution on every family) and helps BB/GB/LP refutations too, but it slows TN refutation (more lookahead work per conflict), which dominates TN tier3-5. Next steps (§7): make it conditional on what it is good at — e.g. use the rule only until a probe's first solution *and* only in feasibility probes whose cap is above the current global lower bound, or select it per half from a cheap structural signal (it lost on all 4 TN cells and won on all 18 BB/GB/LP cells of tiers 1-4) — and re-run the TN panel cells first. Keep the CC engine (GH-124) as the reference: on Tier 5 it remains far ahead (16 solved cells vs 4).

## 1. Design (S0)

Files: `src/solver/Solver.h`, `src/solver/Solver.cc` (CRLF kept), `src/core/distqldpc.cc`; +190 / -1 lines (commit d1f3f41).

- `run_css_half()` passes the half's parity rows (`Hpar` = Hz for the X half, Hx for the Z half, over qubit vars 0..n-1) to the engine when `-frontier` is not off (`Solver::setFrontierRows`), as GH-121 did for PIB.
- `Solver::search()`: `if (frontierMode && (frontierMode == 1 || (frontierMode == 2) == frSeenSolution)) next = pickFrontierLit(); if (next == lit_Undef) next = pickBranchLit();`. With `-frontier=off` this is main's path (`next` starts as `lit_Undef`).
- `pickFrontierLit()`: `frSync()`; among the odd rows the one with the fewest unassigned qubits (ties: smallest row index); in it the unassigned decision qubit with the highest activity (`activity_VSIDS` in VSIDS phases, `activity_CHB` in LRB phases, i.e. the score MaxCDCL itself uses at that moment; ties: smallest index); returns `x_q = 1`. No odd row: `lit_Undef` (fallback to main's decision).
- Incremental state: per row the unassigned count and the parity of its true qubits, plus an indexed set of odd rows. `frApplied` holds the qubit literals reflected in the state with their trail positions; `cancelUntil()` and `cancelUntilBeginning()` lower `frSynced` (one predicated compare, inactive when off); `frSync()` undoes the entries at or above `frSynced` and applies the trail from there. Lookahead's temporary assignments lie above the trail position of the last decision and are undone before the next one, so they never enter the state. `-frontier-check` recomputes the whole state from the assignment at every frontier decision and counts mismatches (0 in every run). Profile (TN_200_10_10 no-card, Mac `sample`): `frApply` + `frSync` < 1 % of samples; `propagateForLK` stays dominant.
- Soundness: no clause, bound, propagation or lookahead rule changes; only which free variable is decided and with which polarity. Completeness and every proof are unaffected.
- Variants: `postsol` (rule only after the probe's solver found a solution), `presol` (only until then). `-frontier-stats` prints per-probe conflicts / decisions / frontier picks to stderr (also with `-frontier=off`; search unchanged).

## 2. S0 results (Mac)

### 2.1 Default-path identity

`cand` (no flag) and `cand -frontier=off` against frozen main abd1770, `-v -cpu-lim=300`, 14 tier0+tier1 codes x {no-card, card-mto}: **56/56 byte-identical logs** (raw `cmp`, timing fields included); the committed build d1f3f41: 28/28 identical (`S0/identity_mac_vs_main_abd1770.txt`). yfclab2: d1f3f41 (no flag) against frozen main 398054e (GH-124 showed abd1770's MaxSAT path equals 398054e): 28/28 identical except the printed `detect_cpu` field in two logs (`S1/server/ident_server.tar.gz`).

### 2.2 Correctness

| Check | Runs | Result |
|---|---:|---|
| tier0+1 x 2 modes x {on, postsol, presol}, `-frontier-check` | 84 | all answers = stem d, 0 check failures, 0 "no eligible qubit" events |
| tier0-2 x 2 modes x {off, on, postsol, presol} (work counts) | 136 | all correct |
| tier3 x 2 modes x {off, on, presol}, `-cpu-lim=1800` | 30 | all correct, no timeout |
| random set 1: 48 codes, n 10-52, d 1-3 (`S0/tools/gen_random_codes.py`), arms {cc, on-nc, on-mto (with check), off-nc, off-mto} | 240 | 0 mismatches vs `-engine=cc`, 0 check failures |
| random set 2: 48 codes, n 18-144, d 2-10 (toric-like HGPs, HGPs of column-weight-3 classical codes, tier0 codes; each qubit-permuted and row-mixed by elementary row operations plus redundant rows; `gen_random_codes2.py`), same 5 arms | 240 | 0 mismatches vs `-engine=cc`, 0 check failures; tier0-derived codes return their stem d |

### 2.3 Work counts (single default-seed runs, 2 concurrent; ratios vs `-frontier=off` = main)

Per-cell tables: `S0/counts_tier0_2.md`, `S0/counts_tier3.md` (wall / conflicts / decisions and the share of decisions made by the rule).

| tier | mode | on: wall / conflicts | postsol: wall / conflicts | presol: wall / conflicts |
|---|---|---|---|---|
| 0 | no-card | 0.843 / 0.654 | 1.020 / 0.972 | 0.835 / 0.674 |
| 0 | card-mto | 0.804 / 0.703 | 1.054 / 1.000 | 0.930 / 0.740 |
| 1 | no-card | 0.473 / 0.416 | 0.852 / 0.826 | 0.577 / 0.538 |
| 1 | card-mto | 0.420 / 0.390 | 0.994 / 1.002 | 0.507 / 0.490 |
| 2 | no-card | 0.403 / 0.322 | 1.005 / 0.983 | 0.363 / 0.343 |
| 2 | card-mto | 0.443 / 0.347 | 1.060 / 0.965 | 0.415 / 0.382 |
| 3 | no-card | 0.482 / 0.365 | - | 0.631 / 0.576 |
| 3 | card-mto | 0.352 / 0.281 | - | 0.532 / 0.513 |

Tier 3 wall ratios (on / presol): BB_288_12_18 0.33 / 0.83 (no-card), 0.22 / 0.74 (card-mto); GB_144_12_12 0.40 / 0.47, 0.10 / 0.20; LP_544_80_12 0.09 / 0.12, 0.38 / 0.64; TN_144_2_13 1.61 / 1.72, 0.72 / 0.54; TN_200_10_10 1.39 / 1.22, 0.89 / 0.85.

Reading:

- The rule makes 50-100 % of the decisions in the probes where it matters (mean 5-13 odd rows per decision). Conflicts drop in almost every cell; S0 counts were not "clearly worse", so S1 ran `-frontier=on`.
- `postsol` is close to main: most work happens before a probe's first solution (feasibility probes stop there, NONE probes never find one). `presol` differs from `on` only in the proof part of optimize probes; it is worse than `on` on BB/GB/LP (the rule helps those proofs) and not better on the TN tier3 codes, so no variant was promoted.
- TN is the weak family. Per-probe timeline of TN_250_10_15 no-card (Mac, default seed, two runs side by side; `S0/raw/t3.tar.gz`, `tn250/`):

  | probe | main (off) | on | presol |
  |---|---|---|---|
  | X cap 16 feasibility (FOUND) | 118 s, 0.97 M conflicts | 28 s, 0.22 M | 28 s |
  | Z cap 16 feasibility (FOUND) | 195 s, 1.48 M | 51 s, 0.39 M | 51 s |
  | X cap 15 feasibility (FOUND) | 141 s, 1.14 M | 80 s, 0.55 M | 80 s |
  | Z cap 14 feasibility (NONE: refutation) | 330 s, 2.35 M | 449 s, 1.99 M | 450 s |
  | X cap 15 optimize (re-find 15, prove no 14) | 312 s, 2.31 M | 729 s, 2.66 M | 341 s, 2.16 M |
  | total | 1096 s | 1337 s | 950 s |

  Solution finding is 2-4x faster with the rule; refutation costs more time per conflict (Z cap 14: 15 % fewer conflicts, 36 % more time: the lookahead does more work per conflict; the frontier bookkeeping itself is < 1 %). Note also that the optimize probe first re-finds the weight-15 logical its feasibility probe had already found (main 1.1 M conflicts twice); that redundancy is the subject of GH-128.

## 3. S1 seed panel (yfclab2)

Method: `S1/runner/s1_panel.py`, binary `frozen/server-gh129-d1f3f41/distqldpc` (sha256 `d8f2b9caaaccd5ea4ed9443697bca788f3787c0e6c0d73eb54069a139438dd97`, GCC build of d1f3f41). Arms per (code, seed S = 0..4): main-nc `-no-card -seed=S`, main-mto `-card-mto -seed=S`, cand-nc / cand-mto the same plus `-frontier=on` (the no-flag binary is main, §2.1). Limits tier1-3 1800 s, tier4 5000 s; timeouts count as the limit. 8 pinned cores (116-123; our other 52 cores ran Tier 5 at the same time); the four arms of a (code, seed) ran side by side. Another session used cores 0-59 and another user's ~33 unpinned jobs ran throughout. 260 runs, 15:20-19:32 CST.

### Seed panel: per cell (wall s, median over seeds 0-4 (range); "T" = timeouts counted as the limit)

| Tier | Code | Mode | main median (range) | cand median (range) | ratio cand/main | cand worst / main best | CPU (utime) median ratio |
|---:|---|---|---|---|---:|---:|---:|
| 1 | BB_108_8_10 | no-card | 0.396 (0.244-0.775) | 0.215 (0.197-0.278) | 0.5429 | 1.14 | 0.46 |
| 1 | BB_108_8_10 | card-mto | 0.992 (0.48-1.266) | 0.217 (0.202-0.285) | 0.2188 | 0.594 | 0.181 |
| 1 | BB_144_12_12 | no-card | 0.723 (0.668-1.274) | 0.327 (0.317-0.378) | 0.4523 | 0.566 | 0.419 |
| 1 | BB_144_12_12 | card-mto | 1.431 (1.268-1.577) | 0.338 (0.316-0.36) | 0.2362 | 0.284 | 0.212 |
| 1 | LP_238_44_6 | no-card | 1.007 (0.785-1.182) | 0.804 (0.734-0.894) | 0.7984 | 1.14 | 0.805 |
| 1 | LP_238_44_6 | card-mto | 1.027 (0.794-1.39) | 0.914 (0.661-0.982) | 0.89 | 1.24 | 0.863 |
| 1 | LP_340_56_8 | no-card | 3.661 (3.253-3.92) | 2.514 (2.193-3.002) | 0.6867 | 0.923 | 0.686 |
| 1 | LP_340_56_8 | card-mto | 3.9 (3.417-4.733) | 2.912 (2.708-3.186) | 0.7467 | 0.932 | 0.754 |
| 2 | BB_144_14_14 | no-card | 81.97 (63.62-90.98) | 21.8 (18.8-43.58) | 0.266 | 0.685 | 0.265 |
| 2 | BB_144_14_14 | card-mto | 76.02 (58.93-89.38) | 25.72 (19.28-44.29) | 0.3383 | 0.752 | 0.338 |
| 2 | LP_442_68_10 | no-card | 50.22 (39.27-87.79) | 24.31 (21.43-32.41) | 0.4841 | 0.825 | 0.484 |
| 2 | LP_442_68_10 | card-mto | 64.3 (44.96-203) | 25.25 (18.71-31.24) | 0.3926 | 0.695 | 0.392 |
| 2 | TN_108_2_12 | no-card | 23.38 (20.91-26.58) | 22.64 (20.54-25.38) | 0.9681 | 1.21 | 0.97 |
| 2 | TN_108_2_12 | card-mto | 28.84 (21.58-29.96) | 25.17 (20.99-26.28) | 0.8728 | 1.22 | 0.873 |
| 3 | BB_288_12_18 | no-card | 964.9 (894.1-1432) | 297.9 (249.6-354.8) | 0.3088 | 0.397 | 0.308 |
| 3 | BB_288_12_18 | card-mto | 1800 (1144-1800, 3T) | 293.6 (283.4-416.4) | 0.1631 | 0.364 | 0.163 |
| 3 | GB_144_12_12 | no-card | 133.1 (111.7-235.5) | 67.68 (19.28-79.15) | 0.5083 | 0.708 | 0.508 |
| 3 | GB_144_12_12 | card-mto | 266.4 (55.1-392.7) | 48.92 (37.01-106.3) | 0.1836 | 1.93 | 0.183 |
| 3 | LP_544_80_12 | no-card | 398.4 (188.8-670) | 85.45 (69.45-102.3) | 0.2145 | 0.542 | 0.214 |
| 3 | LP_544_80_12 | card-mto | 410.4 (231-579.6) | 70.48 (57.62-95.69) | 0.1718 | 0.414 | 0.172 |
| 3 | TN_144_2_13 | no-card | 373.2 (299.2-1111) | 387.9 (258.1-466.1) | 1.039 | 1.56 | 1.04 |
| 3 | TN_144_2_13 | card-mto | 469.4 (234.8-767.5) | 527.4 (377.3-543.9) | 1.123 | 2.32 | 1.12 |
| 3 | TN_200_10_10 | no-card | 29.78 (22.39-138.8) | 45.44 (30.12-51.73) | 1.526 | 2.31 | 1.53 |
| 3 | TN_200_10_10 | card-mto | 22.96 (19.66-51.42) | 29.76 (25.38-267.6) | 1.296 | 13.6 | 1.3 |
| 4 | TN_250_10_15 | no-card | 2934 (2330-5000, 1T) | 4910 (3741-5000, 2T) | 1.673 | 2.15 | 1.67 |
| 4 | TN_250_10_15 | card-mto | 3786 (2380-4296) | 4672 (4447-5000, 2T) | 1.234 | 2.1 | 1.24 |

### Per-tier geomean of seed-median ratios (cand / main) and gate

| Tier | cells per mode | geomean no-card | geomean card-mto | max cell ratio | cells > 1 | cells > 1.25 | gate (geomean < 1 per mode, no cell > 1.25) |
|---:|---:|---:|---:|---:|---:|---:|---|
| 1 | 4 | 0.6057 | 0.4305 | 0.89 | 0 | 0 | PASS |
| 2 | 3 | 0.4995 | 0.4876 | 0.9681 | 0 | 0 | PASS |
| 3 | 5 | 0.5565 | 0.3758 | 1.526 | 4 | 2 | FAIL |
| 4 | 1 | 1.673 | 1.234 | 1.673 | 2 | 1 | FAIL |

Cells with ratio > 1: T3 TN_144_2_13 no-card 1.039, T3 TN_144_2_13 card-mto 1.123, T3 TN_200_10_10 no-card 1.526, T3 TN_200_10_10 card-mto 1.296, T4 TN_250_10_15 no-card 1.673, T4 TN_250_10_15 card-mto 1.234.

Correctness: 252 correct answers, 0 wrong answers or bound violations, 8 timeouts without an answer: TN_250 main-nc s1, cand-nc s0/s3, cand-mto s3/s4 (final lb 9, ub 15), BB_288 main-mto s1/s2/s4 (lb 17, ub 18; censored main, so that cell's ratio overstates the candidate's share). Max RSS 139 MB. CPU-time ratios equal the wall ratios (last column), so the TN regression is not a contention artefact.

## 4. Tier 5 (yfclab2, 6 h, default seed)

`S1/runner/s1_tier5.py`: the 26 tier5 codes x {no-card, card-mto} with `-frontier=on`, 52 runs at once on cores 64-115, `-cpu-lim=21600`, quiet mode (timestamped live `c d_lb` / `c d_ub` lines), 15:20-21:20 CST. Main = the recorded 398054e run (`optimization/baselines/SERVER.md` on main; the tier5 stems on abd1770 carry the confirmed values); CC = GH-124 S1 (`-engine=cc`, one run per code, old stem names matched on family_n_k). The candidate shared the host with its own 8-core panel, the other session (cores 0-59) and another user's jobs; main's recorded run shared it with its own tier0-4 runs. Note: the MaxSAT path prints `c d_ub: -` at a timeout ("no upper bound"); the runner (written for CC, where `-` withdraws a bound) stored `final_lb/final_ub = None` for those runs, so `analyze_gh129.py` recomputes the final bounds from the events.

### Tier 5 table (candidate -frontier=on, default seed, 21600 s) vs main 398054e (SERVER.md) and the CC engine (GH-124 S1)

| Code | Mode | cand result (time) | cand final lb / ub | cand lb events (value@s, last 6) | cand ub events (value@s, last 4) | main: result, lb/ub, wall | CC: result, lb/ub, wall | cand lb vs main | cand ub vs main | check |
|---|---|---|---|---|---|---|---|---|---|---|
| BB_1080_4_ge17 | card-mto | TIMEOUT | 17 / - | 2@0, 3@0, 5@0, 9@1, 17@2889 |  | TIMEOUT, 17/-, 21600 | TIMEOUT, 27/66, 21600 | = | = | ok |
| BB_1080_4_ge17 | no-card | TIMEOUT | 17 / - | 2@0, 3@0, 5@0, 9@1, 17@3101 |  | TIMEOUT, 17/-, 21600 | TIMEOUT, 27/66, 21600 | = | = | ok |
| BB_360_12_24 | card-mto | TIMEOUT | 17 / 24 | 2@0, 3@0, 5@0, 9@0, 17@86 | 30@86, 28@94, 26@200, 24@1204 | TIMEOUT, 17/24, 21600 | d=24 @ 1706 s, 24/24, 1706 | = | = | ok |
| BB_360_12_24 | no-card | TIMEOUT | 17 / 24 | 2@0, 3@0, 5@0, 9@0, 17@83 | 30@83, 28@92, 26@309, 24@479 | TIMEOUT, 17/24, 21600 | d=24 @ 1706 s, 24/24, 1706 | = | = | ok |
| BB_756_16_ge17 | card-mto | TIMEOUT | 17 / - | 2@0, 3@0, 5@0, 9@1, 17@741 |  | TIMEOUT, 17/-, 21600 | TIMEOUT, 27/52, 21600 | = | = | ok |
| BB_756_16_ge17 | no-card | TIMEOUT | 17 / - | 2@0, 3@0, 5@0, 9@0, 17@894 |  | TIMEOUT, 17/-, 21600 | TIMEOUT, 27/52, 21600 | = | = | ok |
| BB_864_4_ge17 | card-mto | TIMEOUT | 17 / - | 2@0, 3@0, 5@0, 9@0, 17@1100 |  | TIMEOUT, 17/-, 21600 | TIMEOUT, 27/108, 21600 | = | = | ok |
| BB_864_4_ge17 | no-card | TIMEOUT | 17 / - | 2@0, 3@0, 5@0, 9@0, 17@944 |  | TIMEOUT, 17/-, 21600 | TIMEOUT, 27/108, 21600 | = | = | ok |
| LP_1020_136_16 | card-mto | d=16 @ 4511 s | 16 / 16 | 2@1, 3@1, 5@3, 9@9, 16@4511 | 16@40 | solved, 16/16, 8328 | d=16 @ 2 s, 16/16, 2 | = | = | ok |
| LP_1020_136_16 | no-card | d=16 @ 3055 s | 16 / 16 | 2@1, 3@2, 5@4, 9@19, 16@3055 | 16@71 | solved, 16/16, 7159 | d=16 @ 2 s, 16/16, 2 | = | = | ok |
| LP_1054_140_20 | card-mto | TIMEOUT | 17 / 32 | 2@1, 3@2, 5@4, 9@13, 17@11049 | 32@11358 | TIMEOUT, 17/-, 21600 | d=20 @ 123 s, 20/20, 123 | = | new | ok |
| LP_1054_140_20 | no-card | TIMEOUT | 17 / 32 | 2@1, 3@2, 5@3, 9@18, 17@10939 | 32@11380 | TIMEOUT, 17/-, 21600 | d=20 @ 123 s, 20/20, 123 | = | new | ok |
| LP_1428_184_24 | card-mto | TIMEOUT | 17 / 32 | 2@1, 3@4, 5@7, 9@16, 17@12086 | 32@21533 | TIMEOUT, 17/-, 21600 | d=24 @ 2884 s, 24/24, 2884 | = | new | ok |
| LP_1428_184_24 | no-card | TIMEOUT | 17 / - | 2@1, 3@3, 5@5, 9@14, 17@13321 |  | TIMEOUT, 17/-, 21600 | d=24 @ 2884 s, 24/24, 2884 | = | = | ok |
| LP_1768_224_22 | card-mto | TIMEOUT | 17 / - | 2@6, 3@12, 5@21, 9@62, 17@16962 |  | TIMEOUT, 9/-, 21600 | d=22 @ 327 s, 22/22, 327 | > | = | ok |
| LP_1768_224_22 | no-card | TIMEOUT | 17 / - | 2@8, 3@17, 5@33, 9@88, 17@18222 |  | TIMEOUT, 9/-, 21600 | d=22 @ 327 s, 22/22, 327 | > | = | ok |
| LP_714_100_16 | card-mto | d=16 @ 3348 s | 16 / 16 | 2@0, 3@1, 5@1, 9@6, 16@3348 | 16@21 | solved, 16/16, 5321 | d=16 @ 2 s, 16/16, 2 | = | = | ok |
| LP_714_100_16 | no-card | d=16 @ 4200 s | 16 / 16 | 2@0, 3@1, 5@2, 9@8, 16@4200 | 16@28 | solved, 16/16, 8752 | d=16 @ 2 s, 16/16, 2 | = | = | ok |
| TN_180_2_17 | card-mto | TIMEOUT | 9 / - | 2@0, 3@0, 5@0, 9@2 |  | TIMEOUT, 17/19, 21600 | d=17 @ 257 s, 17/17, 257 | < | missing | ok |
| TN_180_2_17 | no-card | TIMEOUT | 9 / - | 2@0, 3@0, 5@0, 9@1 |  | solved, 17/17, 9837 | d=17 @ 257 s, 17/17, 257 | < | missing | ok |
| TN_216_4_18 | card-mto | TIMEOUT | 17 / 24 | 2@0, 3@0, 5@0, 9@2, 17@19084 | 32@19348, 24@19348 | solved, 18/18, 18346 | d=18 @ 696 s, 18/18, 696 | < | > | ok |
| TN_216_4_18 | no-card | TIMEOUT | 9 / - | 2@0, 3@0, 5@0, 9@2 |  | solved, 18/18, 16802 | d=18 @ 696 s, 18/18, 696 | < | missing | ok |
| TN_252_2_21 | card-mto | TIMEOUT | 17 / - | 2@0, 3@0, 5@0, 9@2, 17@12404 |  | TIMEOUT, 17/-, 21600 | TIMEOUT, 21/28, 21600 | = | = | ok |
| TN_252_2_21 | no-card | TIMEOUT | 17 / 28 | 2@0, 3@0, 5@0, 9@2, 17@16351 | 28@16351 | TIMEOUT, 17/28, 21600 | TIMEOUT, 21/28, 21600 | = | = | ok |
| TN_288_2_ge9 | card-mto | TIMEOUT | 9 / - | 2@0, 3@0, 5@1, 9@8 |  | TIMEOUT, 9/-, 21600 | TIMEOUT, 20/32, 21600 | = | = | ok |
| TN_288_2_ge9 | no-card | TIMEOUT | 9 / - | 2@0, 3@0, 5@1, 9@10 |  | TIMEOUT, 9/-, 21600 | TIMEOUT, 20/32, 21600 | = | = | ok |
| TN_324_4_ge9 | card-mto | TIMEOUT | 9 / - | 2@0, 3@0, 5@2, 9@9 |  | TIMEOUT, 9/-, 21600 | TIMEOUT, 20/36, 21600 | = | = | ok |
| TN_324_4_ge9 | no-card | TIMEOUT | 9 / - | 2@0, 3@0, 5@2, 9@10 |  | TIMEOUT, 9/-, 21600 | TIMEOUT, 20/36, 21600 | = | = | ok |
| TN_360_4_ge17 | card-mto | TIMEOUT | 17 / - | 2@0, 3@0, 5@0, 9@2, 17@8846 |  | TIMEOUT, 17/-, 21600 | TIMEOUT, 22/40, 21600 | = | = | ok |
| TN_360_4_ge17 | no-card | TIMEOUT | 17 / - | 2@0, 3@0, 5@0, 9@4, 17@12230 |  | TIMEOUT, 17/-, 21600 | TIMEOUT, 22/40, 21600 | = | = | ok |
| TN_396_4_ge17 | card-mto | TIMEOUT | 17 / - | 2@0, 3@0, 5@0, 9@2, 17@11939 |  | TIMEOUT, 17/-, 21600 | TIMEOUT, 22/44, 21600 | = | = | ok |
| TN_396_4_ge17 | no-card | TIMEOUT | 17 / - | 2@0, 3@0, 5@0, 9@3, 17@12832 |  | TIMEOUT, 17/-, 21600 | TIMEOUT, 22/44, 21600 | = | = | ok |
| TN_432_8_ge9 | card-mto | TIMEOUT | 9 / - | 2@0, 3@0, 5@3, 9@25 |  | TIMEOUT, 9/-, 21600 | TIMEOUT, 21/36, 21600 | = | = | ok |
| TN_432_8_ge9 | no-card | TIMEOUT | 9 / - | 2@0, 3@0, 5@3, 9@18 |  | TIMEOUT, 9/-, 21600 | TIMEOUT, 21/36, 21600 | = | = | ok |
| TN_468_4_ge17 | card-mto | TIMEOUT | 17 / - | 2@0, 3@0, 5@0, 9@3, 17@14070 |  | TIMEOUT, 17/-, 21600 | TIMEOUT, 22/52, 21600 | = | = | ok |
| TN_468_4_ge17 | no-card | TIMEOUT | 17 / - | 2@0, 3@0, 5@0, 9@4, 17@11323 |  | TIMEOUT, 17/-, 21600 | TIMEOUT, 22/52, 21600 | = | = | ok |
| TN_496_2_ge17 | card-mto | TIMEOUT | 17 / - | 2@0, 3@0, 5@0, 9@2, 17@15646 |  | TIMEOUT, 17/-, 21600 | TIMEOUT, 22/64, 21600 | = | = | ok |
| TN_496_2_ge17 | no-card | TIMEOUT | 17 / - | 2@0, 3@0, 5@0, 9@1, 17@17876 |  | TIMEOUT, 17/-, 21600 | TIMEOUT, 22/64, 21600 | = | = | ok |
| TN_504_2_ge17 | card-mto | TIMEOUT | 17 / - | 2@0, 3@0, 5@1, 9@4, 17@4166 |  | TIMEOUT, 17/-, 21600 | TIMEOUT, 23/56, 21600 | = | = | ok |
| TN_504_2_ge17 | no-card | TIMEOUT | 17 / - | 2@0, 3@0, 5@0, 9@3, 17@5434 |  | TIMEOUT, 17/-, 21600 | TIMEOUT, 23/56, 21600 | = | = | ok |
| TN_540_4_ge9 | card-mto | TIMEOUT | 9 / - | 2@0, 3@0, 5@6, 9@26 |  | TIMEOUT, 9/-, 21600 | TIMEOUT, 21/50, 21600 | = | = | ok |
| TN_540_4_ge9 | no-card | TIMEOUT | 9 / - | 2@0, 3@0, 5@6, 9@48 |  | TIMEOUT, 9/-, 21600 | TIMEOUT, 21/50, 21600 | = | = | ok |
| TN_576_2_ge9 | card-mto | TIMEOUT | 9 / - | 2@0, 3@0, 5@7, 9@38 |  | TIMEOUT, 9/-, 21600 | TIMEOUT, 22/64, 21600 | = | = | ok |
| TN_576_2_ge9 | no-card | TIMEOUT | 9 / - | 2@0, 3@0, 5@2, 9@34 |  | TIMEOUT, 9/-, 21600 | TIMEOUT, 22/64, 21600 | = | = | ok |
| TN_612_2_ge17 | card-mto | TIMEOUT | 17 / - | 2@0, 3@0, 5@1, 9@4, 17@4325 |  | TIMEOUT, 17/-, 21600 | TIMEOUT, 24/68, 21600 | = | = | ok |
| TN_612_2_ge17 | no-card | TIMEOUT | 17 / - | 2@0, 3@0, 5@1, 9@6, 17@4293 |  | TIMEOUT, 17/-, 21600 | TIMEOUT, 24/68, 21600 | = | = | ok |
| TN_648_10_9to52 | card-mto | TIMEOUT | 9 / - | 2@0, 3@0, 5@8, 9@96 |  | TIMEOUT, 9/-, 21600 | TIMEOUT, 21/52, 21600 | = | = | ok |
| TN_648_10_9to52 | no-card | TIMEOUT | 9 / - | 2@0, 3@0, 5@10, 9@62 |  | TIMEOUT, 9/-, 21600 | TIMEOUT, 21/52, 21600 | = | = | ok |
| TN_648_14_ge9 | card-mto | TIMEOUT | 9 / - | 2@0, 3@0, 5@9, 9@59 |  | TIMEOUT, 9/-, 21600 | TIMEOUT, 21/54, 21600 | = | = | ok |
| TN_648_14_ge9 | no-card | TIMEOUT | 9 / - | 2@0, 3@1, 5@18, 9@72 |  | TIMEOUT, 9/-, 21600 | TIMEOUT, 21/54, 21600 | = | = | ok |
| TN_684_2_ge9 | card-mto | TIMEOUT | 9 / - | 2@0, 3@0, 5@1, 9@5 |  | TIMEOUT, 9/-, 21600 | TIMEOUT, 22/57, 21600 | = | = | ok |
| TN_684_2_ge9 | no-card | TIMEOUT | 9 / - | 2@0, 3@0, 5@1, 9@4 |  | TIMEOUT, 9/-, 21600 | TIMEOUT, 22/57, 21600 | = | = | ok |

Solved cells: cand 4 of 52, main 7 of 52, CC 16 of 52 (one CC run per code covers both mode cells).
Cells where cand is worse than main (lower lb, higher/missing ub, or unsolved where main solved): ['TN_180_2_17 card-mto', 'TN_180_2_17 no-card', 'TN_216_4_18 card-mto', 'TN_216_4_18 no-card'].
Cells where cand is better than main: 5 (LP_1054_140_20 card-mto, LP_1054_140_20 no-card, LP_1428_184_24 card-mto, LP_1768_224_22 card-mto, LP_1768_224_22 no-card).
Science problems: 0.

### Time to reach the final lower bound of main (cells where both reach the same lb >= 16), cand / main

| Code | Mode | lb | cand s | main s | ratio |
|---|---|---:|---:|---:|---:|
| BB_1080_4_ge17 | card-mto | 17 | 2889 | 2422 | 1.19 |
| BB_1080_4_ge17 | no-card | 17 | 3101 | 2423 | 1.28 |
| BB_360_12_24 | card-mto | 17 | 86 | 168 | 0.51 |
| BB_360_12_24 | no-card | 17 | 83 | 206 | 0.40 |
| BB_756_16_ge17 | card-mto | 17 | 741 | 846 | 0.88 |
| BB_756_16_ge17 | no-card | 17 | 894 | 844 | 1.06 |
| BB_864_4_ge17 | card-mto | 17 | 1100 | 1175 | 0.94 |
| BB_864_4_ge17 | no-card | 17 | 944 | 1176 | 0.80 |
| LP_1020_136_16 | card-mto | 16 | 4511 | 8328 | 0.54 |
| LP_1020_136_16 | no-card | 16 | 3055 | 7159 | 0.43 |
| LP_1054_140_20 | card-mto | 17 | 11049 | 16386 | 0.67 |
| LP_1054_140_20 | no-card | 17 | 10939 | 16379 | 0.67 |
| LP_1428_184_24 | card-mto | 17 | 12086 | 15997 | 0.76 |
| LP_1428_184_24 | no-card | 17 | 13321 | 19868 | 0.67 |
| LP_714_100_16 | card-mto | 16 | 3348 | 5321 | 0.63 |
| LP_714_100_16 | no-card | 16 | 4200 | 8751 | 0.48 |
| TN_252_2_21 | card-mto | 17 | 12404 | 8034 | 1.54 |
| TN_252_2_21 | no-card | 17 | 16351 | 8660 | 1.89 |
| TN_360_4_ge17 | card-mto | 17 | 8846 | 5154 | 1.72 |
| TN_360_4_ge17 | no-card | 17 | 12230 | 5403 | 2.26 |
| TN_396_4_ge17 | card-mto | 17 | 11939 | 4588 | 2.60 |
| TN_396_4_ge17 | no-card | 17 | 12832 | 4468 | 2.87 |
| TN_468_4_ge17 | card-mto | 17 | 14070 | 9988 | 1.41 |
| TN_468_4_ge17 | no-card | 17 | 11323 | 8437 | 1.34 |
| TN_496_2_ge17 | card-mto | 17 | 15646 | 11092 | 1.41 |
| TN_496_2_ge17 | no-card | 17 | 17876 | 9969 | 1.79 |
| TN_504_2_ge17 | card-mto | 17 | 4166 | 4866 | 0.86 |
| TN_504_2_ge17 | no-card | 17 | 5434 | 4919 | 1.10 |
| TN_612_2_ge17 | card-mto | 17 | 4325 | 4182 | 1.03 |
| TN_612_2_ge17 | no-card | 17 | 4293 | 4293 | 1.00 |

Geomean 1.011 over 30 cells.

## 5. Mac tier0-2 quick check (default seed)

`S1/runner/mac_serial.py` (one process at a time, `caffeinate -i -s`, 2 GB cap): `-frontier=on` 3 runs per cell plus 1 drift sample of frozen main abd1770, against the recorded Mac main table (`optimization/baselines/README.md`, 398054e). Full table: `S1/mac/summary.md`.

| Tier | geomean no-card | geomean card-mto | max cell |
|---:|---:|---:|---:|
| 0 | 0.827 | 0.884 | 0.994 |
| 1 | 0.497 | 0.436 | 0.878 |
| 2 | 0.408 | 0.453 | 0.854 |

All 102 candidate answers correct; the main drift samples are -3 %..+8 % from the recorded medians on tier1-2 (host slightly slower today), so the ratios are, if anything, conservative. This filter has no TN code above tier 2 (TN_108_2_12 0.85 / 0.81), so it could not show the TN tier3/4 regression.

## 6. Gate verdicts

| Tier | Rule | Evidence | Verdict |
|---|---|---|---|
| 0 | correctness, no severe slowdown | identity 28/28 (Mac) and 28/28 (server); every tier0 answer right in S0 (with the state check), the Mac quick check and the random sets; slowest tier0 run 0.34 s | **PASS** (the QDistSAT cross-repo CI check was not run in this round) |
| 1 | geomean < 1 per mode, no cell > 1.25 (seed medians) | 0.606 / 0.431, max cell 0.89 | **PASS** |
| 2 | same | 0.500 / 0.488, max cell 0.97 (TN_108_2_12 no-card) | **PASS** |
| 3 | same | 0.557 / 0.376, but TN_200_10_10 1.526 / 1.296 (> 1.25) and TN_144_2_13 1.039 / 1.123 | **FAIL** |
| 4 | same | TN_250_10_15 1.673 / 1.234 | **FAIL** |
| 5 | bounds and solved cells vs main (informational, Tier 3/4 failed) | 4 solved cells vs main 7; worse than main on TN_180_2_17 and TN_216_4_18 (both modes); better on LP_1054 / LP_1428 card-mto (new ub 32) and LP_1768 (lb 17 vs 9); LP_714 / LP_1020 solved 1.6-2.3x sooner | **FAIL** |

The TN regression is reproducible (all four TN tier3/4 cells above 1 over 5 seeds, CPU ratios equal to wall ratios), so by policy the candidate is rejected as a default. The BB/GB/LP gains are large and reproducible: every BB/GB/LP cell of tiers 1-3 is below 0.9 (BB_288_12_18 0.31 / 0.16, LP_544_80_12 0.21 / 0.17, GB_144_12_12 0.51 / 0.18, BB_144_14_14 0.27 / 0.34).

## 7. Recommendation and lessons

1. **Do not adopt `-frontier=on` as the default.** Keep the flag (default off, byte-identical to main) on the branch for follow-ups.
2. **What the rule does well:** finding solutions. In every family the feasibility probes that end in FOUND need 2-4x fewer conflicts; on BB/GB/LP the rule also shortens refutations, which gives 3-6x on tier2-3 and the faster LP_714 / LP_1020 solves and new LP upper bounds in Tier 5.
3. **What it does badly:** TN refutations. Conflicts fall slightly but each conflict costs more lookahead work, and on TN codes the refutation probes (NONE at d-1, the proof part of the last optimize probe) dominate, so TN tier3-5 get 1.0-2.9x slower.
4. **Next round (candidates, not tried here):**
   - a probe-level policy: the rule in FOUND-type work only. `presol` (rule until the probe's first solution) fixed TN_250 on the Mac (950 s vs main 1096 s vs on 1337 s) but cost BB 2.5-3.4x of the `on` gain; a better split is to switch the rule off in probes whose cap is below the best known logical of the *other* half or at d-1 (refutation-expected probes), keeping it in phase-1 doubling probes above the global lower bound;
   - a per-half selector from structure (it won on all 18 BB/GB/LP cells and lost on all 4 TN cells of tiers 1-4; TN halves have weight-2 qubit columns / tree-like Tanner graphs), to be preregistered and tested on the TN panel cells first;
   - combine with GH-128's removal of the re-find in optimize probes (the rule makes the re-find cheap but it is still repeated work).
5. The CC engine (GH-124) remains the stronger route for the hard sets (Tier 5: CC 16 solved cells, candidate 4, main 7); step 3 of the plan (packing propagator with explanations) targets the refutation side that this round did not improve on TN.

## 8. Files

All paths relative to `optimization/experiments/GH-129/`.

- `S0/identity_mac_vs_main_abd1770.txt`, `S0/counts_tier0_2.md`, `S0/counts_tier3.md`; `S0/tools/` (`macrun.py` Mac runner with the 2 GB cap, `tsrun.py` timestamped runner, `sum_counts.py`, `gen_random_codes.py`, `gen_random_codes2.py`); `S0/raw/*.tar.gz` (every S0 log: ident, ident2, chk, cnt, t3 incl. presol and the TN_250 timelines, rnd, rnd2, and the 96 random codes).
- `S1/runner/` (`s1_panel.py`, `s1_tier5.py`, `analyze_gh129.py`, `mac_serial.py`, `analyze_macq.py`); `S1/server/panel/` (`results.jsonl`, `config.json`, `logs.tar.gz`, `RUNNER_DONE`), `S1/server/panel.out`, `S1/server/ident_server.tar.gz`; `S1/server/tier5/` (`results.json`, 52 timestamped logs, `RUNNER_DONE`), `S1/server/tier5.out`; `S1/server/summary.md` (full output of `analyze_gh129.py`); `S1/mac/` (`summary.md`, `results.tsv`, `jobs.jsonl`, `logs.tar.gz`).
- Server originals: `yfclab2:~/mac-agent-20261009/gh129-s1/`, worktree `~/mac-agent-20261009/gh129-d1f3f41`, binary `~/mac-agent-20261009/frozen/server-gh129-d1f3f41/`. Nothing is left running on either host.

Reproduce the server summary (from this directory):

```
python3 S1/runner/analyze_gh129.py S1/server/panel/results.jsonl S1/server/tier5/results.json \
    ../../baselines/SERVER.md ../GH-124/S1/server/tier5/results.json
```

## Completion report

- **What changed:** `-frontier=off|on|postsol|presol` (+ `-frontier-stats`, `-frontier-check`) in MaxCDCL and the driver (d1f3f41); this report, runners and raw data.
- **Validation:** default-path identity (Mac + server), S0 correctness and work counts (tier0-3, 96 random codes vs CC), S1 seed panel (260 runs), Tier 5 (52 runs, 6 h), Mac quick check (136 runs).
- **Result:** Tier 0-2 PASS, Tier 3 FAIL, Tier 4 FAIL (TN family), Tier 5 worse than main on TN_180 / TN_216. Not adopted.
- **Scientific semantics changed:** no (decision order only; no answer or bound differed from the stems in any run).
- **PI action required:** none for adoption; decide whether a TN-aware variant (§7.4) is worth a follow-up round.
