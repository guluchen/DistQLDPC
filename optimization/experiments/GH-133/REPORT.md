# GH-133 report: CC parity shortcut + leaf hash lookup; MaxSAT odd-cap skip

Issue: https://github.com/guluchen/DistQLDPC/issues/133 (hub #15). Baseline: main `cbb0642` (frontier auto default;
CC engine optional). Candidate: branch `experiment/gh-133-parity-leaf` (S0 code `d8fcce8`, docs/stats histogram
`6092b19`; the histogram commit changes only a `-cc-stats` diagnostic line). Literature basis:
`docs/LITERATURE_CC_2026.md` (Rank 1 and Rank 4). Clean-room: written from the published descriptions and the
mathematics; no Qubitserf, dist-m4ri, Crocker or Lee code was read.

## Summary

| Item | Result |
|---|---|
| Default MaxSAT path | byte-identical to main `cbb0642`: 28/28 `-v` logs identical on tier0+1 x {`-no-card`, `-card-mto`} (`S0/identity_tier01.txt`) |
| CC `parity` rule (odd levels skipped on halves with only odd column weights: all BB and LP codes) | **3.7-4.2x** on every BB/LP code with a level above ~12: BB_288 0.86 -> 0.21 s (Mac), BB_360 795 -> 192 s (Mac) / 1706 -> 426 s (server), LP_1428 1371 -> 342 s (Mac) / 2884 -> 744 s (server), LP_1768 149 -> 40 s, LP_1054 35 -> 9 s; no effect on TN/GB (rule off: even column weights) |
| CC `leaf` rule (hash lookup of the closing qubit at budget 1 and 2) | **neutral**: 0-5 % fewer nodes, -3 % .. +3 % time. The packing bound already prunes almost every cluster at budget 2-4, so budget-0/1 nodes are ~5 % of the tree (`-cc-stats` nodes-by-budget) |
| Tier 1-4 panel, `-engine=cc` old rules vs new rules, 5 seeds (yfclab2) | geomean of seed-median ratios tier1 0.969, tier2 0.900, tier3 0.677, tier4 1.004; max cell ratio 1.007; 130/130 correct answers; **PASS** |
| Tier 5 (6 h, new rules) vs GH-124 S1 (old rules) | 158/158 server runs clean; BB_360 1706 -> 426 s, LP_1428 2884 -> 744 s, LP_1768 327 -> 87 s, LP_1054 123 -> 20 s; BB_756/864/1080 certified lb 27 -> **28**; LP_1122_148_20 d=20 (18 s), LP_2610_744_16 d=16 (5 s); every TN cell same final bound (time to it 0.79-1.02x) |
| Correctness | `make test-cc`: 57 600 ladders (64 rule subsets x 3 seeds, 300 halves, 121 with all-odd columns), 2 200 driver runs on 200 random CSS codes (new rules, GH-124 rules, none, mrv, seeds, dual off, ub-basis, no-symbreak, sequential), 400 MaxSAT split runs with `-oddcap-skip` off/on, 0 bad; every mutant (1-7) changes answers. `make test-cc-flags`: 164 checks pass. Tier 0-4 answers = stem in every CC run (old and new rules), Mac and server |
| `-oddcap-skip` (MaxSAT path, default off) | Tier 1-3 BB/LP 5-seed panel: geomeans 0.62/0.69, 0.58/0.59, 0.43/0.48 (mto/nc), max cell 1.002 (control), 160 correct; Tier 5: LP_714 2663 -> 473 s, LP_1020 2316/8955 -> 1058/1056 s, every timeout cell lb 17 -> 18, none worse |
| Recommendation | adopt `parity` + `leaf` as CC defaults (branch does); make `-oddcap-skip=on` the MaxSAT default in a follow-up PR (PI decision); details in section 7 |

Scientific semantics changed: no. Every bound emitted by the new rules is implied by the parity theorem (proof
in `MODIFICATIONS.md`) or identical to the old engine's; every witness is still verified by the independent GF(2)
test. No external solver was used.

## 1. What was implemented (S0)

**`parity`** (CC rule, on by default). For a half whose parity matrix H has only odd column weights,
sum_i (H v)_i = sum_j colwt_j v_j = |v| (mod 2), so every element of ker H has even weight. The driver starts
such a half at level 2 (emits `LB 2`), never runs an odd level, and after an EMPTY level 2t sets lb = 2t + 2
(`-v`: `c cc: X half level 23 skipped (parity: ...)`; the trace file gets a `SKIPPED` line). The per-node check
"qubits still to add = syndrome weight (mod 2)" is implemented but provably never fires at an even level on a
qualifying half (`parprune` is 0 in every run); the proposal's "+1 on a mismatched lower bound" is vacuous for the
same reason (both proofs in `MODIFICATIONS.md`, `src/cc/`). The rule is never applied when a column weight is even
(GB_144_12_12: weights 2-4; BB_144_14_14: weight 4; all TN codes), and `-v` prints the decision per half. Column
weights of the 49 bundled codes: every BB and LP stem has only odd weights (3; 3 and 5), no TN or GB stem does.

**`leaf`** (CC rule, on by default). Zobrist keys per row give every qubit a column key and the syndrome an
incrementally maintained key; an open-addressing table maps a key to the qubits with that column (chained,
ascending). At budget 1 the node is closed by a lookup of the syndrome (exact column comparison, free qubit,
nontrivial closure); at budget 2 each candidate of the branching row is toggled and completed by one lookup
instead of a recursion (sibling exclusion, the forbidden set, the detector check and the syndrome-free-child
trap exactly as the branching does). Verdicts are unchanged; only the node count drops.

**`-oddcap-skip=on|off`** (MaxSAT split path, default **off**). On a half with only odd column weights the odd
probe caps are replaced by the even cap below: Phase 1 cap 1 is not probed (lb 2), a NONE at cap 2t sets lb
2t + 2; Phase 2a cap U-1 -> U-2 when odd; Phase 2b/3 an odd optimisation cap (dual-half elimination) -> U-2.
`-v`: `c oddcap X: column weights 3..3 all odd ... -> odd caps skipped`.

Flags: `-cc-rules` default `excl,pack,orbf,parity,leaf` (`excl,pack,orbf` = the GH-124 engine; `none` and explicit
lists work); `-cc-stats` adds `parprune`, `leaf1`, `leaf2` and a `nodes-by-budget` line; `-cc-mutant` 5-7.

**Mutants.** 5: parity rule forced on a half with an even column weight (3584/5728 ladders wrong; on
BB_144_14_14 / GB_144_12_12 it stops with a trap, `lb > ub`, because every odd-size cluster is pruned). 6: leaf
budget off by one (1344/9600 wrong). 7: leaf closure without the detector check (1408/9600 wrong). The spec's
literal leaf mutant ("ignore the forbidden set") is a sound weakening (a forbidden closing qubit is a genuine
element of F; a closing qubit already in S gives a syndrome-free set of weight w-2, trivial under the level
precondition, rejected by the detector check), so it cannot change an answer and was replaced, as GH-124 did for
its mutant 3. Mutant 4's block now runs with `-ub-basis=off` (51/200 wrong instead of a stream-dependent 1/200).

## 2. Correctness

| Check | Runs | Result |
|---|---:|---|
| Identity of the default path with main `cbb0642` (`-v` logs, tier0+tier1 x `-no-card`/`-card-mto`, time fields masked) | 28 | 28 identical (`S0/identity_tier01.txt`) |
| `make test-cc` Part A: half ladders, 64 rule subsets x 3 relabeling seeds, 300 random halves (159 with verified orbits, 121 with all-odd columns, 112 without any element) vs brute force | 57 600 | 0 bad; every all-odd half has even d_h |
| Part B: 200 random CSS codes (70 with a verified dual map, 55 with X orbits, 63 with dX != dZ, 45 with all-odd Hz), 10 configurations incl. the GH-124 rule set, vs enumeration | 2 200 | 0 bad, 0 `RESULT -1` |
| Part D: production MaxSAT split, `-oddcap-skip` off and on, vs enumeration | 400 | 0 bad |
| Part C mutants 1-7 | - | all change answers (see above) |
| `make test-cc-flags` (new flags/values, parity decision lines, stats line, oddcap lines, trap withdrawal) | 164 | pass (Mac and yfclab2) |
| Tier 0-4 bundled codes, `-engine=cc`, old and new rules, Mac (default seed) | 2 x 24 | every answer = stem |
| Tier 1-4 server panel (5 seeds x 2 arms), every `c d_lb` <= d <= `c d_ub` | 130 | 130 correct, 0 science problems, 0 traps |
| Tier 5 server runs (new rules), answers and bounds vs stem range | 28 | section 5 |

## 3. S0: per-level node counts and single-run times, old rules vs new rules (Mac, M6, 2 GB cap, <= 2 concurrent, default seed)

Binary `d8fcce8` (`../frozen-cand133`); old = `-cc-rules=excl,pack,orbf`, new = default. "skipped" = level not run
(parity). Node counts of the levels that are run are within 0-5 % of the old engine (the leaf rule removes the
budget-0/1 nodes only); the time of a run level is unchanged within noise, so the whole gain is the skipped odd
levels. Full table with the four top levels per code: `S0/s0mac_table.md`; raw logs `S0/mac/`.

| Tier | Code | old wall s | new wall s | ratio | top-level nodes old -> new (level: nodes, time s) |
|---:|---|---:|---:|---:|---|
| 2 | BB_144_14_14 (even col. weights: parity off) | 0.549 | 0.547 | 0.995 | X13: 4.34M -> 4.32M (0.380 / 0.379) |
| 2 | LP_442_68_10 | 0.014 | 0.018 | 1.24 (process floor) | X9, Z9 skipped |
| 2 | TN_108_2_12 | 0.333 | 0.322 | 0.968 | X11: 2.20M -> 1.75M (0.158 / 0.149) |
| 3 | BB_288_12_18 | 0.856 | 0.215 | **0.251** | X17: 7.59M (0.589 s) skipped; X16: 2.43M -> 2.41M (0.180 / 0.182) |
| 3 | GB_144_12_12 (parity off) | 0.075 | 0.075 | 0.991 | X12: 603k -> 589k |
| 3 | LP_544_80_12 | 0.030 | 0.018 | 0.599 | X11, Z11 skipped |
| 3 | TN_144_2_13 | 1.223 | 1.209 | 0.989 | X12: 4.08M -> 3.87M (0.386 / 0.383); Z13: 4.51M -> 4.32M |
| 3 | TN_200_10_10 | 0.090 | 0.075 | 0.833 | X9: 340k -> 293k |
| 4 | TN_250_10_15 | 33.40 | 32.56 | 0.975 | X14: 146.8M -> 143.6M (16.60 / 16.12); Z14: 57.6M -> 56.2M |
| 5 | LP_714_100_16 | 0.951 | 0.247 | 0.260 | X15 3.45M, Z15 5.48M skipped |
| 5 | LP_1020_136_16 | 0.628 | 0.184 | 0.293 | X15 1.59M, Z15 3.33M skipped |
| 5 | LP_1054_140_20 | 34.55 | 8.91 | **0.258** | Z19: 182M (17.6 s) skipped; Z18: 63.7M -> 63.6M (5.93 / 5.97) |
| 5 | LP_1768_224_22 | 148.7 | 39.8 | **0.268** | Z21: 717M (84.1 s) skipped; Z20: 256M -> 256M (29.0 / 29.2) |
| 5 | LP_1122_148_20 (new, PR #132) | 31.25 | 7.98 | 0.255 | d = 20 both |
| 5 | LP_2610_744_16 (new, PR #132) | 9.16 | 2.24 | 0.245 | d = 16 both |
| 5 | TN_180_2_17 | 113.6 | 113.6 | 1.001 | X16: 397.0M -> 392.1M (42.43 / 42.40) |
| 5 | TN_216_4_18 | 290.9 | 291.1 | 1.001 | X17: 1.085G -> 1.079G (123.5 / 123.5) |
| 5 | BB_360_12_24 | 795.5 | 191.8 | **0.241** | X23: 5.73G (~590 s) skipped; X22: 1.834G -> 1.833G (170.1 / 170.2); X24 FOUND 30.6M (3.2 s) both |
| 5 | LP_1428_184_24 | 1371.0 | 341.9 | **0.249** | odd levels skipped |

Where the node mass sits (`-cc-stats` nodes-by-budget, budget = w - |S|): TN_144 level 12 (old): budget 0: 6.5k,
1: 194k, 2: 1.16M, 3: 1.60M, 4: 795k, 5: 241k ...; LP_544 Z level 11: 0, 6.1k, 18.8k, 28.1k, 38.7k, 19.7k ...
The leaf rule removes exactly the budget-0 and budget-1 nodes (new: 0, 0, 1.16M, 1.60M, ...) and replaces them by
one lookup per surviving budget-2 candidate (`leaf2` = old budget-1 count). dist-m4ri's 3-5x for the same idea
applies to a plain CC whose leaves are not pruned by a packing bound; in our engine the packing bound already
does the leaf work.

**Tier 5 codes not solved within the Mac cap of 3600 s** (new rules on all 18; old rules on four reference codes;
2 workers, 2 GB cap, no memory kill, no sleep event in `pmset -g log`). Final certified lower bound and the last
completed levels (half, level: nodes, seconds). The old-rule levels of the GH-124 logs (quiet mode) have no node
counts; the Mac references below do.

| Code | arm | final lb at 3600 s | last completed levels (half level: nodes, s) |
|---|---|---:|---|
| BB_1080_4_ge17 | new | **28** | X22: 427M, 45; X24: 3300M, 364; X26: 25 775M, 2982 |
| BB_864_4_ge17 | new | **28** | X22: 392M, 39; X24: 3053M, 323; X26: 24 123M, 2527 |
| BB_756_16_ge17 | new | 26 | X22: 448M, 46; X24: 3569M, 384 (level 26 unfinished at 3600 s) |
| BB_756_16_ge17 | old | 26 | X23: 1261M, 122; X24: 3575M, 355; X25: 10 129M, 1032 (level 26 unfinished) |
| TN_252_2_21 | new / old | 20 / 20 | Z20: 9157M, 1090 / 9160M, 1070 (X19 570 / 564) |
| TN_288_2_ge9 | new / old | 19 / 19 | Z19: 10 930M, 1332 / 10 933M, 1332 |
| TN_612_2_ge17 | new / old | 23 / 23 | X22: 6071M, 954 / 6071M, 954 |
| TN_324_4_ge9 | new | 19 | Z19: 7952M, 993 |
| TN_360_4_ge17 | new | 21 | X21: 9183M, 1331 |
| TN_396_4_ge17 | new | 21 | Z21: 5917M, 753 |
| TN_432_8_ge9 | new | 20 | X19: 5527M, 774 |
| TN_468_4_ge17 | new | 22 | X21: 12 532M, 1672 |
| TN_496_2_ge17 | new | 21 | X21: 10 923M, 1508 |
| TN_504_2_ge17 | new | 22 | Z22: 8038M, 1212 |
| TN_540_4_ge9 | new | 20 | Z20: 10 626M, 1496 |
| TN_576_2_ge9 | new | 21 | X20: 7684M, 1128 |
| TN_648_10_9to52 | new | 21 | X20: 9176M, 1404 |
| TN_648_14_ge9 | new | 20 | Z20: 7179M, 1054 |
| TN_684_2_ge9 | new | 21 | X20: 7695M, 932 |

On the TN references the per-level node counts and times of old and new agree to 0.1 % (the leaf rule removes
only the budget-0/1 nodes, which at these levels are below 0.1 % of the tree). On the BB codes the even levels cost
the same as before (BB_756 X24: 3575M / 355 s old vs 3569M / 384 s new) and the odd levels are gone: level 25
(10 129M nodes, 1032 s) is skipped, so the Mac reaches lb 28 on BB_864/BB_1080 within the hour where the old
engine, on the server, needed 8722-10206 s for lb 27. Raw: `S0/mac/results.tsv`, `S0/mac/logs.tar.gz`,
`S0/s0mac_table.md`.

## 4. S1 Tier 1-4 panel, `-engine=cc` old rules vs new rules (yfclab2, cores 105-123, 4 GB cap, seeds 0-4)

Limits tier1-3 1800 s, tier4 5000 s; one process per pinned core; both arms of a (code, seed) queued back to
back. Wall seconds, median over seeds 0-4 (range).

| Tier | Code | old median (range) | new median (range) | ratio new/old |
|---:|---|---|---|---:|
| 1 | BB_108_8_10 | 0.025 (0.024-0.025) | 0.024 (0.023-0.025) | 0.960 |
| 1 | BB_144_12_12 | 0.025 (0.024-0.025) | 0.024 (0.022-0.024) | 0.960 |
| 1 | LP_238_44_6 | 0.023 (0.022-0.024) | 0.023 (0.022-0.024) | 1.000 |
| 1 | LP_340_56_8 | 0.024 (0.023-0.025) | 0.023 (0.023-0.024) | 0.958 |
| 2 | BB_144_14_14 | 1.073 (1.052-1.194) | 1.081 (1.060-1.206) | 1.007 |
| 2 | LP_442_68_10 | 0.034 (0.029-0.036) | 0.025 (0.024-0.027) | 0.735 |
| 2 | TN_108_2_12 | 1.952 (0.861-2.689) | 1.921 (0.820-2.647) | 0.984 |
| 3 | BB_288_12_18 | 1.831 (1.791-1.966) | 0.458 (0.448-0.480) | **0.250** |
| 3 | GB_144_12_12 | 0.188 (0.126-0.290) | 0.181 (0.125-0.286) | 0.963 |
| 3 | LP_544_80_12 | 0.078 (0.066-0.087) | 0.046 (0.036-0.047) | 0.590 |
| 3 | TN_144_2_13 | 6.701 (2.847-10.703) | 6.697 (2.822-10.712) | 0.999 |
| 3 | TN_200_10_10 | 0.489 (0.185-0.569) | 0.488 (0.176-0.568) | 0.998 |
| 4 | TN_250_10_15 | 113.8 (69.2-132.1) | 114.2 (69.2-132.4) | 1.003 |

| Tier | cells | geomean | max cell | cells > 1.25 | gate (geomean < 1, no cell > 1.25) |
|---:|---:|---:|---:|---:|---|
| 1 | 4 | 0.969 | 1.000 | 0 | PASS (all cells at the process floor, 0.02 s) |
| 2 | 3 | 0.900 | 1.007 | 0 | PASS |
| 3 | 5 | 0.677 | 0.999 | 0 | PASS |
| 4 | 1 | 1.004 | 1.003 | 0 | PASS as neutral (TN: parity off, leaf neutral; within seed noise) |

CC has one cell per code (no cardinality modes). The old arm reproduces GH-124 S1 (BB_288 1.83 s vs 2.19 s,
TN_250 114 s vs 138 s on different cores). Raw: `S1/server/cc/results.jsonl`, logs `S1/server/cc/logs/`.

## 5. S1 Tier 5 (yfclab2, 6 h, default seed), new rules vs GH-124 S1 Tier 5 (old rules)

One run per code (CC has no cardinality modes), cores 105-123, 4 GB cap, `-cc-stats`, default seed; 28 codes
(26 tier5 + LP_1122_148_20 and LP_2610_744_16 from PR #132). Reference: GH-124 S1 Tier 5 (old rules `excl,pack,orbf`,
binary 244f670, same server, 6 h). 158/158 runs of the whole queue without a science problem (every answer equals
the stem value, every lb <= the stem's upper value, every ub >= its lower value, no trap, no backstop kill).

| BB_1080_4_ge17 | TIMEOUT, 27/66, 21600 | TIMEOUT, 28/66, 21600 | 16@0 18@0 20@1 22@14 24@114 26@924 28@7505 28@21600 | 15@0 16@0 17@0 18@1 19@2 20@7 21@20 22@56 23@211 24@643 25@1667 26@3882 27@10206 27@21600 | lb 27: 10206 -> 7506 |
| BB_360_12_24 | d=24 @ 1706, 24/24, 1706 | d=24 @ 426, 24/24, 426 | 16@0 18@0 20@4 22@42 24@419 | 15@0 16@0 17@0 18@1 19@5 20@18 21@55 22@173 23@539 24@1698 | lb 24: 1699 -> 419 |
| BB_756_16_ge17 | TIMEOUT, 27/52, 21600 | TIMEOUT, 28/52, 21600 | 16@0 18@0 20@1 22@13 24@114 26@951 28@7938 28@21600 | 15@0 16@0 17@0 18@0 19@2 20@6 21@19 22@54 23@163 24@445 25@1253 26@4250 27@11250 27@21600 | lb 27: 11251 -> 7939 |
| BB_864_4_ge17 | TIMEOUT, 27/108, 21600 | TIMEOUT, 28/108, 21600 | 16@0 18@0 20@1 22@12 24@103 26@821 28@6669 28@21600 | 15@0 16@0 17@0 18@0 19@2 20@6 21@17 22@49 23@137 24@383 25@1078 26@3056 27@8721 27@21600 | lb 27: 8722 -> 6669 |
| LP_1020_136_16 | d=16 @ 2, 16/16, 2 | d=16 @ 0, 16/16, 0 | 16@0 | 15@0 16@1 | lb 16: 2 -> 0 |
| LP_1054_140_20 | d=20 @ 123, 20/20, 123 | d=20 @ 20, 20/20, 20 | 16@0 18@2 20@19 | 15@0 16@1 17@4 18@14 19@42 20@123 | lb 20: 123 -> 19 |
| LP_1122_148_20 | n/a (new code) | d=20 @ 18, 20/20, 18 | 16@0 18@2 20@17 | - | - |
| LP_1428_184_24 | d=24 @ 2884, 24/24, 2884 | d=24 @ 744, 24/24, 744 | 16@0 18@1 20@11 22@87 24@743 | 15@0 16@0 17@2 18@5 19@15 20@42 21@120 22@336 23@974 24@2884 | lb 24: 2884 -> 744 |
| LP_1768_224_22 | d=22 @ 327, 22/22, 327 | d=22 @ 87, 22/22, 87 | 16@0 18@1 20@10 22@84 | 15@0 16@0 17@2 18@5 19@15 20@42 21@116 22@324 | lb 22: 324 -> 84 |
| LP_2610_744_16 | n/a (new code) | d=16 @ 5, 16/16, 5 | 16@5 | - | - |
| LP_714_100_16 | d=16 @ 2, 16/16, 2 | d=16 @ 1, 16/16, 1 | 16@0 | 15@0 16@2 | lb 16: 2 -> 1 |
| TN_180_2_17 | d=17 @ 257, 17/17, 257 | d=17 @ 256, 17/17, 256 | 15@13 16@47 17@176 | 15@13 16@49 17@178 | lb 17: 178 -> 176 |
| TN_216_4_18 | d=18 @ 696, 18/18, 696 | d=18 @ 651, 18/18, 651 | 15@13 16@46 17@161 18@568 | 15@19 16@68 17@218 18@615 | lb 18: 615 -> 569 |
| TN_252_2_21 | TIMEOUT, 21/28, 21600 | TIMEOUT, 21/28, 21600 | 15@4 16@16 17@59 18@210 19@757 20@2748 21@10166 21@21600 | 15@5 16@17 17@60 18@229 19@769 20@2739 21@10045 21@21600 | lb 21: 10045 -> 10167 |
| TN_288_2_ge9 | TIMEOUT, 20/32, 21600 | TIMEOUT, 20/32, 21600 | 15@27 16@86 17@282 18@936 19@3130 20@10691 20@21600 | 15@28 16@88 17@285 18@927 19@3096 20@10566 20@21600 | lb 20: 10567 -> 10692 |
| TN_324_4_ge9 | TIMEOUT, 20/36, 21600 | TIMEOUT, 20/36, 21600 | 15@29 16@91 17@285 18@908 19@2912 20@9558 20@21600 | 15@31 16@93 17@288 18@903 19@2900 20@9488 20@21600 | lb 20: 9488 -> 9559 |
| TN_360_4_ge17 | TIMEOUT, 22/40, 21600 | TIMEOUT, 22/40, 21600 | 15@2 16@6 17@20 18@67 19@222 20@742 21@2484 22@8470 22@21600 | 15@2 16@7 17@21 18@69 19@224 20@734 21@3149 22@10903 22@21600 | lb 22: 10903 -> 8471 |
| TN_396_4_ge17 | TIMEOUT, 22/44, 21600 | TIMEOUT, 22/44, 21600 | 15@3 16@9 17@28 18@89 19@284 20@903 21@2886 22@9383 22@21600 | 15@3 16@10 17@30 18@92 19@286 20@895 21@2856 22@9247 22@21600 | lb 22: 9247 -> 9384 |
| TN_432_8_ge9 | TIMEOUT, 21/36, 21600 | TIMEOUT, 21/36, 21600 | 15@17 16@52 17@157 18@478 19@1458 20@4543 21@14308 21@21600 | 15@18 16@53 17@158 18@473 19@1442 20@4473 21@14127 21@21600 | lb 21: 14128 -> 14309 |
| TN_468_4_ge17 | TIMEOUT, 22/52, 21600 | TIMEOUT, 22/52, 21600 | 15@2 16@8 17@25 18@77 19@236 20@728 21@2242 22@7029 22@21600 | 15@3 16@9 17@26 18@78 19@238 20@720 21@2219 22@6905 22@21600 | lb 22: 6906 -> 7029 |
| TN_496_2_ge17 | TIMEOUT, 22/64, 21600 | TIMEOUT, 22/64, 21600 | 15@4 16@15 17@44 18@130 19@403 20@1198 21@3592 22@10942 22@21600 | 15@7 16@23 17@65 18@191 19@578 20@1717 21@5140 22@13785 22@21600 | lb 22: 13785 -> 10943 |
| TN_504_2_ge17 | TIMEOUT, 23/56, 21600 | TIMEOUT, 23/56, 21600 | 15@1 16@3 17@9 18@28 19@87 20@268 21@831 22@2592 23@8244 23@21600 | 15@1 16@3 17@10 18@30 19@89 20@270 21@825 22@2571 23@8144 23@21600 | lb 23: 8145 -> 8245 |
| TN_540_4_ge9 | TIMEOUT, 21/50, 21600 | TIMEOUT, 21/50, 21600 | 15@17 16@51 17@149 18@442 19@1322 20@4020 21@12355 21@21600 | 15@18 16@53 17@158 18@524 19@1393 20@4068 21@12298 21@21600 | lb 21: 12298 -> 12356 |
| TN_576_2_ge9 | TIMEOUT, 22/64, 21600 | TIMEOUT, 22/64, 21600 | 15@12 16@33 17@92 18@260 19@752 20@2151 21@6318 22@18699 22@21600 | 15@12 16@34 17@93 18@261 19@735 20@2117 21@6190 22@18676 22@21600 | lb 22: 18676 -> 18700 |
| TN_612_2_ge17 | TIMEOUT, 24/68, 21600 | TIMEOUT, 24/68, 21600 | 15@0 16@2 17@7 18@22 19@64 20@190 21@570 22@1711 23@5225 24@16118 24@21600 | 15@1 16@2 17@8 18@22 19@65 20@191 21@564 22@1692 23@5148 24@15939 24@21600 | lb 24: 15939 -> 16119 |
| TN_648_10_9to52 | TIMEOUT, 21/52, 21600 | TIMEOUT, 21/52, 21600 | 15@15 16@43 17@119 18@334 19@944 20@2708 21@7876 21@21600 | 15@25 16@63 17@140 18@354 19@958 20@2877 21@8103 21@21600 | lb 21: 8104 -> 7877 |
| TN_648_14_ge9 | TIMEOUT, 21/54, 21600 | TIMEOUT, 21/54, 21600 | 15@16 16@45 17@127 18@360 19@1032 20@3003 21@8834 21@21600 | 15@17 16@46 17@130 18@363 19@1043 20@3058 21@11074 21@21600 | lb 21: 11075 -> 8835 |
| TN_684_2_ge9 | TIMEOUT, 22/57, 21600 | TIMEOUT, 22/57, 21600 | 15@6 16@18 17@54 18@165 19@508 20@1573 21@4928 22@15406 22@21600 | 15@6 16@19 17@56 18@203 19@732 20@2357 21@6556 22@18209 22@21600 | lb 22: 18210 -> 15406 |

Reading of the table:
- **BB/LP (parity on): 3.7-6x to the same result.** BB_360 1706 -> 426 s, LP_1428 2884 -> 744 s, LP_1768
  327 -> 87 s, LP_1054 123 -> 20 s. The three open BB codes reach the **new certified lower bound 28** (level 26
  EMPTY at 821-951 s, level 28 EMPTY at 6669-7938 s; the old engine reached 27 at 8722-11251 s and ran out of
  time in level 28). Level 30 was still running at 6 h (BB_864 and BB_1080: ~14 000 s into it). The two
  new codes: LP_1122_148_20 d = 20 in 18 s, LP_2610_744_16 d = 16 in 5 s (both agree with the PR #132 stems).
- **TN (parity off, leaf neutral): same levels, same bounds within the 6 h.** Time to the same final lower bound
  ranges from 0.79x (TN_496, TN_684, TN_648_14) to 1.02x (most TN cells); the 1-2 % slow-downs on 9 TN cells are
  within the core-to-core variation of this server (GH-124 S1 itself ran on other cores), and the 20-25 % gains on
  four cells are likewise not attributable to the leaf rule (its node reduction is 1-5 %). No TN cell changed its
  final bound.
- Certification status of the new bounds (BB_756 >= 28, BB_864 >= 28, BB_1080 >= 28) follows the GH-124 rule:
  they come from the canonical CC search (the odd level is skipped by the parity theorem, the even levels are the
  same exhaustive searches as before) and keep the PLAUSIBLE status of `GH-124/ADJUDICATION.md` until the
  certification track confirms them; the stems are not renamed here.

Raw: `S1/server/cc/results.jsonl` (bound events with elapsed seconds, per-level `-cc-stats` lines), logs in
`S1/server/cc/logs.tar.gz`.

## 6. `-oddcap-skip=on` vs main (MaxSAT path)

### 6.1 Tier 1-4 panel: BB/LP codes, `-oddcap-skip=off` (= main `cbb0642`, byte-identical default) vs `on`, seeds 0-4, both modes (yfclab2, cores 100-104 + 121, 4 GB cap, limits tier1-3 1800 s)

One binary (`d8fcce8`); the `off` arm is main's search (identity verified in section 2). Wall seconds, median over
seeds 0-4 (range). BB_144_14_14 has even column weights (the flag is a no-op there: control cell).

160 runs; science problems: []
| Tier | Code | mode | off median (range) | on median (range) | ratio on/off | timeouts off/on |
|---:|---|---|---|---|---:|---|
| 1 | BB_108_8_10 | card-mto | 0.17 (0.16-0.23) | 0.09 (0.07-0.10) | 0.521 | 0/0 (n=5/5) |
| 1 | BB_108_8_10 | no-card | 0.16 (0.16-0.22) | 0.09 (0.07-0.09) | 0.540 | 0/0 (n=5/5) |
| 1 | BB_144_12_12 | card-mto | 0.28 (0.26-0.30) | 0.27 (0.25-0.30) | 0.982 | 0/0 (n=5/5) |
| 1 | BB_144_12_12 | no-card | 0.27 (0.26-0.30) | 0.27 (0.26-0.30) | 0.996 | 0/0 (n=5/5) |
| 1 | LP_238_44_6 | card-mto | 0.78 (0.56-0.85) | 0.33 (0.25-0.39) | 0.420 | 0/0 (n=5/5) |
| 1 | LP_238_44_6 | no-card | 0.70 (0.62-0.76) | 0.32 (0.25-0.40) | 0.452 | 0/0 (n=5/5) |
| 1 | LP_340_56_8 | card-mto | 2.57 (2.36-2.68) | 1.79 (1.71-2.38) | 0.699 | 0/0 (n=5/5) |
| 1 | LP_340_56_8 | no-card | 2.21 (1.92-2.61) | 2.02 (1.50-2.48) | 0.912 | 0/0 (n=5/5) |
| 2 | BB_144_14_14 | card-mto | 22.47 (16.52-38.09) | 22.40 (16.53-37.13) | 0.997 | 0/0 (n=5/5) |
| 2 | BB_144_14_14 | no-card | 19.04 (16.45-32.08) | 19.07 (16.51-31.42) | 1.002 | 0/0 (n=5/5) |
| 2 | LP_442_68_10 | card-mto | 22.21 (15.86-26.58) | 7.44 (5.25-7.82) | 0.335 | 0/0 (n=5/5) |
| 2 | LP_442_68_10 | no-card | 21.56 (19.15-28.77) | 7.61 (5.76-8.93) | 0.353 | 0/0 (n=5/5) |
| 3 | BB_288_12_18 | card-mto | 209.73 (200.69-232.34) | 44.06 (43.56-57.58) | 0.210 | 0/0 (n=5/5) |
| 3 | BB_288_12_18 | no-card | 190.73 (182.80-212.47) | 45.23 (41.69-52.26) | 0.237 | 0/0 (n=5/5) |
| 3 | LP_544_80_12 | card-mto | 59.17 (46.17-69.94) | 52.21 (44.39-73.38) | 0.882 | 0/0 (n=5/5) |
| 3 | LP_544_80_12 | no-card | 64.04 (56.35-75.04) | 62.85 (54.88-70.00) | 0.981 | 0/0 (n=5/5) |

tier 1 card-mto: cells 4 geomean 0.6222 max 0.982
tier 1 no-card: cells 4 geomean 0.6866 max 0.996
tier 2 card-mto: cells 2 geomean 0.5780 max 0.997
tier 2 no-card: cells 2 geomean 0.5944 max 1.002
tier 3 card-mto: cells 2 geomean 0.4305 max 0.882
tier 3 no-card: cells 2 geomean 0.4824 max 0.981

Gate (geomean < 1 per mode, no cell > 1.25): tier 1 PASS (0.62 / 0.69), tier 2 PASS (0.58 / 0.59), tier 3 PASS
(0.43 / 0.48); max cell ratio 1.002 (the control cell); 160/160 correct answers. The gain is the final
refutation: with the flag the NONE at cap 16 of Phase 1 already certifies lb 18 = U on BB_288 (d = 18), so the
Phase 2a probe at cap 17 (the most expensive probe of main's run) is not issued; on LP_442 (d = 10) the cap-9
probe is replaced by cap 8 (already refuted in Phase 1). Codes whose distance is odd or whose caps do not line up
(LP_544, d = 12: Phase 1 refutes 8 and finds at 16, then Phase 2a cap 11 -> 10 is still an expensive probe) gain
little (0.88-0.98). Raw: `S1/server/oddcap/results.jsonl`.

### 6.2 Tier 5 BB/LP codes (6 h, default seed), `-oddcap-skip=on` vs main `cbb0642`

18 runs (9 BB/LP tier5 codes x {`-no-card`, `-card-mto`}), cores 100-115 + 118-119, 4 GB cap, 6 h, started
00:25 on 2026-10-19 after the CC runs; 18/18 without a science problem. Main arm: the main `cbb0642` Tier 5
baseline recorded concurrently on the same server by the baseline session (`frozen/server-main-cbb0642`, 6 h, 56
cells, copied to `S1/server/oddcap5/main_cbb0642_tier5_baseline.json`); main `398054e` values are in GH-124 S1
section 4. "lb" = last `c d_lb` line (timeouts without an upper bound print `c d_ub: -`).

| Code | mode | main `cbb0642`: result, lb/ub, wall s | `-oddcap-skip=on`: result, lb/ub, wall s | lb events on (value@s) | lb events main |
|---|---|---|---|---|---|
| BB_1080_4_ge17 | card-mto | TIMEOUT, 17/-, 21600 | TIMEOUT, 18/-, 21600 | 18@2160 | 17@9263 |
| BB_1080_4_ge17 | no-card | TIMEOUT, 17/-, 21600 | TIMEOUT, 18/-, 21600 | 18@2178 | 17@2566 |
| BB_360_12_24 | card-mto | TIMEOUT, 17/24, 21600 | TIMEOUT, 18/24, 21600 | 18@70 | 17@87 |
| BB_360_12_24 | no-card | TIMEOUT, 17/24, 21600 | TIMEOUT, 18/24, 21600 | 18@68 | 17@85 |
| BB_756_16_ge17 | card-mto | TIMEOUT, 17/-, 21600 | TIMEOUT, 18/-, 21600 | 18@554 | 17@672 |
| BB_756_16_ge17 | no-card | TIMEOUT, 17/-, 21600 | TIMEOUT, 18/-, 21600 | 18@553 | 17@3352 |
| BB_864_4_ge17 | card-mto | TIMEOUT, 17/-, 21600 | TIMEOUT, 18/-, 21600 | 18@718 | 17@873 |
| BB_864_4_ge17 | no-card | TIMEOUT, 17/-, 21600 | TIMEOUT, 18/-, 21600 | 18@716 | 17@876 |
| LP_1020_136_16 | card-mto | d=16 @ 2316 | **d=16 @ 1058** | 16@1058 | 16@2315 |
| LP_1020_136_16 | no-card | d=16 @ 8955 | **d=16 @ 1056** | 16@1056 | 16@8954 |
| LP_1054_140_20 | card-mto | TIMEOUT, 17/32, 21600 | TIMEOUT, 18/32, 21600 | 18@7691 | 17@9356 |
| LP_1054_140_20 | no-card | TIMEOUT, 17/32, 21600 | TIMEOUT, 18/32, 21600 | 18@7703 | 17@9360 |
| LP_1428_184_24 | card-mto | TIMEOUT, 17/32, 21600 | TIMEOUT, 18/32, 21600 | 18@8193 | 17@9149 |
| LP_1428_184_24 | no-card | TIMEOUT, 17/32, 21600 | TIMEOUT, 18/32, 21600 | 18@8197 | 17@9157 |
| LP_1768_224_22 | card-mto | TIMEOUT, 17/-, 21600 | TIMEOUT, 18/-, 21600 | 18@12403 | 17@14204 |
| LP_1768_224_22 | no-card | TIMEOUT, 17/-, 21600 | TIMEOUT, 18/-, 21600 | 18@12364 | 17@14094 |
| LP_714_100_16 | card-mto | d=16 @ 2663 | **d=16 @ 473** | 16@472 | 16@2662 |
| LP_714_100_16 | no-card | d=16 @ 2670 | **d=16 @ 661** | 16@661 | 16@2670 |

Both solved codes are solved 2.2-8.5x sooner (LP_714 473 / 661 s vs 2663 / 2670 s; LP_1020 1058 / 1056 s vs
2316 / 8955 s): d = 16 is found at cap 32 in Phase 1, and the Phase 2a refutation of cap 15 becomes the cap-14
refutation, which is cheaper than main's cap-15 probe. Every timeout cell ends with lb 18 instead of 17 (the
NONE at cap 16 certifies 18) and reaches it earlier than main reaches 17 (same probe, 16 cells; the difference
is the cores' speed and the skipped cap-1 probe). No cell is worse; no bound disagrees with the stems or with the
CC results (section 5). The MaxSAT path remains far behind the CC engine on these codes (BB_360: CC 426 s, MaxSAT
lb 18 / ub 24 at 6 h), as in GH-124.

Raw: `S1/server/oddcap5/results.jsonl`, `S1/server/oddcap5/logs.tar.gz`.

## 7. Gate verdicts and recommendation

| Gate | Criterion | Result | Verdict |
|---|---|---|---|
| Tier 0 (correctness / smoke) | tests pass; default path byte-identical to main; CC answers = stem on tier0 | `make test-cc` and `make test-cc-flags` pass on Mac and yfclab2; 28/28 identical `-v` logs; 10/10 tier0 codes correct with both rule sets | PASS |
| Tier 1 (CC old vs new, 5 seeds) | geomean < 1, no cell > 1.25 | 0.969, max 1.000 (process floor) | PASS |
| Tier 2 | same | 0.900, max 1.007 | PASS |
| Tier 3 | same | 0.677, max 0.999 (BB_288 0.250, LP_544 0.590) | PASS |
| Tier 4 | same | 1.004, max 1.003 (TN_250: parity off, leaf neutral) | PASS (neutral, within seed noise) |
| Tier 5 (CC, 6 h) | no cell worse; bounds consistent | 10 solved (incl. the 2 new LP codes), all 3.7-6x faster where parity applies, TN cells equal; lb 27 -> 28 on BB_756/864/1080; 0 science problems | PASS |
| `-oddcap-skip` Tier 1-3 (BB/LP, 5 seeds, 2 modes) | geomean < 1 per mode, no cell > 1.25 | 0.62 / 0.69, 0.58 / 0.59, 0.43 / 0.48; max 1.002 (control cell) | PASS |
| `-oddcap-skip` Tier 4 | - | no BB/LP code in tier4 (TN_250 only) | n/a |
| `-oddcap-skip` Tier 5 (6 h) | no cell worse | LP_714 / LP_1020 solved 2.2-8.5x sooner; every timeout cell lb 17 -> 18; no cell worse | PASS |

**Recommendation.**
1. **CC engine: keep `parity` and `leaf` on by default** (as the branch does; `-engine=cc` itself stays optional,
   PI decision of GH-124). `parity` is a theorem-backed 3.7-6x on every BB and LP code with a hard level and
   raised the certified lower bound of the three open BB codes to 28 within the same 6 h. `leaf` is neutral
   (0-5 % fewer nodes, no measurable time change); it is kept because it is exact, free, and removes the budget-1
   recursion, but it is not a performance argument: in a packing-bounded CC the leaves are already gone. The
   literature's 3-5x for the leaf trick applies to plain CC searches without a packing bound.
2. **`-oddcap-skip=on` should become the default of the MaxSAT path** (a separate adoption PR after PI
   approval, per the policy: this round only evaluated it). It is a pure cap-sequence change on halves with
   only odd column weights, proven by the same theorem, identity-tested in the off position, never slower in
   160 + 18 server cells, 2-5x on the BB/LP codes whose final refutation lines up with a Phase 1 cap (BB_288
   0.21-0.24, LP_442 0.34, LP_714 0.18-0.25, LP_1020 0.12-0.46), and a free +1 on every timeout lower bound.
   Caveat: its gain depends on where the distance sits relative to the doubling caps (LP_544, d = 12: 0.88-0.98);
   a Phase 2 cap sequence in steps of 2 after the first FOUND, instead of a single U-1 probe, would make the
   gain uniform and is the natural next MaxSAT-path round.
3. Next CC round, from the node histogram: the packing scan at budget 2-4 is where the time goes (78 % of the
   nodes are packing prunes). Candidates: Lee's stabilizer-overlap rule with forbidden-qubit propagation
   (survey Rank 3) and the degree bound as a cheap pre-check before the scan; the leaf trick has no further
   room. For the open BB codes (level 30 needs ~1e5 core-s single-threaded), only the parallel partition search
   (survey Rank 5) moves the bound further within 6 h.

**Scientific semantics changed:** no. **PI action required:** decide on (a) merging the branch (CC defaults;
`-oddcap-skip` present but off) and (b) a follow-up PR making `-oddcap-skip=on` the default; (c) whether the
BB_756/864/1080 `ge17` stems should be advanced to `ge28` (same certification status as the GH-124 `ge27`
bounds, which were not written into the stems either).

## 8. Reproduction

Build: `make clean && make CXX="c++ -Wno-reserved-user-defined-literal"` (Mac) / `make` (yfclab2, g++ 13).
Tests: `make test-cc`, `make test-cc-flags`. Mac S0: `S0/s0_mac.py` with `S0/mac/jobs.jsonl` (2 workers, 2 GB RSS
watchdog, `caffeinate -i -s`); identity: `S0/ident_mac.py MAIN CAND OUT`. Server: `S1/runner/s1_queue.py --bin
frozen/server-gh133-d8fcce8/distqldpc --cpus 105-123 --jobs jobs_cc.jsonl --out gh133-s1/cc` (panel + Tier 5
queue), `launch_oddcap.sh` (starts the oddcap panel when >= 4 of the cores 100-123 are free, then the oddcap
Tier 5 runs when >= 18 are free). Every process: `taskset -c CORE prlimit --as=4294967296 -- BIN ARGS`. The two
new LP codes come from branch `data/zenodo-crocker-codes` (PR #132) and were copied into the server worktree's
`data/matrices/tier5/` (not committed here).
