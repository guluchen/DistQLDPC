# GH-130: frontier branching with a structural per-half selector (`-frontier=auto`)

- Date: 2026-10-17/18. Issue #130 (hub #15). Baseline: main **abd1770** (origin/main; merging it into the branch was a no-op: the five renamed tier5 stems BB_360_12_24, TN_252_2_21, LP_1054_140_20, LP_1428_184_24, LP_1768_224_22 are already in abd1770). Branch `experiment/gh-130-frontier-auto`, started from GH-129's 090191d (`-frontier=off|on|postsol|presol`); candidate code commit **0976153** (report and raw data committed on top).
- Selected proposal (1 of 3 in #130): enable GH-129's frontier rule per CSS half from a structural property of the half's parity matrix, computed before search, never from the code name.
- Prior records read: GH-129 `REPORT.md` and its S0 raw logs (per-probe `-frontier-stats`), GH-124 S1 (CC engine Tier 5), `docs/OPTIMIZATION_LOOP_POLICY.md`.
- No PR, no merge, no external solver. Mac: Apple M6, at most 6 concurrent correctness processes and strictly serial timing, 2 GB RSS cap per process, `caffeinate -i -s`. yfclab2: every process `taskset -c <core> prlimit --as=4294967296 --`, one per physical core: cores 0-39 (panel), 64-81 (Tier 5), 100-107 (identity sample); another user ran ~25 unpinned jobs throughout (load 30-80 of 256 threads). Nothing is left running on either host.

## Summary

- **Selector (S0).** Of eleven candidate properties of a half's parity matrix, only four separate the halves where GH-129's rule helped (all BB/GB/LP) from those where it hurt (TN) on tiers 1-5, and only one with a wide margin: **Tanner-graph 4-cycles per row** (C4/row = sum over row pairs of C(|r ∩ s|, 2) / rows). BB/GB/LP halves: 0-1.6 (max LP_238_44_6); TN halves: 6.15-25.5 (min TN_648_14_ge9); **margin 3.84x**. `-frontier=auto` turns the rule on for a half iff C4/row < 3 (1.9x / 2.05x from the two sides). Others: max row weight (8 vs 9, margin 1.12), max qubit degree (5 vs 7, 1.40), mean adjacent-row overlap (1.17 vs 1.28, 1.09); row weight, mean degree, min degree (GB_144_12_12 also has degree-2 qubits), odd-row candidate counts and redundancy do not separate.
- **Mechanism (partly supported).** Measured: with the rule, MaxCDCL's lookahead does 1.4-1.9x more propagations per conflict in *every* family (BB 486 -> 736, LP 1656 -> 3110, GB 475 -> 712, TN_108 391 -> 532, TN_200 722 -> 1046), but refutation conflicts fall 2.4-6.6x on BB/GB/LP and only 0.76x / 1.00x on TN_108 / TN_200. Hypothesis: overlapping rows (4-cycles) let a repair qubit turn rows the cluster already touches even again, so the odd-row frontier stops growing with the cluster and stops shortening refutations. **Causal check negative:** adding redundant rows that raise C4/row to 4-13 on BB_144_14_14 / LP_442_68_10 / GB_144_12_12 left the rule 2-5x faster than off (only GB weakened, 0.25 -> 0.48). So C4/row is a clean marker of TN's overlapping local structure, not a demonstrated cause, and it depends on the matrix presentation (§1.2).
- **Implementation:** `-frontier=auto` per half, decision printed with `-v`; default off; no flag byte-identical to main (Mac 56/56 `-v` logs). The selector picks on for every BB/GB/LP code and off for every TN code of tiers 1-5, so auto-off cells run main's search unchanged (server: 22/22 per-probe identical) and auto-on cells run GH-129's `on` search (8/8 identical).
- **Correctness: no mismatch.** Tier0-3 x 2 modes (44 runs, `-frontier-check` on tier0-1), 54 random codes x 2 modes vs `-engine=cc` (108 runs, 80 halves on / 136 off, 0 mismatches), 180 panel runs (177 correct, 3 main timeouts), 18 Tier 5 runs (all bounds consistent), 136 Mac quick-check runs, 60 server identity runs.
- **S1 seed panel (yfclab2, 5 seeds, seed-median ratio cand / main, auto-off cells = 1 by identity):** Tier 1 **0.600 / 0.381** (no-card / card-mto), Tier 2 **0.488 / 0.523**, Tier 3 **0.465 / 0.338**, Tier 4 **1 / 1** (TN_250 only: identical search). No cell > 1; worst auto-on cell LP_238_44_6 card-mto 0.896; auto-on cells 0.137-0.896.
- **Tier 5 (6 h, default seed):** auto-on cells (BB, LP; re-run) vs main: never worse; LP_714 / LP_1020 solved in 2061-2685 s (main 5321-8752 s, 2.3-3.9x sooner); new ub 32 on LP_1054 and LP_1428 (main none); lb 17 on LP_1768 (main 9); time to main's final lb geomean **0.487** over 16 cells (BB 0.34-0.89, LP 0.25-0.51). Auto-off TN cells = main (identical search): TN_180 no-card and TN_216 both modes stay solved (GH-129 `on` lost them). Solved cells: auto 7 = main's 7 (same cells), GH-129 4, CC 16. Against CC the MaxSAT path stays far behind on Tier 5 (CC solves BB_360, LP_1054/1428/1768, TN_180/216 in 2-2884 s and reaches lb 20-27 on the open codes vs 9-17).
- **Mac tier0-2 quick check:** geomean 0.868 / 0.926, 0.502 / 0.435, 0.430 / 0.487; all answers correct.
- **Gate verdicts:** Tier 0 PASS, Tier 1 PASS, Tier 2 PASS, Tier 3 PASS, Tier 4 neutral (identical to main; no regression, no gain), Tier 5 PASS (no cell worse than main, 6 cells better, LP 2-4x faster).
- **Recommendation:** `-frontier=auto` is the first frontier variant that passes every gate; it is a candidate for adoption as the MaxSAT path's default, with two caveats for the PI: the selector separates by a marker whose causal role is not demonstrated (it is equivalent to "on for BB/GB/LP, off for TN" on all 49 codes), and it is presentation-dependent (redundant rows can switch a helpful rule off). It leaves TN exactly at main, and the CC engine remains far ahead on Tier 5.

## 1. The selector

### 1.1 Candidate properties

Each half's parity matrix: Hz for the X half, Hx for the Z half. Labels are used only for this evaluation (the selector never sees names): GH-129's rule helped on every BB/GB/LP half (tier1-3 seed-median ratios 0.16-0.89; Tier 5 BB/LP equal or faster) and hurt on every TN half of tiers 3-5 (TN_144 1.04/1.12, TN_200 1.53/1.30, TN_250 1.67/1.23; TN tier5 1.0-2.9x later to main's lb, TN_180/TN_216 lost); TN_108 (tier2) was neutral to helped (0.97/0.87); tier0 codes are too small to label (every run < 0.4 s). Ranges and margins over the 78 halves of tiers 1-5 (the same with tier0 added: `S0/separation.md`; per-code table `S0/half_structure_table.md`; raw values `S0/half_structure.json`; tools `S0/tools/half_structure.py`, `S0/tools/separation.py`):

| property | help (BB/GB/LP) range | hurt (TN) range | separates? | margin (hurt min / help max) |
|---|---|---|---|---:|
| mean row weight | 6-8 | 8-10 | no | - |
| max row weight | 6-8 | 9-16 | yes | 1.12 |
| mean qubit degree | 3-4 | 3.84-5 | no | - |
| min qubit degree | 2-4 | 2-2 | no | - |
| max qubit degree | 3-5 | 7-9 | yes | 1.40 |
| mean row neighbours | 12-24 | 19.33-29.48 | no | - |
| mean overlap of adjacent rows | 1-1.17 | 1.281-1.848 | yes | 1.09 |
| share of adjacent row pairs with overlap >= 2 | 0.0-0.17 | 0.103-0.554 | no | - |
| Tanner 4-cycles per row | 0.0-1.6 | 6.15-25.5 | yes | 3.84 |
| odd-row repair candidates per qubit (sum_r (w_r - 1)) | 15-28 | 27.84-51 | no | - |
| row redundancy (m - rank) / m | 0.0-0.097 | 0.0-0.022 | no | - |

Selector: **frontier on for a half iff C4/row < 3**, where C4/row = (1/m) * sum over pairs of rows r, s of C(|r ∩ s|, 2) and m is the number of nonzero rows (each term counts the qubit pairs two rows share, i.e. the Tanner-graph 4-cycles through that row pair). 3 is the geometric midpoint (3.14) of 1.6 and 6.15, rounded down. Values (X / Z): BB all 0 / 0; GB_144_12_12 0.91 / 0.91; LP_238 1.60, LP_340 1.07, all other LP 0; TN_108 10.28 / 12.17, TN_144 7.89 / 7.89, TN_200 9.25 / 8.67, TN_250 8.50 / 8.50, TN tier5 6.15-11.9 except TN_496_2_ge17 25.5. In tier0 auto is off for LP_34_20_2 (16.0), LP_136_32_4 (3.2), TN_36_8_4 (22.3) and TN_72_8_8 (12.1 / 14.8) and on for the weight-6 TN codes TN_36_8_3, TN_54_11_4, TN_72_14_4 (1.5-2.5) and for BB/GB tier0 codes.

### 1.2 Mechanism: what the data support

Hypothesis. The rule grows a cluster the way CC does, repairing an odd row with one of its unassigned qubits; the odd-row frontier acts as a lower-bound signal (each odd row needs another qubit), so with a frontier that grows with the cluster, refutations reach the weight cap after few, forced decisions. When rows overlap in two or more qubits, a repair qubit often lies in rows the cluster already touches and turns them even again; the frontier no longer grows with the cluster, many repair orders lead to the same cluster, and the forced positive decisions stop shortening refutations while the rule's overhead per conflict remains.

Evidence 1, GH-129 per-probe data (`S0/gh129_probe_classes.txt`, matched probes of the Mac S0 logs, conflicts on / off, card-mto / no-card): refutation feasibility probes (cap < d) BB_144_14_14 0.27 / 0.29, BB_288 0.33 / 0.31, LP_544 0.35 / 0.30, GB_144_12_12 0.20 / 0.37; TN_108 0.41 / 0.76, TN_200 0.63 / 0.75, TN_144 0.36 / 0.38 at its small caps but optimize probes (the final proof) 0.50 / 1.62, TN_200 optimize 0.94 / 1.10, TN_250 Z cap 14 refutation 0.85 (GH-129 §2.3), against BB_288 0.28, LP_544 0.29 / 0.33, GB 0.41. Ratios of wall to conflicts show that the time per conflict rises with the rule in every family (LP_442 1.7, LP_544 1.3-1.5, BB_288 1.1-1.2, TN_200 1.6).

Evidence 2, MaxCDCL's own lookahead counters (new, `S0/lookahead_per_conflict.md`; Mac, no-card, default seed, `-v`, summed over the NONE probes and the final optimize proof):

| code (C4/row) | refutation conflicts on/off | lookahead propagations per conflict off -> on | whole-run wall on/off |
|---|---:|---:|---:|
| BB_144_14_14 (0) | 0.29 | 486 -> 736 (1.51x) | 0.23 |
| LP_442_68_10 (0) | 0.15 | 1656 -> 3110 (1.88x) | 0.34 |
| GB_144_12_12 (0.91) | 0.41 | 475 -> 712 (1.50x) | 0.43 |
| TN_108_2_12 (10-12) | 0.76 | 391 -> 532 (1.36x) | 0.84 |
| TN_200_10_10 (8.7-9.3) | 1.00 | 722 -> 1046 (1.45x) | 1.38 |

So the TN loss is quantified: the lookahead cost per conflict rises 1.36-1.88x for every family, and on BB/GB/LP it is paid back by 2.4-6.6x fewer refutation conflicts, on TN not (0.76x, 1.00x).

Evidence 3, causal check (negative; `S0/augmentation_4cycles.md`, tools `augment.py`, `aug_sum.py`). If 4-cycles cause the loss, adding them to the rows the rule sees should weaken it where it now helps. I appended redundant rows (sums of two rows sharing a qubit; the row spaces, the code, its distance and every half's solution set are unchanged) to BB_144_14_14, LP_442_68_10 and GB_144_12_12 and ran on / off with seeds 0-2 (Mac, no-card, medians):

| code | parity rows (orig, or +10 % / +25 % redundant sum rows) | C4/row (X/Z) | off: median wall s / conflicts | on: median wall s / conflicts | on/off wall | on/off conflicts |
|---|---|---|---|---|---:|---:|
| BB_144_14_14 | orig | 0 / 0 | 35.4 / 630364 | 9.0 / 156510 | 0.255 | 0.248 |
| BB_144_14_14 | a0.1 | 4.86 / 4.67 | 42.7 / 708882 | 8.7 / 148419 | 0.203 | 0.209 |
| BB_144_14_14 | a0.25 | 13.06 / 11.46 | 36.3 / 588015 | 12.0 / 175592 | 0.329 | 0.299 |
| LP_442_68_10 | orig | 0 / 0 | 35.4 / 258524 | 13.8 / 55736 | 0.390 | 0.216 |
| LP_442_68_10 | a0.1 | 4.09 / 4.70 | 35.1 / 232028 | 17.0 / 60572 | 0.485 | 0.261 |
| LP_442_68_10 | a0.25 | 9.85 / 9.95 | 34.6 / 238736 | 15.9 / 50516 | 0.460 | 0.212 |
| GB_144_12_12 | orig | 0.91 / 0.91 | 83.2 / 1253214 | 20.9 / 334701 | 0.251 | 0.267 |
| GB_144_12_12 | a0.1 | 6.40 / 6.04 | 51.5 / 774263 | 18.0 / 258098 | 0.350 | 0.333 |
| GB_144_12_12 | a0.25 | 11.22 / 11.74 | 50.4 / 763458 | 24.0 / 337760 | 0.476 | 0.442 |

The rule stays 2-5x faster than off at TN-like 4-cycle counts; only GB weakens markedly (on/off 0.25 -> 0.35 -> 0.48). The added rows are heavy (weight 2w-2) and the rule repairs the odd row with the fewest unassigned qubits, so it rarely follows them; the check therefore cannot create TN-like overlap among the light rows the rule actually uses, but it does show that **the 4-cycle count as such does not cause the regression**. Conclusion: C4/row is a clean, simple marker of TN's overlapping local structure (quantum-Tanner local codes: adjacent rows share 2-8 qubits), with a mechanism that is plausible and consistent with evidence 1-2 but **not demonstrated**; the separation is also confounded with family (TN is the only 4-cycle-rich family above tier 0, so any TN-specific property separates too, e.g. max qubit degree). Practical consequence: the decision depends on the matrix presentation. A BB/LP/GB code supplied with redundant rows would get C4/row > 3 and lose a 2-5x gain (the augmented matrices above are such false negatives); a TN code supplied in another basis could flip either way. The benchmark matrices have 0-10 % redundant rows and every decision is at least 1.9x from the threshold.

Because one simple property separates cleanly with a wide margin, the round used it; proposal 2 (presol-only in probes) was not needed as a fallback.

## 2. Implementation (S0)

`src/core/distqldpc.cc` only (+60 / -6, commit 0976153); `Solver.cc/.h` unchanged from GH-129 (CRLF preserved).

- `-frontier=auto` (mode 4). In `min_distance_css_interleaved()`, before any probe, each existing half computes `tanner_c4_per_row(*hs[k].H)` (per row, a counter over the rows reached through its qubits; O(sum over rows of w x degree)) and stores `hs[k].frontier = c4 < 3.0 ? 1 (on) : 0 (off)`. `run_css_half()` uses `h.frontier` instead of the global mode; for off / on / postsol / presol `h.frontier` equals the global mode, so these modes are unchanged. With `-v`: `c frontier auto X: 9.25 Tanner 4-cycles per row (threshold 3.00) -> off`.
- Default (no flag) stays off, main's path. `-help` documents `auto`.

## 3. Correctness

| Check | Runs | Result |
|---|---:|---|
| Default-path identity, Mac: no flag and `-frontier=off` vs frozen main abd1770, `-v -cpu-lim=300`, 14 tier0+tier1 codes x 2 modes (raw `cmp` of full logs) | 84 | **56/56 byte-identical** (`S0/identity_mac_vs_main_abd1770.txt`) |
| Mac tier0-3 x 2 modes, `-frontier=auto -v` (tier0+1 also `-frontier-check`), limit 1800 s | 44 | all answers = stem d, 0 check failures, max 174 s, max RSS 354 MB; decisions printed for every half (tier0 24 on / 16 off, tier1 16 / 0, tier2 8 / 4, tier3 12 / 8) |
| 54 random CSS codes (24 from GH-129's `gen_random_codes.py`, n 10-52; 30 from `gen_random_codes2.py`: toric-like HGPs, column-weight-3 HGPs, tier0 codes, all qubit-permuted and row-mixed; seed 130) x {auto no-card, auto card-mto} with `-frontier-check`, against `-engine=cc` | 162 | **0 mismatches**, 0 check failures; auto chose on for 80 and off for 136 halves, so both branches were exercised (`S0/correctness_mac.txt`) |
| Server identity sample (`ident_server.py`, `ident_compare.py`): auto vs main's path on auto-off cells (TN_108, TN_144, TN_200 seeds 0-1 both modes; TN_250, TN_180, TN_216, TN_504, TN_684 seed 0 both modes, 900 s cap: completed probes compared), auto vs `-frontier=on` on auto-on cells (BB_144_14_14, LP_442, GB_144_12_12, LP_238, seed 0, both modes) | 60 | **30/30 pairs identical** per-probe conflicts / decisions / picks and bound lines (`S1/server/ident_compare.txt`; the label "0.on" there means "vs -frontier=on") |
| S1 seed panel answers | 180 | 177 correct, 0 wrong, 3 timeouts (all main BB_288 card-mto, lb 17 / ub 18) |
| Tier 5 bounds vs stems | 18 | 0 problems |
| Mac quick check answers | 136 | all correct |

## 4. S1 seed panel (yfclab2)

Method: `S1/runner/s1_panel.py`, binary `frozen/server-gh130-0976153/distqldpc` (GCC build of 0976153, sha256 `f9984936a035f03255e69926a2c9811aeec8c3956061138b0d65b4d34d95491c`). Arms per (code, seed S = 0..4): main-nc `-no-card -seed=S`, main-mto `-card-mto -seed=S` (no-flag binary = main, §3), cand-nc / cand-mto the same plus `-frontier=auto`. Limits tier1-3 1800 s, tier4 5000 s; timeouts count as the limit. 40 pinned cores (0-39), the four arms of a (code, seed) side by side, 180 runs, 2026-10-17 21:34-22:04 CST. Only the nine codes where auto turns the rule on were run; on the four TN codes of tiers 2-4 auto is off on both halves and the search is main's (identity, §3), so their ratio is 1 by construction and they were not re-run (main's medians from the GH-129 batch are shown for scale). The last column repeats GH-129's `-frontier=on` ratio of the same cell (independent batch, same search on auto-on cells).

- Runs: 180 (runner errors: 0). Answers vs stem d: 177 correct, 0 wrong/bound violations, 3 without an answer (timeout).
- Runner backstop kills: 0; non-zero rc: 3; max RSS: 134 MB.
  - TIMEOUT BB_288_12_18 main-mto seed 1 (limit 1800 s, final lb 17, ub 18)
  - TIMEOUT BB_288_12_18 main-mto seed 2 (limit 1800 s, final lb 17, ub 18)
  - TIMEOUT BB_288_12_18 main-mto seed 4 (limit 1800 s, final lb 17, ub 18)


### Per cell (wall s, median over seeds 0-4 (range); "T" = timeouts counted as the limit)

| Tier | Code | Mode | auto decision | main median (range) | cand median (range) | ratio cand/main | cand worst / main best | CPU median ratio | GH-129 on/main (replicate) |
|---:|---|---|---|---|---|---:|---:|---:|---:|
| 1 | BB_108_8_10 | no-card | on/on | 0.491 (0.258-0.78) | 0.27 (0.207-0.356) | 0.5499 | 1.38 | 0.484 | 0.5429 |
| 1 | BB_108_8_10 | card-mto | on/on | 1.273 (0.476-1.324) | 0.228 (0.22-0.295) | 0.1791 | 0.62 | 0.146 | 0.2188 |
| 1 | BB_144_12_12 | no-card | on/on | 0.773 (0.678-1.295) | 0.333 (0.322-0.364) | 0.4308 | 0.537 | 0.409 | 0.4523 |
| 1 | BB_144_12_12 | card-mto | on/on | 1.648 (1.414-2.038) | 0.339 (0.318-0.384) | 0.2057 | 0.272 | 0.19 | 0.2362 |
| 1 | LP_238_44_6 | no-card | on/on | 1.09 (0.794-1.392) | 0.851 (0.753-0.913) | 0.7807 | 1.15 | 0.76 | 0.7984 |
| 1 | LP_238_44_6 | card-mto | on/on | 1.137 (0.81-1.392) | 1.019 (0.671-1.314) | 0.8962 | 1.62 | 0.884 | 0.89 |
| 1 | LP_340_56_8 | no-card | on/on | 3.738 (3.259-5.295) | 2.615 (2.239-3.039) | 0.6996 | 0.932 | 0.703 | 0.6867 |
| 1 | LP_340_56_8 | card-mto | on/on | 4.742 (3.66-5.031) | 3.031 (2.782-3.343) | 0.6392 | 0.913 | 0.641 | 0.7467 |
| 2 | BB_144_14_14 | no-card | on/on | 83.76 (65.58-98.33) | 21.68 (18.81-37.49) | 0.2588 | 0.572 | 0.258 | 0.266 |
| 2 | BB_144_14_14 | card-mto | on/on | 79.68 (56.31-96.79) | 26.51 (19.14-43.03) | 0.3327 | 0.764 | 0.332 | 0.3383 |
| 2 | LP_442_68_10 | no-card | on/on | 70.33 (40.11-88) | 31.65 (23.48-33.87) | 0.4499 | 0.844 | 0.451 | 0.4841 |
| 2 | LP_442_68_10 | card-mto | on/on | 60.15 (47.35-219.2) | 25.9 (18.89-34.42) | 0.4306 | 0.727 | 0.427 | 0.3926 |
| 2 | TN_108_2_12 | no-card | off/off | 23.38 (20.91-26.58) (GH-129 batch) | = main (identical search) | 1 | - | - | 0.9681 |
| 2 | TN_108_2_12 | card-mto | off/off | 28.84 (21.58-29.96) (GH-129 batch) | = main (identical search) | 1 | - | - | 0.8728 |
| 3 | BB_288_12_18 | no-card | on/on | 960.1 (797.9-1113) | 232 (222.5-258.3) | 0.2416 | 0.324 | 0.241 | 0.3088 |
| 3 | BB_288_12_18 | card-mto | on/on | 1800 (989.7-1800, 3T) | 342.4 (240.4-382.1) | 0.1902 | 0.386 | 0.189 | 0.1631 |
| 3 | GB_144_12_12 | no-card | on/on | 147.2 (80.91-204) | 66.03 (19.28-79.59) | 0.4485 | 0.984 | 0.447 | 0.5083 |
| 3 | GB_144_12_12 | card-mto | on/on | 284 (56.3-362.4) | 47.63 (37.42-99.59) | 0.1677 | 1.77 | 0.168 | 0.1836 |
| 3 | LP_544_80_12 | no-card | on/on | 375.7 (271.6-592.6) | 75.68 (64.86-88.62) | 0.2014 | 0.326 | 0.201 | 0.2145 |
| 3 | LP_544_80_12 | card-mto | on/on | 500 (229.3-564.4) | 68.63 (54.48-87.07) | 0.1373 | 0.38 | 0.137 | 0.1718 |
| 3 | TN_144_2_13 | no-card | off/off | 373.2 (299.2-1111) (GH-129 batch) | = main (identical search) | 1 | - | - | 1.039 |
| 3 | TN_144_2_13 | card-mto | off/off | 469.4 (234.8-767.5) (GH-129 batch) | = main (identical search) | 1 | - | - | 1.123 |
| 3 | TN_200_10_10 | no-card | off/off | 29.78 (22.39-138.8) (GH-129 batch) | = main (identical search) | 1 | - | - | 1.526 |
| 3 | TN_200_10_10 | card-mto | off/off | 22.96 (19.66-51.42) (GH-129 batch) | = main (identical search) | 1 | - | - | 1.296 |
| 4 | TN_250_10_15 | no-card | off/off | 2934 (2330-5000, 1T) (GH-129 batch) | = main (identical search) | 1 | - | - | 1.673 |
| 4 | TN_250_10_15 | card-mto | off/off | 3786 (2380-4296) (GH-129 batch) | = main (identical search) | 1 | - | - | 1.234 |

### Per-tier geomean of seed-median ratios (cand / main) and gate

| Tier | cells per mode | geomean no-card | geomean card-mto | max cell ratio | cells > 1 | cells > 1.25 | gate |
|---:|---:|---:|---:|---:|---:|---:|---|
| 1 | 4 | 0.5998 | 0.3812 | 0.8962 | 0 | 0 | PASS |
| 2 | 3 | 0.4884 | 0.5233 | 1 | 0 | 0 | PASS |
| 3 | 5 | 0.4654 | 0.3375 | 1 | 0 | 0 | PASS |
| 4 | 1 | 1 | 1 | 1 | 0 | 0 | NEUTRAL (identical to main) |

Cells with ratio > 1: none.


## 5. Tier 5 (yfclab2, 6 h, default seed)

`S1/runner/s1_tier5.py --stems <the 9 auto-on codes>`: BB_1080, BB_360, BB_756, BB_864, LP_714, LP_1020, LP_1054, LP_1428, LP_1768 x {no-card, card-mto} with `-frontier=auto`, 18 runs at once on cores 64-81, `-cpu-lim=21600`, 2026-10-17 22:09 to 2026-10-18 04:09 CST (a first launch at 21:34 failed at argument parsing, no run started). The 17 TN tier5 codes are auto-off on both halves: their search is main's (per-probe identity on TN_180, TN_216, TN_504, TN_684 and TN_250, §3), so main's recorded 398054e run (`optimization/baselines/SERVER.md`) stands for them. The auto-on cells run the same search as GH-129's `-frontier=on`; this replicate ran on a less loaded host (18 of our processes vs GH-129's 60 plus another session's 60), so its times are 1.2-2.2x shorter than GH-129's for identical work, and main's recorded times also came from a loaded host: treat time ratios against main as indicative, bounds and solved cells as firm. CC = GH-124 S1 (`-engine=cc`, one run per code). Full 52-cell table: `S1/server/summary.md`.

| Code | Mode | auto | auto result | auto lb / ub | auto lb events | auto ub events | main result, lb/ub, wall | GH-129 on result, lb/ub | CC result, lb/ub, wall | auto vs main | check |
|---|---|---|---|---|---|---|---|---|---|---|---|
| BB_1080_4_ge17 | card-mto | on | TIMEOUT | 17 / - | 5@0, 9@0, 17@2162 |  | TIMEOUT, 17/-, 21600 | TIMEOUT, 17/- | TIMEOUT, 27/66, 21600 | lb =, ub = | ok |
| BB_1080_4_ge17 | no-card | on | TIMEOUT | 17 / - | 5@0, 9@0, 17@2162 |  | TIMEOUT, 17/-, 21600 | TIMEOUT, 17/- | TIMEOUT, 27/66, 21600 | lb =, ub = | ok |
| BB_360_12_24 | card-mto | on | TIMEOUT | 17 / 24 | 5@0, 9@0, 17@70 | 28@77, 26@160, 24@923 | TIMEOUT, 17/24, 21600 | TIMEOUT, 17/24 | d=24 @ 1706 s, 24/24, 1706 | lb =, ub = | ok |
| BB_360_12_24 | no-card | on | TIMEOUT | 17 / 24 | 5@0, 9@0, 17@69 | 28@76, 26@255, 24@398 | TIMEOUT, 17/24, 21600 | TIMEOUT, 17/24 | d=24 @ 1706 s, 24/24, 1706 | lb =, ub = | ok |
| BB_756_16_ge17 | card-mto | on | TIMEOUT | 17 / - | 5@0, 9@0, 17@554 |  | TIMEOUT, 17/-, 21600 | TIMEOUT, 17/- | TIMEOUT, 27/52, 21600 | lb =, ub = | ok |
| BB_756_16_ge17 | no-card | on | TIMEOUT | 17 / - | 5@0, 9@0, 17@549 |  | TIMEOUT, 17/-, 21600 | TIMEOUT, 17/- | TIMEOUT, 27/52, 21600 | lb =, ub = | ok |
| BB_864_4_ge17 | card-mto | on | TIMEOUT | 17 / - | 5@0, 9@0, 17@721 |  | TIMEOUT, 17/-, 21600 | TIMEOUT, 17/- | TIMEOUT, 27/108, 21600 | lb =, ub = | ok |
| BB_864_4_ge17 | no-card | on | TIMEOUT | 17 / - | 5@0, 9@0, 17@716 |  | TIMEOUT, 17/-, 21600 | TIMEOUT, 17/- | TIMEOUT, 27/108, 21600 | lb =, ub = | ok |
| LP_1020_136_16 | card-mto | on | d=16 @ 2061 s | 16 / 16 | 5@5, 9@14, 16@2061 | 16@58 | solved, 16/16, 8328 | d=16 @ 4511 s, 16/16 | d=16 @ 2 s, 16/16, 2 | lb =, ub = | ok |
| LP_1020_136_16 | no-card | on | d=16 @ 2246 s | 16 / 16 | 5@5, 9@19, 16@2246 | 16@63 | solved, 16/16, 7159 | d=16 @ 3055 s, 16/16 | d=16 @ 2 s, 16/16, 2 | lb =, ub = | ok |
| LP_1054_140_20 | card-mto | on | TIMEOUT | 17 / 32 | 5@3, 9@12, 17@7991 | 32@8191 | TIMEOUT, 17/-, 21600 | TIMEOUT, 17/32 | d=20 @ 123 s, 20/20, 123 | lb =, ub new | ok |
| LP_1054_140_20 | no-card | on | TIMEOUT | 17 / 32 | 5@3, 9@16, 17@8052 | 32@8252 | TIMEOUT, 17/-, 21600 | TIMEOUT, 17/32 | d=20 @ 123 s, 20/20, 123 | lb =, ub new | ok |
| LP_1428_184_24 | card-mto | on | TIMEOUT | 17 / 32 | 5@4, 9@10, 17@8162 | 32@15985 | TIMEOUT, 17/-, 21600 | TIMEOUT, 17/32 | d=24 @ 2884 s, 24/24, 2884 | lb =, ub new | ok |
| LP_1428_184_24 | no-card | on | TIMEOUT | 17 / 32 | 5@4, 9@10, 17@8498 | 32@16330 | TIMEOUT, 17/-, 21600 | TIMEOUT, 17/- | d=24 @ 2884 s, 24/24, 2884 | lb =, ub new | ok |
| LP_1768_224_22 | card-mto | on | TIMEOUT | 17 / - | 5@10, 9@31, 17@12618 |  | TIMEOUT, 9/-, 21600 | TIMEOUT, 17/- | d=22 @ 327 s, 22/22, 327 | lb >, ub = | ok |
| LP_1768_224_22 | no-card | on | TIMEOUT | 17 / - | 5@10, 9@31, 17@12497 |  | TIMEOUT, 9/-, 21600 | TIMEOUT, 17/- | d=22 @ 327 s, 22/22, 327 | lb >, ub = | ok |
| LP_714_100_16 | card-mto | on | d=16 @ 2363 s | 16 / 16 | 5@1, 9@5, 16@2363 | 16@16 | solved, 16/16, 5321 | d=16 @ 3348 s, 16/16 | d=16 @ 2 s, 16/16, 2 | lb =, ub = | ok |
| LP_714_100_16 | no-card | on | d=16 @ 2685 s | 16 / 16 | 5@1, 9@4, 16@2685 | 16@16 | solved, 16/16, 8752 | d=16 @ 4200 s, 16/16 | d=16 @ 2 s, 16/16, 2 | lb =, ub = | ok |

TN cells (auto off = main): TN_180_2_17 solved no-card (9837 s) and lb 17 / ub 19 card-mto, TN_216_4_18 solved in both modes (16802 / 18346 s), TN_252 lb 17 (ub 28 no-card), the other 14 TN codes lb 9 or 17 — all equal to main and better than GH-129 `on` (which lost TN_180 and TN_216).

Solved cells (of 52): auto 7 (LP_714 and LP_1020 both modes, re-run; TN_180 no-card and TN_216 both modes, main's search) = the same 7 cells main solves; GH-129 `on` 4; CC 16. Auto-on cells worse than main: none; better than main: 6 (new ub 32 on LP_1054 both modes and LP_1428 both modes; lb 17 vs 9 on LP_1768 both modes).

#### Time to main's final lb (auto-on cells, lb >= 16): auto / main and GH-129 on / main

| Code | Mode | lb | auto s | GH-129 on s | main s | auto/main | on/main |
|---|---|---:|---:|---:|---:|---:|---:|
| BB_1080_4_ge17 | card-mto | 17 | 2162 | 2888.6 | 2422 | 0.89 | 1.19 |
| BB_1080_4_ge17 | no-card | 17 | 2162 | 3100.8 | 2423 | 0.89 | 1.28 |
| BB_360_12_24 | card-mto | 17 | 70 | 85.8 | 168 | 0.42 | 0.51 |
| BB_360_12_24 | no-card | 17 | 69 | 83.3 | 206 | 0.34 | 0.40 |
| BB_756_16_ge17 | card-mto | 17 | 554 | 740.8 | 846 | 0.65 | 0.88 |
| BB_756_16_ge17 | no-card | 17 | 549 | 893.9 | 844 | 0.65 | 1.06 |
| BB_864_4_ge17 | card-mto | 17 | 721 | 1099.9 | 1175 | 0.61 | 0.94 |
| BB_864_4_ge17 | no-card | 17 | 716 | 944.5 | 1176 | 0.61 | 0.80 |
| LP_1020_136_16 | card-mto | 16 | 2061 | 4510.9 | 8328 | 0.25 | 0.54 |
| LP_1020_136_16 | no-card | 16 | 2246 | 3054.6 | 7159 | 0.31 | 0.43 |
| LP_1054_140_20 | card-mto | 17 | 7991 | 11048.8 | 16386 | 0.49 | 0.67 |
| LP_1054_140_20 | no-card | 17 | 8052 | 10939.0 | 16379 | 0.49 | 0.67 |
| LP_1428_184_24 | card-mto | 17 | 8162 | 12085.5 | 15997 | 0.51 | 0.76 |
| LP_1428_184_24 | no-card | 17 | 8498 | 13321.4 | 19868 | 0.43 | 0.67 |
| LP_714_100_16 | card-mto | 16 | 2363 | 3348.4 | 5321 | 0.44 | 0.63 |
| LP_714_100_16 | no-card | 16 | 2685 | 4199.6 | 8751 | 0.31 | 0.48 |

Geomean auto/main 0.487 over 16 cells.


Against CC (GH-124 S1): CC solves 16 cells (BB_360 at 1706 s, LP_714 / LP_1020 at 2 s, LP_1054 123 s, LP_1428 2884 s, LP_1768 327 s, TN_180 257 s, TN_216 696 s) and reaches lb 20-27 on every open code where the MaxSAT path (main or auto) has 9 or 17. Auto narrows nothing on TN and only speeds up the MaxSAT path on BB/LP.

## 6. Mac tier0-2 quick check (default seed)

`S1/runner/mac_serial.py`, strictly one process at a time under `caffeinate -i -s` (no sleep in `pmset -g log` during the run), 2 GB cap: `-frontier=auto` 3 runs per cell plus 1 drift sample of frozen main abd1770, against the recorded Mac main table (`optimization/baselines/README.md`, 398054e). Full table: `S1/mac/summary.md`.

| Tier | geomean no-card | geomean card-mto | max cell |
|---:|---:|---:|---:|
| 0 | 0.868 | 0.926 | 1.073 (TN_72_8_8 no-card: auto off = main's search, host drift) |
| 1 | 0.502 | 0.435 | 0.872 |
| 2 | 0.430 | 0.487 | 1.007 (TN_108_2_12: auto off = main's search) |

All 102 candidate answers correct. Tier0 cells above 1 are auto-off cells (identical searches) within the host's drift (drift samples +3-7 % over the recorded medians).

## 7. Gate verdicts

| Tier | Rule | Evidence | Verdict |
|---|---|---|---|
| 0 | correctness, no severe slowdown | identity 56/56 (Mac), 30/30 per-probe pairs (server); tier0-3, 54 random codes vs CC, all S1 runs correct; slowest tier0 run 0.34 s | **PASS** (the QDistSAT cross-repo CI check was not run in this round) |
| 1 | geomean < 1 per mode, no cell > 1.25 (seed medians) | 0.600 / 0.381, max cell 0.896 | **PASS** |
| 2 | same | 0.488 / 0.523, max cell 1 (TN_108, identical search) | **PASS** |
| 3 | same | 0.465 / 0.338, max cell 1 (TN_144 / TN_200, identical searches); BB_288 0.24 / 0.19, LP_544 0.20 / 0.14, GB_144_12_12 0.45 / 0.17 | **PASS** |
| 4 | same | TN_250 only, auto off: identical to main (ratio 1 / 1) | **NEUTRAL** (no regression; strict "geomean < 1" not met because nothing changes) |
| 5 | bounds and solved cells vs main | no cell worse; 6 cells better (LP_1054 / LP_1428 ub 32, LP_1768 lb 17); LP_714 / LP_1020 2.3-3.9x sooner; time to main's lb geomean 0.49 on BB/LP; TN = main | **PASS** |

## 8. Recommendation

1. `-frontier=auto` is the first frontier variant that passes Tiers 0-3 and 5 with Tier 4 unchanged: it keeps GH-129's 2-7x gains on BB/GB/LP (tier1-3 geomeans 0.34-0.60, Tier 5 LP solves 2-4x sooner, new LP bounds) and removes GH-129's TN regression by leaving TN at main's search. It is a candidate for the MaxSAT path's default; per policy the PI decides (the flag stays opt-in on the branch; no PR opened).
2. Caveats for that decision: (a) the selector is a structural marker that separates the families with a 3.84x margin, but its causal role is not demonstrated (the redundant-row check was negative) and on these 49 codes it is equivalent to a family split; (b) it depends on the matrix presentation, so redundant or row-mixed inputs can switch off a rule that would help (or switch it on for a TN-like code); if adopted, consider computing C4/row on a canonical sparse presentation (e.g. after removing rows that are sums of others) and keep `-frontier=on|off` as overrides.
3. TN is untouched: the rule's per-conflict lookahead overhead (1.4-1.9x in every family) is what TN cannot repay. A TN-side follow-up should reduce that overhead (e.g. skip the lookahead on frontier decisions, or use the rule only above the current global lower bound) rather than refine the selector.
4. The CC engine (GH-124) remains far stronger on Tier 5 (16 solved cells vs 7, lb 20-27 vs 9-17); the MaxSAT-side work should be weighed against investing in CC.

## 9. Files

All paths relative to `optimization/experiments/GH-130/`.

- `S0/half_structure.json`, `S0/half_structure_table.md` (all 49 codes x 2 halves), `S0/separation.md`, `S0/gh129_probe_classes.txt`, `S0/lookahead_per_conflict.md`, `S0/augmentation_4cycles.md`, `S0/correctness_mac.txt`, `S0/identity_mac_vs_main_abd1770.txt`; `S0/tools/` (`half_structure.py`, `separation.py`, `gh129_probe_classes.py`, `lkstats.py`, `augment.py`, `aug_sum.py`, `check_corr.py`, `macrun.py`, `gen_random_codes.py`, `gen_random_codes2.py`); `S0/raw/` (`ident`, `corr`, `randcodes` (the 54 random codes), `aug` (augmented matrices and runs), `lk` (lookahead runs), tar.gz).
- `S1/runner/` (`s1_panel.py`, `s1_tier5.py`, `ident_server.py`, `ident_compare.py`, `analyze_gh130.py`, `mac_serial.py`, `analyze_macq.py`); `S1/server/panel/` (`results.jsonl`, `config.json`, `logs.tar.gz`, `RUNNER_DONE`), `S1/server/panel.out`; `S1/server/ident.tar.gz`, `S1/server/ident_compare.txt`; `S1/server/tier5/` (`results.json`, 18 timestamped logs, `RUNNER_DONE`), `S1/server/tier5.out`; `S1/server/summary.md` (output of `analyze_gh130.py`); `S1/mac/` (`summary.md`, `results.tsv`, `jobs.jsonl`, `logs.tar.gz`).
- Server originals: `yfclab2:~/mac-agent-20261009/gh130-s1/`, worktree `~/mac-agent-20261009/gh130-0976153`, binary `~/mac-agent-20261009/frozen/server-gh130-0976153/`.

Reproduce the server summary (from this directory):

```
python3 S1/runner/analyze_gh130.py S1/server/panel/results.jsonl ../GH-129/S1/server/panel/results.jsonl \
    S1/server/tier5/results.json ../GH-129/S1/server/tier5/results.json ../../baselines/SERVER.md \
    ../GH-124/S1/server/tier5/results.json
```

## Completion report

- **What changed:** `-frontier=auto` (per-half selector: frontier on iff the half's parity matrix has < 3 Tanner 4-cycles per row) in `src/core/distqldpc.cc` (0976153); default off, byte-identical to main without the flag. This report, tools, runners and raw data.
- **Validation:** Mac and server identity, tier0-3 and 54 random codes vs CC, 180-run seed panel, 18-run Tier 5 (6 h), 136-run Mac quick check, selector study on all 49 codes, lookahead counters and a causal augmentation check.
- **Result:** Tier 0-3 PASS, Tier 4 neutral (identical), Tier 5 PASS (no cell worse than main, 6 better). Selector margin 3.84x; mechanism only partly supported.
- **Scientific semantics changed:** no (decision order only, chosen per half before search; no answer or bound differed from the stems in any run).
- **PI action required:** decide whether `-frontier=auto` becomes the MaxSAT default given the caveats in §8.
