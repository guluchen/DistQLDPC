# GH-140 report: in-house randomized upper-bound finder feeding the CC stop rule (`-ub-search`)

Issue: https://github.com/guluchen/DistQLDPC/issues/140 (hub #15). Baseline: main `c914ef5` plus the GH-138 overlap
rule (branch `experiment/gh-138-overlap`, `f76c6d6`, PR #139, not yet merged). Candidate: branch
`experiment/gh-140-ub-search`. Evaluated binary `793905c` (panel, Tier 5). The final commit `f6abb8a` only adds the
optional `-cc-ub-evo` flag (default off; defaults search-identical to `793905c`); the S0 finder-only runs used
`1c3e91b` (same finder code; the later commits changed only the driver's schedule). Literature basis:
`docs/LITERATURE_CC_2026.md` (random information sets, QDistRnd, dist-m4ri RW and bracketing, QDistEvol).
Clean-room: written from the published one-paragraph descriptions and the GF(2) mathematics; no code of dist-m4ri,
QDistRnd, codeDistance/QDistEvol or Qubitserf was read. No external solver was used.

## Summary

| Item | Result |
|---|---|
| Default MaxSAT path | byte-identical to main `c914ef5`: 28/28 `-v` logs identical on tier0+1 x {`-no-card`, `-card-mto`} for `1c3e91b` and for the final `f6abb8a` (yfclab2) |
| Finder alone (S0, 600 s, 3 seeds, no basis bound) | **reaches the true d on all 34 bundled codes with a known d, in every seed (102/102)**: 31 codes in < 0.5 s from process start, LP_1428 1.9 s, LP_1768 13 s; TN_252_2_21: weight 21 in 0.13-0.16 s |
| Open codes, finder ub (S0, 600 s) | BB_756 **34** in 0.3-5 s (Bravyi / Webster value; basis bound 52); BB_864 40-44 (basis 108); BB_1080 56-64 (basis 66); TN ge stems 24-47 (basis 32-68), stable across seeds up to n ~ 500, still falling at n >= 504 |
| **Tier 5 (6 h): TN_252_2_21 solved, d = 21 at 10 464 s** | first CC solve of TN_252 within 6 h: ub 21 from the finder at 5.6 s, the stop rule finishes as soon as both halves have lb 21 (the off arm in the same session and GH-138 time out at lb 21 / ub 28); solved codes 9 -> **10 of 27** |
| Tier 5 ub columns | 17 open codes get finder upper bounds instead of basis rows: BB_756 34, BB_864 42, TN_288 24, TN_324 25, TN_360 24, TN_396 26, TN_432 29, TN_468 29, TN_496 30, TN_504 37, TN_540 40, TN_576 50, TN_612 47, TN_648_14 32, TN_648_10 33, TN_684 29 (BB_1080 stays 66 at the decayed default share; 56 with 600 s of full finder time in S0) |
| Tier 5 lower bounds | identical to GH-138 and to the off arm on every code (no level lost); per-level node counts identical on/off (852/852 completed EMPTY levels); level seconds on/off for levels run concurrently: median 1.005 (23 levels) |
| Tier 1-4 panel, `-engine=cc` off vs on, 5 seeds x 2 repetitions (yfclab2) | pooled geomean on/off: tier1 1.000 (process floor), **tier2 0.760**, **tier3 0.916**, tier4 1.010 (LP_714 1.052, TN_250 0.969); max cell 1.068 (BB_288); gains GB_144_12_12 0.41x, TN_200 0.52x, TN_144 0.79x; 330/330 answers correct |
| Correctness | `make test-cc` (new Part E: finder on 400 halves reaches d_h on 400/400, every word valid and >= d_h; 1 600 driver runs; rotated surface codes; 34 abandoned levels) and `test_cc_engine 1500 600` (1 200 halves, 4 800 driver runs, 100 abandoned levels) pass; mutants 11/12 fail as required; `make test-cc-flags` 241 checks pass; 0 science problems in 472 S0 + 330 panel + 55 Tier 5 runs |
| Gates | Tier 0 PASS; Tier 1 neutral (process floor); Tier 2 PASS; Tier 3 PASS; **Tier 4 not < 1 (1.010 pooled, within noise; strictly a FAIL of the coordinator criterion)**; Tier 5 PASS (+1 solved code, ub on 16 more codes, no bound lost) |
| Recommendation | keep the flag; code default left **off** because Tier 4 does not meet "geomean < 1"; recommend the PI approve **`-ub-search=on` as the CC default** (share 0.05) as an exception: the Tier 4 excess is the finder's 5 % share on two codes with nothing to save, inside the server noise, and the gain is a new Tier 5 solve plus realistic upper bounds |

Scientific semantics changed: no. The finder only produces upper bounds; each is a GF(2)-verified nontrivial logical
(the same independent test as CC witnesses). Lower bounds still come only from exhaustive CC levels, and the
termination rule (d = U once every half's certified lower bound reaches U) is unchanged.

## 1. What was implemented (S0)

**Finder (`src/cc/cc_ubsearch.{h,cc}`, class `UbFinder`, one per searched CSS half).** One iteration:
1. random column order (Fisher-Yates with splitmix64; the sequence is fixed by `-seed` / `-cc-seed` and the half);
2. Gauss-Jordan elimination of the half's parity matrix H with pivot columns taken greedily in that order; the r
   pivot columns form the redundancy set, the other K = n - r columns the information set I;
3. the systematic kernel basis c_j = e_j + sum_i A[i][j] e_{P_i} (j in I); H c_j = 0 by construction;
4. enumeration of single basis words (weight 1 + |A_j|), pairs (2 + |A_j xor A_k|) and, with `-cc-ub-triples=K` on
   small information sets, triples; a word is kept when its weight is at most U - 1 + slack (slack 4) and its detector
   parity G c is nonzero (nontrivial; with the complete detectors checked at start-up, ker [H; G] = rs S);
5. greedy local improvement of the (at most 64) lightest kept words: add a same-type stabilizer row g while
   |c & g| > |g|/2 (the weight drops, the logical class is unchanged).
The lightest result below U is handed to the driver.

**Driver (`src/cc/cc_driver.cc`).** The ladder stays single-threaded; the finder is time-sliced into the same thread:
at the top of every ladder iteration and, through a new `HalfSearch::set_poll` callback, every 16 384 search nodes
inside a level. The finder is due while its time (all time spent in the poll loop) is below `pre + share x elapsed`
(defaults: pre 0, share 0.05; `budget:S` caps the total). The share drops to share/16 once 16 iterations re-found U
without improving it, or after a plateau of max(64, 4 x the iteration count of the last improvement) iterations; an
improvement restores it (a QDistRnd-style convergence heuristic; scheduling only). Every word is verified by
`verify_in_half` (H e = 0 and e not in rs S by the driver's own echelon form; with a verified XZ-dual map, the image in
the Z half too) before it lowers ub_h and U and is reported as `UB` on the existing pipe (`c d_ub`). When U <= w for
the level w in progress, the level is abandoned (`LEVEL_ABORTED`, lb unchanged) and the stop rule LB >= U decides. A
finder word lighter than a half's certified lb traps (`lb > ub`), as for CC witnesses.

**Flags.** `-ub-search=off|on|budget:S` (CC family: needs `-engine=cc|auto`; default off); tuning `-cc-ub-pre=S`,
`-cc-ub-share=F`, `-cc-ub-hits=H` (0 = never reduce the share), `-cc-ub-triples=K`, `-cc-ub-slack=L`,
`-cc-ub-evo=MU` (column-order evolution; not adopted, 3.3); `-cc-ub-only` (with `budget:S`: finder alone, no ladder,
`s UNKNOWN` with a `c d_ub`; used for S0). `-cc-ub-*` without `-ub-search=on|budget:S` is rejected. `-v` prints the
finder setup, every improvement with its witness and the share reduction; `-cc-stats` prints per-half finder
statistics; `-cc-trace` records `UB-SEARCH` and `ABORTED` lines. Docs: README (CC section), MODIFICATIONS.md (GH-140).

**Determinism.** For a given seed the finder's sequence of column orders and words is fixed (checked in `make
test-cc`); how many iterations fit in a wall-time slice depends on the machine, so the time at which a bound arrives
varies, never the answer.

**Schedule history (all in S0, before S1 was decided).** `1c3e91b`: share 0.1, no decay. `2501a46`: share / 16 after
16 re-hits of U. The first panel with `2501a46` (aborted, kept as `S1/server/panel_logs.tar.gz:panel_v1_2501a46_aborted`)
showed tier4 1.04-1.08 and BB_288 1.13 (the basis bound already equals d there and re-hits of weight 18 are rare), so
`793905c` lowered the share to 0.05 and added the plateau rule. All S1 numbers are `793905c`.

**Orbit-biased permutations: not implemented.** The finder reaches the known distance of every bundled code with a
known d in < 1 s on 31 of 34 codes (section 3), so there was nothing for an orbit bias to gain where it could be
measured; the weak cases are the largest open codes, where the obstacle is the size of the information set.

## 2. Correctness

| Check | Runs | Result |
|---|---:|---|
| Default MaxSAT path vs main `c914ef5` (`-v` logs, tier0+tier1 x `-no-card`/`-card-mto`, time fields masked; yfclab2, pinned) | 28 + 28 | 28/28 identical for `1c3e91b` (`S0/identity_tier01.txt`) and 28/28 for `f6abb8a` (`S1/server/final_f6abb8a_identity.txt`) |
| `make test-cc` Parts A, B, D (GH-138 checks, unchanged) | 115 200 ladders + 2 800 driver + 400 MaxSAT | 0 bad (`1c3e91b`, `793905c`, `f6abb8a`) |
| Part E (a): finder alone on the 400 halves of the Part B codes, 300 iterations each (triples on half of them): every word in ker H, nontrivial, below the target, >= the half's true distance; a second finder with the same seed returns the same words | 400 halves | 0 bad, 0 nondeterministic, **reached d_h on 400/400** |
| Part E (b): driver with the finder, 8 configurations (pre-pass, share 0.9 with a poll at every node, two late-start configurations, dual off + seed 3, sequential schedule, `-ub-basis=off`, finder-only) | 1 600 | 0 bad (answer = enumeration, every UB >= d, LBs monotone); 34 levels abandoned (U <= w) |
| Part E on rotated surface codes d = 3, 4 (and X/Z swapped; weight-2 stabilizers lighter than d) | 16 | 0 bad |
| Mutant 11 (finder without detector check and without local improvement) | 28 halves / 6 driver runs where a trivial word is lighter than d | finder returned a trivial word on 28/28; the driver's verification stopped 6/6 runs (trap) |
| Mutant 12 (mutant 11 + words reported without the driver's verification) | 6 | 6/6 wrong `RESULT d OPTIMAL` below the true d |
| Mutants 1-10 | - | all still fail as required |
| Large run `test_cc_engine 1500 600` (`f6abb8a`, yfclab2) | 576 000 ladders, 8 400 + 4 800 driver runs, 1 200 finder halves | 0 bad; finder reached d_h on 1 200/1 200; 100 abandoned levels; mutants 11 (76/76, 10/10) and 12 (10/10 wrong) fail |
| `make test-cc-flags` (new: `-ub-search` values, `-cc-ub-*` values and conflicts, `-v` lines, finder-only output, mutant 11 trap and mutant 12 wrong answer on BB_90_8_10, canonical answer) | 241 | PASS (Mac and yfclab2) |
| S0 finder-only runs: every ub >= the stem's lower value | 472 | 0 science problems |
| Panels (3 x 110) and Tier 5 (27 on + 27 off + 1 seed-1 run): answers in the stem range, lb <= stem upper value, ub >= stem lower value; max RSS 80 MB | 385 | 0 science problems, 0 traps |

## 3. S0: the finder alone (yfclab2, `-cc-ub-only`, 600 s, seeds 0-2, one pinned core each, 4 GB cap)

Times are wall seconds from process start (matrix parse, detector check and dual-map detection included; the finder
itself starts after ~0.03-0.1 s). Arm `nobasis` = `-ub-basis=off` (the finder must find everything itself); arm
`base` = default `-ub-basis` (first `c d_ub` = basis-row bound). Full tables: `S0/finder_table.md`
(`S0/analyze_finder.py`); raw: `S0/server/finder_*.jsonl`, logs `S0/server/finder_logs.tar.gz`.

### 3.1 Codes with a known distance: time until ub = d (arm nobasis)

**The finder reaches the true d on all 34 codes with a numeric stem, in all 3 seeds (102/102 runs).**

| Tier | codes | time to ub = d, median over seeds (s) |
|---:|---|---|
| 0 | BB_72, BB_90, BB_108, BB_144_12_12, GB_144_12_8, LP_34, LP_136, LP_238, TN_36_8_3, TN_36_8_4, TN_54, TN_72_14_4, TN_72_8_8 | 0.04-0.07 each |
| 1 | LP_340_56_8 | 0.04 |
| 2 | BB_144_14_14, GB_144_12_12, LP_442, LP_544, TN_108, TN_200 | 0.05-0.09 |
| 3 | BB_288_12_18, TN_144_2_13 | 0.06, 0.06 |
| 4 | LP_714_100_16, TN_250_10_15 | 0.12 (0.06-0.44), 0.07 |
| 5 | BB_360_12_24 0.07; TN_180_2_17 0.06; TN_216_4_18 0.07; **TN_252_2_21 0.15 (0.13-0.16)**; LP_1020 0.14; LP_1054 0.14; LP_1122 0.10; LP_2610 0.41; LP_1428 1.94 (0.39-1.97); LP_1768 13.1 (11.6-22.5) | |

### 3.2 Open codes: best ub (arm nobasis; per seed), with GH-138's certified lb and the basis bound

| Code | GH-138 lb (6 h) | basis ub | finder ub @ 60 s | finder ub @ 600 s (first reached at, s) |
|---|---:|---:|---|---|
| BB_756_16_ge28 | 30 | 52 | 34/34/34 | **34/34/34** (1.0, 5.3, 0.3) |
| BB_864_4_ge28 | 30 | 108 | 42/50/48 | 40/42/44 (275, 416, 149) |
| BB_1080_4_ge28 | 30 | 66 | 72/70/64 | 62/64/56 (570, 557, 399) |
| TN_288_2_ge9 | 20 | 32 | 24/24/24 | 24 (0.2-0.7) |
| TN_324_4_ge9 | 20 | 36 | 25/25/25 | 25 (0.1-1.2) |
| TN_360_4_ge17 | 22 | 40 | 24/24/24 | 24 (0.3-0.7) |
| TN_396_4_ge17 | 22 | 44 | 26/26/26 | 26 (0.4-5.6) |
| TN_432_8_ge9 | 21 | 36 | 29/29/29 | 29 (2.7-53) |
| TN_468_4_ge17 | 23 | 52 | 29/29/29 | 29 (3.0-27) |
| TN_496_2_ge17 | 22 | 64 | 30/30/32 | 30/30/30 (6.7-103) |
| TN_504_2_ge17 | 23 | 56 | 39/38/34 | 37/34/34 |
| TN_540_4_ge9 | 21 | 50 | 42/39/45 | 35/34/35 |
| TN_576_2_ge9 | 22 | 64 | 50/51/46 | 40/41/40 |
| TN_612_2_ge17 | 24 | 68 | 53/48/53 | 47/43/43 |
| TN_648_10_9to52 | 21 | 52 | 33/34/50 | 33/34/32 |
| TN_648_14_ge9 | 21 | 54 | 32/32/34 | 31/32/28 |
| TN_684_2_ge9 | 22 | 57 | 29/29/30 | 29 (3.5-235) |

Reading: BB_756 reaches the value 34 of Bravyi et al. / Webster et al. within seconds in every seed. Up to n ~ 500
the TN ubs settle within seconds to a minute and agree across seeds. For the largest codes (BB_864/1080, TN_504-648)
the ub is still falling at 600 s and differs between seeds, so these values are probably not the distances: with
p <= 2 a minimum word must have at most two ones on an information set of about n/2 columns, which becomes rare at
d ~ 30-40. The gap between the certified lb (20-24) and these ubs (24-47) on the TN stems is what remains open.

### 3.3 Finder variants (tier 3-5 codes, seeds 0-1, 600 s, nobasis)

| Variant | Effect |
|---|---|
| `-cc-ub-triples=400` (triples on information sets <= 400 columns) | no gain: TN_252 time to 21 0.12 s (vs 0.15); BB_864 40/42; worse on TN_576-648 (more time per iteration): TN_612 44/60, TN_648_10 33/39 |
| `-cc-ub-slack=8` | marginal: BB_864 40/40 (vs 40/42), TN_648_14 31/30, otherwise equal |
| `-cc-ub-evo=10` (QDistEvol-like column-order evolution, our simple variant: mu = 10, 1..n/50 transpositions, fitness = lightest nontrivial word, then mean nontrivial systematic weight) | worse: TN_252 time to 21 3.3 / 127 s (vs 0.15), TN_288 25 (vs 24), TN_576 39/51; BB unchanged |

The default stays: pairs, slack 4, fresh random orders. None of the variants is adopted.

### 3.4 End-to-end effect inside CC (Tier 5 runs, section 5)

- **TN_252_2_21**: ub 28 (basis) -> 23 @ 0.1 s -> 22 @ 5.6 s -> **21 @ 5.6 s**; levels as without the finder (Z20 EMPTY
  at 5 575 s, X20 EMPTY at 10 464 s); with lb 21 in both halves and U = 21 the stop rule returns **d = 21 at 10 464 s**
  without the level-21 searches (the off arm reaches lb 21 at 10 553 s and then spends the remaining 3 h in level 21
  without finishing; GH-138 the same). A relabeled run (`-seed=1`, same finder ub 21) is much slower in the ladder
  itself (lb 19 at 7 875 s, lb 20 not reached in 6 h), as GH-138 saw for TN_468 seed 1; the stop needs lb 21.
- **BB_756/864/1080**: ub 52 -> 34 (at 344 s), 108 -> 42 (at 10 870 s), 66 unchanged in 6 h (the default share
  decays to 0.3 % between improvements; S0 with 600 s of full finder time reaches 56-64). Certified lb 30 unchanged.

## 4. S1 Tier 1-4 panel, `-engine=cc` with `-ub-search=off` vs `-ub-search=on` (yfclab2, cores 2-9, 4 GB cap, seeds 0-4)

Binary `793905c`, limits tier1-3 1800 s, tier4 5000 s, both arms of a (code, seed) back to back, `-cc-stats` in both
arms (GH-138 rules). The panel was run twice (repetitions 1 and 2, same jobs); a third panel ran the "on" arm with
`-cc-ub-share=0.02` as a sensitivity check. Wall seconds, medians; "first d_ub = d" = median wall time of the first
`c d_ub` equal to the answer (on: the finder's word; off: the basis bound or the CC hit). Raw:
`S1/server/panel*.jsonl`, logs `S1/server/panel_logs.tar.gz`; tables `S1/panel_table.md`, `S1/panel_rep2_table.md`,
`S1/panel_pooled_table.md`, `S1/panel_share002_table.md` (`S1/runner/analyze_panel.py`; several files are pooled with
each (file, seed) as one sample).

Pooled repetitions 1 + 2 (10 samples per arm and cell):

| Tier | Code | off wall median (range) | on wall median (range) | ratio on/off | nodes on/off | first d_ub = d: on / off (s) | answers |
|---:|---|---|---|---:|---:|---|---|
| 1 | LP_340_56_8 | 0.025 (0.022-0.027) | 0.025 (0.021-0.031) | 1.000 | 0.969 | 0.023 / 0.024 | 8 |
| 2 | BB_144_14_14 | 1.268 (1.152-1.427) | 1.203 (1.091-1.330) | 0.948 | 0.946 | 0.026 / 1.268 | 14 |
| 2 | GB_144_12_12 | 0.211 (0.133-0.353) | 0.086 (0.075-0.097) | **0.411** | 0.340 | 0.031 / 0.210 | 12 |
| 2 | LP_442_68_10 | 0.026 (0.024-0.031) | 0.026 (0.023-0.031) | 0.981 | 0.907 | 0.024 / 0.026 | 10 |
| 2 | LP_544_80_12 | 0.048 (0.045-0.050) | 0.046 (0.043-0.050) | 0.979 | 0.932 | 0.035 / 0.047 | 12 |
| 2 | TN_108_2_12 | 2.226 (0.880-3.126) | 2.228 (0.888-3.140) | 1.001 | 1.000 | 0.025 / 0.025 | 12 |
| 2 | TN_200_10_10 | 0.577 (0.195-0.701) | 0.297 (0.195-0.355) | **0.515** | 0.512 | 0.027 / 0.577 | 10 |
| 3 | BB_288_12_18 | 0.288 (0.275-0.311) | 0.307 (0.286-0.332) | 1.068 | 1.000 | 0.025 / 0.026 | 18 |
| 3 | TN_144_2_13 | 7.991 (3.165-13.236) | 6.284 (2.068-7.703) | **0.786** | 0.652 | 0.035 / 7.990 | 13 |
| 4 | LP_714_100_16 | 0.795 (0.634-1.495) | 0.837 (0.662-0.962) | 1.052 | 0.991 | 0.090 / 0.794 | 16 |
| 4 | TN_250_10_15 | 125.612 (75.696-180.751) | 121.764 (73.002-129.312) | 0.969 | 0.955 | 0.077 / 125.610 | 15 |

| Tier | cells | rep 1 geomean (max cell) | rep 2 geomean (max cell) | **pooled geomean (max cell)** | share-0.02 panel geomean (max cell) | cells > 1.25 (pooled) |
|---:|---:|---|---|---|---|---:|
| 1 | 1 | 0.957 (0.957) | 1.000 (1.000) | **1.000** (1.000) | 1.000 (1.000) | 0 |
| 2 | 6 | 0.766 (1.000) | 0.768 (1.005) | **0.760** (1.001) | 0.801 (1.286: LP_442 at the 0.03 s process floor) | 0 |
| 3 | 2 | 0.894 (1.042) | 0.911 (1.060) | **0.916** (1.068) | 0.873 (1.000) | 0 |
| 4 | 2 | 1.045 (1.103) | 1.012 (1.037) | **1.010** (1.052) | 0.934 (0.984) | 0 |

330 panel runs, 0 science problems, every answer = stem.

Reading. The finder reaches d at 0.02-0.09 s on every panel code. It saves time exactly where the basis-row bound is
above d, so that CC must otherwise complete the hit level (and, under lockstep, the other half's level d):
GB_144_12_12 0.41x, TN_200 0.52x, TN_144 0.79x, BB_144_14_14 0.95x, TN_250 0.97x (its hit level is a small part of
the run). Where the basis bound already equals d (TN_108, BB_288) or the hit level costs almost nothing (LP_714: its
X16 level has ~0 nodes), nothing can be saved and the cost is the finder's share: BB_288 +7 %, LP_714 +5 % (its
off-arm range 0.63-1.50 s shows server noise of the same size; node ratio 0.991). The node column is deterministic:
the "on" arm never searches more nodes. With share 0.02 the tier-4 cells are below 1 (0.934) but one process-floor
cell of tier 2 is above 1.25, i.e. the share mainly trades a few percent on no-benefit codes against noise.

## 5. S1 Tier 5 (yfclab2, 6 h, default seed)

On arm: `-engine=cc -cc-stats -ub-search=on`, cores 10-36 (started 08:32). Off arm: same binary without the finder,
cores 37-63 (started 09:35, same session; it ran while the first hour of the on arm overlapped the S0 finder-only
runs on 63 other cores, so early levels of the on arm ran under more load). GH-138 column: GH-138's Tier 5 (same
rules, binary `fc41a01`, other session). "ub @ s" = final upper bound and when it was first reached. Raw:
`S1/server/tier5_on.jsonl`, `tier5_off.jsonl`, `xcheck_TN252_seed1.jsonl`, logs `S1/server/tier5_logs.tar.gz`;
`S1/runner/analyze_tier5.py` (`S1/tier5_table.md`), `S1/runner/level_overhead.py` (`S1/tier5_level_overhead.md`).

| Code | GH-138 (6 h) | ub | off, this session | ub | **on (ub-search)** | lb | ub @ s | time to the final lb (s): GH-138 / off / on | completed levels: same nodes on/off |
|---|---|---|---|---|---|---:|---|---|---|
| BB_360_12_24 | d=24 @ 172 s | 24 @ 171.9 | d=24 @ 188 s | 24 @ 187.5 | **d=24 @ 194 s** | 24 | 24 @ 0.1 | 168 / 183 / 194 | 11/11 |
| BB_756_16_ge28 | timeout, lb 30 | 52 @ 0.0 | timeout, lb 30 | 52 @ 0.1 | **timeout, lb 30** | 30 | 34 @ 344.1 | 16250 / 17553 / 17648 | 14/14 |
| BB_864_4_ge28 | timeout, lb 30 | 108 @ 0.1 | timeout, lb 30 | 108 @ 0.1 | **timeout, lb 30** | 30 | 42 @ 10870.0 | 11329 / 12487 / 12596 | 14/14 |
| BB_1080_4_ge28 | timeout, lb 30 | 66 @ 0.1 | timeout, lb 30 | 66 @ 0.1 | **timeout, lb 30** | 30 | 66 @ 0.1 | 13633 / 14748 / 14751 | 14/14 |
| LP_1020_136_16 | d=16 @ 0 s | 16 @ 0.5 | d=16 @ 0 s | 16 @ 0.4 | **d=16 @ 0 s** | 16 | 16 @ 0.3 | 0 / 0 / 0 | 14/14 |
| LP_1054_140_20 | d=20 @ 19 s | 20 @ 19.4 | d=20 @ 17 s | 20 @ 16.9 | **d=20 @ 18 s** | 20 | 20 @ 0.5 | 19 / 17 / 18 | 18/18 |
| LP_1122_148_20 | d=20 @ 13 s | 20 @ 12.9 | d=20 @ 15 s | 20 @ 14.6 | **d=20 @ 25 s** | 20 | 20 @ 0.5 | 13 / 15 / 25 | 18/18 |
| LP_1428_184_24 | d=24 @ 443 s | 24 @ 442.7 | d=24 @ 491 s | 24 @ 491.1 | **d=24 @ 531 s** | 24 | 24 @ 6.4 | 442 / 491 / 531 | 22/22 |
| LP_1768_224_22 | d=22 @ 53 s | 22 @ 53.3 | d=22 @ 60 s | 22 @ 59.5 | **d=22 @ 65 s** | 22 | 22 @ 65.0 | 51 / 56 / 62 | 20/20 |
| LP_2610_744_16 | d=16 @ 8 s | 16 @ 7.6 | d=16 @ 6 s | 16 @ 6.2 | **d=16 @ 7 s** | 16 | 16 @ 0.4 | 7 / 6 / 7 | 14/14 |
| TN_180_2_17 | d=17 @ 275 s | 17 @ 274.8 | d=17 @ 265 s | 17 @ 264.9 | **d=17 @ 191 s** | 17 | 17 @ 0.0 | 190 / 184 / 191 | 32/32 |
| TN_216_4_18 | d=18 @ 578 s | 18 @ 578.3 | d=18 @ 631 s | 18 @ 630.7 | **d=18 @ 596 s** | 18 | 18 @ 0.1 | 506 / 552 / 596 | 34/34 |
| TN_252_2_21 | timeout, lb 21 | 28 @ 0.0 | timeout, lb 21 | 28 @ 0.0 | **d=21 @ 10464 s** | 21 | 21 @ 5.6 | 9395 / 10553 / 10464 | 40/40 |
| TN_288_2_ge9 | timeout, lb 20 | 32 @ 0.0 | timeout, lb 20 | 32 @ 0.0 | **timeout, lb 20** | 20 | 24 @ 59.2 | 10236 / 11065 / 11127 | 38/38 |
| TN_324_4_ge9 | timeout, lb 20 | 36 @ 0.0 | timeout, lb 20 | 36 @ 0.0 | **timeout, lb 20** | 20 | 25 @ 11.5 | 8844 / 9754 / 10579 | 39/39 |
| TN_360_4_ge17 | timeout, lb 22 | 40 @ 0.0 | timeout, lb 22 | 40 @ 0.1 | **timeout, lb 22** | 22 | 24 @ 89.9 | 9627 / 8948 / 9018 | 43/43 |
| TN_396_4_ge17 | timeout, lb 22 | 44 @ 0.0 | timeout, lb 22 | 44 @ 0.1 | **timeout, lb 22** | 22 | 26 @ 1684.1 | 8052 / 8841 / 8999 | 43/43 |
| TN_432_8_ge9 | timeout, lb 21 | 36 @ 0.0 | timeout, lb 21 | 36 @ 0.0 | **timeout, lb 21** | 21 | 29 @ 10731.3 | 14084 / 15599 / 15828 | 40/40 |
| TN_468_4_ge17 | timeout, lb 23 | 52 @ 0.0 | timeout, lb 23 | 52 @ 0.0 | **timeout, lb 23** | 23 | 29 @ 815.6 | 18316 / 20096 / 20384 | 44/44 |
| TN_496_2_ge17 | timeout, lb 22 | 64 @ 0.0 | timeout, lb 22 | 64 @ 0.0 | **timeout, lb 22** | 22 | 30 @ 2283.6 | 9796 / 10819 / 10978 | 43/43 |
| TN_504_2_ge17 | timeout, lb 23 | 56 @ 0.0 | timeout, lb 23 | 56 @ 0.1 | **timeout, lb 23** | 23 | 37 @ 3263.1 | 7900 / 8609 / 9184 | 45/45 |
| TN_540_4_ge9 | timeout, lb 21 | 50 @ 0.0 | timeout, lb 21 | 50 @ 0.1 | **timeout, lb 21** | 21 | 40 @ 9172.6 | 11954 / 13190 / 13351 | 40/40 |
| TN_576_2_ge9 | timeout, lb 22 | 64 @ 0.0 | timeout, lb 22 | 64 @ 0.1 | **timeout, lb 22** | 22 | 50 @ 1419.4 | 18594 / 20206 / 20383 | 42/42 |
| TN_612_2_ge17 | timeout, lb 24 | 68 @ 0.0 | timeout, lb 24 | 68 @ 0.1 | **timeout, lb 24** | 24 | 47 @ 6542.5 | 15395 / 16990 / 17915 | 46/46 |
| TN_648_14_ge9 | timeout, lb 21 | 54 @ 0.1 | timeout, lb 21 | 54 @ 0.1 | **timeout, lb 21** | 21 | 32 @ 1848.1 | 8593 / 9370 / 9764 | 41/41 |
| TN_648_10_9to52 | timeout, lb 21 | 52 @ 0.1 | timeout, lb 21 | 52 @ 0.1 | **timeout, lb 21** | 21 | 33 @ 1380.8 | 7634 / 8284 / 8475 | 41/41 |
| TN_684_2_ge9 | timeout, lb 22 | 57 @ 0.0 | timeout, lb 22 | 57 @ 0.1 | **timeout, lb 22** | 22 | 29 @ 8685.0 | 11624 / 12617 / 12835 | 42/42 |

solved codes: GH-138 9, off (this session) 9, on 10 (of 27); node-count mismatches on common EMPTY levels: []; science problems: []

Search cost of the finder on long levels (levels that ran while both arms were alive, identical node counts,
`S1/tier5_level_overhead.md`):

| Code | levels compared | level seconds on/off: median (min-max) |
|---|---:|---|
| TN_288_2_ge9 | 1 | 0.978 (0.978-0.978) |
| TN_324_4_ge9 | 2 | 1.177 (1.157-1.197) |
| TN_360_4_ge17 | 1 | 0.971 (0.971-0.971) |
| TN_396_4_ge17 | 2 | 0.990 (0.982-0.998) |
| TN_432_8_ge9 | 2 | 1.006 (0.999-1.013) |
| TN_468_4_ge17 | 1 | 0.987 (0.987-0.987) |
| TN_496_2_ge17 | 2 | 1.001 (0.991-1.010) |
| TN_504_2_ge17 | 1 | 1.040 (1.040-1.040) |
| TN_540_4_ge9 | 2 | 1.002 (0.994-1.010) |
| TN_576_2_ge9 | 2 | 0.986 (0.964-1.007) |
| TN_612_2_ge17 | 2 | 1.043 (1.039-1.047) |
| TN_648_14_ge9 | 1 | 0.998 (0.998-0.998) |
| TN_648_10_9to52 | 2 | 0.992 (0.978-1.006) |
| TN_684_2_ge9 | 2 | 1.006 (1.005-1.008) |

all 23 levels: median 1.005, geomean 1.015

Reading:
- **TN_252_2_21 is solved (d = 21 at 10 464 s)**, the only change in the solved column (9 -> 10 of 27). Everything
  else in the lb columns is identical to the off arm and to GH-138 (BB lb 30, TN lbs 20-24): the finder costs no level.
- **Upper bounds**: 16 open codes get a finder ub below the basis bound (BB_756 52 -> 34, BB_864 108 -> 42, TN stems
  32-68 -> 24-50); BB_1080 keeps 66. With the default share the finder spends ~5 % of the run while it improves and
  ~0.3 % after a plateau, so the big codes get less finder time in 6 h than the 600 s of S0 (BB_864 42 vs 40-44,
  BB_1080 66 vs 56-64, TN_576 50 vs 40-41, TN_540 40 vs 34-35).
- **Time**: on long levels the CC search with the finder runs at the same speed as without (median level-seconds
  ratio 1.005, geomean 1.015 over 23 concurrent levels). Time to the final lb on vs off (same session): 1.00-1.02 on
  most open codes, 1.05-1.08 on TN_324/504/612 (their early levels ran during the heavier load of the first hour);
  solved codes on/off 0.72-1.67 (BB_360 194/188, LP_1428 531/491, TN_216 596/631, TN_180 191/265, LP_1122 25/15 s;
  the on arm's solved codes all ran in its first hour), dominated by load differences (identical node counts on all 852 completed common EMPTY levels).

## 6. Gate verdicts

| Gate | Criterion | Result | Verdict |
|---|---|---|---|
| Tier 0 (correctness / smoke) | tests pass; default path byte-identical to main; witnesses valid | `make test-cc` (+ Part E) and the 1500/600 run pass; mutants 11/12 fail as required; `make test-cc-flags` 241/241; 28/28 identical `-v` logs (twice); 0 science problems in all 857 server runs | PASS |
| Tier 1 (CC off vs on, 5 seeds) | geomean < 1, no cell > 1.25 | 0.957 / 1.000 (rep 1 / rep 2), pooled 1.000 (LP_340 at the 0.025 s process floor) | neutral (process floor) |
| Tier 2 | same | pooled 0.760, max 1.001 | PASS |
| Tier 3 | same | pooled 0.916, max 1.068 (BB_288: basis bound already = d) | PASS |
| Tier 4 | same | pooled 1.010 (rep 1 1.045, rep 2 1.012), max 1.052 (LP_714, nothing to save); share 0.02: 0.934 | **not < 1: FAIL of the coordinator criterion (neutral, within noise)** |
| Tier 5 (6 h) | no cell worse; bounds consistent | TN_252 solved (d = 21, 10 464 s); 16 more finite ubs; no lb lost; level speed 1.005x | PASS |

## 7. Recommendation

1. **Keep `-ub-search` in the CC engine** (`-engine=cc` stays optional, PI decision of GH-124). It is the
   mechanism that turns the certified lower bound into an answer when the hit level is expensive: it solved
   TN_252_2_21 within 6 h for the first time, gives 1.3-2.4x on the panel codes whose basis bound is above d, and
   replaces the basis-row upper bounds of 16 open Tier 5 codes by verified weights (BB_756 34, TN stems 24-50).
2. **Default.** By the strict panel rule the code default stays `off` (Tier 4 pooled geomean 1.010 >= 1). I
   recommend that the PI approve **`-ub-search=on` (share 0.05, the evaluated setting) as the CC default** as an
   exception: the Tier 4 excess is the finder's 5 % share on two codes where nothing can be saved, the same size as
   the server noise of those cells, while Tier 2/3/5 gain clearly. A share of 0.02 would remove the Tier 4 excess
   (0.934 in the sensitivity panel) at the cost of slower ub progress on the large open codes; for upper-bound
   hunting use `-cc-ub-only -ub-search=budget:S` or a larger `-cc-ub-share`.
3. **PI decisions:** (a) default of `-ub-search` inside CC (recommended: on); (b) TN_252_2_21: already named
   `TN_252_2_21` (d = 21 adjudicated in GH-124); this run is the first full CC certification within 6 h (lb 21 from
   exhaustive levels + verified weight-21 witness); (c) whether to record the finder ubs on the open stems (e.g.
   `BB_756_16_ge28` -> `28to34` with lb 30 from GH-138, TN_288 `20to24`, ...) under the usual PLAUSIBLE/verified
   status: every ub here is a GF(2)-verified witness, so it is a proven upper bound.
4. **Next round, from these numbers.** The finder is the weak part on n >= 500 (BB_864/1080, TN_504-648: ub still
   falling at 600 s, seeds disagree). A Stern/Dumer-type collision step (two disjoint halves of the information set,
   p = 1-2 each, matched on a window of redundancy rows) should raise the hit probability per iteration by roughly an
   order of magnitude at d ~ 30-40; our simple evolution variant did not help. On the CC side the remaining gaps (TN
   lb 20-24 vs ub 24-50, BB lb 30 vs 34/42/66) are lower-bound problems.

## 8. Reproduction

Build: `make clean && make CXX="c++ -Wno-reserved-user-defined-literal"` (Mac) / `make -j8` (yfclab2). Tests:
`make test-cc`, `make test-cc-flags`, `./build/test_cc_engine 1500 600`. Identity: `python3 -I S0/ident_server.py MAIN
CAND OUTDIR CORE` (from a worktree root on yfclab2). S0 finder runs (worktree of `1c3e91b`): `python3 -I
S0/s1_queue.py --bin ./bin/distqldpc --cpus 10-99 --jobs S0/jobs_finder_base.jsonl --out OUT`, likewise
`jobs_finder_nobasis.jsonl` and `jobs_finder_var.jsonl` (cores 37-99), `jobs_finder_evo.jsonl` with `f6abb8a`; job
files from `S0/make_jobs_finder.py`. S1 (binary `793905c`, frozen as `frozen/server-gh140-793905c`):
`S1/runner/make_jobs.py`, then `s1_queue.py --cpus 2-9 --jobs jobs_panel.jsonl` (and `jobs_panel_rep2.jsonl`,
`jobs_panel_share002.jsonl`), `--cpus 10-36 --jobs jobs_tier5.jsonl`, `--cpus 37-63 --jobs jobs_tier5_off.jsonl`,
`--cpus 0 --jobs jobs_xcheck.jsonl`. Every server process: `taskset -c CORE prlimit --as=4294967296 -- BIN ARGS`.
Summaries: `S0/analyze_finder.py`, `S1/runner/analyze_panel.py`, `S1/runner/analyze_tier5.py ON OFF GH138`,
`S1/runner/level_overhead.py ON OFF`. No timing ran on the Mac (Mac: builds, `make test-cc` subsets,
`make test-cc-flags` and a few sub-10-s smoke runs).
