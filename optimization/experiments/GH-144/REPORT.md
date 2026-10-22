# GH-144 report: verified upper-bound pre-pass seeding the MaxSAT path (`-ub-pre`)

Issue: https://github.com/guluchen/DistQLDPC/issues/144 (hub #15). Baseline: main `8eb047b` (default MaxSAT path:
frontier auto + oddcap-skip; CC optional), with GH-140's finder (PR #143, not merged) underneath. Candidate: branch
`experiment/gh-144-ub-pre-maxsat` (from GH-140's `76e43e8`). Evaluated binary `6d2b7a1` (S1 panel, Tier 5, final
identity and tests); S0 finder measurements used `7bce6b0` (initial rule) and `e4e73f0` (same code plus the
`-ub-pre-hits` / `-ub-pre-plateau` tuning flags; `-ub-pre-plateau=1000` there = the defaults of `6d2b7a1`).
Frozen server binaries: `frozen/server-main-8eb047b` (sha256 `6c978fd2...`), `frozen/server-gh144-6d2b7a1`
(`38ce8187...`). No external solver was used; the finder is GH-140's clean-room code; the new code is ours.

## Summary

| Item | Result |
|---|---|
| Default MaxSAT path | byte-identical to main `8eb047b`: 28/28 `-v` logs identical on tier0+1 x {`-no-card`, `-card-mto`} without the flag and 28/28 with `-ub-pre=off`, for `7bce6b0` (Mac and yfclab2) and for the final `6d2b7a1` (yfclab2); main `c914ef5` (recorded Tier 5 baseline) vs `8eb047b`: 28/28 identical |
| Finder pre-pass (S0, yfclab2, 3 seeds, final rule) | **U0 = d on all 34 codes with a known d in every seed (102/102)**; pre-pass time <= 0.29 s on every tier 1-4 code (TN_250 0.26 s, BB_288 0.09 s, LP_340 0.01 s); Tier 5: 0.03-25 s, LP_1768 55-60 s (cap); open codes: BB_756 34, TN_288 24-25, TN_360 24, TN_684 29-31, BB_864 48-58, BB_1080 70-80 |
| Stop rule chosen from measurements | per half: 16 re-hits of U, or max(**1000**, 4 x last improvement) iterations without improvement; cap S. Plateau 64 (initial) missed d on 6/102 runs (TN_252 22/23, LP_1428 26, LP_1768 24/32); 256 on 3/102; 1000 and 4000 on 0/102 (4000 costs ~3x more time on Tier 5 and 0.35 s on TN_200) |
| **S1 Tier 1-4 panel** (5 seeds, both modes, main `8eb047b` vs `-ub-pre=60`, concurrent pinned cores) | geomean pre/main: **tier1 0.917 / 0.908** (no-card / card-mto), **tier2 0.329 / 0.333**, **tier3 0.509 / 0.413**, **tier4 0.922 / 0.750**; max cell 1.157 (LP_714 no-card: identical solver work, core placement; 1.000 with the arms' cores swapped); no cell > 1.25; every answer = stem |
| Biggest gains | GB_144_12_12 **0.019-0.026** (51-70 s -> 1.3 s), TN_144_2_13 **0.17 / 0.26** (337-481 s -> 83-87 s), LP_544 0.36-0.40, TN_200 0.47-0.49, LP_442 0.52-0.60, BB_144_14_14 0.60-0.70, TN_250 **0.64 / 0.74** (2337-2352 s -> 1499-1717 s) |
| **Tier 5** (6 h, both modes, vs main `c914ef5`'s recorded Tier 5) | **solved cells 6 of 54 (main 5)**: TN_180_2_17 card-mto newly solved (d = 17 at 9 885 s; main: timeout, lb 17 / ub 19); TN_180 no-card **0.50x** (5 760 s vs 11 486 s), TN_216 **0.52x / 0.62x** (10 066 / 9 161 s vs 19 298 / 14 842 s), LP_1020 0.95x / 0.94x; final lb identical on all 48 unsolved cells (none lower); an upper bound on every cell: 37 cells where main had none (BB_756 34, BB_864 52, BB_1080 70, LP_1768 22, TN_252 21, TN_288 24, TN_360 24, ...) and 8 lower ones (LP_1054 / LP_1122 32 -> 20, LP_1428 32 -> 24, TN_252 no-card 28 -> 21, TN_180 card-mto 19 -> 17); ub = d on every known-d code |
| Correctness | `make test-cc` (new Part F: 200 random codes x 8 configurations vs exhaustive enumeration, U0 > d on 180 runs) and `test_cc_engine 1500 600` on yfclab2 (Part F 4 800 runs on 600 codes, 0 bad, U0 > d on 477) pass; mutant 1 (finder without its detector check) stays correct (the verification rejects every trivial word), mutant 2 (no verification) answers wrongly (7/600 codes, 9/9 surface-code runs) as required; `make test-cc-flags` 283 checks pass (Mac and yfclab2); Mac tier0-2 x 2 modes with `-ub-pre=on`: 40/40 answers correct; every server run (panel, repetitions, Tier 5): anytime bounds monotone, every ub >= every earlier lb, 0 science problems |
| Gates | Tier 0 PASS, Tier 1 PASS, Tier 2 PASS, Tier 3 PASS, Tier 4 PASS (watch: LP_714 no-card, placement noise), Tier 5 PASS |
| Recommendation | make `-ub-pre=on` (S = 60 s, plateau 1000, 16 re-hits) the default of the MaxSAT path (PI decision; the code default is left off in this branch, so the default path stays byte-identical to main) |

Scientific semantics changed: no. The pre-pass only adds an upper bound that is a GF(2)-verified feasible solution of
the half instance; every lower bound still comes from a NONE of a MaxSAT probe (or from GH-107 / GH-133, unchanged);
the answer is returned only when every half is proven to have no logical below U.

## 1. What was implemented (S0)

**Pre-pass (`src/core/distqldpc.cc`, `ub_prepass`).** With `-ub-pre=S` (`on` = 60 s; default off) the interleaved MaxSAT
search (`min_distance_css_interleaved`) first runs GH-140's `UbFinder` (`src/cc/cc_ubsearch.h`: random information
sets, words of 1-2 systematic rows, same-type stabilizer local improvement) on every half that has logicals, after
dual-map, oddcap and symmetry detection: X half H = Hz, G = Gx, S = Hx; Z half H = Hx, G = Gz, S = Hz; the finder seed
is derived from `-seed` exactly as in the CC driver. One iteration at a time runs on the half with less finder time,
always looking for a word lighter than the current global bound U. A half stops after `-ub-pre-hits=H` (16)
iterations that re-hit U without improving it, or after max(`-ub-pre-plateau=P` (1000), 4 x its iteration count at its
last improvement) iterations without improvement; the pre-pass ends when both halves stopped or after S seconds. The
rule counts iterations, so for a given seed the pre-pass is deterministic unless S ends it.

**Verification.** Every word is checked before use by `ubpre_verify`: it must be a feasible solution of the half
instance that `build_css_half` encodes (Hpar e = 0 and some Glog row with odd overlap, computed on the input matrices,
independent of the finder's bit arrays), and `distcc::verify_logical` (the CC engine's independent check: Hpar e = 0,
e not in rs S by its own echelon form) must agree. A failure discards the whole pre-pass (warning on stderr; the search
then runs as without the flag).

**Seeding.** The lightest verified weight U0 becomes the initial global UB (pipe `UB U0`, so the default output's
first bound line is `c d_ub: U0`) and each half's lightest word its incumbent (`h.ub`, `h.pre`). Then, only when U0
exists (otherwise main byte for byte):
- Phase 1 (doubling) keeps probing a half whose only incumbent is a pre-pass word, but only at caps c < U - 1 (GH-133
  odd-cap rule applied first); it ends when the next doubling cap is >= U - 1, or as in main when a probe finds a
  solution (which lowers U). The anytime lower bounds of Phase 1 (e.g. lb 17/18 on Tier 5) are kept.
- Phase 2a runs while both halves are unfinished (main: only while their incumbents tie), each probe a feasibility
  probe at U - 1 (U - 2 on an all-odd-column half when U - 1 is odd); FOUND lowers U, NONE finishes the half with
  lb = U; the global lower bound min(U, lb of the unfinished halves) is piped after each probe.
- Phase 2b optimises a remaining half with cap U - 1 (main: U, which re-finds weight U before proving it).

GH-107 sharing, GH-133 odd caps, GH-85 orbit clauses, frontier branching and the encoding are untouched. On an
all-odd-column half every kernel element has even weight, so its verified words (and U0, when it comes from such a
half) are even. The soundness argument is in `MODIFICATIONS.md` (GH-144).

**Flags.** `-ub-pre=off|on|S`, tuning `-ub-pre-hits=H` (0 = never), `-ub-pre-plateau=P`. MaxSAT tuning family:
refused with `-engine=cc`, applied with `-engine=auto` when it selects maxsat (warning otherwise), refused with
`-joint` / `-roundingsat`; the tuning flags need `-ub-pre`. `-v` prints the finder setup per half, every improvement
with its witness, convergence per half and a summary (`c ub-pre: U0 after Xs (...): U0 (X a, Z b)`). Docs: README
(flag table), MODIFICATIONS.md (row and GH-144 paragraph).

**Schedule history (all in S0, before S1).** `7bce6b0`: plateau 64 (GH-140's driver constant); the S0 finder runs
showed that it stops large codes after ~65 iterations per half (6/102 runs above d), so `e4e73f0` added the tuning
flags, the stop rule was measured with four plateau values (section 3) and `6d2b7a1` set the default plateau to 1000
and `-ub-pre=on` = 60 s. All S1 numbers are `6d2b7a1` with `-ub-pre=60`.

## 2. Correctness

| Check | Runs | Result |
|---|---:|---|
| Default path vs main `8eb047b` (`-v` logs, tier0+1 x `-no-card`/`-card-mto`, time fields masked; `S0/ident.py`) | 5 x 28 | identical: `7bce6b0` on the Mac; `7bce6b0` on yfclab2 without the flag and with `-ub-pre=off`; `6d2b7a1` on yfclab2 without the flag and with `-ub-pre=off` (`S0/server/ident_*.txt`) |
| main `c914ef5` vs `8eb047b` (same check) | 28 | identical (the recorded Tier 5 of `c914ef5` is the Tier 5 baseline) |
| `make test-cc` Part F (new): the MaxSAT driver with the pre-pass on the 200 random Part B codes, exhaustive enumeration as the oracle; budget 1 s, pre-passes cut after 1-3 iterations, `-oddcap-skip=off`, `-seed=5`, `-dualmode=off`, `-dualmode=skip`, `-no-symbreak`, `-card-mto` | 1 600 | 0 bad (RESULT = enumeration, every UB >= d, LBs monotone <= d, first UB >= d); first UB > d on 180 runs (Phase 1 FOUND, Phase 2a FOUND and Phase 2b OPT below a seeded U exercised) |
| Part F mutants: 1 = finder without its detector check / local improvement (trivial words reach the verification); 2 = mutant 1 and words used unverified | 200 + 200 codes, 9 + 9 surface-code runs (rotated d = 3..5, seeds 0-2) | mutant 1: 0 wrong (every trivial word rejected, pre-pass discarded); mutant 2: 2/200 codes and 9/9 surface runs wrong, as required |
| Parts A-E (GH-124..140, unchanged) | 115 200 ladders, 4 400 driver, 400 MaxSAT | 0 bad; all old mutants still fail as required |
| `test_cc_engine 1500 600` (yfclab2, `6d2b7a1`) | Part F 4 800 runs on 600 codes; Parts A-E as in GH-140 | 0 bad; U0 > d on 477 runs; mutant 1 0/600 wrong, mutant 2 7/600 codes and 9/9 surface runs wrong; `CC_ENGINE_TESTS PASS` (`S0/server/test_cc_engine_1500_600.txt`) |
| `make test-cc-flags` (new: `-ub-pre` values, `on`, tuning flags and their conflicts, `-engine=cc` / `-joint` / `-roundingsat` / auto, `-v` lines, first `c d_ub` line = U0, probe caps < U0 - 1 and the Phase 2a cap on BB_90_8_10, no output with `-ub-pre=off`) | 283 | PASS on the Mac and on yfclab2 |
| Mac quick check (idle Mac, serial, caffeinate, 2 GB poll): tier0-2 x 2 modes, `-ub-pre=on` | 40 | 40/40 answers = stem, first `c d_ub` = d on all (`S0/mac_quick_tier012.jsonl`; walls informational only) |
| S1 server runs (panel 220, LP_714 repetitions 40, Tier 5 54): runner science check (answer in the stem range, lb <= stem upper value, ub >= stem lower value) and `S1/runner/check_anytime.py` (lb never decreases, ub never increases, every ub >= every earlier lb, answer = final bounds) | 314 | 0 problems (220 + 40 + 54 runs) |

## 3. S0: the pre-pass alone, and the choice of the stop rule (yfclab2)

Runner `S0/finder_runs.py`: `BIN -v -ub-pre=S -seed=K CODE`; the process group is killed once the pre-pass summary is
printed (only the pre-pass is measured); one pinned core per process, 4 GB cap; seeds 0-2; all 51 bundled codes.
"pre-pass s" is the time printed by the binary (from the pre-pass start); the process wall to the summary adds parse,
dual-map and symmetry detection (<= 0.1 s except the largest codes).

### 3.1 Stop rule: four settings (`S0/plateau_table.md`; full per-code tables `S0/finder_table.md`)

| Setting | U0 = d (codes with a numeric stem) | max pre-pass s on tiers 1-4 | Tier 5 open codes (examples, seeds 0-2) |
|---|---:|---:|---|
| plateau 64, S 600 (`7bce6b0`, initial) | 96/102 (TN_252 22/23/22, LP_1428 26, LP_1768 24/32) | 0.14 | BB_756 40/42/38, TN_504 53/55/60, BB_864 60/58/72 |
| plateau 256, S 60 | 99/102 (TN_252 22/22, LP_1768 24) | 0.11 | BB_756 40/38/38, TN_504 53/55/59 |
| **plateau 1000, S 60 (chosen)** | **102/102** | **0.29** | BB_756 34/34/34, TN_288 24/25/24, TN_360 24, TN_504 45/46/42, BB_864 52/58/48, BB_1080 70/80/74 |
| plateau 4000, S 60 | 102/102 | 0.38 (TN_200 0.35) | BB_756 34, TN_648_10 33/34/56, BB_864 42/50/48, BB_1080 70/68/64 (LP_1428, LP_1768, BB_1080 hit the 60 s cap) |

Trajectories without any early stop (`-ub-pre-hits=0 -ub-pre-plateau=10^9`, 120 s, seeds 0-1, `S0/server/traj120.jsonl`):
every tier 1-4 code reaches d within 25 iterations per half (< 0.01 s); TN_252 needs 236/284 iterations (0.08 s),
TN_288 415/1519, LP_1768 286/492 (20-23 s), BB_756 504/683 (2-3 s); improvements on the large open TN/BB codes continue
for 10^4-10^5 iterations. A plateau of 1000 iterations covers every known-d code; the re-hit rule stops the BB/LP codes
early (many minimum-weight words), the plateau stops the TN codes (TN_250: 2 000 iterations, 0.26 s).

### 3.2 Final rule (plateau 1000, hits 16, S 60): per-code pre-pass (U0 per seed, median pre-pass seconds)

| Tier | codes |
|---:|---|
| 0 | all 13 codes: U0 = d, <= 0.01 s |
| 1 | LP_340_56_8 8, 0.01 s |
| 2 | TN_108 12, 0.00; BB_144_14_14 14, 0.00; GB_144_12_12 12, 0.02; TN_200 10, 0.09; LP_442 10, 0.02; LP_544 12, 0.04 |
| 3 | TN_144 13, 0.02; BB_288 18, 0.09 |
| 4 | TN_250 15, 0.26; LP_714 16, 0.10 |
| 5 (known d) | TN_180 17, 0.08; TN_216 18, 0.03; TN_252 21, 0.36; BB_360 24, 0.08; LP_1020 16, 1.25; LP_1054 20, 3.06; LP_1122 20, 3.38; LP_1428 24, 24.9; LP_1768 22, 54.8 (one seed at the 60 s cap); LP_2610 16, 14.6 |
| 5 (open) | TN_288 24/25/24 (0.54 s); TN_324 25/26/25 (0.56); TN_360 24 (1.35); TN_396 27/27/26 (1.14); TN_432 32/31/32 (3.2); TN_468 33/30/29 (10.9); TN_496 34/32/32 (6.5); TN_504 45/46/42 (2.6); TN_540 46/40/52 (2.0); TN_576 54/54/61 (2.3); TN_612 62/65/62 (2.7); TN_648_10 65/56/56 (2.9); TN_648_14 40/40/36 (2.7); TN_684 31/29/31 (9.0); BB_756 34 (7.2); BB_864 52/58/48 (6.3); BB_1080 70/80/74 (14.8) |

Compared with GH-140's 600 s finder-only runs, the pre-pass reaches the same value on every known-d code and on BB_756
(34), TN_288-TN_396 within 0-1, but stays above GH-140's 600 s values on the largest open codes (TN_504-648: 40-65 vs
28-47; BB_864 48-58 vs 40-44; BB_1080 70-80 vs 56-64): those need minutes of finder time, which a pre-pass bounded by
S = 60 s and a plateau rule does not spend. For the MaxSAT search these differences do not matter (its refutations
reach only lb 17-18 on those codes within 6 h); they only change the reported ub.

### 3.3 Default S

The pre-pass ends by its own rule on every code except LP_1768 (one seed at 60 s); on tiers 1-4 it costs at most
0.29 s. S is a safety cap for very large inputs: S = 60 s is at most 0.3 % of a Tier 5 run and is reached only for
n >= 1 768 in our set. Recommended: **S = 60 s (`-ub-pre=on`) with plateau 1000 and 16 re-hits**. A smaller cap
(1-5 s) gives the same U0 on every tier 1-4 code and on every known-d Tier 5 code except LP_1768 (24 instead of 22 at
S = 5 s), and worse ub on the large open codes.

## 4. S1 Tier 1-4 panel (yfclab2, main `8eb047b` vs `-ub-pre=60`, seeds 0-4, both modes)

Runner `S1/runner/s1_queue.py` (GH-140 queue with a per-job binary), cores 0-3, 5-19, 21-27, 29, 80-92, one pinned core
per process, 4 GB cap, limits tier1-3 1800 s, tier4 5000 s; the two arms of a (code, mode, seed) are adjacent in the
queue and run concurrently. Ratio = median(pre) / median(main) over the 5 seeds. "pre first d_ub" = wall time of the
first `c d_ub` line of the pre arm (process start + pre-pass). Full table: `S1/panel_table.md`; raw:
`S1/server/panel.jsonl`, logs `S1/server/panel_logs.tar.gz`.

| Tier | Code | Mode | main median s (seed range) | pre median s (seed range) | ratio | pre first d_ub s |
|---:|---|---|---|---|---:|---:|
| 1 | LP_340_56_8 | no-card | 2.62 (1.85-3.09) | 2.40 (1.75-2.90) | 0.917 | 0.07 |
| 1 | LP_340_56_8 | card-mto | 2.29 (2.21-3.11) | 2.08 (1.98-2.89) | 0.908 | 0.07 |
| 2 | BB_144_14_14 | no-card | 23.74 (20.15-51.35) | 16.67 (16.15-17.13) | 0.702 | 0.06 |
| 2 | BB_144_14_14 | card-mto | 27.65 (20.47-46.53) | 16.52 (15.92-17.16) | 0.598 | 0.06 |
| 2 | GB_144_12_12 | no-card | 70.27 (20.53-81.31) | 1.31 (1.25-1.34) | **0.019** | 0.08 |
| 2 | GB_144_12_12 | card-mto | 50.80 (39.27-107.71) | 1.33 (1.30-1.71) | **0.026** | 0.07 |
| 2 | LP_442_68_10 | no-card | 10.81 (7.38-12.28) | 5.61 (3.68-7.13) | 0.519 | 0.09 |
| 2 | LP_442_68_10 | card-mto | 9.46 (6.71-9.67) | 5.64 (4.80-8.29) | 0.597 | 0.08 |
| 2 | LP_544_80_12 | no-card | 74.89 (66.74-92.46) | 30.22 (18.89-36.36) | 0.403 | 0.14 |
| 2 | LP_544_80_12 | card-mto | 67.29 (55.86-87.99) | 24.48 (18.73-41.18) | 0.364 | 0.11 |
| 2 | TN_108_2_12 | no-card | 25.74 (23.04-34.47) | 25.27 (22.56-28.11) | 0.981 | 0.06 |
| 2 | TN_108_2_12 | card-mto | 30.71 (23.81-42.22) | 24.72 (23.01-29.81) | 0.805 | 0.05 |
| 2 | TN_200_10_10 | no-card | 32.44 (25.27-149.39) | 15.10 (14.74-20.13) | 0.465 | 0.15 |
| 2 | TN_200_10_10 | card-mto | 29.90 (21.30-54.67) | 14.76 (13.99-16.58) | 0.494 | 0.15 |
| 3 | BB_288_12_18 | no-card | 57.25 (51.85-64.75) | 57.46 (49.48-65.19) | 1.004 | 0.17 |
| 3 | BB_288_12_18 | card-mto | 58.47 (53.34-72.25) | 58.08 (53.95-71.56) | 0.993 | 0.16 |
| 3 | TN_144_2_13 | no-card | 336.86 (303.88-1087.62) | 87.00 (82.25-102.91) | **0.258** | 0.08 |
| 3 | TN_144_2_13 | card-mto | 480.98 (236.67-739.67) | 82.50 (77.86-98.48) | **0.172** | 0.08 |
| 4 | LP_714_100_16 | no-card | 699.47 (612.45-952.76) | 808.97 (611.98-882.99) | 1.157 | 0.14 |
| 4 | LP_714_100_16 | card-mto | 780.99 (616.41-911.85) | 688.84 (585.91-839.77) | 0.882 | 0.14 |
| 4 | TN_250_10_15 | no-card | 2336.55 (2109.53-4317.26) | 1716.57 (1453.54-2077.15) | **0.735** | 0.27 |
| 4 | TN_250_10_15 | card-mto | 2351.79 (1994.24-3330.99) | 1499.02 (1486.74-1557.78) | **0.637** | 0.26 |

| Tier | cells (codes x modes) | geomean no-card | geomean card-mto | pooled | max cell | cells > 1.25 |
|---:|---:|---:|---:|---:|---:|---:|
| 1 | 1 x 2 | **0.917** | **0.908** | 0.913 | 0.917 | 0 |
| 2 | 6 x 2 | **0.329** | **0.333** | 0.331 | 0.981 | 0 |
| 3 | 2 x 2 | **0.509** | **0.413** | 0.458 | 1.004 | 0 |
| 4 | 2 x 2 | **0.922** | **0.750** | 0.831 | 1.157 | 0 |

**LP_714 (watch cell).** Its run is two refutations at cap 14 (X and Z, no dual map); main additionally finds the
weight-16 solution at cap 16 first (11-15 s). With `-frontier-stats` (seed 3, no-card, `S1/server/lp714_s3_*.err`)
both arms show the same conflict counts on every shared probe (X cap 14: 384 791, Z cap 14: 295 240) and the pre arm
has two probes fewer (the cap-16 finds, 12 522 conflicts): the search work is identical apart from the skipped finds.
The wall differences come from core placement: the queue gives the pre arm of seeds 2 and 3 cores 6 and 8 in every
repetition (pre s3 883 s / 792 s on core 8 vs main 699 s / 657 s on core 7; in the spot check above the same work took
12.5 min on core 93 and 16 min on core 99; hyper-thread siblings 128 + c are shared with other users' unpinned jobs).
Two more repetitions of the 20 LP_714 jobs: same order (`S1/rep2_lp714_table.md`): no-card 1.205, card-mto 0.968;
arms swapped so that each arm runs on the other's core (`S1/rep3_lp714_swapped_table.md`): **no-card 1.000, card-mto
1.008**; pooled over the three repetitions (15 samples per arm): no-card 1.065, card-mto 0.941. LP_714 is neutral, as
expected for a refutation-only run.

Reading. The pre-pass costs 0.01-0.29 s and gives U0 = d on every panel run. It removes the find-and-descend part of
main's search: Phase 1's FOUND at the first doubling cap >= d (16 for d = 12-15) and the Phase 2a FOUND probes at
U - 1 that walk down to d, plus Phase 2b's re-find at cap U. Where those finds are expensive the gain is large
(GB_144_12_12 38-54x: main spends almost all of its time finding weight-12 logicals; TN_144 4-6x; TN_200, LP_544,
LP_442 2-3x; TN_250 1.4-1.6x); where they are cheap compared with the final refutation (TN_108 no-card, BB_288, LP_714)
the cell is neutral (0.98-1.00). The seed spread of the pre arm is much smaller than main's (GB_144_12_12 1.25-1.71 s
vs 20-108 s; TN_144 78-103 s vs 237-1088 s; TN_250 1454-2077 s vs 1994-4317 s): the solution-finding luck that drives
main's seed variance is gone.

## 5. S1 Tier 5 (yfclab2, 6 h, default seed, both modes, `-ub-pre=60` vs main `c914ef5`'s recorded Tier 5)

Cores 30-79 and 95-98 (one pinned core per run, 4 GB cap), all 54 cells at once, started 16:21 (concurrently with the
panel for its first ~85 min). Baseline: `optimization/baselines/raw/main-c914ef5/server_tier5_results.json` on branch
`baselines/main-c914ef5` (PR #142; same server, limits and rules; `c914ef5` and `8eb047b` have identical MaxSAT logs).
"ub events" = every `c d_ub` value with its time (the first is the pre-pass U0). Table: `S1/tier5_table.md`
(`S1/runner/analyze_tier5.py`); raw `S1/server/tier5.jsonl`, logs `S1/server/tier5_logs.tar.gz`.

| Code | Mode | main c914ef5 | lb | ub | **-ub-pre** | lb | ub | ub events (value@s) | lb events (value@s) | change |
|---|---|---|---:|---:|---|---:|---:|---|---|---|
| BB_360_12_24 | card-mto | TIMEOUT | 18 | 24 | TIMEOUT | 18 | 24 | 24@0.2, 24@21600.1 | 2@0, 4@0, 6@0, 10@0, 18@79, 18@21600 |  |
| BB_360_12_24 | no-card | TIMEOUT | 18 | 24 | TIMEOUT | 18 | 24 | 24@0.1, 24@21600.1 | 2@0, 4@0, 6@0, 10@0, 18@77, 18@21600 |  |
| BB_756_16_ge30 | card-mto | TIMEOUT | 18 | - | TIMEOUT | 18 | 34 | 34@8.3, 34@21600.1 | 2@8, 4@8, 6@8, 10@9, 18@686, 18@21600 | ub - -> 34 |
| BB_756_16_ge30 | no-card | TIMEOUT | 18 | - | TIMEOUT | 18 | 34 | 34@8.4, 34@21600.1 | 2@8, 4@8, 6@9, 10@9, 18@685, 18@21600 | ub - -> 34 |
| BB_864_4_ge30 | card-mto | TIMEOUT | 18 | - | TIMEOUT | 18 | 52 | 52@12.1, 52@21600.1 | 2@12, 4@12, 6@12, 10@12, 18@884, 18@21600 | ub - -> 52 |
| BB_864_4_ge30 | no-card | TIMEOUT | 18 | - | TIMEOUT | 18 | 52 | 52@10.3, 52@21600.1 | 2@10, 4@10, 6@10, 10@11, 18@885, 18@21600 | ub - -> 52 |
| BB_1080_4_ge30 | card-mto | TIMEOUT | 18 | - | TIMEOUT | 18 | 70 | 70@16.9, 70@21600.1 | 2@17, 4@17, 6@17, 10@17, 18@2528, 18@21600 | ub - -> 70 |
| BB_1080_4_ge30 | no-card | TIMEOUT | 18 | - | TIMEOUT | 18 | 70 | 70@16.8, 70@21600.1 | 2@17, 4@17, 6@17, 10@17, 18@2538, 18@21600 | ub - -> 70 |
| LP_1020_136_16 | card-mto | d=16 @ 1309 s | 16 | 16 | d=16 @ 1247 s | 16 | 16 | 16@1.1 | 2@1, 4@2, 6@3, 10@8, 15@1247, 16@1247 | 0.95x time |
| LP_1020_136_16 | no-card | d=16 @ 1331 s | 16 | 16 | d=16 @ 1254 s | 16 | 16 | 16@1.1 | 2@1, 4@2, 6@3, 10@11, 15@1254, 16@1254 | 0.94x time |
| LP_1054_140_20 | card-mto | TIMEOUT | 18 | 32 | TIMEOUT | 18 | 20 | 20@3.4, 20@21600.1 | 2@3, 4@4, 6@6, 10@14, 18@8912, 18@21600 | ub 32->20 |
| LP_1054_140_20 | no-card | TIMEOUT | 18 | 32 | TIMEOUT | 18 | 20 | 20@3.4, 20@21600.1 | 2@3, 4@4, 6@6, 10@17, 18@9724, 18@21600 | ub 32->20 |
| LP_1122_148_20 | card-mto | TIMEOUT | 18 | 32 | TIMEOUT | 18 | 20 | 20@6.6, 20@21600.1 | 2@7, 4@8, 6@9, 10@16, 18@5401, 18@21600 | ub 32->20 |
| LP_1122_148_20 | no-card | TIMEOUT | 18 | 32 | TIMEOUT | 18 | 20 | 20@5.1, 20@21600.1 | 2@5, 4@6, 6@7, 10@15, 18@5448, 18@21600 | ub 32->20 |
| LP_1428_184_24 | card-mto | TIMEOUT | 18 | 32 | TIMEOUT | 18 | 24 | 24@27.1, 24@21600.1 | 2@27, 4@28, 6@30, 10@37, 18@9022, 18@21600 | ub 32->24 |
| LP_1428_184_24 | no-card | TIMEOUT | 18 | 32 | TIMEOUT | 18 | 24 | 24@27.1, 24@21600.1 | 2@27, 4@28, 6@30, 10@37, 18@9019, 18@21600 | ub 32->24 |
| LP_1768_224_22 | card-mto | TIMEOUT | 18 | - | TIMEOUT | 18 | 22 | 22@60.2, 22@21600.1 | 2@60, 4@64, 6@70, 10@100, 18@13528, 18@21600 | ub - -> 22 |
| LP_1768_224_22 | no-card | TIMEOUT | 18 | - | TIMEOUT | 18 | 22 | 22@60.2, 22@21600.1 | 2@60, 4@66, 6@76, 10@118, 18@13975, 18@21600 | ub - -> 22 |
| LP_2610_744_16 | card-mto | TIMEOUT | 10 | 16 | TIMEOUT | 10 | 16 | 16@12.2, 16@21600.2 | 2@12, 4@29, 6@68, 10@379, 10@21600 |  |
| LP_2610_744_16 | no-card | TIMEOUT | 10 | 16 | TIMEOUT | 10 | 16 | 16@12.1, 16@21600.2 | 2@12, 4@29, 6@68, 10@376, 10@21600 |  |
| TN_180_2_17 | card-mto | TIMEOUT | 17 | 19 | d=17 @ 9885 s | 17 | 17 | 17@0.2 | 2@0, 3@0, 5@0, 9@3, 17@9885 | SOLVED; ub 19->17 |
| TN_180_2_17 | no-card | d=17 @ 11486 s | 17 | 17 | d=17 @ 5760 s | 17 | 17 | 17@0.1 | 2@0, 3@0, 5@0, 9@4, 17@5760 | 0.50x time |
| TN_216_4_18 | card-mto | d=18 @ 19298 s | 18 | 18 | d=18 @ 10066 s | 18 | 18 | 18@0.1 | 2@0, 3@0, 5@0, 9@5, 17@3457, 18@10066 | 0.52x time |
| TN_216_4_18 | no-card | d=18 @ 14842 s | 18 | 18 | d=18 @ 9161 s | 18 | 18 | 18@0.1 | 2@0, 3@0, 5@0, 9@5, 17@2879, 18@9161 | 0.62x time |
| TN_252_2_21 | card-mto | TIMEOUT | 17 | - | TIMEOUT | 17 | 21 | 21@0.4, 21@21600.1 | 2@0, 3@0, 5@1, 9@5, 17@7470, 17@21600 | ub - -> 21 |
| TN_252_2_21 | no-card | TIMEOUT | 17 | 28 | TIMEOUT | 17 | 21 | 21@0.4, 21@21600.1 | 2@0, 3@0, 5@1, 9@5, 17@8050, 17@21600 | ub 28->21 |
| TN_288_2_ge9 | card-mto | TIMEOUT | 9 | - | TIMEOUT | 9 | 24 | 24@0.7, 24@21600.1 | 2@1, 3@1, 5@1, 9@11, 9@21600 | ub - -> 24 |
| TN_288_2_ge9 | no-card | TIMEOUT | 9 | - | TIMEOUT | 9 | 24 | 24@0.7, 24@21600.1 | 2@1, 3@1, 5@1, 9@13, 9@21600 | ub - -> 24 |
| TN_324_4_ge9 | card-mto | TIMEOUT | 9 | - | TIMEOUT | 9 | 25 | 25@0.6, 25@21600.1 | 2@1, 3@1, 5@2, 9@15, 9@21600 | ub - -> 25 |
| TN_324_4_ge9 | no-card | TIMEOUT | 9 | - | TIMEOUT | 9 | 25 | 25@0.6, 25@21600.1 | 2@1, 3@1, 5@2, 9@13, 9@21600 | ub - -> 25 |
| TN_360_4_ge17 | card-mto | TIMEOUT | 17 | - | TIMEOUT | 17 | 24 | 24@1.1, 24@21600.1 | 2@1, 3@1, 5@2, 9@6, 17@4823, 17@21600 | ub - -> 24 |
| TN_360_4_ge17 | no-card | TIMEOUT | 17 | - | TIMEOUT | 17 | 24 | 24@1.1, 24@21600.1 | 2@1, 3@1, 5@1, 9@5, 17@4867, 17@21600 | ub - -> 24 |
| TN_396_4_ge17 | card-mto | TIMEOUT | 17 | - | TIMEOUT | 17 | 27 | 27@1.0, 27@21600.1 | 2@1, 3@1, 5@1, 9@8, 17@3855, 17@21600 | ub - -> 27 |
| TN_396_4_ge17 | no-card | TIMEOUT | 17 | - | TIMEOUT | 17 | 27 | 27@1.5, 27@21600.1 | 2@2, 3@2, 5@2, 9@12, 17@3880, 17@21600 | ub - -> 27 |
| TN_432_8_ge9 | card-mto | TIMEOUT | 9 | - | TIMEOUT | 9 | 32 | 32@5.9, 32@21600.1 | 2@6, 3@6, 5@7, 9@25, 9@21600 | ub - -> 32 |
| TN_432_8_ge9 | no-card | TIMEOUT | 9 | - | TIMEOUT | 9 | 32 | 32@5.8, 32@21600.1 | 2@6, 3@6, 5@8, 9@26, 9@21600 | ub - -> 32 |
| TN_468_4_ge17 | card-mto | TIMEOUT | 17 | - | TIMEOUT | 17 | 33 | 33@1.3, 33@21600.1 | 2@1, 3@1, 5@2, 9@10, 17@9211, 17@21600 | ub - -> 33 |
| TN_468_4_ge17 | no-card | TIMEOUT | 17 | - | TIMEOUT | 17 | 33 | 33@1.9, 33@21600.1 | 2@2, 3@2, 5@2, 9@11, 17@7790, 17@21600 | ub - -> 33 |
| TN_496_2_ge17 | card-mto | TIMEOUT | 17 | - | TIMEOUT | 17 | 34 | 34@2.9, 34@21600.1 | 2@3, 3@3, 5@3, 9@9, 17@11255, 17@21600 | ub - -> 34 |
| TN_496_2_ge17 | no-card | TIMEOUT | 17 | - | TIMEOUT | 17 | 34 | 34@2.9, 34@21600.1 | 2@3, 3@3, 5@3, 9@9, 17@10282, 17@21600 | ub - -> 34 |
| TN_504_2_ge17 | card-mto | TIMEOUT | 17 | - | TIMEOUT | 17 | 45 | 45@2.9, 45@21600.1 | 2@3, 3@3, 5@3, 9@13, 17@4942, 17@21600 | ub - -> 45 |
| TN_504_2_ge17 | no-card | TIMEOUT | 17 | - | TIMEOUT | 17 | 45 | 45@4.3, 45@21600.1 | 2@4, 3@5, 5@5, 9@15, 17@4989, 17@21600 | ub - -> 45 |
| TN_540_4_ge9 | card-mto | TIMEOUT | 9 | - | TIMEOUT | 9 | 46 | 46@2.4, 46@21600.1 | 2@2, 3@3, 5@6, 9@34, 9@21600 | ub - -> 46 |
| TN_540_4_ge9 | no-card | TIMEOUT | 9 | - | TIMEOUT | 9 | 46 | 46@2.5, 46@21600.1 | 2@3, 3@3, 5@6, 9@37, 9@21600 | ub - -> 46 |
| TN_576_2_ge9 | card-mto | TIMEOUT | 9 | - | TIMEOUT | 9 | 54 | 54@2.9, 54@21600.1 | 2@3, 3@3, 5@8, 9@38, 9@21600 | ub - -> 54 |
| TN_576_2_ge9 | no-card | TIMEOUT | 9 | - | TIMEOUT | 9 | 54 | 54@2.9, 54@21600.1 | 2@3, 3@3, 5@8, 9@43, 9@21600 | ub - -> 54 |
| TN_612_2_ge17 | card-mto | TIMEOUT | 17 | - | TIMEOUT | 17 | 62 | 62@3.2, 62@21600.1 | 2@3, 3@3, 5@4, 9@12, 17@4310, 17@21600 | ub - -> 62 |
| TN_612_2_ge17 | no-card | TIMEOUT | 17 | - | TIMEOUT | 17 | 62 | 62@3.2, 62@21600.1 | 2@3, 3@3, 5@4, 9@13, 17@4343, 17@21600 | ub - -> 62 |
| TN_648_10_9to52 | card-mto | TIMEOUT | 9 | - | TIMEOUT | 9 | 65 | 65@3.5, 65@21600.1 | 2@4, 3@4, 5@9, 9@65, 9@21600 | ub - -> 65 |
| TN_648_10_9to52 | no-card | TIMEOUT | 9 | - | TIMEOUT | 9 | 65 | 65@3.5, 65@21600.1 | 2@4, 3@4, 5@9, 9@58, 9@21600 | ub - -> 65 |
| TN_648_14_ge9 | card-mto | TIMEOUT | 9 | - | TIMEOUT | 9 | 40 | 40@3.2, 40@21600.1 | 2@3, 3@3, 5@11, 9@63, 9@21600 | ub - -> 40 |
| TN_648_14_ge9 | no-card | TIMEOUT | 9 | - | TIMEOUT | 9 | 40 | 40@3.2, 40@21600.1 | 2@3, 3@4, 5@9, 9@74, 9@21600 | ub - -> 40 |
| TN_684_2_ge9 | card-mto | TIMEOUT | 9 | - | TIMEOUT | 9 | 31 | 31@10.4, 31@21600.1 | 2@10, 3@11, 5@11, 9@26, 9@21600 | ub - -> 31 |
| TN_684_2_ge9 | no-card | TIMEOUT | 9 | - | TIMEOUT | 9 | 31 | 31@14.6, 31@21600.1 | 2@15, 3@15, 5@15, 9@36, 9@21600 | ub - -> 31 |

solved cells: main c914ef5 5, -ub-pre 6 (of 54); final lb higher on 0, lower on 0; ub where main had none: 37; ub lower than main: 8; science problems: []

Reading:
- **Lower bounds are unchanged.** Phase 1's probes at caps <= 16 are the same instances with the same seed in both
  runs, so every unsolved cell ends at main's lb (17/18 from the NONE at cap 16; 9 on the TN ge9 stems, where the cap-16
  probe does not finish; 10 on LP_2610). The time to that lb is 0.72-1.05x of main's (geomean 0.89 over the 30 cells
  with lb > 10); for identical probes this reflects the session conditions (main's record ran its 54 Tier 5 cells together with
  its tier 0-4 panel), not the change.
- **What changes after the lb.** On the codes with lb 17/18, main spends the rest of the 6 h in the Phase 1 probe at
  cap 32 (find any logical of weight <= 32), which returned only on BB_360 (24; main then refutes cap 22 as the
  pre-pass run does), LP_1054/1122/1428 (32) and TN_252 no-card (28); with the pre-pass the remaining time goes into
  the refutation at U0 - 1 (e.g. LP_1054 cap 18, TN_252 cap 20, TN_360 cap 23), which finishes within 6 h only on
  TN_180, TN_216 and LP_1020. On the TN ge9 stems (lb 9) both runs spend the remaining time in the same cap-16 Phase 1
  probe, and on LP_2610 both end in the refutation at cap 14. Every cell now reports a verified upper bound (main: 37
  of its 49 unsolved cells without one).
- **Solved cells.** TN_180 (U0 = 17): Phase 1 stops after cap 8 (lb 9 at 3-4 s) and Phase 2a probes cap 16 directly;
  its NONE at 5 760 s (no-card) / 9 885 s (card-mto) proves d = 17. Main reached the same lb 17 (7 300 / 11 937 s) and
  then had to find a solution at cap 32 and walk down (solved at 11 486 s no-card, timeout with ub 19 card-mto).
  TN_216 (U0 = 18): Phase 1 up to cap 16 (lb 17 at 2 879 / 3 457 s), then the single refutation at cap 17 (NONE at
  9 161 / 10 066 s); main first found and descended from cap 32 (14 842 / 19 298 s). LP_1020 (U0 = 16): Phase 2a's
  refutation at cap 14 ends at 1 254 / 1 247 s; main found the weight-16 solution at 35 s in Phase 1 before the same
  refutation (1 331 / 1 309 s).
- **Upper-bound quality.** U0 = d on all ten Tier 5 codes with a known d, in both modes (LP_1428 24 at 27 s, LP_1768 22
  at 60 s). On the open codes the pre-pass values are 24-70 (S0, 3.2); BB_756 34 equals the value of Bravyi et al. /
  Webster et al.; GH-140's CC runs report lower values on BB_864/1080 and TN_504-648 after hours of time-sliced finder
  time.

## 6. Gate verdicts

| Gate | Criterion | Result | Verdict |
|---|---|---|---|
| Tier 0 (correctness / smoke) | tests pass; default path byte-identical to main; witnesses verified | Part F + 1500/600 run pass, mutants 1/2 as required, 283 flag checks, 5 x 28/28 identical logs, Mac tier0-2 40/40; tier0 codes solve in <= 0.2 s on the Mac | PASS |
| Tier 1 (5 seeds) | geomean < 1 per mode, no cell > 1.25 | 0.917 / 0.908 | PASS |
| Tier 2 | same | 0.329 / 0.333, max 0.981 | PASS |
| Tier 3 | same | 0.509 / 0.413, max 1.004 | PASS |
| Tier 4 | same | 0.922 / 0.750, max 1.157 (LP_714 no-card: identical work, 1.000 with the cores swapped) | PASS (watch LP_714) |
| Tier 5 (6 h) | no cell worse; bounds consistent | 6 vs 5 solved cells (TN_180 card-mto new), solved cells 0.50-0.95x, final lb equal on every unsolved cell (none lower), ub on every cell (37 new, 8 lower), 0 science problems | PASS |

## 7. Recommendation

1. **Adopt `-ub-pre=on` as the MaxSAT default** (S = 60 s, plateau 1000, 16 re-hits; the evaluated setting). It passes
   every gate by the coordinator criteria: Tier 1-4 geomeans 0.33-0.92 per mode with no cell > 1.25 (largest gains
   GB_144_12_12 38-54x, TN_144 4-6x, TN_200 / LP_544 / LP_442 2-3x, TN_250 1.4-1.6x), and Tier 5 gains a solved cell
   (TN_180 card-mto), solves TN_180 / TN_216 in 0.50-0.62x of main's time, keeps every lower bound and reports a
   verified upper bound on all 54 cells. The pre-pass costs <= 0.3 s on tiers 1-4. In this branch the code default
   is still `off` (the default path is byte-identical to main, as S0 required); adoption is a one-line change
   (`g_ub_pre = UBPRE_ON_SECONDS`), after which main's tier0-5 baselines must be re-recorded (PI rule 2026-10-13) and
   the tier placement re-checked (GB_144_12_12, LP_442, TN_200 and TN_144 would move down).
2. **Watch cell:** LP_714 no-card (1.157 in the panel; identical conflict counts in both arms, 1.000 with the cores
   swapped). It is a refutation-only run on which the pre-pass can save only the 11-15 s cap-16 find.
3. **Default S.** 60 s; on our set the cap is reached only by LP_1768 (n = 1 768). The effective pre-pass time is set
   by the iteration rule (<= 0.3 s on tiers 1-4, <= 25 s on all known-d Tier 5 codes except LP_1768).
4. **Next rounds (from these numbers).** On Tier 5 the MaxSAT path now ends every run in the refutation at U0 - 1;
   its lower bounds stay at the doubling cap 16 (lb 17/18) on all open codes. The finder side is the weak part only for
   the ub of n >= 500 codes (pre-pass 40-70 vs GH-140's 600 s values 28-56): proposal 3 of the issue (a Stern/Dumer
   collision step in the finder) would help both engines. Scientific semantics changed: no. PI action required: yes
   (adoption decision for the MaxSAT default).

## 8. Reproduction

Build: `make clean && make CXX="c++ -Wno-reserved-user-defined-literal"` (Mac) / `make -j8` (yfclab2). Tests:
`make test-cc`, `make test-cc-flags`, `./build/test_cc_engine 1500 600`. Identity: `python3 -I S0/ident.py MAIN CAND
OUTDIR CORE [EXTRA]` from a worktree root (CORE = `mac` on the Mac). S0: `python3 -I S0/finder_runs.py --bin BIN
--cpus 30-41,43-47,49-57,59-67,69-79 --budget 600 --out OUT` (initial rule, `7bce6b0`); trajectories with
`--budget 120 --seeds 0,1 --tiers 1,2,3,4,5 --extra "-ub-pre-hits=0 -ub-pre-plateau=1000000000"`; the plateau sweep
with `--budget 60 --extra=-ub-pre-plateau=P` for P = 256, 1000, 4000 (`e4e73f0`); tables `S0/analyze_finder.py`,
`S0/compare_plateaus.py`; logs `S0/server/s0_logs.tar.gz`. S1 (binary `6d2b7a1`, frozen as
`frozen/server-gh144-6d2b7a1`; main as `frozen/server-main-8eb047b`): `S1/runner/make_jobs.py MAIN CAND 60`, then
`s1_queue.py --cpus 0-3,5-19,21-27,29,80-92 --jobs jobs_panel.jsonl` and `--cpus 30-79,95-98 --jobs jobs_tier5.jsonl`;
LP_714 repetitions `jobs_rep2_lp714.jsonl` and `jobs_rep3_lp714_swapped.jsonl` on cores 0-3,5-19,21. Every server
process: `taskset -c CORE prlimit --as=4294967296 -- BIN ARGS`. Summaries: `S1/runner/analyze_panel.py`,
`S1/runner/analyze_tier5.py CAND MAIN_TIER5.json`, `S1/runner/check_anytime.py`. No timing ran on the Mac (Mac: builds,
tests, identity, the tier0-2 answer check).
