# GH-146 report: Stern / Dumer collision step in the verified upper-bound finder (`-ub-isd`)

Issue: https://github.com/guluchen/DistQLDPC/issues/146 (hub #15). Baseline: GH-144's branch (`8dc7627`, PR #145,
stacked on GH-140's PR #143; main `8eb047b` underneath). Candidate: branch `experiment/gh-146-isd-collision`. Evaluated
binary `4f16e0d` (S0 and S1; frozen on yfclab2 as `frozen/server-gh146-4f16e0d/distqldpc`, sha256 `c7e19c9d...`); the
later commits only add documentation and evidence. Our own implementation from the published algorithms (Stern 1988;
Dumer's and Finiasz-Sendrier's split with an overlapping window; the Canteaut-Chabaud random walk on information
sets); no other project's code was read and no external solver was used. Every timing ran on yfclab2 (one pinned core
per process, `prlimit --as=4294967296`, cores 1-99); the Mac only built and ran the tests.

## Summary

| Item | Result |
|---|---|
| Implementation | `-ub-isd=off\|stern\|dumer[:P,L,W,B,R]`: Stern collision step (subsets of size <= 2 from each half of a random split of the information set, bucketed on an automatic window of ~log2(list size) redundancy rows, detector-parity precheck per colliding pair), Canteaut-Chabaud pivot swaps (32 per round) instead of a fresh elimination, Dumer variant; one shared finder for CC `-ub-search` and MaxSAT `-ub-pre`; default `off` (old finder); default path identical to GH-144 (112/112 comparable logs) |
| Correctness | `make test-cc` (6 collision configurations on 400 random halves: every word valid, never below the true d_h, **d_h reached on 400/400** per configuration; driver and pre-pass runs 0 bad), `test_cc_engine 1500 600` on yfclab2 PASS; **mutant 12 (unverified reporting) in collision mode: 8/8 wrong answers** (must fail: it does), pre-pass mutant 2: 13 wrong; `make test-cc-flags` 321 checks PASS; 2 252 server runs, 0 science problems |
| Choice of P, L, W (S0, 2 x 5 seeds x 300 s, 9 open codes) | P = 2 (P = 1 worse), L automatic (18 / 20 worse), W = 32 (0 / 64 / 128 within noise, 8 worse), Stern = Dumer within noise |
| **Open Tier 5 codes, finder alone, 5 seeds** | median ub new <= old on **17/17 codes at 60, 600 and 3600 s**; e.g. at 60 s / 600 s: TN_540 40 -> 34 / 35 -> 34, TN_576 46 -> 45 / 40 -> 38, TN_612 53 -> 44 / 43 -> 41, BB_864 46 -> 42 / 40 -> 40, BB_1080 70 -> 58 / 64 -> 58, TN_504 39 -> 37 / 36 -> 34, TN_648_14 32 -> 31 / 32 -> 28; at 3600 s both finders meet on 15 codes, new lower on TN_576 (40 -> 37) and TN_612 (41 -> 40); **time to the common bound 5.1x shorter (geomean over 12 codes, 1.2-73x)** |
| Known-d codes (34 codes, 5 seeds, 60 s) | both reach d in 170/170 runs; new faster where it is not instant: LP_1768 19.5 -> 2.5 s, LP_1428 2.5 -> 0.6 s, TN_252 0.34 -> 0.18 s (medians) |
| MaxSAT pre-pass (`-ub-pre=60`, 51 codes, 5 seeds) | U0 = d on all 34 known-d codes in both arms; pre-pass <= 0.28 s on tiers 1-4 (old <= 0.32 s); median U0 lower on 11 open codes, never higher |
| **S1 Tier 1-4 panel** (5 seeds, CC with `-ub-search=on`, MaxSAT with `-ub-pre=on`, both modes) | **neutral**: geomean new/old 0.977-1.026 per tier and engine/mode, max cell 1.083 (LP_442 CC, 0.06 vs 0.07 s), no cell > 1.25, 330/330 answers correct; U = d at 0.06-0.33 s in both arms |
| **S1 Tier 5** (6 h, CC + MaxSAT x 2 modes, 81 cells) vs GH-140 (CC) / GH-144 (MaxSAT) | solved cells 16 = 16, every final lb identical; **ub lower on 25 cells**, higher on 4 (seed-0 MaxSAT pre-pass on TN_432 32 -> 33, TN_504 45 -> 47); CC: TN_576 50 -> 38, TN_612 47 -> 41, TN_540 40 -> 34, TN_504 37 -> 34, BB_756 34 at 6 s instead of 344 s; MaxSAT: TN_612 62 -> 41, TN_576 54 -> 43, TN_648_10 65 -> 47, TN_648_14 40 -> 31, BB_1080 70 -> 60 |
| **Best verified upper bounds (witnesses saved and independently checked)** | **BB_1080_4 <= 48** (before 56), **TN_576_2 <= 37** (before 40), **TN_612_2 <= 40** (before 43); the other 14 open codes keep their values (BB_756 34, BB_864 40, TN_288 24, TN_324 25, TN_360 24, TN_396 26, TN_432 29, TN_468 29, TN_496 30, TN_504 34, TN_540 34, TN_648_10 32, TN_648_14 28, TN_684 29); 17/17 witness files VALID |
| Gates | Tier 0 PASS; Tier 1-4 neutral (no regression; the finder's bound was already d on every panel code, so no gain was possible); Tier 5 PASS (no cell lost, no lb changed, 25 lower ubs) |
| Recommendation | make `-ub-isd=stern` the finder default for both engines (PI decision; one-line change of `UbParams::isd`), so `-ub-search` and `-ub-pre` get it; keep `-ub-isd=off` for reproduction |

Scientific semantics changed: no. The collision step only changes which words the finder proposes; every word is
still verified independently (CC: `verify_in_half`; MaxSAT pre-pass: `ubpre_verify` + `distcc::verify_logical`) before
it becomes an upper bound, lower bounds still come only from exhaustive CC levels / MaxSAT NONE probes, and the
termination rules are unchanged.

## 1. What was implemented (S0)

**Collision mode of `UbFinder`** (`src/cc/cc_ubsearch.{h,cc}`; used by both the CC `-ub-search` finder and the MaxSAT
`-ub-pre` pre-pass). The first round does GH-140's random elimination (random column order, Gauss-Jordan elimination
of the half's H, systematic columns A_j of ker H over the information set I, |I| = K). Each round then:
1. **Re-randomisation (Canteaut-Chabaud).** W pivot swaps on the stored columns: a random information column j with
   A_j != 0 and a random pivot row i with A[i][j] = 1 exchange roles; every other information column j' with
   A[i][j'] = 1 gets A_j' + A_j + e_i, and the old pivot column P_i takes the vector A_j. These are exactly the GF(2)
   row operations "add row i to every row with a 1 in column j", so the systematic invariant (each c_j in ker H) holds
   after any number of swaps; cost O(K r / 64) per swap instead of a full elimination. W = 0 gives a fresh random
   elimination every round.
2. **Stern collision.** A random split of I into halves I1, I2 and a random window Z of L pivot rows. All subsets of
   size <= P of I1 (list L1) are bucketed by the window part of their column sum (counting sort on 2^L buckets); for
   every subset of I2 the matching bucket is scanned. A colliding pair (T1, T2) gives the word sum_{j in T1 u T2} c_j,
   which is zero on the window; pairs with equal detector parities (trivial words, G c = 0) are skipped before the
   weight count; the weight |T1| + |T2| + |sum A_j| is counted with an early exit at the threshold.
   **Dumer / Finiasz-Sendrier variant** (`dumer`): the window pivot columns are elements too (split with I1 / I2); such
   an element contributes a unit vector to the key and nothing to the word, so words with up to P ones per side on
   I u P_Z are matched.
3. Single systematic words c_j are tried as well. Kept words (weight <= threshold, nontrivial) go through GH-140's
   unchanged detector check and stabilizer local improvement; the lightest word of the iteration (B rounds) is returned.

**Flag** `-ub-isd=off|stern|dumer[:P,L,W,B,R]` (shared by both engines; needs `-ub-search=on|budget:S` or `-ub-pre=S`;
default `off` = GH-140's enumeration). P = subset size per side (1-2), L = window rows (default automatic:
round(log2 |L1|), at most 20), W = pivot swaps per round (default 32), B = rounds per finder iteration (default 1; the
iteration is the unit of the stop rules), R = a fresh elimination every R rounds (default 0 = never). `-v` appends
`collision stern p 2 l 15 walk 32 batch 1 refresh 0` to the finder setup lines (CC and pre-pass); `-cc-stats` adds
`rounds, colliding pairs (nontrivial)` per half. Docs: README (flag table, CC section, summary table), MODIFICATIONS.md
(row, `cc_ubsearch` file row and the GH-146 soundness paragraph).

**Defaults chosen from S0 (section 3.1).** P = 2 (P = 1 is clearly worse), L automatic (about 14-17 on the open
codes; 18 and 20 are worse), W = 32 (W = 0, 32, 64, 128 are within the seed noise; W = 8 is behind), Stern rather than
Dumer (equal within noise, simpler), B = 1. A cost-model batch (rounds per iteration chosen to match the cost of a
GH-140 iteration) was dropped before the measurements below: it underestimated the cost of a round by about 3x (the
window keys of these LDPC codes are far from uniform, so there are 10-20x more colliding pairs than for a random code
of the same size), and B = 1 keeps the stop-rule semantics simple.

**Code default.** `-ub-isd=off` stays the default in this branch (the issue asked to keep the old finder until
evaluated); identity of the default path with GH-144's binary is in section 2.

## 2. Correctness

| Check | Runs | Result |
|---|---:|---|
| Default path vs GH-144's `6d2b7a1` (`S0/ident.py`, tier0+1, time fields masked): MaxSAT default and `-ub-pre=on` (both modes, full `-v` logs), CC finder alone (`-engine=cc -ub-basis=off -ub-search=budget:1 -cc-ub-only`, word / witness sequence), each without `-ub-isd` and with `-ub-isd=off` | 140 comparisons | **112 identical**; the other 28 are the MaxSAT-default runs with `-ub-isd=off`, which the candidate refuses by design (`-ub-isd: needs the finder`, exit 1) (`S0/server/ident2.txt`) |
| `make test-cc` (new GH-146 part): six collision configurations (Stern P 1/2, Dumer P 1/2, window automatic / 0 / 2 / 3, walk 0 / 1 / 8 / 32, batch 1-3, refresh 5) on the 400 random Part B halves, 300 iterations each with a falling target: every word in ker H, nontrivial, lighter than the target and >= the true half distance (exhaustive enumeration); same seed, same words; d_h must be reached on >= 90 % of the halves | 2 400 finder halves | 0 bad, 0 nondeterministic, **d_h reached on 400/400 halves in every configuration** |
| CC driver in collision mode (pre-pass, late start with abandoned levels, finder-only; Stern and Dumer) | 600 | 0 bad (answer = enumeration, every UB >= d, LBs monotone) |
| MaxSAT pre-pass in collision mode (budget 1 s; cut after 2 iterations; Stern / Dumer, P 1 / 2) | 400 | 0 bad |
| Mutant 11 in collision mode (no detector check, no local improvement) | 41 halves; 8 driver runs | finder returned a trivial word on 41/41 halves; the driver's verification stopped 8/8 runs |
| **Mutant 12 in collision mode (words reported without verification)** | 8 driver runs | **8/8 wrong `RESULT d OPTIMAL`** (must fail: it does) |
| Pre-pass mutants in collision mode: 1 (no detector check: rejected by the verification), 2 (no verification) | 200 + 209 | mutant 1: 0 wrong; **mutant 2: 13 wrong answers** (codes + rotated surface codes) |
| Old parts A-F (GH-124..144) | as before | 0 bad, all old mutants fail as required |
| `make test-cc` and `test_cc_engine 1500 600` on yfclab2 (binary tree of `4f16e0d`) | 1 200 finder halves x 6 configurations, 1 800 driver, 1 200 pre-pass runs | 0 bad; d_h on 1 200/1 200 in every configuration; mutant 12 14/14 wrong, pre-pass mutant 2 20 wrong; `CC_ENGINE_TESTS PASS` (`S0/server/test_cc*.txt`) |
| `make test-cc-flags` (new: 17 invalid `-ub-isd` values, 4 "needs the finder" conflicts, 8 accepted combinations incl. `-engine=auto`, the `-v` lines with and without the flag, the `-cc-stats` collision line, finder-only output, mutants 11 (trap) and 12 (wrong answer) with `stern` and `dumer` on BB_90_8_10) | 321 checks | PASS (Mac and yfclab2) |
| Independent witness check (`witnesses/verify_witnesses.py`, pure Python: Hx Hz^T = 0, H e = 0, e not in rowspace(S) by its own elimination, odd overlap with a logical row) | 17 open-code witnesses | **ALL VALID** (section 5) |
| Every S0 / S1 server run: runner science check (answer in the stem range, lb <= stem upper value, ub >= stem lower value) | 1 742 queue runs + 510 pre-pass runs | 0 problems |

## 3. S0: the finder alone (yfclab2)

Runner `S0/queue.py` (GH-140's queue), jobs from `S0/make_jobs.py`: `distqldpc -engine=cc -v -cc-stats -ub-basis=off
-ub-search=budget:B -cc-ub-only -seed=S [-ub-isd=...]`, one pinned core per process, 4 GB cap. With `-v` the child's
`c d_ub` lines are not printed live, so `S0/analyze.py` takes every improvement from the log line `c cc: ub-search: X
half word of weight W` at its runner timestamp (the binary flushes stdout right after that line). Times are wall
seconds from process start. "old" = the GH-140 finder (no `-ub-isd`), same binary; "new" = `-ub-isd=stern`.

### 3.1 Choice of P, L and W (open codes, 300 s, seeds 0-4)

Two panels on BB_864, BB_1080, TN_496/504/540/576/612/648_10/648_14 (TN_684 instead of TN_496 in the second). Score =
mean over the codes of (arm's median ub - best arm's median ub); full tables `S0/tune300_table.md`,
`S0/tune2_table.md`, scores `S0/tune300_scores.md`, `S0/tune2_scores.md`; a first 120 s / 2-seed exploration in
`S0/explore1_table.md`.

| arm (`-ub-isd=`) | score @ 60 s | @ 120 s | @ 300 s |
|---|---:|---:|---:|
| old (GH-140) | 5.44 | 4.67 | 2.67 |
| `stern:1` (P 1) | 5.00 | 2.89 | 1.67 |
| `stern:2,20` | 3.78 | 2.00 | 1.44 |
| `stern:2,18` | 2.78 | 1.56 | 1.22 |
| `dumer:2,18` | 2.33 | 1.33 | 1.00 |
| `dumer` (L auto, W 8) | 2.44 | 1.44 | 0.78 |
| `stern` (L auto, W 8) | 2.11 | 1.33 | 0.78 |
| `stern:2,,0` (fresh elimination every round) | 0.33 | 0.33 | 0.78 |
| **`stern:2,,32` (W 32)** | 1.33 | 0.33 | **0.33** |

Second panel (W only; 60 / 120 / 300 s): W 0 0.44 / 0.56 / 0.78, W 32 1.44 / 0.56 / 0.33, W 64 1.33 / 1.22 / 0.78,
W 128 0.78 / 0.78 / 0.33, Dumer W 32 0.78 / 0.89 / 0.44. The runs are deterministic per seed (W 32 gave the same
values in both panels). Reading: P = 2 is needed; the automatic window is best; more re-randomisation than W 8 helps,
beyond W 32 nothing is resolved; Stern = Dumer within noise. Chosen default: `stern` = P 2, L automatic, W 32.

### 3.2 Open Tier 5 codes: best verified weight after 60 / 600 / 3600 s (seeds 0-4, old vs new)

`S0/open3600_table.md` (`S0/analyze.py`), raw `S0/server/open3600/`. Per seed (0-4), then the median.

| code | arm | ub @ 60 s (per seed; median) | ub @ 600 s (per seed; median) | ub @ 3600 s (per seed; median) | time to the final best (median s) |
|---|---|---|---|---|---|
| TN_288_2_ge9 | old | 24/24/24/24/24; 24 | 24/24/24/24/24; 24 | 24/24/24/24/24; 24 | 0.2/0.7/0.2/3.1/0.3 |
| TN_288_2_ge9 | stern | 24/24/24/24/24; 24 | 24/24/24/24/24; 24 | 24/24/24/24/24; 24 | 0.2/0.5/0.2/1.1/0.2 |
| TN_324_4_ge9 | old | 25/25/25/25/25; 25 | 25/25/25/25/25; 25 | 25/25/25/25/25; 25 | 0.1/1.2/0.4/0.9/1.7 |
| TN_324_4_ge9 | stern | 25/25/25/25/25; 25 | 25/25/25/25/25; 25 | 25/25/25/25/25; 25 | 0.1/0.1/0.4/0.3/0.1 |
| TN_360_4_ge17 | old | 24/24/24/24/24; 24 | 24/24/24/24/24; 24 | 24/24/24/24/24; 24 | 0.4/0.5/0.6/0.3/0.1 |
| TN_360_4_ge17 | stern | 24/24/24/24/24; 24 | 24/24/24/24/24; 24 | 24/24/24/24/24; 24 | 0.2/0.1/0.1/0.2/0.2 |
| TN_396_4_ge17 | old | 26/26/26/26/26; 26 | 26/26/26/26/26; 26 | 26/26/26/26/26; 26 | 6.1/3.5/0.4/0.4/2.4 |
| TN_396_4_ge17 | stern | 26/26/26/26/26; 26 | 26/26/26/26/26; 26 | 26/26/26/26/26; 26 | 0.6/0.4/0.2/0.1/0.2 |
| TN_432_8_ge9 | old | 29/29/29/29/29; 29 | 29/29/29/29/29; 29 | 29/29/29/29/29; 29 | 59.1/25.9/3.0/55.4/6.4 |
| TN_432_8_ge9 | stern | 29/29/29/29/29; 29 | 29/29/29/29/29; 29 | 29/29/29/29/29; 29 | 2.4/0.3/7.4/30.8/15.0 |
| TN_468_4_ge17 | old | 29/29/29/29/29; 29 | 29/29/29/29/29; 29 | 29/29/29/29/29; 29 | 3.7/31.8/7.6/12.4/11.6 |
| TN_468_4_ge17 | stern | 29/29/29/29/29; 29 | 29/29/29/29/29; 29 | 29/29/29/29/29; 29 | 3.3/21.1/36.2/3.0/6.2 |
| TN_496_2_ge17 | old | 30/30/32/30/30; 30 | 30/30/30/30/30; 30 | 30/30/30/30/30; 30 | 7.9/42.4/116.3/58.8/4.5 |
| TN_496_2_ge17 | stern | 30/30/30/30/30; 30 | 30/30/30/30/30; 30 | 30/30/30/30/30; 30 | 9.5/4.5/7.8/14.4/3.1 |
| TN_504_2_ge17 | old | 39/38/40/41/39; 39 | 37/34/34/36/37; 36 | 34/34/34/34/35; 34 | 1598.1/264.7/60.2/2167.4/890.2 |
| TN_504_2_ge17 | stern | 38/38/36/37/34; 37 | 34/34/34/36/34; 34 | 34/34/34/34/34; 34 | 296.2/118.2/147.8/862.5/2.9 |
| TN_540_4_ge9 | old | 42/39/45/40/37; 40 | 35/34/35/36/35; 35 | 34/34/34/35/34; 34 | 3240.2/528.2/3220.4/1835.3/799.0 |
| TN_540_4_ge9 | stern | 34/34/36/34/36; 34 | 34/34/34/34/35; 34 | 34/34/34/34/34; 34 | 44.3/43.4/90.6/6.0/807.3 |
| TN_576_2_ge9 | old | 50/51/46/45/42; 46 | 40/41/40/40/42; 40 | 40/41/39/40/40; 40 | 291.1/66.6/3148.8/257.9/2039.5 |
| TN_576_2_ge9 | stern | 38/45/37/45/46; 45 | 38/38/37/39/37; 38 | 38/38/37/37/37; 37 | 7.0/140.0/57.1/1571.1/222.7 |
| TN_612_2_ge17 | old | 62/60/53/46/40; 53 | 47/43/43/46/40; 43 | 42/41/40/43/40; 41 | 1611.0/1182.7/1938.9/3049.4/23.9 |
| TN_612_2_ge17 | stern | 41/44/47/41/45; 44 | 41/42/40/41/42; 41 | 40/40/40/40/40; 40 | 2953.2/1176.4/107.1/1736.4/2500.6 |
| TN_648_10_9to52 | old | 33/34/50/35/36; 35 | 33/34/32/34/32; 33 | 32/32/32/32/32; 32 | 1200.5/2128.1/368.3/740.8/65.4 |
| TN_648_10_9to52 | stern | 33/32/32/33/33; 33 | 32/32/32/33/32; 32 | 32/32/32/32/32; 32 | 560.4/16.2/17.5/975.9/114.7 |
| TN_648_14_ge9 | old | 32/32/34/32/33; 32 | 31/32/28/32/32; 32 | 28/28/28/28/28; 28 | 2153.4/3073.3/128.5/1712.7/1263.9 |
| TN_648_14_ge9 | stern | 31/29/32/32/29; 31 | 28/28/28/28/29; 28 | 28/28/28/28/28; 28 | 421.1/134.2/470.9/164.4/766.8 |
| TN_684_2_ge9 | old | 29/29/30/31/29; 29 | 29/29/29/29/29; 29 | 29/29/29/29/29; 29 | 32.5/4.3/288.0/74.1/42.4 |
| TN_684_2_ge9 | stern | 29/30/30/29/29; 29 | 29/29/29/29/29; 29 | 29/29/29/29/29; 29 | 22.9/78.2/107.8/7.8/3.8 |
| BB_756_16_ge30 | old | 34/34/34/34/34; 34 | 34/34/34/34/34; 34 | 34/34/34/34/34; 34 | 1.3/6.2/0.4/23.9/0.2 |
| BB_756_16_ge30 | stern | 34/34/34/34/34; 34 | 34/34/34/34/34; 34 | 34/34/34/34/34; 34 | 0.4/4.7/1.3/5.6/9.3 |
| BB_864_4_ge30 | old | 42/50/48/46/40; 46 | 40/46/44/40/40; 40 | 40/40/40/40/40; 40 | 301.7/3370.6/1696.1/196.7/16.7 |
| BB_864_4_ge30 | stern | 42/42/40/42/40; 42 | 40/40/40/40/40; 40 | 40/40/40/40/40; 40 | 96.1/352.1/29.5/150.2/0.7 |
| BB_1080_4_ge30 | old | 72/70/64/64/70; 70 | 70/70/56/64/54; 64 | 50/64/56/58/54; 56 | 1183.8/627.4/450.1/1023.9/403.8 |
| BB_1080_4_ge30 | stern | 58/58/56/62/64; 58 | 58/58/56/54/62; 58 | 58/56/56/50/56; 56 | 21.2/3599.7/11.2/1941.5/625.7 |

Arm score (mean over the 17 codes of median - best median): old 2.18 / 1.06 / 0.24 at 60 / 600 / 3600 s, new 0.00 at
every checkpoint (new median <= old median on 17/17 codes at every checkpoint).

**Time to the common bound** (`S0/open3600_time_to_target.md`): target = the larger of the two arms' 3600-s medians,
median time over the seeds until a seed's ub <= target (a seed that never reaches it counts as > 3600 s):

| code | target ub | old: time to target per seed (s) | median | stern: time to target per seed (s) | median | old / stern |
|---|---:|---|---:|---|---:|---:|
| BB_756_16_ge30 | 34 | 1.3/6.2/0.4/23.9/0.2 | 1.3 | 0.4/4.7/1.3/5.6/9.3 | 4.7 | 0.3 |
| BB_864_4_ge30 | 40 | 301.7/3370.6/1696.1/196.7/16.7 | 301.7 | 96.1/352.1/29.5/150.2/0.7 | 96.1 | 3.1 |
| BB_1080_4_ge30 | 56 | 727.5/>3600/450.1/>3600/403.8 | 727.5 | >3600/3599.7/11.2/169.6/625.7 | 625.7 | 1.2 |
| TN_288_2_ge9 | 24 | 0.2/0.7/0.2/3.1/0.3 | 0.3 | 0.2/0.5/0.2/1.1/0.2 | 0.2 | 1.3 |
| TN_324_4_ge9 | 25 | 0.1/1.2/0.4/0.9/1.7 | 0.9 | 0.1/0.1/0.4/0.3/0.1 | 0.1 | 8.6 |
| TN_360_4_ge17 | 24 | 0.4/0.5/0.6/0.3/0.1 | 0.4 | 0.2/0.1/0.1/0.2/0.2 | 0.2 | 2.1 |
| TN_396_4_ge17 | 26 | 6.1/3.5/0.4/0.4/2.4 | 2.4 | 0.6/0.4/0.2/0.1/0.2 | 0.2 | 11.9 |
| TN_432_8_ge9 | 29 | 59.1/25.9/3.0/55.4/6.4 | 25.9 | 2.4/0.3/7.4/30.8/15.0 | 7.4 | 3.5 |
| TN_468_4_ge17 | 29 | 3.7/31.8/7.6/12.4/11.6 | 11.6 | 3.3/21.1/36.2/3.0/6.2 | 6.2 | 1.9 |
| TN_496_2_ge17 | 30 | 7.9/42.4/116.3/58.8/4.5 | 42.4 | 9.5/4.5/7.8/14.4/3.1 | 7.8 | 5.5 |
| TN_504_2_ge17 | 34 | 1598.1/264.7/60.2/2167.4/>3600 | 1598.1 | 296.2/118.2/147.8/862.5/2.9 | 147.8 | 10.8 |
| TN_540_4_ge9 | 34 | 3240.2/528.2/3220.4/>3600/799.0 | 3220.4 | 44.3/43.4/90.6/6.0/807.3 | 44.3 | 72.7 |
| TN_576_2_ge9 | 40 | 291.1/>3600/436.5/257.9/2039.5 | 436.5 | 7.0/140.0/57.1/72.0/222.7 | 72.0 | 6.1 |
| TN_612_2_ge17 | 41 | >3600/1182.7/1074.1/>3600/23.9 | 1182.7 | 1.3/1176.4/107.1/42.3/737.3 | 107.1 | 11.0 |
| TN_648_14_ge9 | 28 | 2153.4/3073.3/128.5/1712.7/1263.9 | 1712.7 | 421.1/134.2/470.9/164.4/766.8 | 421.1 | 4.1 |
| TN_648_10_9to52 | 32 | 1200.5/2128.1/368.3/740.8/65.4 | 740.8 | 560.4/16.2/17.5/975.9/114.7 | 114.7 | 6.5 |
| TN_684_2_ge9 | 29 | 32.5/4.3/288.0/74.1/42.4 | 42.4 | 22.9/78.2/107.8/7.8/3.8 | 22.9 | 1.8 |

Geometric mean speedup over the 12 codes where the old finder needs > 10 s: **5.1x** (1.2x-73x).

### 3.3 Codes with a known distance: time to reach d (seeds 0-4, 60 s)

`S0/knownd60_table.md`. **Both finders reach the true d on all 34 known-d codes in all 5 seeds (170/170 each); no word
below d was ever reported.** 30 codes reach d within 0.04-0.2 s in both arms (process floor). The others:

| code | old: time to d per seed (s) | median | new: time to d per seed (s) | median |
|---|---|---:|---|---:|
| TN_252_2_21 | 0.36 / 0.07 / 0.37 / 0.34 / 0.22 | 0.34 | 0.29 / 0.20 / 0.07 / 0.18 / 0.08 | 0.18 |
| LP_1428_184_24 | 2.56 / 0.51 / 0.98 / 2.54 / 5.78 | 2.54 | 0.63 / 0.65 / 0.65 / 0.45 / 0.23 | **0.63** |
| LP_1768_224_22 | 13.8 / 5.4 / 26.7 / 34.4 / 19.5 | 19.5 | 4.3 / 12.1 / 1.5 / 2.2 / 2.5 | **2.5** |
| LP_2610_744_16 | 0.66 / 0.66 / 0.42 / 0.51 / 0.59 | 0.59 | 0.81 / 0.69 / 0.69 / 0.75 / 0.60 | 0.69 |

### 3.4 The MaxSAT pre-pass (`-ub-pre=60`, all 51 codes, seeds 0-4)

`S0/prepass_table.md` (`S0/prepass_runs.py` = GH-144's pre-pass runner; `S0/prepass_compare.py`). **U0 = d on all 34
known-d codes in all seeds in both arms.** Pre-pass seconds (median) on tiers 1-4: old <= 0.32, new <= 0.28 (TN_200
0.17 -> 0.28 the largest increase, TN_250 0.32 -> 0.24, TN_144 0.07 -> 0.01); known-d Tier 5: LP_1020 / 1054 / 1122
1.5-4.0 s -> 0.6-0.9 s, LP_1428 24.8 -> 15.0 s, LP_1768 at the 60 s cap in both. Median U0 lower on 11 open codes,
equal on 40 codes, higher on none: BB_864 48 -> 42, BB_1080 72 -> 62, TN_324 26 -> 25, TN_396 27 -> 26, TN_432 32 -> 30, TN_468 31 -> 30, TN_540 46 -> 40, TN_576 60 -> 47, TN_612 62 -> 58, TN_648_10 56 -> 42, TN_648_14 40 -> 32.

## 4. S1 (yfclab2, binary `4f16e0d`)

### 4.1 Tier 1-4 panel, both engines, old vs new finder (5 seeds)

Runner `S1/runner/s1_queue.py` (GH-144's queue with a per-job binary) on cores 1 and 90-99, concurrently with the
Tier 5 runs on 81 other cores; the two arms of a (code, engine/mode, seed) are adjacent in the queue and ran
concurrently. CC: `-engine=cc -cc-stats -ub-search=on -seed=S` (+ `-ub-isd=stern`); MaxSAT: `-no-card|-card-mto
-seed=S -ub-pre=on` (+ `-ub-isd=stern`). Limits tier1-3 1800 s, tier4 5000 s. Ratio = median(new) / median(old) over
the 5 seeds. "first d_ub = d" = median wall time of the first `c d_ub` equal to the answer. Full table
`S1/panel_table.md` (`S1/runner/analyze_panel.py`); raw `S1/server/panel.jsonl`, logs `S1/server/logs.tar.gz`.

| Tier | Code | Engine / mode | old median s (seeds 0-4) | new median s (seeds 0-4) | ratio new/old | first d_ub = d: old / new (median s) | answers |
|---:|---|---|---|---|---:|---|---|
| 1 | LP_340_56_8 | cc | 0.06 (0.06 0.06 0.05 0.07 0.06) | 0.06 (0.06 0.06 0.06 0.06 0.06) | 0.983 | 0.057 / 0.056 | [8] |
| 1 | LP_340_56_8 | no-card | 1.99 (1.49 2.27 1.50 2.49 1.99) | 2.02 (1.50 2.30 1.52 2.50 2.02) | 1.017 | 0.067 / 0.084 | [8] |
| 1 | LP_340_56_8 | card-mto | 1.79 (1.79 2.46 1.83 1.65 1.72) | 1.80 (1.80 2.50 1.83 1.66 1.73) | 1.006 | 0.067 / 0.088 | [8] |
| 2 | TN_108_2_12 | cc | 2.23 (0.91 2.23 2.88 2.08 2.28) | 2.08 (0.89 2.25 2.96 2.03 2.08) | 0.933 | 0.058 / 0.059 | [12] |
| 2 | TN_108_2_12 | no-card | 21.57 (21.57 24.12 23.05 21.21 19.54) | 21.71 (21.72 24.09 21.71 21.15 21.01) | 1.006 | 0.067 / 0.055 | [12] |
| 2 | TN_108_2_12 | card-mto | 20.84 (20.84 25.57 19.95 23.55 20.78) | 22.18 (22.18 25.77 20.02 23.54 20.88) | 1.065 | 0.055 / 0.056 | [12] |
| 2 | BB_144_14_14 | cc | 1.15 (1.19 1.24 1.13 1.12 1.15) | 1.15 (1.17 1.24 1.14 1.10 1.15) | 1.005 | 0.067 / 0.055 | [14] |
| 2 | BB_144_14_14 | no-card | 14.35 (14.35 14.76 14.39 14.23 14.17) | 14.17 (14.17 14.78 14.38 14.11 13.91) | 0.987 | 0.065 / 0.067 | [14] |
| 2 | BB_144_14_14 | card-mto | 14.35 (14.69 14.82 14.35 13.69 14.04) | 14.22 (14.81 14.88 14.22 13.64 14.17) | 0.991 | 0.067 / 0.062 | [14] |
| 2 | GB_144_12_12 | cc | 0.12 (0.13 0.11 0.12 0.12 0.12) | 0.12 (0.12 0.10 0.13 0.12 0.12) | 1.059 | 0.064 / 0.065 | [12] |
| 2 | GB_144_12_12 | no-card | 1.15 (1.17 1.10 1.15 1.15 1.16) | 1.15 (1.17 1.08 1.15 1.15 1.18) | 1.005 | 0.076 / 0.075 | [12] |
| 2 | GB_144_12_12 | card-mto | 1.19 (1.19 1.12 1.16 1.21 1.19) | 1.15 (1.19 1.12 1.15 1.15 1.17) | 0.972 | 0.087 / 0.067 | [12] |
| 2 | TN_200_10_10 | cc | 0.32 (0.23 0.36 0.31 0.32 0.35) | 0.33 (0.24 0.36 0.32 0.33 0.35) | 1.038 | 0.067 / 0.073 | [10] |
| 2 | TN_200_10_10 | no-card | 12.93 (12.93 13.73 12.59 13.49 12.77) | 12.94 (12.94 12.97 12.64 13.63 12.81) | 1.001 | 0.135 / 0.219 | [10] |
| 2 | TN_200_10_10 | card-mto | 12.79 (12.86 12.15 12.79 12.64 14.03) | 12.90 (12.90 12.20 13.72 12.56 14.84) | 1.009 | 0.138 / 0.227 | [10] |
| 2 | LP_442_68_10 | cc | 0.06 (0.06 0.06 0.08 0.06 0.06) | 0.07 (0.06 0.07 0.09 0.06 0.07) | 1.083 | 0.057 / 0.059 | [10] |
| 2 | LP_442_68_10 | no-card | 4.59 (3.12 4.67 4.11 4.86 4.59) | 3.99 (3.15 4.68 3.99 4.97 3.97) | 0.869 | 0.073 / 0.097 | [10] |
| 2 | LP_442_68_10 | card-mto | 4.88 (5.26 4.69 4.07 5.70 4.88) | 4.91 (5.27 4.65 4.17 5.46 4.91) | 1.006 | 0.085 / 0.094 | [10] |
| 2 | LP_544_80_12 | cc | 0.08 (0.08 0.09 0.08 0.08 0.08) | 0.08 (0.10 0.08 0.08 0.08 0.08) | 0.963 | 0.064 / 0.068 | [12] |
| 2 | LP_544_80_12 | no-card | 22.03 (23.44 25.82 22.03 19.41 16.34) | 22.03 (23.98 26.22 22.03 20.52 16.20) | 1.000 | 0.100 / 0.120 | [12] |
| 2 | LP_544_80_12 | card-mto | 21.11 (16.84 27.21 21.11 16.52 21.33) | 21.03 (16.09 26.37 21.16 16.56 21.03) | 0.996 | 0.111 / 0.110 | [12] |
| 3 | TN_144_2_13 | cc | 5.77 (2.09 5.77 6.96 6.52 5.55) | 5.78 (2.06 5.78 7.01 6.54 5.60) | 1.002 | 0.068 / 0.069 | [13] |
| 3 | TN_144_2_13 | no-card | 74.30 (70.28 71.85 74.30 78.12 88.26) | 75.22 (70.21 71.44 75.22 77.90 87.86) | 1.012 | 0.079 / 0.070 | [13] |
| 3 | TN_144_2_13 | card-mto | 72.95 (66.91 73.86 72.95 85.88 69.25) | 72.85 (67.21 72.88 72.85 86.37 68.80) | 0.999 | 0.079 / 0.070 | [13] |
| 3 | BB_288_12_18 | cc | 0.32 (0.33 0.31 0.33 0.31 0.32) | 0.32 (0.33 0.32 0.33 0.32 0.32) | 0.991 | 0.061 / 0.058 | [18] |
| 3 | BB_288_12_18 | no-card | 48.48 (54.77 48.48 48.41 44.06 54.53) | 48.23 (54.24 48.23 48.08 44.01 54.98) | 0.995 | 0.148 / 0.121 | [18] |
| 3 | BB_288_12_18 | card-mto | 49.51 (46.56 46.44 49.51 60.05 56.53) | 49.17 (45.89 46.31 49.17 59.92 56.36) | 0.993 | 0.154 / 0.121 | [18] |
| 4 | TN_250_10_15 | cc | 116.63 (66.74 105.87 116.63 125.51 117.73) | 117.09 (73.68 106.07 117.09 126.53 117.22) | 1.004 | 0.099 / 0.119 | [15] |
| 4 | TN_250_10_15 | no-card | 1557.07 (1301.56 1549.21 1686.71 1753.87 1557.07) | 1548.37 (1347.31 1533.32 1691.50 1638.55 1548.37) | 0.994 | 0.327 / 0.229 | [15] |
| 4 | TN_250_10_15 | card-mto | 1482.61 (1459.77 1488.62 1438.14 1527.69 1482.61) | 1483.86 (1453.96 1568.29 1459.51 1522.85 1483.86) | 1.001 | 0.309 / 0.238 | [15] |
| 4 | LP_714_100_16 | cc | 0.74 (0.67 0.82 0.91 0.74 0.74) | 0.78 (0.62 0.82 0.79 0.75 0.78) | 1.049 | 0.096 / 0.064 | [16] |
| 4 | LP_714_100_16 | no-card | 577.86 (718.93 566.55 680.88 577.86 523.68) | 579.37 (730.25 568.40 754.72 579.37 522.80) | 1.003 | 0.187 / 0.176 | [16] |
| 4 | LP_714_100_16 | card-mto | 593.75 (508.54 660.32 728.89 584.36 593.75) | 601.19 (510.56 645.78 717.59 573.04 601.19) | 1.013 | 0.185 / 0.175 | [16] |

| Tier | Engine / mode | cells | geomean new/old | max cell | cells > 1.25 |
|---:|---|---:|---:|---:|---:|
| 1 | cc | 1 | 0.983 | 0.983 | 0 |
| 1 | no-card | 1 | 1.017 | 1.017 | 0 |
| 1 | card-mto | 1 | 1.006 | 1.006 | 0 |
| 2 | cc | 6 | 1.012 | 1.083 | 0 |
| 2 | no-card | 6 | 0.977 | 1.006 | 0 |
| 2 | card-mto | 6 | 1.006 | 1.065 | 0 |
| 3 | cc | 2 | 0.996 | 1.002 | 0 |
| 3 | no-card | 2 | 1.004 | 1.012 | 0 |
| 3 | card-mto | 2 | 0.996 | 0.999 | 0 |
| 4 | cc | 2 | 1.026 | 1.049 | 0 |
| 4 | no-card | 2 | 0.999 | 1.003 | 0 |
| 4 | card-mto | 2 | 1.007 | 1.013 | 0 |

Reading: neutral, as expected. Both finders give U = d within 0.06-0.33 s on every panel code in both engines (the
"first d_ub = d" column), so nothing downstream changes: CC levels and MaxSAT probes are the same; the ratios
(0.87-1.08 per cell, 0.977-1.026 per tier and engine/mode) are seed and placement noise around 1 (the largest cell,
LP_442 CC 1.083, is 0.06 vs 0.07 s at the process floor; LP_442 no-card 0.869 is the same noise in the other
direction). 330/330 answers = stem, no run unsolved, 0 science problems.

### 4.2 Tier 5 (6 h, default seed, new finder) vs GH-140 (CC) and GH-144 (MaxSAT)

New runs: CC `-engine=cc -cc-stats -ub-search=on -ub-isd=stern -cc-trace=...` (27 codes) and MaxSAT `-no-card|-card-mto
-ub-pre=on -ub-isd=stern` (27 x 2), all 81 at once on cores 2-13, 15, 17-19, 21-49, 51-73, 75-77, 79-87, 89 (started
01:35; the panel ran on 11 other cores during the first 73 min, then the 4-hour finder runs of 4.3). Baselines: GH-140's CC Tier 5 with the old finder
(`GH-140/S1/server/tier5_on.jsonl`, binary `793905c`, same flags without `-ub-isd`) and GH-144's MaxSAT Tier 5
(`GH-144/S1/server/tier5.jsonl`, binary `6d2b7a1`, `-ub-pre=60`); same server, limits and rules, other sessions.
Table `S1/tier5_table.md` (`S1/runner/analyze_tier5.py`); raw `S1/server/tier5.jsonl`, logs and CC traces in
`S1/server/logs.tar.gz`. "ub @ s" = final upper bound and when it was first reached.

| Code | Engine / mode | baseline (GH-140 CC / GH-144 MaxSAT) | lb | ub @ s | **new finder (-ub-isd=stern)** | lb | ub @ s | change |
|---|---|---|---:|---|---|---:|---|---|
| BB_360_12_24 | cc | d=24 @ 194 s | 24 | 24 @ 0.1 | d=24 @ 205 s | 24 | 24 @ 0.0 | 1.06x time |
| BB_360_12_24 | no-card | TIMEOUT | 18 | 24 @ 0.1 | TIMEOUT | 18 | 24 @ 0.1 |  |
| BB_360_12_24 | card-mto | TIMEOUT | 18 | 24 @ 0.2 | TIMEOUT | 18 | 24 @ 0.1 |  |
| BB_756_16_ge30 | cc | TIMEOUT | 30 | 34 @ 344.1 | TIMEOUT | 30 | 34 @ 5.8 |  |
| BB_756_16_ge30 | no-card | TIMEOUT | 18 | 34 @ 8.4 | TIMEOUT | 18 | 34 @ 9.6 |  |
| BB_756_16_ge30 | card-mto | TIMEOUT | 18 | 34 @ 8.3 | TIMEOUT | 18 | 34 @ 9.6 |  |
| BB_864_4_ge30 | cc | TIMEOUT | 30 | 42 @ 10870.0 | TIMEOUT | 30 | 42 @ 3849.5 |  |
| BB_864_4_ge30 | no-card | TIMEOUT | 18 | 52 @ 10.3 | TIMEOUT | 18 | 50 @ 12.6 | ub 52->50 |
| BB_864_4_ge30 | card-mto | TIMEOUT | 18 | 52 @ 12.1 | TIMEOUT | 18 | 50 @ 12.6 | ub 52->50 |
| BB_1080_4_ge30 | cc | TIMEOUT | 30 | 66 @ 0.1 | TIMEOUT | 30 | 66 @ 0.1 |  |
| BB_1080_4_ge30 | no-card | TIMEOUT | 18 | 70 @ 16.8 | TIMEOUT | 18 | 60 @ 30.1 | ub 70->60 |
| BB_1080_4_ge30 | card-mto | TIMEOUT | 18 | 70 @ 16.9 | TIMEOUT | 18 | 60 @ 27.5 | ub 70->60 |
| LP_1020_136_16 | cc | d=16 @ 0 s | 16 | 16 @ 0.3 | d=16 @ 1 s | 16 | 16 @ 0.1 | 0.52x time |
| LP_1020_136_16 | no-card | d=16 @ 1254 s | 16 | 16 @ 1.1 | d=16 @ 1082 s | 16 | 16 @ 0.6 | 0.86x time |
| LP_1020_136_16 | card-mto | d=16 @ 1247 s | 16 | 16 @ 1.1 | d=16 @ 1078 s | 16 | 16 @ 0.5 | 0.86x time |
| LP_1054_140_20 | cc | d=20 @ 18 s | 20 | 20 @ 0.5 | d=20 @ 19 s | 20 | 20 @ 1.0 | 1.04x time |
| LP_1054_140_20 | no-card | TIMEOUT | 18 | 20 @ 3.4 | TIMEOUT | 18 | 20 @ 0.9 |  |
| LP_1054_140_20 | card-mto | TIMEOUT | 18 | 20 @ 3.4 | TIMEOUT | 18 | 20 @ 0.9 |  |
| LP_1122_148_20 | cc | d=20 @ 25 s | 20 | 20 @ 0.5 | d=20 @ 17 s | 20 | 20 @ 0.2 | 0.67x time |
| LP_1122_148_20 | no-card | TIMEOUT | 18 | 20 @ 5.1 | TIMEOUT | 18 | 20 @ 0.9 |  |
| LP_1122_148_20 | card-mto | TIMEOUT | 18 | 20 @ 6.6 | TIMEOUT | 18 | 20 @ 0.9 |  |
| LP_1428_184_24 | cc | d=24 @ 531 s | 24 | 24 @ 6.4 | d=24 @ 551 s | 24 | 24 @ 6.1 | 1.04x time |
| LP_1428_184_24 | no-card | TIMEOUT | 18 | 24 @ 27.1 | TIMEOUT | 18 | 24 @ 12.1 |  |
| LP_1428_184_24 | card-mto | TIMEOUT | 18 | 24 @ 27.1 | TIMEOUT | 18 | 24 @ 14.3 |  |
| LP_1768_224_22 | cc | d=22 @ 65 s | 22 | 22 @ 65.0 | d=22 @ 66 s | 22 | 22 @ 49.9 | 1.01x time |
| LP_1768_224_22 | no-card | TIMEOUT | 18 | 22 @ 60.2 | TIMEOUT | 18 | 22 @ 53.2 |  |
| LP_1768_224_22 | card-mto | TIMEOUT | 18 | 22 @ 60.2 | TIMEOUT | 18 | 22 @ 53.4 |  |
| LP_2610_744_16 | cc | d=16 @ 7 s | 16 | 16 @ 0.4 | d=16 @ 8 s | 16 | 16 @ 0.7 | 1.11x time |
| LP_2610_744_16 | no-card | TIMEOUT | 10 | 16 @ 12.1 | TIMEOUT | 10 | 16 @ 8.2 |  |
| LP_2610_744_16 | card-mto | TIMEOUT | 10 | 16 @ 12.2 | TIMEOUT | 10 | 16 @ 8.3 |  |
| TN_180_2_17 | cc | d=17 @ 191 s | 17 | 17 @ 0.0 | d=17 @ 197 s | 17 | 17 @ 0.1 | 1.03x time |
| TN_180_2_17 | no-card | d=17 @ 5760 s | 17 | 17 @ 0.1 | d=17 @ 6341 s | 17 | 17 @ 0.2 | 1.10x time |
| TN_180_2_17 | card-mto | d=17 @ 9885 s | 17 | 17 @ 0.2 | d=17 @ 10986 s | 17 | 17 @ 0.2 | 1.11x time |
| TN_216_4_18 | cc | d=18 @ 596 s | 18 | 18 @ 0.1 | d=18 @ 612 s | 18 | 18 @ 0.1 | 1.03x time |
| TN_216_4_18 | no-card | d=18 @ 9161 s | 18 | 18 @ 0.1 | d=18 @ 10397 s | 18 | 18 @ 0.1 | 1.13x time |
| TN_216_4_18 | card-mto | d=18 @ 10066 s | 18 | 18 @ 0.1 | d=18 @ 11063 s | 18 | 18 @ 0.1 | 1.10x time |
| TN_252_2_21 | cc | d=21 @ 10464 s | 21 | 21 @ 5.6 | d=21 @ 11141 s | 21 | 21 @ 38.6 | 1.06x time |
| TN_252_2_21 | no-card | TIMEOUT | 17 | 21 @ 0.4 | TIMEOUT | 17 | 21 @ 0.6 |  |
| TN_252_2_21 | card-mto | TIMEOUT | 17 | 21 @ 0.4 | TIMEOUT | 17 | 21 @ 0.6 |  |
| TN_288_2_ge9 | cc | TIMEOUT | 20 | 24 @ 59.2 | TIMEOUT | 20 | 24 @ 52.8 |  |
| TN_288_2_ge9 | no-card | TIMEOUT | 9 | 24 @ 0.7 | TIMEOUT | 9 | 24 @ 0.8 |  |
| TN_288_2_ge9 | card-mto | TIMEOUT | 9 | 24 @ 0.7 | TIMEOUT | 9 | 24 @ 0.8 |  |
| TN_324_4_ge9 | cc | TIMEOUT | 20 | 25 @ 11.5 | TIMEOUT | 20 | 25 @ 0.9 |  |
| TN_324_4_ge9 | no-card | TIMEOUT | 9 | 25 @ 0.6 | TIMEOUT | 9 | 25 @ 0.9 |  |
| TN_324_4_ge9 | card-mto | TIMEOUT | 9 | 25 @ 0.6 | TIMEOUT | 9 | 25 @ 0.9 |  |
| TN_360_4_ge17 | cc | TIMEOUT | 22 | 24 @ 89.9 | TIMEOUT | 22 | 24 @ 32.9 |  |
| TN_360_4_ge17 | no-card | TIMEOUT | 17 | 24 @ 1.1 | TIMEOUT | 17 | 24 @ 1.1 |  |
| TN_360_4_ge17 | card-mto | TIMEOUT | 17 | 24 @ 1.1 | TIMEOUT | 17 | 24 @ 1.1 |  |
| TN_396_4_ge17 | cc | TIMEOUT | 22 | 26 @ 1684.1 | TIMEOUT | 22 | 26 @ 27.6 |  |
| TN_396_4_ge17 | no-card | TIMEOUT | 17 | 27 @ 1.5 | TIMEOUT | 17 | 26 @ 2.0 | ub 27->26 |
| TN_396_4_ge17 | card-mto | TIMEOUT | 17 | 27 @ 1.0 | TIMEOUT | 17 | 26 @ 2.0 | ub 27->26 |
| TN_432_8_ge9 | cc | TIMEOUT | 21 | 29 @ 10731.3 | TIMEOUT | 21 | 29 @ 306.9 |  |
| TN_432_8_ge9 | no-card | TIMEOUT | 9 | 32 @ 5.8 | TIMEOUT | 9 | 33 @ 1.6 | ub 32->33 (higher) |
| TN_432_8_ge9 | card-mto | TIMEOUT | 9 | 32 @ 5.9 | TIMEOUT | 9 | 33 @ 1.6 | ub 32->33 (higher) |
| TN_468_4_ge17 | cc | TIMEOUT | 23 | 29 @ 815.6 | TIMEOUT | 23 | 29 @ 185.1 |  |
| TN_468_4_ge17 | no-card | TIMEOUT | 17 | 33 @ 1.9 | TIMEOUT | 17 | 29 @ 10.4 | ub 33->29 |
| TN_468_4_ge17 | card-mto | TIMEOUT | 17 | 33 @ 1.3 | TIMEOUT | 17 | 29 @ 10.3 | ub 33->29 |
| TN_496_2_ge17 | cc | TIMEOUT | 22 | 30 @ 2283.6 | TIMEOUT | 22 | 30 @ 3227.0 |  |
| TN_496_2_ge17 | no-card | TIMEOUT | 17 | 34 @ 2.9 | TIMEOUT | 17 | 32 @ 2.5 | ub 34->32 |
| TN_496_2_ge17 | card-mto | TIMEOUT | 17 | 34 @ 2.9 | TIMEOUT | 17 | 32 @ 2.4 | ub 34->32 |
| TN_504_2_ge17 | cc | TIMEOUT | 23 | 37 @ 3263.1 | TIMEOUT | 23 | 34 @ 6197.5 | ub 37->34 |
| TN_504_2_ge17 | no-card | TIMEOUT | 17 | 45 @ 4.3 | TIMEOUT | 17 | 47 @ 1.8 | ub 45->47 (higher) |
| TN_504_2_ge17 | card-mto | TIMEOUT | 17 | 45 @ 2.9 | TIMEOUT | 17 | 47 @ 1.9 | ub 45->47 (higher) |
| TN_540_4_ge9 | cc | TIMEOUT | 21 | 40 @ 9172.6 | TIMEOUT | 21 | 34 @ 9682.4 | ub 40->34 |
| TN_540_4_ge9 | no-card | TIMEOUT | 9 | 46 @ 2.5 | TIMEOUT | 9 | 40 @ 3.8 | ub 46->40 |
| TN_540_4_ge9 | card-mto | TIMEOUT | 9 | 46 @ 2.4 | TIMEOUT | 9 | 40 @ 3.8 | ub 46->40 |
| TN_576_2_ge9 | cc | TIMEOUT | 22 | 50 @ 1419.4 | TIMEOUT | 22 | 38 @ 2601.4 | ub 50->38 |
| TN_576_2_ge9 | no-card | TIMEOUT | 9 | 54 @ 2.9 | TIMEOUT | 9 | 43 @ 2.6 | ub 54->43 |
| TN_576_2_ge9 | card-mto | TIMEOUT | 9 | 54 @ 2.9 | TIMEOUT | 9 | 43 @ 2.7 | ub 54->43 |
| TN_612_2_ge17 | cc | TIMEOUT | 24 | 47 @ 6542.5 | TIMEOUT | 24 | 41 @ 263.1 | ub 47->41 |
| TN_612_2_ge17 | no-card | TIMEOUT | 17 | 62 @ 3.2 | TIMEOUT | 17 | 41 @ 4.7 | ub 62->41 |
| TN_612_2_ge17 | card-mto | TIMEOUT | 17 | 62 @ 3.2 | TIMEOUT | 17 | 41 @ 4.5 | ub 62->41 |
| TN_648_10_9to52 | cc | TIMEOUT | 21 | 33 @ 1380.8 | TIMEOUT | 21 | 33 @ 1902.6 |  |
| TN_648_10_9to52 | no-card | TIMEOUT | 9 | 65 @ 3.5 | TIMEOUT | 9 | 47 @ 3.7 | ub 65->47 |
| TN_648_10_9to52 | card-mto | TIMEOUT | 9 | 65 @ 3.5 | TIMEOUT | 9 | 47 @ 3.4 | ub 65->47 |
| TN_648_14_ge9 | cc | TIMEOUT | 21 | 32 @ 1848.1 | TIMEOUT | 21 | 31 @ 45.4 | ub 32->31 |
| TN_648_14_ge9 | no-card | TIMEOUT | 9 | 40 @ 3.2 | TIMEOUT | 9 | 31 @ 4.9 | ub 40->31 |
| TN_648_14_ge9 | card-mto | TIMEOUT | 9 | 40 @ 3.2 | TIMEOUT | 9 | 31 @ 4.9 | ub 40->31 |
| TN_684_2_ge9 | cc | TIMEOUT | 22 | 29 @ 8685.0 | TIMEOUT | 22 | 29 @ 3060.8 |  |
| TN_684_2_ge9 | no-card | TIMEOUT | 9 | 31 @ 14.6 | TIMEOUT | 9 | 31 @ 3.8 |  |
| TN_684_2_ge9 | card-mto | TIMEOUT | 9 | 31 @ 10.4 | TIMEOUT | 9 | 31 @ 3.8 |  |

solved cells: baseline 16, new 16; ub lower on 25, higher on 4; final lb higher on 0, lower on 0; science problems: []

Reading:
- **Solved cells and lower bounds: unchanged.** The same 16 of 81 cells are solved (CC: BB_360, LP_1020/1054/1122/
  1428/1768/2610, TN_180, TN_216, TN_252; MaxSAT: LP_1020, TN_180, TN_216 in both modes) and every unsolved cell ends
  with the same certified lower bound as its baseline (CC: BB 30, TN 20-24; MaxSAT: 17/18, 9 on the TN ge9 stems, 10 on
  LP_2610). Solve times are 0.52-1.13x of the baselines; the levels / probes are the same instances (U = d from the
  first second in both), and the differences follow the session: the MaxSAT TN_180 / TN_216 cells are 1.10-1.13x
  slower already in their first probes (lb 9 at 4.3 s vs 3.9 s on TN_180 no-card; GH-144 ran them on cores 95-98, this
  run on cores 36-40), the MaxSAT LP_1020 cells 0.86x faster from their first probes on.
- **Upper bounds: lower on 25 cells, equal on 52, higher on 4.** CC (finder time-sliced at 5 % of the wall time, 0.3 %
  after a plateau): BB_756 34 at 5.8 s instead of 344 s, BB_864 42 at 3 850 s instead of 10 870 s, TN_504 37 -> 34,
  TN_540 40 -> 34, TN_576 50 -> 38, TN_612 47 -> 41, TN_648_14 32 -> 31; TN_324 / TN_360 / TN_396 / TN_432 / TN_468 / TN_684
  reach the same value 3-61x earlier, TN_252 / TN_496 / TN_648_10 later (same value; the finder runs in 5 % slices); BB_1080 stays at its basis bound 66 in both (the finder never gets below 66 in the few seconds it
  has before the share decays; with full finder time it reaches 56-58 in 60 s, section 3.2). MaxSAT (U0 of the 60-s
  pre-pass, seed 0): BB_864 52 -> 50, BB_1080 70 -> 60, TN_468 33 -> 29, TN_496 34 -> 32, TN_540 46 -> 40, TN_576 54 -> 43,
  TN_612 62 -> 41, TN_648_10 65 -> 47, TN_648_14 40 -> 31, TN_396 27 -> 26; higher on TN_432 (32 -> 33) and TN_504 (45 -> 47)
  in both modes: one deterministic pre-pass per seed, and on these two codes seed 0 of the new finder stops on a worse
  plateau (over seeds 0-4 the median U0 is 32 -> 30 and 42 -> 42, section 3.4). On the MaxSAT path the U0 of an open code
  does not change any lower bound (all of them stay at the doubling cap, 17/18 or 9).
- 81 runs, 0 science problems (anytime bounds consistent with the stems), max RSS < 4 GB.

### 4.3 Extra: 4-hour finder-only runs with the new finder (seeds 5-7)

On the 11 panel cores after the panel (`S0/jobs/long14400.jsonl`, `S0/long14400_table.md`, raw
`S0/server/long14400.jsonl`, logs `S0/server/logs_long14400.tar.gz`): **BB_1080 reaches 48** (seeds 5 and 6, at 8 226 s
and 1 989 s; seed 7 56); TN_576 37 (both seeds), TN_612 40 (both), BB_864 40, TN_540 34, TN_504 34, TN_648_10 32 - the
same plateaus as the 3600-s runs.


## 5. Best verified upper bounds on the open codes (witnesses)

Files `witnesses/<stem>.<X|Z>.w<W>.txt` (support, 0-based qubit indices; header with the source run), extracted from
all S0 / S1 logs and CC traces by `witnesses/extract_witnesses.py` and checked by `witnesses/verify_witnesses.py`
(output `witnesses/VERIFY.txt`): every file passes Hx Hz^T = 0, H e = 0 and e not in rowspace(S), so it is a
nontrivial logical operator and d <= W. "Before" = the best upper bound of the project before this round (GH-140 S0
600 s over 3 seeds, GH-140 CC Tier 5, GH-144 Tier 5).

| code | certified lb (CC, 6 h) | best ub before GH-146 | **best verified ub (witness)** | old finder: seeds reaching it within 3600 s | new finder: seeds reaching it within 3600 s | file |
|---|---:|---:|---|---|---|---|
| BB_756_16_ge30 | 30 | 34 | **34** (X) | 5/5 (first at 0.2 s) | 5/5 (first at 0.4 s) | `BB_756_16_ge30.X.w34.txt` |
| BB_864_4_ge30 | 30 | 40 | **40** (X) | 5/5 (first at 16.7 s) | 5/5 (first at 0.7 s) | `BB_864_4_ge30.X.w40.txt` |
| BB_1080_4_ge30 | 30 | 56 | **48** (X) | 0/5 | 0/5 | `BB_1080_4_ge30.X.w48.txt` |
| TN_288_2_ge9 | 20 | 24 | **24** (Z) | 5/5 (first at 0.2 s) | 5/5 (first at 0.2 s) | `TN_288_2_ge9.Z.w24.txt` |
| TN_324_4_ge9 | 20 | 25 | **25** (X) | 5/5 (first at 0.1 s) | 5/5 (first at 0.1 s) | `TN_324_4_ge9.X.w25.txt` |
| TN_360_4_ge17 | 22 | 24 | **24** (Z) | 5/5 (first at 0.1 s) | 5/5 (first at 0.1 s) | `TN_360_4_ge17.Z.w24.txt` |
| TN_396_4_ge17 | 22 | 26 | **26** (X) | 5/5 (first at 0.4 s) | 5/5 (first at 0.1 s) | `TN_396_4_ge17.X.w26.txt` |
| TN_432_8_ge9 | 21 | 29 | **29** (X) | 5/5 (first at 3.0 s) | 5/5 (first at 0.3 s) | `TN_432_8_ge9.X.w29.txt` |
| TN_468_4_ge17 | 23 | 29 | **29** (Z) | 5/5 (first at 3.7 s) | 5/5 (first at 3.0 s) | `TN_468_4_ge17.Z.w29.txt` |
| TN_496_2_ge17 | 22 | 30 | **30** (Z) | 5/5 (first at 4.5 s) | 5/5 (first at 3.1 s) | `TN_496_2_ge17.Z.w30.txt` |
| TN_504_2_ge17 | 23 | 34 | **34** (X) | 4/5 (first at 60.2 s) | 5/5 (first at 2.9 s) | `TN_504_2_ge17.X.w34.txt` |
| TN_540_4_ge9 | 21 | 34 | **34** (X) | 4/5 (first at 528.2 s) | 5/5 (first at 6.0 s) | `TN_540_4_ge9.X.w34.txt` |
| TN_576_2_ge9 | 22 | 40 | **37** (X) | 0/5 | 3/5 (first at 57.1 s) | `TN_576_2_ge9.X.w37.txt` |
| TN_612_2_ge17 | 24 | 43 | **40** (Z) | 2/5 (first at 23.9 s) | 5/5 (first at 107.1 s) | `TN_612_2_ge17.Z.w40.txt` |
| TN_648_10_9to52 | 21 | 32 | **32** (X) | 5/5 (first at 65.4 s) | 5/5 (first at 16.2 s) | `TN_648_10_9to52.X.w32.txt` |
| TN_648_14_ge9 | 21 | 28 | **28** (Z) | 5/5 (first at 128.5 s) | 5/5 (first at 134.2 s) | `TN_648_14_ge9.Z.w28.txt` |
| TN_684_2_ge9 | 22 | 29 | **29** (Z) | 5/5 (first at 4.3 s) | 5/5 (first at 3.8 s) | `TN_684_2_ge9.Z.w29.txt` |

New upper bounds of the project: **BB_1080_4: 56 -> 48** (new finder, 4-hour runs, seeds 5 and 6; within 3600 s weight
50 was reached by one seed of each finder), **TN_576_2: 40 -> 37** (new finder only, 3 of 5 seeds within 3600 s, first
at 57 s; the old finder's best in 5 x 3600 s is 39), **TN_612_2: 43 -> 40** (new finder 5/5 seeds, old finder 2/5). All
other open codes keep their previous best value, which both finders re-find; with the new finder within seconds to
minutes. The `old.*` / `stern.*` / `long.*` prefixes in the files' source lines name the run (old = GH-140 finder, the
others = `-ub-isd=stern`; same binary). The gap to the certified lower bounds stays large (e.g. BB_1080 30..48,
TN_576 22..37, TN_612 24..40); closing it is a lower-bound problem.

## 6. Verdicts

| Gate | Criterion | Result | Verdict |
|---|---|---|---|
| Tier 0 (correctness / smoke) | tests pass, default path identical, witnesses valid, unverified-reporting mutant must fail | test-cc (+1500/600 on yfclab2) PASS, 321 flag checks PASS, 112/112 identical logs, mutant 12 8/8 and pre-pass mutant 2 13 wrong answers, 17/17 witnesses VALID, 0 science problems in 2 252 server runs | PASS |
| S0 (finder quality) | better ub vs time on the open codes; no loss on known-d codes | new <= old median on 17/17 codes at 60 / 600 / 3600 s, 5.1x shorter time to the common bound; d reached 170/170 in both arms, faster on LP_1428 / LP_1768 / TN_252 | PASS (gain) |
| Tier 1-4 panel (CC and MaxSAT, 5 seeds) | no regression (coordinator: geomean < 1, no cell > 1.25) | geomeans 0.977-1.026 (7 of 12 tier x engine/mode groups above 1.00, none above 1.026), max cell 1.083, 0 cells > 1.25 | neutral: no regression; strictly "not < 1" in 7 of 12 groups (process floor / seed noise; nothing to gain because U = d already) |
| Tier 5 (6 h) | no cell worse in solved / lb; bounds consistent | 16 = 16 solved, lb identical on all 65 unsolved cells, ub lower on 25 and higher on 4 (seed-0 pre-pass variance) | PASS |

**Recommendation.**
1. **Adopt `-ub-isd=stern` as the default collision mode of the shared finder** (P 2, L automatic, W 32, B 1). It finds
   the same or better verified upper bounds than the GH-140 enumeration on every open code at every checkpoint, about
   5x faster to the common plateau, new best bounds on BB_1080 / TN_576 / TN_612, and changes nothing on tiers 1-4 (U = d
   in both arms). Adoption is one line (`UbParams() ... isd(1)`), after which `-ub-search` (CC, still optional) and
   `-ub-pre` (MaxSAT, adoption pending from GH-144) use it; `-ub-isd=off` reproduces the old finder.
2. **Publishable bounds** (PI decision whether to record them in the stems, e.g. `BB_1080_4_30to48`, `TN_576_2_22to37`,
   `TN_612_2_24to40`, with the lower bounds of GH-138 / GH-140): every value is a verified witness in
   `witnesses/`, checked by an independent script.
3. **Next rounds, from these numbers.** (a) At 1 hour both finders meet on 15 of 17 open codes, so these plateaus are
   probably the minimum weights or close to it; more upper-bound work has small returns, the open gaps (BB 30..34-48, TN
   20-24..24-40) are lower-bound problems. (b) The CC driver gives the finder 5 % of the time and 0.3 % after a plateau,
   which leaves BB_1080 at its basis bound 66 in 6 h although the finder alone reaches 56-58 in 60 s: a fixed pre-pass
   (`-cc-ub-pre=60`) or a larger plateau would fix that at no cost to the levels. (c) The window keys of these LDPC codes
   are skewed (10-20x more collisions than for a random code); choosing the window among rows whose reduced columns are
   close to half dense, or p = 3 on one side, are the obvious refinements.

Scientific semantics changed: no. PI action required: yes (default of `-ub-isd`; whether to record the new upper
bounds in the stems).

## 7. Reproduction

Build: `make clean && make CXX="c++ -Wno-reserved-user-defined-literal"` (Mac) / `make -j8` (yfclab2). Tests:
`make test-cc`, `make test-cc-flags`, `./build/test_cc_engine 1500 600`. Identity (yfclab2, worktree root): `python3 -I
S0/ident.py ../frozen/server-gh144-6d2b7a1/distqldpc ../frozen/server-gh146-4f16e0d/distqldpc OUT 1`. S0: job files
`S0/jobs/*.jsonl` from `S0/make_jobs.py` (`OUT BUDGET SEEDS STEMS|tier5open|knownd ARM=flags ...`), runner
`python3 -I S0/queue.py --bin BIN --cpus LIST --jobs JOBS --out DIR`; pre-pass `python3 -I S0/prepass_runs.py --bin BIN
--cpus LIST --budget 60 --seeds 0,1,2,3,4 [--extra=-ub-isd=stern] --out DIR`; the chain actually run is `S0/run_s0.sh`
(tuning panels before it: `S0/jobs/explore1.jsonl`, `tune300.jsonl`, `tune2.jsonl` with a pre-commit build of the same
finder code). Tables: `S0/analyze.py RESULTS T1,T2 LOGDIR`, `S0/score.py`, `S0/time_to_target.py`,
`S0/prepass_compare.py`. S1: `S1/runner/make_jobs.py BIN OUTDIR`, `S1/runner/run_s1.sh` (Tier 5 on 81 cores, panel on
11 cores, concurrently), `S1/runner/analyze_panel.py`, `S1/runner/analyze_tier5.py NEW GH-140/S1/server/tier5_on.jsonl
GH-144/S1/server/tier5.jsonl`. Witnesses: `witnesses/extract_witnesses.py witnesses LOGDIR|TRACEDIR ...`,
`witnesses/verify_witnesses.py data/matrices witnesses/*.txt`. Raw logs: `S0/server/logs.tar.gz`,
`S1/server/logs.tar.gz`.
