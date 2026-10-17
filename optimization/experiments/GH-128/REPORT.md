# GH-128: skip probes that cannot change d once lb reaches ub (`-p1skip`)

Issue #128 (hub #15), branch `experiment/gh-128-phase1-redundancy` from main abd1770. MaxCDCL (`src/solver`) and
`src/cc` untouched. Judging: docs/OPTIMIZATION_LOOP_POLICY.md. Prior record: GH-127 S1_REPORT.md section 5.3 (the
Phase 1 finding this round implements).

## 0. Summary

- **Change.** `-p1skip=on|off`. With `on`, Phase 1 of `min_distance_css_interleaved` skips a half's feasibility probe
  when that half's proven lb (own, or shared through GH-107) is already >= the global UB, and the search stops as soon
  as every half has lb >= UB (global lb = UB), reporting d with the usual output lines. Phase 2a/2b already had both
  properties (`h.lb >= U` guards; nothing added there). Evaluated with default `off` (= main); after the evaluation
  the branch default is `on` (commit after the S1 data, section 6). Soundness: section 1 and MODIFICATIONS.md.
- **Where it can trigger on main's search.** Main's Phase 1 probes both halves at the same doubling caps, so when the
  second half is probed both halves have lb = m/2 + 1. The skip fires only when the first half's cap-m feasibility
  probe returns a logical of weight exactly m/2 + 1, i.e. **d in {2, 3, 5, 9, 17, 33, ...} and the first solution found
  is already optimal**; it then always coincides with "global lb = UB" and saves exactly one probe (the other half's
  cap-m probe). No tier1-4 code has such a d (6, 8, 10, 10, 12, 12, 12, 13, 14, 15, 18), so on Tier 1-4 the search is
  identical for every seed; the runs confirm it (section 3).
- **Observed triggers.** Only tier0: LP_34_20_2 (both modes; Z cap-2 probe skipped) and TN_36_8_3 card-mto (Z cap-4
  probe skipped), on the Mac and on yfclab2, each saving one tiny probe. **Tier 5: none** (48/52 cells print exactly
  main's recorded sequence of `c trying d` / bound lines; the other 4 are the same sequence cut off earlier by the 6 h
  limit on a slower host).
- **The GH-127 TN_180_2_17 card-mto situation does not arise on main's path.** It came from the unit ladder (cap =
  lb + 1, so U usually equals the other half's lb). With main's doubling caps TN_180 card-mto finds ub 19 at cap 32
  while lb is 17 (identical to main's record, both runs end at lb 17 / ub 19), and TN_180 no-card proves d = 17 in Phase
  2, not by a lb = ub meeting in Phase 1. A cheap reproduction is therefore impossible on this branch (GH-127's ladder
  is not in main); the effect is shown on the tier0 trigger cells instead.
- **Correctness: clean.** Every answer equals the stem distance (Mac 102 runs, server 232 tier0-4 runs, 52 Tier 5
  runs); lb sequences never decrease and ub sequences never increase; no memory-cap hit. `-p1skip=off` reproduces
  main's search fingerprint (probe sequence plus per-half conflict totals) in 62/62 compared cells (Mac tier0-2 vs
  frozen main abd1770 34/34; server tier0-1 vs main 398054e 28/28). The default-on build equals the evaluated
  `-p1skip=on` fingerprint and answer on tier0-1 x both modes (28/28, Mac).
- **Gates.** Tier 0 PASS. Tier 1-4 PASS as neutral: the skip never triggers and on/off fingerprints are identical in
  every compared run (tier1-2: 5 seeds x 2 modes, 70/70; tier3-4: default seed, 12/12), so every seed-median ratio is
  1.000 by construction. Measured wall ratios of these identical searches on the loaded server range 0.67-1.57
  (section 3.3): that is the host noise floor, not an effect. Tier 5 NEUTRAL: same trajectories as main; 6 of main's
  7 solved cells solved (TN_216_4_18 card-mto lost to host drift: the host was 1.31x slower in geomean than during
  main's record on identical trajectories, and main itself needed 18346 s of the 21600 s limit); no new solve, no
  higher bound.
- **Recommendation: keep it, default on (branch now defaults to on), low priority for adoption.** It is sound, can
  only remove probes, and is free when it does not trigger, but on main's doubling search it changes nothing measurable
  outside two tier0 codes. Its real value is as a prerequisite for any finer lb schedule (unit/adaptive ladder), where
  GH-127 measured 130-2400 s of redundant probing per solved Tier 5 cell. Merge into main only with the PI's
  agreement (policy: neutral rounds are not automatic adoptions).

## 1. Change and soundness

`src/core/distqldpc.cc`, `min_distance_css_interleaved`, Phase 1 only:

```
if (g_p1skip && U != INF && h.lb >= U) { p1skips++; /* -v: c p1skip: X|Z half cap m skipped (lb L >= UB U) */ continue; }
...
if (g_p1skip && css_bounds_meet(hs, U)) met = true;   /* every existing half has lb >= U: d = U, -v line */
```

U is the weight of a logical found by an earlier probe, so U >= d = min(dX, dZ). A half H with lb(H) >= U has no
logical of weight < U: a FOUND on H would return weight >= U (U unchanged) and a NONE would only raise lb(H), while
d = min(U, d of the other half) is unchanged either way. When every half has lb >= U, min(dX, dZ) >= U >= d, so d = U
is already proven, and Phase 2a/2b issue no probe because their existing `h.lb >= U` guards finish every half. Only
probes are removed; no probe kind, cap or bound is added, and every remaining probe runs on a fresh solver with the
same inputs (per-instance solver state since GH-73), so the search up to the skip point is identical. A skipped half
keeps ub = INF instead of its probe's FOUND weight; this would only affect Phase 2's tie/ordering, which on main's path
is never reached with a probe (the skip always coincides with global lb = U). Reported bounds are the values main
reports (the skipped probe could only have produced hidden or already known bounds). The `-dualshare-stats` line
gets a `p1skips` field and `-v` prints `c p1skip:` lines only when the flag is on, so `-p1skip=off` prints main's
output byte for byte.

Development note: the first S0 commit (c84c891) also had explicit early breaks in Phase 2a/2b. They never changed the
search but bypassed GH-107's `-v` "NONE implied" accounting lines (seen on BB_144_14_14 in the first Mac pass, which
was discarded). They were removed in 2498e1d, the evaluated tier0-4 binary. The Tier 5 run uses c84c891, whose
quiet-mode behaviour is identical to 2498e1d (the removed breaks only replaced `done[k] = true` marking of halves the
guards finish without a probe, and the `-v`/stats counter), and the Tier 5 sequences match main line for line anyway.

## 2. Setup

- Mac (Apple M6, 12 CPUs): `make CXX="c++ -Wno-reserved-user-defined-literal"`; candidate frozen as
  `frozen128/distqldpc` (2498e1d, sha256 `bc9be3d088389e0506d8f8a971892125d3c2542981db3727ef018c5655a6fc94`);
  main = `frozen-main-abd1770/distqldpc` (sha256 `d5ea725340b7ab4cc1cb041e1a57efc73c17442a35ba6c3b967f6ef0a083c239`).
  tier0-2 x both modes x {main, off, on}, default seed, serial, `caffeinate -i -s`, 2 GB RSS watchdog, limit 600 s
  (`runner/s128_runs.py --cpus serial`, 102 runs). No sleep events in `pmset -g log`.
- yfclab2 (2 x EPYC 7742): worktrees `~/mac-agent-20261009/gh128-2498e1d` and `gh128-c84c891`, repository Makefile
  (g++ -O3), frozen as `frozen/server-gh128-2498e1d/distqldpc` (sha256
  `0a063d2fab8c8ed51bdc69955e5bc7a693e1d3642792e325ac8bc2613a243fc4`) and `frozen/server-gh128-c84c891/distqldpc`
  (sha256 `0ac7b07804b6af2a8945f81a1455b98af729b2bed93cf7abada8e53c9741562d`); main = `frozen/server-main398`
  (sha256 `9bf55806b61938d35eeabb03a32de751c4082aa341b66492d733f3c6abb47cf3`, abd1770's MaxSAT path). Every process
  `taskset -c CORE prlimit --as=4294967296 --`, one per core, cores 0-59 only (another session used 64-123; another
  user ran unpinned jobs throughout, load 95-150).
  - tier0-4 (`runner/s128_runs.py --cpus 52-59`, `server/server_jobs.jsonl`): every tier0-4 code x both modes x
    {off, on} with `-v -dualshare-stats`, default seed, limits tier0 600 s, tier1-3 1800 s, tier4 5000 s; main for
    tier0-1; seeds 1-4 (`-seed=S`) x {off, on} for tier1 and tier2. 232 runs, 15:22-16:33 CST (server clock).
  - Tier 5 (`runner/s128_tier5.py --cpus 0-51 --flags=-p1skip=on`): every tier5 code x both modes, default seed,
    `-cpu-lim=21600`, quiet output with timestamped lines, 15:15-21:15 CST. Main = the recorded 398054e run
    (`optimization/baselines/SERVER.md`, 1 run per cell, 2026-10-14; its stems already carry the renamed names
    BB_360_12_24, TN_252_2_21, LP_1054_140_20, LP_1428_184_24, LP_1768_224_22; its raw logs, used for the sequence
    comparison, still have the old file names and are matched on family_n_k).
  - Nothing is left running (checked after the driver's ALL_DONE at 21:15:07).
- Search fingerprint = sha256 of every `c CSS interleave:` probe line (half, cap, lb, kind, result, weight) plus the
  `c dualshare stats` line without the `p1skips` field (probe count and conflict total per half). Equal fingerprints
  mean the same probe sequence with the same conflict counts.

## 3. Tier 0-4

### 3.1 Where the skip triggers (server, default seed)

| Tier | Code | Mode | d | off s | on s | on/off | fingerprint on = off | off = main | p1skip lines (on) | checks |
|---:|---|---|---:|---:|---:|---:|---|---|---|---|
| 0 | BB_72_12_6 | card-mto | 6 | 0.10 | 0.10 | 1.000 | yes | yes | - | ok |
| 0 | BB_72_12_6 | no-card | 6 | 0.10 | 0.10 | 1.000 | yes | yes | - | ok |
| 0 | BB_90_8_10 | card-mto | 10 | 0.30 | 0.35 | 1.164 | yes | yes | - | ok |
| 0 | BB_90_8_10 | no-card | 10 | 0.35 | 0.36 | 1.003 | yes | yes | - | ok |
| 0 | GB_144_12_8 | card-mto | 8 | 0.26 | 0.25 | 0.996 | yes | yes | - | ok |
| 0 | GB_144_12_8 | no-card | 8 | 0.25 | 0.25 | 1.000 | yes | yes | - | ok |
| 0 | LP_136_32_4 | card-mto | 4 | 0.26 | 0.26 | 1.000 | yes | yes | - | ok |
| 0 | LP_136_32_4 | no-card | 4 | 0.30 | 0.26 | 0.836 | yes | yes | - | ok |
| 0 | LP_34_20_2 | card-mto | 2 | 0.05 | 0.05 | 1.000 | no (skip) | yes | Z half cap 2 skipped (lb 2 >= UB 2); global lb 2 = UB 2 after Phase 1: d determined, no further probe | ok |
| 0 | LP_34_20_2 | no-card | 2 | 0.05 | 0.05 | 1.000 | no (skip) | yes | Z half cap 2 skipped (lb 2 >= UB 2); global lb 2 = UB 2 after Phase 1: d determined, no further probe | ok |
| 0 | TN_36_8_3 | card-mto | 3 | 0.05 | 0.05 | 1.000 | no (skip) | yes | Z half cap 4 skipped (lb 3 >= UB 3); global lb 3 = UB 3 after Phase 1: d determined, no further probe | ok |
| 0 | TN_36_8_3 | no-card | 3 | 0.05 | 0.05 | 1.019 | yes | yes | - | ok |
| 0 | TN_36_8_4 | card-mto | 4 | 0.05 | 0.05 | 1.000 | yes | yes | - | ok |
| 0 | TN_36_8_4 | no-card | 4 | 0.05 | 0.05 | 0.981 | yes | yes | - | ok |
| 0 | TN_54_11_4 | card-mto | 4 | 0.10 | 0.10 | 1.000 | yes | yes | - | ok |
| 0 | TN_54_11_4 | no-card | 4 | 0.05 | 0.05 | 1.000 | yes | yes | - | ok |
| 0 | TN_72_14_4 | card-mto | 4 | 0.10 | 0.15 | 1.467 | yes | yes | - | ok |
| 0 | TN_72_14_4 | no-card | 4 | 0.10 | 0.10 | 1.000 | yes | yes | - | ok |
| 0 | TN_72_8_8 | card-mto | 8 | 1.26 | 0.91 | 0.721 | yes | yes | - | ok |
| 0 | TN_72_8_8 | no-card | 8 | 0.71 | 0.86 | 1.212 | yes | yes | - | ok |
| 1 | BB_108_8_10 | card-mto | 10 | 1.51 | 1.06 | 0.701 | yes | yes | - | ok |
| 1 | BB_108_8_10 | no-card | 10 | 0.86 | 0.86 | 1.001 | yes | yes | - | ok |
| 1 | BB_144_12_12 | card-mto | 12 | 1.56 | 2.26 | 1.448 | yes | yes | - | ok |
| 1 | BB_144_12_12 | no-card | 12 | 0.76 | 0.71 | 0.934 | yes | yes | - | ok |
| 1 | LP_238_44_6 | card-mto | 6 | 1.66 | 1.16 | 0.698 | yes | yes | - | ok |
| 1 | LP_238_44_6 | no-card | 6 | 1.31 | 1.31 | 0.998 | yes | yes | - | ok |
| 1 | LP_340_56_8 | card-mto | 8 | 4.07 | 4.12 | 1.013 | yes | yes | - | ok |
| 1 | LP_340_56_8 | no-card | 8 | 3.52 | 3.62 | 1.029 | yes | yes | - | ok |
| 2 | BB_144_14_14 | card-mto | 14 | 66.72 | 63.30 | 0.949 | yes | - | - | ok |
| 2 | BB_144_14_14 | no-card | 14 | 76.07 | 131.90 | 1.734 | yes | - | - | ok |
| 2 | LP_442_68_10 | card-mto | 10 | 52.47 | 52.28 | 0.996 | yes | - | - | ok |
| 2 | LP_442_68_10 | no-card | 10 | 45.47 | 45.67 | 1.004 | yes | - | - | ok |
| 2 | TN_108_2_12 | card-mto | 12 | 32.02 | 32.36 | 1.011 | yes | - | - | ok |
| 2 | TN_108_2_12 | no-card | 12 | 26.18 | 26.18 | 1.000 | yes | - | - | ok |
| 3 | BB_288_12_18 | card-mto | 18 | 1197.59 | 1591.66 | 1.329 | yes | - | - | ok |
| 3 | BB_288_12_18 | no-card | 18 | 937.90 | 937.38 | 0.999 | yes | - | - | ok |
| 3 | GB_144_12_12 | card-mto | 12 | 63.06 | 95.69 | 1.517 | yes | - | - | ok |
| 3 | GB_144_12_12 | no-card | 12 | 160.43 | 251.37 | 1.567 | yes | - | - | ok |
| 3 | LP_544_80_12 | card-mto | 12 | 425.18 | 653.16 | 1.536 | yes | - | - | ok |
| 3 | LP_544_80_12 | no-card | 12 | 676.28 | 675.51 | 0.999 | yes | - | - | ok |
| 3 | TN_144_2_13 | card-mto | 13 | 567.97 | 457.47 | 0.805 | yes | - | - | ok |
| 3 | TN_144_2_13 | no-card | 13 | 456.98 | 458.63 | 1.004 | yes | - | - | ok |
| 3 | TN_200_10_10 | card-mto | 10 | 21.12 | 21.64 | 1.025 | yes | - | - | ok |
| 3 | TN_200_10_10 | no-card | 10 | 161.53 | 241.51 | 1.495 | yes | - | - | ok |
| 4 | TN_250_10_15 | card-mto | 15 | 4254.24 | 4182.20 | 0.983 | yes | - | - | ok |
| 4 | TN_250_10_15 | no-card | 15 | 3408.75 | 2395.61 | 0.703 | yes | - | - | ok |

server: 46 cells; fingerprint on = off in 43; off = main in 28/28; skip triggered in 3: LP_34_20_2 card-mto, LP_34_20_2 no-card, TN_36_8_3 card-mto; check failures 0.

### 3.2 Seeds (server): identity and on/off wall ratios

The policy's seed panel is replaced by identity because no tier1-4 cell triggers the skip (as instructed: panel only
where the skip triggers). Tier1-2 were still run with all 5 seeds in both arms to show identity across seeds;
tier3-4 with the default seed. The official seed-median ratio is 1.000 in every tier1-4 cell (identical searches).

| Tier | Code | Mode | seeds run | fingerprint on = off (seeds) | off median s (range) | on median s (range) | ratio on/off |
|---:|---|---|---:|---|---|---|---:|
| 0 | BB_72_12_6 | card-mto | 1 | 1/1 | 0.10 (0.10-0.10) | 0.10 (0.10-0.10) | 1.000 |
| 0 | BB_72_12_6 | no-card | 1 | 1/1 | 0.10 (0.10-0.10) | 0.10 (0.10-0.10) | 1.000 |
| 0 | BB_90_8_10 | card-mto | 1 | 1/1 | 0.30 (0.30-0.30) | 0.35 (0.35-0.35) | 1.164 |
| 0 | BB_90_8_10 | no-card | 1 | 1/1 | 0.35 (0.35-0.35) | 0.36 (0.36-0.36) | 1.003 |
| 0 | GB_144_12_8 | card-mto | 1 | 1/1 | 0.26 (0.26-0.26) | 0.25 (0.25-0.25) | 0.996 |
| 0 | GB_144_12_8 | no-card | 1 | 1/1 | 0.25 (0.25-0.25) | 0.25 (0.25-0.25) | 1.000 |
| 0 | LP_136_32_4 | card-mto | 1 | 1/1 | 0.26 (0.26-0.26) | 0.26 (0.26-0.26) | 1.000 |
| 0 | LP_136_32_4 | no-card | 1 | 1/1 | 0.30 (0.30-0.30) | 0.26 (0.26-0.26) | 0.836 |
| 0 | LP_34_20_2 | card-mto | 1 | 0/1 | 0.05 (0.05-0.05) | 0.05 (0.05-0.05) | 1.000 |
| 0 | LP_34_20_2 | no-card | 1 | 0/1 | 0.05 (0.05-0.05) | 0.05 (0.05-0.05) | 1.000 |
| 0 | TN_36_8_3 | card-mto | 1 | 0/1 | 0.05 (0.05-0.05) | 0.05 (0.05-0.05) | 1.000 |
| 0 | TN_36_8_3 | no-card | 1 | 1/1 | 0.05 (0.05-0.05) | 0.05 (0.05-0.05) | 1.019 |
| 0 | TN_36_8_4 | card-mto | 1 | 1/1 | 0.05 (0.05-0.05) | 0.05 (0.05-0.05) | 1.000 |
| 0 | TN_36_8_4 | no-card | 1 | 1/1 | 0.05 (0.05-0.05) | 0.05 (0.05-0.05) | 0.981 |
| 0 | TN_54_11_4 | card-mto | 1 | 1/1 | 0.10 (0.10-0.10) | 0.10 (0.10-0.10) | 1.000 |
| 0 | TN_54_11_4 | no-card | 1 | 1/1 | 0.05 (0.05-0.05) | 0.05 (0.05-0.05) | 1.000 |
| 0 | TN_72_14_4 | card-mto | 1 | 1/1 | 0.10 (0.10-0.10) | 0.15 (0.15-0.15) | 1.467 |
| 0 | TN_72_14_4 | no-card | 1 | 1/1 | 0.10 (0.10-0.10) | 0.10 (0.10-0.10) | 1.000 |
| 0 | TN_72_8_8 | card-mto | 1 | 1/1 | 1.26 (1.26-1.26) | 0.91 (0.91-0.91) | 0.721 |
| 0 | TN_72_8_8 | no-card | 1 | 1/1 | 0.71 (0.71-0.71) | 0.86 (0.86-0.86) | 1.212 |
| 1 | BB_108_8_10 | card-mto | 5 | 5/5 | 1.36 (0.51-1.51) | 1.06 (0.51-1.96) | 0.779 |
| 1 | BB_108_8_10 | no-card | 5 | 5/5 | 0.46 (0.26-0.86) | 0.41 (0.30-0.86) | 0.888 |
| 1 | BB_144_12_12 | card-mto | 5 | 5/5 | 1.56 (1.41-2.26) | 1.61 (1.36-2.26) | 1.033 |
| 1 | BB_144_12_12 | no-card | 5 | 5/5 | 0.76 (0.71-1.41) | 1.01 (0.71-1.41) | 1.329 |
| 1 | LP_238_44_6 | card-mto | 5 | 5/5 | 1.36 (0.86-2.16) | 1.16 (0.86-1.51) | 0.851 |
| 1 | LP_238_44_6 | no-card | 5 | 5/5 | 1.06 (0.86-1.31) | 1.06 (0.86-1.31) | 1.000 |
| 1 | LP_340_56_8 | card-mto | 5 | 5/5 | 5.22 (4.07-5.32) | 4.27 (3.77-7.54) | 0.818 |
| 1 | LP_340_56_8 | no-card | 5 | 5/5 | 4.02 (3.52-6.18) | 4.17 (3.57-5.87) | 1.037 |
| 2 | BB_144_14_14 | card-mto | 5 | 5/5 | 84.43 (66.72-152.73) | 84.47 (63.30-99.47) | 1.001 |
| 2 | BB_144_14_14 | no-card | 5 | 5/5 | 97.97 (70.11-168.63) | 98.16 (75.89-144.31) | 1.002 |
| 2 | LP_442_68_10 | card-mto | 5 | 5/5 | 109.67 (52.47-235.21) | 73.92 (52.28-239.97) | 0.674 |
| 2 | LP_442_68_10 | no-card | 5 | 5/5 | 58.05 (45.47-98.86) | 85.15 (45.67-149.07) | 1.467 |
| 2 | TN_108_2_12 | card-mto | 5 | 5/5 | 32.02 (24.19-33.68) | 33.82 (24.19-47.36) | 1.056 |
| 2 | TN_108_2_12 | no-card | 5 | 5/5 | 26.14 (23.52-29.64) | 26.28 (23.78-44.40) | 1.005 |
| 3 | BB_288_12_18 | card-mto | 1 | 1/1 | 1197.59 (1197.59-1197.59) | 1591.66 (1591.66-1591.66) | 1.329 |
| 3 | BB_288_12_18 | no-card | 1 | 1/1 | 937.90 (937.90-937.90) | 937.38 (937.38-937.38) | 0.999 |
| 3 | GB_144_12_12 | card-mto | 1 | 1/1 | 63.06 (63.06-63.06) | 95.69 (95.69-95.69) | 1.517 |
| 3 | GB_144_12_12 | no-card | 1 | 1/1 | 160.43 (160.43-160.43) | 251.37 (251.37-251.37) | 1.567 |
| 3 | LP_544_80_12 | card-mto | 1 | 1/1 | 425.18 (425.18-425.18) | 653.16 (653.16-653.16) | 1.536 |
| 3 | LP_544_80_12 | no-card | 1 | 1/1 | 676.28 (676.28-676.28) | 675.51 (675.51-675.51) | 0.999 |
| 3 | TN_144_2_13 | card-mto | 1 | 1/1 | 567.97 (567.97-567.97) | 457.47 (457.47-457.47) | 0.805 |
| 3 | TN_144_2_13 | no-card | 1 | 1/1 | 456.98 (456.98-456.98) | 458.63 (458.63-458.63) | 1.004 |
| 3 | TN_200_10_10 | card-mto | 1 | 1/1 | 21.12 (21.12-21.12) | 21.64 (21.64-21.64) | 1.025 |
| 3 | TN_200_10_10 | no-card | 1 | 1/1 | 161.53 (161.53-161.53) | 241.51 (241.51-241.51) | 1.495 |
| 4 | TN_250_10_15 | card-mto | 1 | 1/1 | 4254.24 (4254.24-4254.24) | 4182.20 (4182.20-4182.20) | 0.983 |
| 4 | TN_250_10_15 | no-card | 1 | 1/1 | 3408.75 (3408.75-3408.75) | 2395.61 (2395.61-2395.61) | 0.703 |

| Tier | no-card geomean on/off | card-mto geomean on/off | max cell |
|---:|---:|---:|---|
| 0 | 1.002 | 1.021 | 1.467 (TN_72_14_4 card-mto) |
| 1 | 1.052 | 0.865 | 1.329 (BB_144_12_12 no-card) |
| 2 | 1.139 | 0.893 | 1.467 (LP_442_68_10 no-card) |
| 3 | 1.186 | 1.207 | 1.567 (GB_144_12_12 no-card) |
| 4 | 0.703 | 0.983 | 0.983 (TN_250_10_15 card-mto) |

Cells with ratio > 1: GB_144_12_12 no-card 1.567, LP_544_80_12 card-mto 1.536, GB_144_12_12 card-mto 1.517, TN_200_10_10 no-card 1.495, LP_442_68_10 no-card 1.467, TN_72_14_4 card-mto 1.467, BB_288_12_18 card-mto 1.329, BB_144_12_12 no-card 1.329, TN_72_8_8 no-card 1.212, BB_90_8_10 card-mto 1.164, TN_108_2_12 card-mto 1.056, LP_340_56_8 no-card 1.037, BB_144_12_12 card-mto 1.033, TN_200_10_10 card-mto 1.025, TN_36_8_3 no-card 1.019, TN_108_2_12 no-card 1.005, TN_144_2_13 no-card 1.004, BB_90_8_10 no-card 1.003, BB_144_14_14 no-card 1.002, BB_144_14_14 card-mto 1.001; cells > 1.25: TN_72_14_4 card-mto, BB_144_12_12 no-card, LP_442_68_10 no-card, BB_288_12_18 card-mto, GB_144_12_12 card-mto, GB_144_12_12 no-card, LP_544_80_12 card-mto, TN_200_10_10 no-card.

### 3.3 Reading the wall ratios

Every tier1-4 run pair above has the same fingerprint (same probes, same conflict counts), yet measured wall ratios
range from 0.67 (LP_442 card-mto) to 1.57 (GB_144_12_12 no-card), and per-tier "geomeans" from 0.70 to 1.21. On
this host (unpinned foreign jobs sharing the physical cores and their SMT siblings, load 95-150) that is the noise
floor for single runs, so the wall numbers carry no information about the change; the identity does. The "cells >
1.25" list is purely host noise for the same reason.

### 3.4 Mac tier0-2 quick check (serial, caffeinate, 2 GB; main = frozen abd1770)

| Tier | Code | Mode | d | off s | on s | on/off | fingerprint on = off | off = main | p1skip lines (on) | checks |
|---:|---|---|---:|---:|---:|---:|---|---|---|---|
| 0 | BB_72_12_6 | card-mto | 6 | 0.07 | 0.07 | 1.000 | yes | yes | - | ok |
| 0 | BB_72_12_6 | no-card | 6 | 0.06 | 0.07 | 1.078 | yes | yes | - | ok |
| 0 | BB_90_8_10 | card-mto | 10 | 0.13 | 0.13 | 1.008 | yes | yes | - | ok |
| 0 | BB_90_8_10 | no-card | 10 | 0.14 | 0.14 | 1.007 | yes | yes | - | ok |
| 0 | GB_144_12_8 | card-mto | 8 | 0.07 | 0.07 | 1.000 | yes | yes | - | ok |
| 0 | GB_144_12_8 | no-card | 8 | 0.13 | 0.14 | 1.053 | yes | yes | - | ok |
| 0 | LP_136_32_4 | card-mto | 4 | 0.07 | 0.07 | 1.043 | yes | yes | - | ok |
| 0 | LP_136_32_4 | no-card | 4 | 0.07 | 0.07 | 1.029 | yes | yes | - | ok |
| 0 | LP_34_20_2 | card-mto | 2 | 0.07 | 0.07 | 1.014 | no (skip) | yes | Z half cap 2 skipped (lb 2 >= UB 2); global lb 2 = UB 2 after Phase 1: d determined, no further probe | ok |
| 0 | LP_34_20_2 | no-card | 2 | 0.07 | 0.07 | 1.000 | no (skip) | yes | Z half cap 2 skipped (lb 2 >= UB 2); global lb 2 = UB 2 after Phase 1: d determined, no further probe | ok |
| 0 | TN_36_8_3 | card-mto | 3 | 0.07 | 0.07 | 0.972 | no (skip) | yes | Z half cap 4 skipped (lb 3 >= UB 3); global lb 3 = UB 3 after Phase 1: d determined, no further probe | ok |
| 0 | TN_36_8_3 | no-card | 3 | 0.07 | 0.07 | 1.000 | yes | yes | - | ok |
| 0 | TN_36_8_4 | card-mto | 4 | 0.07 | 0.07 | 0.972 | yes | yes | - | ok |
| 0 | TN_36_8_4 | no-card | 4 | 0.07 | 0.07 | 1.014 | yes | yes | - | ok |
| 0 | TN_54_11_4 | card-mto | 4 | 0.07 | 0.07 | 1.014 | yes | yes | - | ok |
| 0 | TN_54_11_4 | no-card | 4 | 0.07 | 0.07 | 1.000 | yes | yes | - | ok |
| 0 | TN_72_14_4 | card-mto | 4 | 0.07 | 0.07 | 0.972 | yes | yes | - | ok |
| 0 | TN_72_14_4 | no-card | 4 | 0.07 | 0.07 | 1.000 | yes | yes | - | ok |
| 0 | TN_72_8_8 | card-mto | 8 | 0.42 | 0.42 | 0.995 | yes | yes | - | ok |
| 0 | TN_72_8_8 | no-card | 8 | 0.28 | 0.28 | 0.996 | yes | yes | - | ok |
| 1 | BB_108_8_10 | card-mto | 10 | 0.48 | 0.48 | 1.004 | yes | yes | - | ok |
| 1 | BB_108_8_10 | no-card | 10 | 0.34 | 0.35 | 1.027 | yes | yes | - | ok |
| 1 | BB_144_12_12 | card-mto | 12 | 0.63 | 0.63 | 1.000 | yes | yes | - | ok |
| 1 | BB_144_12_12 | no-card | 12 | 0.34 | 0.34 | 0.994 | yes | yes | - | ok |
| 1 | LP_238_44_6 | card-mto | 6 | 0.49 | 0.48 | 0.988 | yes | yes | - | ok |
| 1 | LP_238_44_6 | no-card | 6 | 0.47 | 0.49 | 1.036 | yes | yes | - | ok |
| 1 | LP_340_56_8 | card-mto | 8 | 1.85 | 1.79 | 0.964 | yes | yes | - | ok |
| 1 | LP_340_56_8 | no-card | 8 | 1.71 | 1.73 | 1.010 | yes | yes | - | ok |
| 2 | BB_144_14_14 | card-mto | 14 | 31.60 | 32.03 | 1.014 | yes | yes | - | ok |
| 2 | BB_144_14_14 | no-card | 14 | 31.68 | 35.12 | 1.108 | yes | yes | - | ok |
| 2 | LP_442_68_10 | card-mto | 10 | 22.72 | 22.73 | 1.000 | yes | yes | - | ok |
| 2 | LP_442_68_10 | no-card | 10 | 35.85 | 35.85 | 1.000 | yes | yes | - | ok |
| 2 | TN_108_2_12 | card-mto | 12 | 12.16 | 12.12 | 0.997 | yes | yes | - | ok |
| 2 | TN_108_2_12 | no-card | 12 | 10.57 | 10.59 | 1.002 | yes | yes | - | ok |

Mac: 34 cells; fingerprint on = off in 31; off = main in 34/34; skip triggered in 3: LP_34_20_2 card-mto, LP_34_20_2 no-card, TN_36_8_3 card-mto; check failures 0.

On the quiet Mac the identical tier1-2 searches agree within +-4% except BB_144_14_14 no-card (1.108, one run, identical
fingerprint); tier0 times are at the 0.07 s process-start floor.

## 4. Tier 5 (6 h, default seed): `-p1skip=on` vs recorded main 398054e

| Code | Mode | main | p1skip=on | lb vs main | ub vs main | on lb events | ub-to-answer gap (s) | checks |
|---|---|---|---|---|---|---|---:|---|
| BB_1080_4_ge17 | card-mto | T, 17/- | T, 17/- | = | = | 9@1, 17@2793, 17@21600 | - | ok |
| BB_1080_4_ge17 | no-card | T, 17/- | T, 17/- | = | = | 9@1, 17@3719, 17@21600 | - | ok |
| BB_360_12_24 | card-mto | T, 17/24 | T, 17/26 | = | > | 9@0, 17@207, 17@21600 | - | ok |
| BB_360_12_24 | no-card | T, 17/24 | T, 17/24 | = | = | 9@0, 17@226, 17@21600 | - | ok |
| BB_756_16_ge17 | card-mto | T, 17/- | T, 17/- | = | = | 9@1, 17@1038, 17@21600 | - | ok |
| BB_756_16_ge17 | no-card | T, 17/- | T, 17/- | = | = | 9@1, 17@1087, 17@21600 | - | ok |
| BB_864_4_ge17 | card-mto | T, 17/- | T, 17/- | = | = | 9@1, 17@2256, 17@21600 | - | ok |
| BB_864_4_ge17 | no-card | T, 17/- | T, 17/- | = | = | 9@1, 17@1676, 17@21600 | - | ok |
| LP_1020_136_16 | card-mto | d=16 @ 8328 s | d=16 @ 7623 s | = | = | 9@22, 16@7623 | 5837.2 | ok |
| LP_1020_136_16 | no-card | d=16 @ 7159 s | d=16 @ 7612 s | = | = | 9@38, 16@7612 | 5809.4 | ok |
| LP_1054_140_20 | card-mto | T, 17/- | T, 17/- | = | = | 9@42, 17@20550, 17@21600 | - | ok |
| LP_1054_140_20 | no-card | T, 17/- | T, 9/- | < | = | 9@29, 9@21600 | - | ok |
| LP_1428_184_24 | card-mto | T, 17/- | T, 17/- | = | = | 9@41, 17@19800, 17@21600 | - | ok |
| LP_1428_184_24 | no-card | T, 17/- | T, 9/- | < | = | 9@75, 9@21600 | - | ok |
| LP_1768_224_22 | card-mto | T, 9/- | T, 9/- | = | = | 9@153, 9@21600 | - | ok |
| LP_1768_224_22 | no-card | T, 9/- | T, 9/- | = | = | 9@94, 9@21600 | - | ok |
| LP_714_100_16 | card-mto | d=16 @ 5321 s | d=16 @ 7049 s | = | = | 9@13, 16@7049 | 7004.5 | ok |
| LP_714_100_16 | no-card | d=16 @ 8752 s | d=16 @ 7160 s | = | = | 9@13, 16@7160 | 7110.4 | ok |
| TN_180_2_17 | card-mto | T, 17/19 | T, 17/19 | = | = | 9@6, 17@12677, 17@21600 | - | ok |
| TN_180_2_17 | no-card | d=17 @ 9837 s | d=17 @ 11657 s | = | = | 9@4, 17@8035 | 0.0 | ok |
| TN_216_4_18 | card-mto | d=18 @ 18346 s | T, 17/18 | < | = | 9@8, 17@6246, 17@21600 | - | ok |
| TN_216_4_18 | no-card | d=18 @ 16802 s | d=18 @ 17089 s | = | = | 9@6, 17@4190, 18@17089 | 9208.5 | ok |
| TN_252_2_21 | card-mto | T, 17/- | T, 17/- | = | = | 9@5, 17@10541, 17@21600 | - | ok |
| TN_252_2_21 | no-card | T, 17/28 | T, 17/28 | = | = | 9@5, 17@10592, 17@21600 | - | ok |
| TN_288_2_ge9 | card-mto | T, 9/- | T, 9/- | = | = | 9@11, 9@21600 | - | ok |
| TN_288_2_ge9 | no-card | T, 9/- | T, 9/- | = | = | 9@13, 9@21600 | - | ok |
| TN_324_4_ge9 | card-mto | T, 9/- | T, 9/- | = | = | 9@15, 9@21600 | - | ok |
| TN_324_4_ge9 | no-card | T, 9/- | T, 9/- | = | = | 9@14, 9@21600 | - | ok |
| TN_360_4_ge17 | card-mto | T, 17/- | T, 17/- | = | = | 9@9, 17@6342, 17@21600 | - | ok |
| TN_360_4_ge17 | no-card | T, 17/- | T, 17/- | = | = | 9@5, 17@6857, 17@21600 | - | ok |
| TN_396_4_ge17 | card-mto | T, 17/- | T, 17/- | = | = | 9@8, 17@7163, 17@21600 | - | ok |
| TN_396_4_ge17 | no-card | T, 17/- | T, 17/- | = | = | 9@9, 17@5008, 17@21600 | - | ok |
| TN_432_8_ge9 | card-mto | T, 9/- | T, 9/- | = | = | 9@22, 9@21600 | - | ok |
| TN_432_8_ge9 | no-card | T, 9/- | T, 9/- | = | = | 9@23, 9@21600 | - | ok |
| TN_468_4_ge17 | card-mto | T, 17/- | T, 17/- | = | = | 9@11, 17@12789, 17@21600 | - | ok |
| TN_468_4_ge17 | no-card | T, 17/- | T, 17/- | = | = | 9@14, 17@11242, 17@21600 | - | ok |
| TN_496_2_ge17 | card-mto | T, 17/- | T, 17/- | = | = | 9@9, 17@19550, 17@21600 | - | ok |
| TN_496_2_ge17 | no-card | T, 17/- | T, 17/- | = | = | 9@9, 17@14590, 17@21600 | - | ok |
| TN_504_2_ge17 | card-mto | T, 17/- | T, 17/- | = | = | 9@10, 17@5956, 17@21600 | - | ok |
| TN_504_2_ge17 | no-card | T, 17/- | T, 17/- | = | = | 9@8, 17@6136, 17@21600 | - | ok |
| TN_540_4_ge9 | card-mto | T, 9/- | T, 9/- | = | = | 9@47, 9@21600 | - | ok |
| TN_540_4_ge9 | no-card | T, 9/- | T, 9/- | = | = | 9@35, 9@21600 | - | ok |
| TN_576_2_ge9 | card-mto | T, 9/- | T, 9/- | = | = | 9@36, 9@21600 | - | ok |
| TN_576_2_ge9 | no-card | T, 9/- | T, 9/- | = | = | 9@41, 9@21600 | - | ok |
| TN_612_2_ge17 | card-mto | T, 17/- | T, 17/- | = | = | 9@10, 17@5202, 17@21600 | - | ok |
| TN_612_2_ge17 | no-card | T, 17/- | T, 17/- | = | = | 9@15, 17@5911, 17@21600 | - | ok |
| TN_648_10_9to52 | card-mto | T, 9/- | T, 9/- | = | = | 9@69, 9@21600 | - | ok |
| TN_648_10_9to52 | no-card | T, 9/- | T, 9/- | = | = | 9@60, 9@21600 | - | ok |
| TN_648_14_ge9 | card-mto | T, 9/- | T, 9/- | = | = | 9@57, 9@21600 | - | ok |
| TN_648_14_ge9 | no-card | T, 9/- | T, 9/- | = | = | 9@79, 9@21600 | - | ok |
| TN_684_2_ge9 | card-mto | T, 9/- | T, 9/- | = | = | 9@14, 9@21600 | - | ok |
| TN_684_2_ge9 | no-card | T, 9/- | T, 9/- | = | = | 9@15, 9@21600 | - | ok |

Solved cells: main 7, p1skip=on 6. Time ratios on/main where both solved: LP_1020_136_16 card-mto 0.915, LP_1020_136_16 no-card 1.063, LP_714_100_16 card-mto 1.325, LP_714_100_16 no-card 0.818, TN_180_2_17 no-card 1.185, TN_216_4_18 no-card 1.017; geomean 1.041.

"ub-to-answer gap" = time from the first `c d_ub: d` to the answer; it is 0 for TN_180 no-card in main's record as
well (d = 17 is found and proven by the Phase 2 optimisation, not by a Phase 1 meeting).

Sequence comparison with main's raw logs (`runner/tier5_sequences.py`, output `server/tier5_vs_main_sequences.txt`):
48/52 cells print exactly main's sequence of `c trying d` / `c d_lb` / `c d_ub` / `c d` / `o` values (a skipped probe
would remove a `c trying d` line), and the other 4 print main's sequence up to the point where the 6 h limit stopped
them:

```
BB_360_12 card-mto same first 18 lines; then on ['c d_lb: 17'] (timeout summary follows) vs main ['c d_ub: 24', 'c d_lb: 17', 'c d_ub: 24']
LP_1054_140 no-card same first 14 lines; then on ['c d_lb: 9'] (timeout summary follows) vs main ['c d_lb: 17', 'c trying d: 33', 'c d_lb: 17']
LP_1428_184 no-card same first 14 lines; then on ['c d_lb: 9'] (timeout summary follows) vs main ['c d_lb: 17', 'c trying d: 33', 'c d_lb: 17']
TN_216_4 card-mto same first 26 lines; then on ['c d_lb: 17'] (timeout summary follows) vs main ['c d_lb: 18', 'c d  : 18', 'o 18']
```

Host drift on identical trajectories (time to the last lb value both runs reached, 28 cells with main time >= 60 s):
on/main geomean 1.31, range 1.02-1.92; every cell was slower than in main's record. This accounts for the four
truncated cells: LP_1054_140 and LP_1428_184 no-card (main finished the cap-16 refutation at 16379 / 19868 s),
BB_360_12 card-mto (main reached ub 26 at 16647 s and 24 at 19898 s; this run reached 26), and TN_216_4_18 card-mto
(main proved d = 18 at 18346 s; this run had ub 18 and lb 17 at the limit). Time ratios where both solved: LP_1020
0.915 / 1.063, LP_714 1.325 / 0.818, TN_180 no-card 1.185, TN_216 no-card 1.017 (geomean 1.041), all for identical
searches.

## 5. Gate verdicts

| Gate | Verdict | Evidence |
|---|---|---|
| Tier 0 (correctness, severe slowdown) | PASS | all answers = stem d, both hosts, both modes, three arms; skip triggers on LP_34_20_2 (both modes) and TN_36_8_3 card-mto, one probe saved each; off = main 62/62 |
| Tier 1 | PASS (neutral) | no trigger possible (d not 2^j + 1); fingerprints on = off 40/40 (4 codes x 2 modes x 5 seeds); seed-median ratio 1.000 per cell, geomean 1.000 per mode |
| Tier 2 | PASS (neutral) | same, 30/30 (3 codes x 2 modes x 5 seeds) |
| Tier 3 | PASS (neutral) | same, 10/10 default seed (tier3 run with -cpu-lim=1800, all solved) |
| Tier 4 | PASS (neutral) | same, 2/2 (TN_250_10_15, limit 5000 s, both solved) |
| Tier 5 | NEUTRAL (no regression attributable to the change) | identical trajectories to main in 48/52 cells, 4 limit-truncated prefixes on a 1.31x slower host; 6/7 of main's solves (TN_216 card-mto lost to drift); no new solve or higher bound |

The coordinator criteria (geomean < 1 per mode, no cell > 1.25) are not met in the strict sense for a neutral change:
the geomean is exactly 1, not < 1, because the change cannot act on tier1-4 codes.

## 6. Recommendation and lessons

- Keep `-p1skip`; the branch default is now `on` (decided from the evaluation: sound, never more probes, identical
  search wherever it does not trigger, one probe saved where it does). With default on, main's outputs change only on
  codes with d = 2^j + 1 whose first feasible solution is optimal (here LP_34_20_2, TN_36_8_3 card-mto) and in the
  extra `-v` / stats fields. `-p1skip=off` restores main abd1770 byte for byte.
- Adoption: no measurable speed-up on Tier 1-5 under main's doubling caps, so it does not justify a main replacement
  on its own; propose it to the PI as a zero-risk cleanup, or bundle it with the next lb-schedule round (GH-127
  follow-up 2), where it removes the 130-2400 s of redundant probing measured on solved Tier 5 cells and would have
  let TN_180 card-mto finish.
- Lesson: before measuring, check whether a change can trigger at all. Here a 3-line argument (equal caps in Phase 1,
  so lb = m/2 + 1 for both halves) predicted "tier0 only" exactly; the server's single-run wall noise (0.67-1.57 for
  identical searches, 1.31x drift between days on Tier 5) would otherwise have produced false regressions and false
  gains. Search fingerprints (probe lines + conflict totals) are a cheap, exact identity test for such rounds.

## 7. Files

| Path | Content |
|---|---|
| `runner/s128_runs.py` | tier0-4 runner (fingerprint, answers, bounds, p1skip lines; pinned server cores or serial Mac with RSS watchdog) |
| `runner/mkjobs.py` | job lists (`server` / `mac`) |
| `runner/s128_tier5.py` | Tier 5 runner (GH-127's, cores 0-59 only) |
| `runner/tier5_sequences.py` | Tier 5 bound-line sequence comparison with main's raw logs (run on yfclab2) |
| `runner/analyze.py` | tables: `python3 runner/analyze.py server/t04_results.jsonl mac/results.jsonl server/tier5_results.json ../../baselines/SERVER.md` |
| `summary.md` | analyze.py output (all tables, including tier0 rows omitted from the seed table above) |
| `server/t04_results.jsonl`, `server/t04.out`, `server/gh128-t04-logs.tar.gz`, `server/server_jobs.jsonl` | 232 server tier0-4 records and raw `-v` logs |
| `server/tier5_results.json`, `server/tier5.out`, `server/gh128-tier5-logs.tar.gz`, `server/tier5_vs_main_sequences.txt` | 52 Tier 5 records (timestamped bound events), raw logs, driver files, the aborted first tier0-4 attempt (c84c891) and the sequence comparison |
| `mac/results.jsonl`, `mac/mac.out`, `mac/mac-logs.tar.gz`, `mac/mac_jobs.jsonl` | 102 Mac records and raw `-v` logs |
