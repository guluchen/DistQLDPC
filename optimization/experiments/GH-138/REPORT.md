# GH-138 report: CC stabilizer-overlap pruning (Lee 2026) with forbidden-qubit propagation

Issue: https://github.com/guluchen/DistQLDPC/issues/138 (hub #15). Baseline: main `c914ef5` (CC optional with rules
`excl,pack,orbf,parity,leaf`; MaxSAT defaults frontier auto, oddcap-skip on). Candidate: branch
`experiment/gh-138-overlap`, evaluated binary `fc41a01` (S0 code `44bc29a`; `d662c2f` and `fc41a01` are
search-identical speed revisions). Literature basis: `docs/LITERATURE_CC_2026.md`, [Lee26] rule (iv). Clean-room:
written from the published one-line statement of the inequality and the mathematics; no code by Lee, Crocker,
Qubitserf or dist-m4ri was read. No external solver was used.

## Summary

| Item | Result |
|---|---|
| Default MaxSAT path | byte-identical to main `c914ef5`: 28/28 `-v` logs identical on tier0+1 x {`-no-card`, `-card-mto`}, for the S0 binary `44bc29a`, for `d662c2f` and for the final binary `fc41a01` (`S0/identity_tier01.txt` = the `fc41a01` run) |
| Rule `overlap` (minimum logical e meets every same-type stabilizer row g in <= floor(\|g\|/2) qubits; a tight row forbids the rest of g) | exact (proofs in `MODIFICATIONS.md`); node reduction at the largest common refuted level: **BB 0.20-0.47x** (BB_288 0.46, BB_360 0.35, BB_756/864/1080 0.20-0.23), **LP Z halves 0.49-0.73x** (X halves 0.90-1.0), **TN 0.67-0.96x** (larger TN codes and deeper levels gain more: TN_684 0.67, TN_396/468 0.78, small TN 0.93-0.96) |
| Time per node | +2-4 % on the Mac, +6-9 % on yfclab2 (counter updates), so the TN time gain is smaller than the node gain |
| Tier 1-4 panel, `-engine=cc` old vs new, 5 seeds (yfclab2) | geomean of seed-median ratios: tier1 0.842 (process floor), tier2 0.998, tier3 0.748, tier4 0.945; max cell 1.032; 110/110 correct; **PASS** (tier2 neutral) |
| Tier 5 (6 h, new rules) vs GH-133 Tier 5 (old rules) | 27/27 runs clean; **BB_756/864/1080: certified lb 28 -> 30** (level 28 EMPTY at 11 328-16 249 s; old engine never finished level 28), time to lb 28 0.23-0.26x; **TN_468: lb 22 -> 23**; BB_360 d=24 426 -> 172 s, LP_1428 744 -> 443 s, LP_1768 87 -> 53 s; other TN cells same final lb, time to it 0.75-1.14x (node ratio 0.67-0.92) |
| Correctness | `make test-cc` 115 200 ladders (128 rule subsets x 3 seeds) + 2 800 driver runs, 0 bad; large run 576 000 ladders + 8 400 driver runs, 0 bad (Mac and yfclab2); new mutants 8/9/10 fail as required; `make test-cc-flags` 180 checks; tier0-3 codes x 7-8 variants 168/168 = stem; panel 110/110; Tier 5 0 science problems |
| Recommendation | keep `overlap` in the CC default rule set (as the branch does); CC stays optional. New lower bounds (BB_756/864/1080 >= 30, TN_468 >= 23) are PLAUSIBLE pending PI review (relabeled-seed cross-checks in section 5.1) |

Scientific semantics changed: no. Every bound emitted under the new rule is implied by Lemmas 1-3 (`MODIFICATIONS.md`)
or identical to the old engine's; every witness is still verified by the independent GF(2) test.

## 1. What was implemented (S0)

**Rule `overlap`** (`src/cc/cc_half.{h,cc}`; in the branch's default `-cc-rules` as the candidate default;
`-cc-rules=excl,pack,orbf,parity,leaf` = the GH-133 engine = "old" in every comparison below). For the half that
searches x with H x = 0, nontrivial w.r.t. the detectors, K = the rows of the half's stabilizer generators (X half:
rows of Hx; Z half: rows of Hz). Both conditions the rule needs (H g = 0 and G g = 0 for every row) are verified by
the driver's start-up detector check and re-checked by `HalfSearch`. With lim_g = floor(|g|/2):
- counters slack_g = lim_g - |S & g| are updated on every qubit added to or removed from the cluster (seeds and
  children);
- when slack_g reaches 0, every qubit of g is forbidden (blk counter) for the subtree and released when the counter
  leaves 0; rows with lim_g = 0 (|g| = 1) are forbidden from the start of the level;
- the forbidden qubits leave the candidate lists and the disjoint-row packing bound and can create no-candidate dead
  ends; the strict prune |S & g| > lim_g is implied (a forbidden qubit is never added);
- with the `leaf` rule, children of remaining budget 1 or 2 (whose subtrees are hash lookups only) skip the counter
  updates. This is sound because a closure found there is a weight-w element of F and meets every limit by itself.
  Node counts are unchanged.

**Exact tight condition and the even tie.** The inequality is |e & g| <= floor(|g|/2) for odd and even |g|. The forbid
at |S & g| = floor(|g|/2) is not a tie-break but the look-ahead of the strict inequality: one more qubit of g would
exceed it. The even tie |e & g| = |g|/2 (e + g of equal weight) is **not** cut. Equal weight does not contradict
minimality, and cutting the tie removes both e and e + g (mutant 10 fails on 2112/19 200 ladders). Proofs (Lemmas 1-3
and the compatibility theorem for excl, pack, orbf, parity, leaf) are in `MODIFICATIONS.md`, GH-138. In short: under
the level precondition every weight-w element of F has minimum weight. So the rule prunes no subset of any weight-w
element of F and forbids no qubit of one, and each existing rule's argument is unchanged (each keeps one chosen
weight-w element e* reachable with no forbidden qubit in e*). For `orbf` the verified automorphism does not have to
map stabilizer rows to stabilizer rows. The argument only uses that pi(e) is a weight-w element of F, and the
inequality applies to it with the original rows. Part A of the tests uses row sets that the planted symmetry does
not preserve.

**Flags and counters.** `-cc-rules` accepts `overlap`. `-v` prints one line per half, e.g.
`c cc: X half overlap: on (72 stabilizer rows of Hx, weights 9..9, 0 forbidden from the start)`. `-cc-stats` adds
`ovtight` (rows that became tight) and `ovforbid` (qubits turned from free to forbidden). Revisions `44bc29a`/`d662c2f`
had an extra "overlap cut" counter that needed a second per-qubit counter. `fc41a01` removed it because it slowed the
stats-enabled timing runs. The strict prune never fires by construction, so the pruning effect is reported as the
exact node reduction against the old rules (deterministic node counts). Example (BB_864, X level 28, server):
34.7G nodes, 5.26G tightening events, 11.1G qubits forbidden.

**Mutants** (`-cc-mutant=8..10`, each must change answers): 8 = limit off by one (floor(|g|/2) - 1); 9 = the parity
checks H used as K; 10 = the even-|g| tie cut. `-cc-mutant` now accepts 0..10.

**Side exploration (not adopted).** Lemma 1 holds for every element of rs K, not only for the generator rows. I added
the pair sums g1 + g2 whose limit the rows do not already imply (720 extra rows on TN_250, 280 on TN_144, 864 on
BB_288; tested by appending them to Hx and comparing X-half levels). They cut a further 0-17 % of the nodes but every
run got slower: TN_250 X14 124.0M -> 103.0M nodes but 13.2 -> 13.6 s; TN_144 X12 3.63M -> 3.61M; BB_288 X16
1.11M -> 1.01M but 0.083 -> 0.095 s.

**Speed revisions (search-identical: the same node counts on every code).** The first server panel with `44bc29a`
showed ~10 % more time per node, which cancelled the 5-13 % node reduction on TN. `d662c2f` switched to slack counters
and dropped the updates for children completed by the budget-2 lookup. `fc41a01` also dropped them for budget-2
children and removed the stats-only counter. Per-node overhead fell to ~2-4 % on the Mac; on the server it stays at
~6-9 % (section 4). The aborted v1/v2 server queues are kept on the server (`gh138-s1/cc_v1_44bc29a_aborted`,
`cc_v2_d662c2f_aborted`) and are not used in any gate decision. Their v1 panel gave tier2 1.049 and tier3 0.708.

## 2. Correctness

| Check | Runs | Result |
|---|---:|---|
| Identity of the default MaxSAT path with main `c914ef5` (`-v` logs, tier0+tier1 x `-no-card`/`-card-mto`, time fields masked), binaries `44bc29a`, `d662c2f`, `fc41a01` | 3 x 28 | 28 identical each (`S0/identity_tier01.txt`) |
| `make test-cc` Part A: 300 random halves, each with a stabilizer set K inside ker [H; G] (100 bases, 100 all-low-weight sets, 55 random sets; not invariant under the planted symmetry), 128 rule subsets x 3 relabeling seeds, vs brute force | 115 200 ladders | 0 bad; in 80 halves a minimum element meets a row of K in exactly floor(\|g\|/2) qubits |
| Part B: 200 random CSS codes (68 with a verified dual map, 66 with dX != dZ), 14 driver configurations incl. new default, GH-133 rules, overlap only, overlap with index seeds + ub-basis + no-symbreak, sequential schedule | 2 800 | 0 bad, 0 `RESULT -1` |
| Part D (MaxSAT split, oddcap off/on) | 400 | 0 bad |
| Large run `test_cc_engine 1500 600` (v1 on the Mac, `fc41a01` on yfclab2: `S1/server/test_cc_big.txt`) | 576 000 ladders + 8 400 driver runs, each | 0 bad |
| Mutants 1-10 | - | all change answers; new: 8: 2880/19 200, 9: 3776/19 200, 10: 2112/19 200 ladders wrong |
| `make test-cc-flags` (overlap token, invalid values, `-cc-mutant` 0..10, overlap `-v` lines, stats fields) | 180 | pass (Mac and yfclab2) |
| All tier0-3 codes with `-engine=cc`: tier0-1 x 8 variants (GH-133 rules, new, overlap alone, excl+overlap, new+mrv, seed 1, seed 2 + dual off, no-symbreak + seed 3), tier2-3 x 7 (excl+pack+overlap instead of the two plain variants) (yfclab2, `S1/server/answers_tier0123.txt`) | 168 | 168 = stem |
| Tier 1-4 server panel answers, every `c d_lb` <= d <= `c d_ub` | 110 | 110 correct, 0 science problems |
| Tier 5 server runs vs stem ranges (answers, lb <= stem upper value, ub >= stem lower value), max RSS 41 MB | 27 | 27 clean, 0 traps |
| Mac S0 runs vs stems | 56 | every answer = stem; every timeout lb <= stem range |
| Old-arm node counts vs GH-133's binary `d8fcce8` (same rules): TN_252 Z20 9 157 065 402 both, every level identical | - | identical (so GH-133 logs are a valid old reference) |

## 3. S0: node counts and single-run times, old vs new (Mac M6, 2 GB cap, 2 concurrent, default seed, binary `fc41a01`)

Old = `-cc-rules=excl,pack,orbf,parity,leaf`; new = default (+ `overlap`). Node counts are deterministic and the
same in all three revisions. Tier 2-4 and the solved tier5 codes ran both arms. The unsolved tier5 codes ran the
new arm with a 3600 s cap. Their old side is GH-133's Mac log of the same rule set (same Mac, binary `d8fcce8`; node
counts verified identical on TN_252, the one code with an own old run). The four remaining queued jobs (TN_684 new,
and the old runs of TN_288, TN_612, BB_756 as extra references) were cancelled at the coordinator's request so that
the Mac is free for the baseline re-record (they show as `ERROR` lines in `results.tsv`, i.e. not started). They are
not needed: TN_684's per-level node counts with the same binary are in the server Tier 5 run (section 5), and the
old references come from GH-133. No Mac sleep events occurred during the runs (`pmset -g log`). Raw:
`S0/mac/results.tsv`, `S0/mac/logs.tar.gz`; table: `S0/analyze_s0mac.py` (also `S0/s0mac_table.md`). "ratio" is
new/old wall; the last column lists the top three completed levels common to both arms.

| Tier | Code | old wall s | new wall s | ratio | result old / new | top common levels: nodes old -> new (ratio), s old -> new |
|---:|---|---:|---:|---:|---|---|
| 2 | BB_144_14_14 | 0.6035 | 0.5824 | 0.965 | 14 / 14 | X12: 0.9M -> 0.8M (0.931), 0.1 -> 0.1; X13: 4.3M -> 4.0M (0.921), 0.4 -> 0.4; X14: 0.7M -> 0.6M (0.933), 0.1 -> 0.1 |
| 2 | GB_144_12_12 | 0.0785 | 0.0742 | 0.945 | 12 / 12 | X10: 0.1M -> 0.1M (0.953), 0.0 -> 0.0; X11: 0.2M -> 0.2M (0.945), 0.0 -> 0.0; X12: 0.6M -> 0.6M (0.951), 0.0 -> 0.0 |
| 2 | LP_442_68_10 | 0.0156 | 0.0142 | 0.910 | 10 / 10 | X8: 0.0M -> 0.0M (0.966), 0.0 -> 0.0; Z8: 0.0M -> 0.0M (0.970), 0.0 -> 0.0; X10: 0.0M -> 0.0M (1.000), 0.0 -> 0.0 |
| 2 | LP_544_80_12 | 0.0199 | 0.0179 | 0.899 | 12 / 12 | X10: 0.0M -> 0.0M (0.985), 0.0 -> 0.0; Z10: 0.0M -> 0.0M (0.809), 0.0 -> 0.0; X12: 0.0M -> 0.0M (1.000), 0.0 -> 0.0 |
| 2 | TN_108_2_12 | 0.3129 | 0.3085 | 0.986 | 12 / 12 | Z10: 0.2M -> 0.2M (0.952), 0.0 -> 0.0; X11: 1.7M -> 1.6M (0.913), 0.1 -> 0.1; Z11: 0.8M -> 0.8M (0.930), 0.1 -> 0.1 |
| 2 | TN_200_10_10 | 0.0784 | 0.0781 | 0.996 | 10 / 10 | X9: 0.3M -> 0.3M (0.946), 0.0 -> 0.0; Z9: 0.2M -> 0.2M (0.926), 0.0 -> 0.0; Z10: 0.0M -> 0.0M (0.950), 0.0 -> 0.0 |
| 3 | BB_288_12_18 | 0.2119 | 0.1174 | 0.554 | 18 / 18 | X12: 0.0M -> 0.0M (0.529), 0.0 -> 0.0; X14: 0.3M -> 0.1M (0.496), 0.0 -> 0.0; X16: 2.4M -> 1.1M (0.458), 0.2 -> 0.1 |
| 3 | TN_144_2_13 | 1.2074 | 1.1873 | 0.983 | 13 / 13 | X12: 3.9M -> 3.6M (0.936), 0.4 -> 0.4; Z12: 2.0M -> 1.9M (0.958), 0.2 -> 0.2; Z13: 4.3M -> 4.1M (0.942), 0.4 -> 0.4 |
| 4 | LP_714_100_16 | 0.2412 | 0.2128 | 0.882 | 16 / 16 | X14: 1.2M -> 1.2M (0.969), 0.1 -> 0.1; Z14: 1.8M -> 1.5M (0.809), 0.1 -> 0.1; X16: 0.0M -> 0.0M (1.000), 0.0 -> 0.0 |
| 4 | TN_250_10_15 | 33.0565 | 29.5504 | 0.894 | 15 / 15 | X14: 143.6M -> 124.0M (0.863), 16.0 -> 14.5; Z14: 56.2M -> 48.9M (0.870), 6.3 -> 5.3; Z15: 13.5M -> 11.7M (0.870), 1.5 -> 1.3 |
| 5 | BB_1080_4_ge28 (old: GH-133 log) | - | 3600.0207 | - | lb 28 / lb 28 | X22: 427.3M -> 115.8M (0.271), 44.9 -> 12.0; X24: 3299.6M -> 799.4M (0.242), 364.3 -> 86.9; X26: 25775.1M -> 5597.5M (0.217), 2982.4 -> 637.1 |
| 5 | BB_360_12_24 | 184.8586 | 72.9448 | 0.395 | 24 / 24 | X20: 190.7M -> 72.0M (0.377), 16.5 -> 6.8; X22: 1832.8M -> 633.1M (0.345), 163.7 -> 63.5; X24: 30.6M -> 15.9M (0.520), 2.9 -> 1.7 |
| 5 | BB_756_16_ge28 (old: GH-133 log) | - | 3600.0229 | - | lb 26 / lb 28 | X20: 57.3M -> 17.2M (0.301), 5.5 -> 1.6; X22: 448.2M -> 122.2M (0.273), 45.9 -> 12.3; X24: 3568.5M -> 885.1M (0.248), 384.2 -> 94.0 |
| 5 | BB_864_4_ge28 (old: GH-133 log) | - | 3600.0249 | - | lb 28 / lb 28 | X22: 392.4M -> 96.9M (0.247), 39.4 -> 9.7; X24: 3053.1M -> 674.6M (0.221), 322.8 -> 71.1; X26: 24123.0M -> 4791.4M (0.199), 2526.8 -> 530.2 |
| 5 | LP_1020_136_16 | 0.1847 | 0.1533 | 0.830 | 16 / 16 | X14: 0.6M -> 0.6M (0.949), 0.0 -> 0.0; Z14: 1.1M -> 0.8M (0.726), 0.1 -> 0.1; X16: 0.1M -> 0.1M (1.000), 0.0 -> 0.0 |
| 5 | LP_1054_140_20 | 8.7307 | 6.2421 | 0.715 | 20 / 20 | X18: 24.7M -> 23.6M (0.956), 1.9 -> 1.8; Z18: 63.6M -> 40.2M (0.633), 5.9 -> 3.7; X20: 0.2M -> 0.2M (1.000), 0.0 -> 0.0 |
| 5 | LP_1122_148_20 | 7.9132 | 5.4152 | 0.684 | 20 / 20 | X18: 19.2M -> 18.2M (0.950), 1.5 -> 1.4; Z18: 58.0M -> 35.1M (0.605), 5.5 -> 3.3; X20: 0.0M -> 0.0M (1.000), 0.0 -> 0.0 |
| 5 | LP_1428_184_24 | 310.1694 | 171.9812 | 0.554 | 24 / 24 | X22: 480.5M -> 450.9M (0.939), 39.4 -> 37.6; Z22: 2232.6M -> 1092.9M (0.490), 231.7 -> 112.9; X24: 1.5M -> 1.5M (1.000), 0.1 -> 0.1 |
| 5 | LP_1768_224_22 | 35.8925 | 20.7217 | 0.577 | 22 / 22 | X20: 48.1M -> 43.4M (0.902), 4.1 -> 3.7; Z20: 255.8M -> 127.2M (0.497), 26.3 -> 13.2; X22: 11.6M -> 11.6M (0.999), 1.1 -> 1.1 |
| 5 | LP_2610_744_16 | 1.9708 | 1.9553 | 0.992 | 16 / 16 | X14: 10.6M -> 10.6M (0.999), 0.7 -> 0.8; Z14: 13.4M -> 12.5M (0.934), 1.0 -> 0.9; X16: 0.3M -> 0.3M (1.000), 0.0 -> 0.0 |
| 5 | TN_180_2_17 | 104.8759 | 93.7802 | 0.894 | 17 / 17 | X16: 392.1M -> 324.2M (0.827), 39.0 -> 34.1; Z16: 134.4M -> 118.4M (0.880), 13.5 -> 12.5; Z17: 318.7M -> 273.0M (0.857), 33.0 -> 29.7 |
| 5 | TN_216_4_18 | 268.3685 | 231.6296 | 0.863 | 18 / 18 | X17: 1078.7M -> 853.5M (0.791), 113.9 -> 96.3; Z17: 527.3M -> 433.5M (0.822), 54.4 -> 47.8; Z18: 329.1M -> 261.5M (0.794), 34.3 -> 29.1 |
| 5 | TN_252_2_21 | 3600.0253 | 3600.0234 | - | lb 20 / lb 20 | X19: 4594.2M -> 3937.3M (0.857), 559.3 -> 501.5; Z19: 2582.7M -> 2270.5M (0.879), 296.9 -> 272.5; Z20: 9157.1M -> 7941.9M (0.867), 1080.4 -> 978.1 |
| 5 | TN_288_2_ge9 (old: GH-133 log) | - | 3600.0202 | - | lb 19 / lb 19 | X18: 4530.5M -> 3935.9M (0.869), 563.8 -> 508.3; Z18: 3252.8M -> 2868.0M (0.882), 384.8 -> 353.4; Z19: 10930.3M -> 9515.0M (0.871), 1332.2 -> 1209.3 |
| 5 | TN_324_4_ge9 (old: GH-133 log) | - | 3600.0255 | - | lb 19 / lb 19 | X18: 4736.1M -> 4056.6M (0.857), 564.5 -> 504.4; Z18: 2481.9M -> 2176.4M (0.877), 300.4 -> 274.0; Z19: 7952.3M -> 6904.9M (0.868), 993.2 -> 896.5 |
| 5 | TN_360_4_ge17 (old: GH-133 log) | - | 3600.0111 | - | lb 21 / lb 22 | X20: 2706.7M -> 2414.9M (0.892), 382.2 -> 353.1; Z20: 2879.2M -> 2588.5M (0.899), 388.1 -> 358.1; X21: 9183.3M -> 8120.0M (0.884), 1331.2 -> 1219.3 |
| 5 | TN_396_4_ge17 (old: GH-133 log) | - | 3600.006 | - | lb 21 / lb 22 | X20: 4951.9M -> 3917.1M (0.791), 633.6 -> 522.0; Z20: 1939.7M -> 1561.4M (0.805), 241.1 -> 201.5; Z21: 5916.6M -> 4675.4M (0.790), 752.8 -> 620.5 |
| 5 | TN_432_8_ge9 (old: GH-133 log) | - | 3600.0121 | - | lb 20 / lb 20 | Z18: 1402.2M -> 1282.2M (0.914), 186.5 -> 175.7; X19: 5526.8M -> 5109.5M (0.925), 774.5 -> 732.5; Z19: 4311.6M -> 3918.7M (0.909), 591.8 -> 554.3 |
| 5 | TN_468_4_ge17 (old: GH-133 log) | - | 3600.0226 | - | lb 22 / lb 22 | Z20: 1097.1M -> 882.8M (0.805), 141.2 -> 118.7; X21: 12532.1M -> 9417.1M (0.751), 1671.7 -> 1316.6; Z21: 3228.7M -> 2555.1M (0.791), 426.9 -> 353.5 |
| 5 | TN_496_2_ge17 (old: GH-133 log) | - | 3600.014 | - | lb 21 / lb 21 | X20: 3687.9M -> 3050.9M (0.827), 492.7 -> 420.4; Z20: 4739.5M -> 3871.5M (0.817), 630.1 -> 533.1; X21: 10923.0M -> 8952.2M (0.820), 1507.8 -> 1274.1 |
| 5 | TN_504_2_ge17 (old: GH-133 log) | - | 3600.0213 | - | lb 22 / lb 23 | X21: 2689.4M -> 2435.5M (0.906), 408.5 -> 380.6; Z21: 2561.5M -> 2294.0M (0.896), 375.6 -> 346.8; Z22: 8038.3M -> 7150.5M (0.890), 1211.9 -> 1117.1 |
| 5 | TN_540_4_ge9 (old: GH-133 log) | - | 3600.0177 | - | lb 20 / lb 20 | X19: 5062.6M -> 4614.3M (0.911), 706.7 -> 662.8; Z19: 3524.5M -> 3176.4M (0.901), 480.0 -> 446.2; Z20: 10625.7M -> 9491.7M (0.893), 1495.6 -> 1378.1 |
| 5 | TN_576_2_ge9 (old: GH-133 log) | - | 3600.0141 | - | lb 21 / lb 21 | Z19: 1693.0M -> 1551.1M (0.916), 245.1 -> 229.6; X20: 7684.2M -> 7027.5M (0.915), 1128.5 -> 1060.5; Z20: 4837.2M -> 4407.9M (0.911), 722.2 -> 674.2 |
| 5 | TN_612_2_ge17 (old: GH-133 log) | - | 3600.0248 | - | lb 23 / lb 23 | Z21: 1302.2M -> 1172.0M (0.900), 197.7 -> 181.9; X22: 6071.3M -> 5419.8M (0.893), 953.6 -> 875.7; Z22: 3915.5M -> 3498.8M (0.894), 612.1 -> 559.4 |
| 5 | TN_648_10_9to52 (old: GH-133 log) | - | 3600.0265 | - | lb 21 / lb 21 | Z19: 2098.2M -> 1903.5M (0.907), 304.7 -> 283.1; X20: 9176.1M -> 8303.3M (0.905), 1403.8 -> 1297.7; Z20: 5964.1M -> 5374.3M (0.901), 893.7 -> 825.2 |
| 5 | TN_648_14_ge9 (old: GH-133 log) | - | 3600.0231 | - | lb 20 / lb 20 | X19: 3519.1M -> 3213.3M (0.913), 524.3 -> 489.9; Z19: 2485.4M -> 2245.7M (0.904), 353.3 -> 327.4; Z20: 7179.3M -> 6443.2M (0.897), 1053.7 -> 969.2 |

largest common EMPTY level per code: geomean nodes 0.710, time 0.735 over 36 codes

Reading:
- **BB** (weight-6 rows, limit 3): the rule removes 53-80 % of the nodes, and the gain grows with the level (BB_288
  X16 0.46, BB_360 X22 0.35, BB_864 X26 0.20). BB_360 d=24: 185 -> 73 s.
- **LP** (weight-8 rows, limit 4): the Z half loses 27-51 % of its nodes (LP_1428 Z22 0.49, LP_1768 Z20 0.50), the X
  half 0-10 %. LP_1428: 310 -> 172 s; LP_1768: 36 -> 21 s.
- **TN** (weight-6/9 rows, limit 3/4): 4-6 % fewer nodes on tier 2-3 codes, 13 % on TN_250, 9-25 % on the large tier5
  codes (TN_684 X21 0.67, TN_468 X21 0.75, TN_396 0.79); time per node is ~2-4 % higher on the Mac. Within the hour
  cap the new arm completes one more level on TN_360, TN_396, TN_504 (lb +1) and on BB_756 (lb 26 -> 28).
- **GB_144_12_12** (parity off, weight-8 rows): 5 % fewer nodes, time 0.95x.

## 4. S1 Tier 1-4 panel, `-engine=cc` old vs new (yfclab2, cores 100-123, 4 GB cap, seeds 0-4, binary `fc41a01`)

Limits: tier1-3 1800 s, tier4 5000 s. One process per pinned core, both arms of a (code, seed) back to back,
`-cc-stats` in both arms. Tiers as of main `c914ef5` (tier1 LP_340; tier2 six codes; tier3 BB_288, TN_144; tier4
TN_250, LP_714). Wall seconds, median over seeds 0-4 (range). "nodes new/old" = median over seeds of the per-seed
ratio of total CC nodes (sum of all levels). "ns/node" = search seconds / nodes, median over seeds. Raw:
`S1/server/cc/results.jsonl`, logs `S1/server/cc/logs.tar.gz`; `S1/runner/analyze_panel.py` (also
`S1/panel_table.md`).

| Tier | Code | old wall median (range) | new wall median (range) | ratio | nodes new/old (median over seeds) | search ns/node old -> new | answers |
|---:|---|---|---|---:|---:|---|---|
| 1 | LP_340_56_8 | 0.038 (0.027-0.072) | 0.032 (0.025-0.070) | 0.842 | 1.000 | (process floor) | [8] |
| 2 | BB_144_14_14 | 1.114 (1.094-1.223) | 1.102 (1.088-1.211) | 0.989 | 0.924 | 209 -> 223 | [14] |
| 2 | GB_144_12_12 | 0.186 (0.134-0.298) | 0.192 (0.144-0.298) | 1.032 | 0.935 | 186 -> 200 | [12] |
| 2 | LP_442_68_10 | 0.027 (0.025-0.027) | 0.026 (0.026-0.027) | 0.963 | 0.959 | (process floor) | [10] |
| 2 | LP_544_80_12 | 0.046 (0.041-0.049) | 0.045 (0.038-0.047) | 0.978 | 0.962 | (process floor) | [12] |
| 2 | TN_108_2_12 | 1.975 (0.843-2.704) | 1.992 (0.840-2.732) | 1.009 | 0.947 | 223 -> 243 | [12] |
| 2 | TN_200_10_10 | 0.512 (0.190-0.591) | 0.522 (0.187-0.675) | 1.020 | 0.947 | 220 -> 239 | [10] |
| 3 | BB_288_12_18 | 0.472 (0.462-0.499) | 0.258 (0.257-0.268) | 0.547 | 0.466 | 178 -> 196 | [18] |
| 3 | TN_144_2_13 | 6.938 (2.899-11.119) | 7.101 (2.938-11.412) | 1.023 | 0.959 | 239 -> 253 | [13] |
| 4 | LP_714_100_16 | 0.666 (0.575-0.888) | 0.654 (0.546-0.801) | 0.982 | 0.935 | 200 -> 208 | [16] |
| 4 | TN_250_10_15 | 126.084 (104.085-135.529) | 114.782 (67.067-131.664) | 0.910 | 0.897 | 253 -> 270 | [15] |

| Tier | cells | geomean | max cell | cells > 1.25 |
|---:|---:|---:|---:|---:|
| 1 | 1 | 0.842 | 0.842 | 0 |
| 2 | 6 | 0.998 | 1.032 | 0 |
| 3 | 2 | 0.748 | 1.023 | 0 |
| 4 | 2 | 0.945 | 0.982 | 0 |

110 runs, science problems: []

Gate (geomean < 1, no cell > 1.25): tier 1 PASS (process floor); tier 2 PASS but neutral (0.998; the 5-8 % node
reduction is eaten by +6-9 % time per node on this server; GB_144 1.032 and TN cells 1.01-1.02 are regressions to
watch, all well below 1.25); tier 3 PASS (BB_288 0.547; TN_144 1.023); tier 4 PASS (TN_250 0.910, LP_714 0.982).
The node counts show the rule never adds nodes (ratios 0.47-1.00 in every cell). The server's per-node overhead is
larger than the Mac's (+2-4 %); the server was shared with other users' jobs during the panel (load ~100), and some
old-arm runs on the same cores were 30-40 % slower than their seed mates (TN_250 seeds 0 and 2), which is why the
TN_250 median gain (0.910) is close to the node gain (0.897).

## 5. S1 Tier 5 (yfclab2, 6 h, default seed, new rules) vs GH-133 Tier 5 (old rules)

One run per code (27 tier5 codes as of `c914ef5`), cores 100-123, 4 GB cap, `-cc-stats`. Reference: GH-133 S1 Tier 5
(binary `d8fcce8`, rules `excl,pack,orbf,parity,leaf`, same server, 6 h,
`optimization/experiments/GH-133/S1/server/cc/results.jsonl`). Its per-level node counts are those of the old
arm here (identity checked on TN_252). The server was shared with other users' jobs during this run (load ~100). GH-133
ran under a different load, so cross-session time ratios carry that noise; per-level node counts are exact. "time to
old final lb" = elapsed time at which each run first reached the old run's final value (its answer for solved codes).
Raw: `S1/server/cc/results.jsonl`, `S1/server/cc/logs.tar.gz`; `S1/runner/analyze_tier5.py` (also `S1/tier5_table.md`).

| Code | GH-133 (old rules) | GH-138 (overlap) | time to old final lb: old -> new s (ratio) | largest common EMPTY level: nodes old -> new (ratio), s old -> new (ratio) |
|---|---|---|---|---|
| BB_360_12_24 | d=24 @ 426 | d=24 @ 172 (lb 24) | 426 -> 172 (0.403) | X22: 1832.8M -> 633.1M (0.345), 377 -> 150 (0.397) |
| BB_756_16_ge28 | TIMEOUT lb 28 | TIMEOUT lb 30 (lb 30) | 7939 -> 2057 (0.259) | X26: 28902.2M -> 6531.4M (0.226), 6987 -> 1783 (0.255) |
| BB_864_4_ge28 | TIMEOUT lb 28 | TIMEOUT lb 30 (lb 30) | 6669 -> 1521 (0.228) | X26: 24123.0M -> 4791.4M (0.199), 5848 -> 1311 (0.224) |
| BB_1080_4_ge28 | TIMEOUT lb 28 | TIMEOUT lb 30 (lb 30) | 7506 -> 1836 (0.245) | X26: 25775.1M -> 5597.5M (0.217), 6581 -> 1579 (0.240) |
| LP_1020_136_16 | d=16 @ 0 | d=16 @ 0 (lb 16) | 0 -> 0 (1.078) | Z14: 1.1M -> 0.8M (0.726), 0 -> 0 (0.959) |
| LP_1054_140_20 | d=20 @ 20 | d=20 @ 19 (lb 20) | 20 -> 19 (0.991) | Z18: 63.6M -> 40.2M (0.633), 13 -> 11 (0.877) |
| LP_1122_148_20 | d=20 @ 18 | d=20 @ 13 (lb 20) | 18 -> 13 (0.731) | Z18: 58.0M -> 35.1M (0.605), 12 -> 8 (0.643) |
| LP_1428_184_24 | d=24 @ 744 | d=24 @ 443 (lb 24) | 744 -> 443 (0.595) | Z22: 2232.6M -> 1092.9M (0.490), 558 -> 287 (0.513) |
| LP_1768_224_22 | d=22 @ 87 | d=22 @ 53 (lb 22) | 87 -> 53 (0.614) | Z20: 255.8M -> 127.2M (0.497), 63 -> 34 (0.536) |
| LP_2610_744_16 | d=16 @ 5 | d=16 @ 8 (lb 16) | 5 -> 8 (1.417) | Z14: 13.4M -> 12.5M (0.934), 3 -> 4 (1.403) |
| TN_180_2_17 | d=17 @ 256 | d=17 @ 275 (lb 17) | 256 -> 275 (1.075) | X16: 392.1M -> 324.2M (0.827), 96 -> 101 (1.057) |
| TN_216_4_18 | d=18 @ 651 | d=18 @ 578 (lb 18) | 651 -> 578 (0.888) | X17: 1078.7M -> 853.5M (0.791), 275 -> 238 (0.865) |
| TN_252_2_21 | TIMEOUT lb 21 | TIMEOUT lb 21 (lb 21) | 10167 -> 9395 (0.924) | Z21: 32884.2M -> 28111.3M (0.855), 9131 -> 8625 (0.945) |
| TN_288_2_ge9 | TIMEOUT lb 20 | TIMEOUT lb 20 (lb 20) | 10692 -> 10236 (0.957) | Z20: 37224.4M -> 31974.1M (0.859), 10622 -> 10297 (0.969) |
| TN_324_4_ge9 | TIMEOUT lb 20 | TIMEOUT lb 20 (lb 20) | 9559 -> 8844 (0.925) | Z20: 25818.1M -> 22185.5M (0.859), 7484 -> 7083 (0.946) |
| TN_360_4_ge17 | TIMEOUT lb 22 | TIMEOUT lb 22 (lb 22) | 8471 -> 9627 (1.136) | X22: 31539.0M -> 27621.6M (0.876), 10404 -> 11571 (1.112) |
| TN_396_4_ge17 | TIMEOUT lb 22 | TIMEOUT lb 22 (lb 22) | 9384 -> 8052 (0.858) | Z22: 18227.2M -> 14138.1M (0.776), 5354 -> 4596 (0.858) |
| TN_432_8_ge9 | TIMEOUT lb 21 | TIMEOUT lb 21 (lb 21) | 14309 -> 14084 (0.984) | X20: 17198.9M -> 15793.0M (0.918), 5524 -> 5496 (0.995) |
| TN_468_4_ge17 | TIMEOUT lb 22 | TIMEOUT lb 23 (lb 23) | 7029 -> 5865 (0.834) | Z22: 9590.7M -> 7463.1M (0.778), 2930 -> 2490 (0.850) |
| TN_496_2_ge17 | TIMEOUT lb 22 | TIMEOUT lb 22 (lb 22) | 10943 -> 9796 (0.895) | X22: 32824.0M -> 26543.9M (0.809), 9688 -> 8724 (0.900) |
| TN_504_2_ge17 | TIMEOUT lb 23 | TIMEOUT lb 23 (lb 23) | 8245 -> 7900 (0.958) | Z23: 25542.9M -> 22560.4M (0.883), 8769 -> 8459 (0.965) |
| TN_540_4_ge9 | TIMEOUT lb 21 | TIMEOUT lb 21 (lb 21) | 12356 -> 11954 (0.967) | X20: 15380.2M -> 13922.8M (0.905), 4958 -> 4822 (0.973) |
| TN_576_2_ge9 | TIMEOUT lb 22 | TIMEOUT lb 22 (lb 22) | 18700 -> 18594 (0.994) | X21: 22701.4M -> 20655.7M (0.910), 7583 -> 7567 (0.998) |
| TN_612_2_ge17 | TIMEOUT lb 24 | TIMEOUT lb 24 (lb 24) | 16119 -> 15395 (0.955) | X23: 18563.1M -> 16460.1M (0.887), 6656 -> 6387 (0.960) |
| TN_648_10_9to52 | TIMEOUT lb 21 | TIMEOUT lb 21 (lb 21) | 7877 -> 7634 (0.969) | Z21: 17148.8M -> 15342.0M (0.895), 5972 -> 6808 (1.140) |
| TN_648_14_ge9 | TIMEOUT lb 21 | TIMEOUT lb 21 (lb 21) | 8835 -> 8593 (0.973) | Z21: 20969.5M -> 18684.8M (0.891), 7037 -> 6862 (0.975) |
| TN_684_2_ge9 | TIMEOUT lb 22 | TIMEOUT lb 22 (lb 22) | 15406 -> 11624 (0.754) | X21: 23948.4M -> 15938.1M (0.666), 6900 -> 5180 (0.751) |

geomean over codes of the largest common EMPTY level: nodes 0.657, time 0.754 (27 codes)

Bound events (value@seconds, from lb 18) where the final bound changed:

| Code | GH-133 (old) | GH-138 (new) |
|---|---|---|
| BB_756_16_ge28 | 18@0 20@1 22@13 24@114 26@951 28@7938 | 18@0 20@0 22@4 24@36 26@273 28@2057 **30@16249** |
| BB_864_4_ge28 | 18@0 20@1 22@12 24@103 26@821 28@6669 | 18@0 20@0 22@4 24@28 26@209 28@1521 **30@11328** |
| BB_1080_4_ge28 | 18@0 20@1 22@14 24@114 26@924 28@7505 | 18@0 20@0 22@5 24@35 26@257 28@1836 **30@13632** |
| TN_468_4_ge17 | 18@77 19@236 20@728 21@2242 22@7029 | 18@70 19@210 20@633 21@1913 22@5864 **23@18316** |

Reading:
- **BB: 4-4.4x per level, certified lb 28 -> 30 on the three open BB codes.** Level 26 costs 0.20-0.23x the nodes;
  level 28 (34.7-49.1G nodes, 9 800-14 200 s) completes within the 6 h, which the old engine never managed
  (GH-133: lb 28 at 6 669-7 938 s, level 30 not reached). BB_360 d=24: 426 -> 172 s.
- **LP: 1.4-1.7x on the codes with a hard level** (LP_1428 744 -> 443 s, LP_1768 87 -> 53 s, LP_1122 18 -> 13 s);
  LP_1054 20 -> 19 s; the sub-10-s codes LP_1020 and LP_2610 are at the process/parsing floor (LP_2610 5 -> 8 s:
  its Z14 level has 0.93x the nodes, so the extra seconds are server noise plus counter overhead on a 2610-qubit
  code with a single cheap level).
- **TN: same final bound on 15 of 16 open TN codes, one more level on TN_468** (lb 23 at 18 316 s). Node ratio at the
  largest common level 0.67-0.92 (geomean of all 27 codes 0.657 nodes, 0.754 time). Time to the old final lb ranges
  from 0.75x (TN_684) to 1.14x (TN_360). TN_360 (X22 nodes 0.876, time 1.112) and TN_648_10 (Z21 nodes 0.895, time
  1.140) are the two cells where fewer nodes took longer. The per-node overhead on this server (+6-9 %) explains
  part of it, and cross-session load differences the rest. The reference timings themselves vary that much: between
  GH-124 and GH-133 TN_360 reached lb 22 at 10 903 s vs 8 471 s on the same server, with node counts equal within 1 %.
  TN_252_2_21 is still not solved (lb 21 at 9 394 s vs 10 167 s; level 22 not finished).
- 27/27 runs clean (answers = stems; every lb <= stem upper value; every ub >= stem lower value; no trap; max RSS
  41 MB).

### 5.1 Cross-checks of the new bounds (yfclab2, cores 100-103, 6 h cap, new rules with relabeling seeds)

Relabeling (`-seed=N` = `-cc-seed=N`) permutes qubit and row labels, so the order of branching, the orbit
representatives, the sibling exclusions and the overlap counters all change; the level verdicts must not.

| Code | default seed (Tier 5 run) | relabeled run | level 28 X: nodes, seconds |
|---|---|---|---|
| BB_864_4_ge28 | lb 30 @ 11 328 s | seed 1: **lb 30 @ 13 818 s** | 34.70G, 9 807 s / 44.71G, 11 965 s |
| BB_756_16_ge28 | lb 30 @ 16 249 s | seed 2: **lb 30 @ 15 498 s** | 49.07G, 14 192 s / 49.28G, 13 492 s |
| BB_1080_4_ge28 | lb 30 @ 13 632 s | seed 3: **lb 30 @ 12 995 s** | 39.76G, 11 796 s / 40.21G, 11 249 s |
| TN_468_4_ge17 | lb 23 @ 18 316 s | seed 1: lb 21 @ 15 603 s (stopped at 16 200 s; this labeling is slower) | - |

The BB bounds were reproduced with three other search trees (different node counts, same EMPTY verdict at level 28).
Like the GH-124/GH-133 CC bounds, they come from the canonical CC search, now with the overlap rule. By the
certification rule of `GH-124/ADJUDICATION.md` they are PLAUSIBLE until the certification track confirms them, so the
stems are not renamed here. TN_468 >= 23 has no second run yet. The cross-check runner was stopped once the BB
bounds had been reproduced (level 30 cannot finish within 6 h), so `S1/server/xcheck/` holds only the logs
(`logs.tar.gz`) and the job file.

## 6. Gate verdicts and recommendation

| Gate | Criterion | Result | Verdict |
|---|---|---|---|
| Tier 0 (correctness / smoke) | tests pass; default path byte-identical to main; CC answers = stem | `make test-cc` (115 200 ladders, 2 800 driver runs) and the 576 000-ladder run pass on Mac and yfclab2; mutants 8-10 fail as required; `make test-cc-flags` 180/180; 28/28 identical `-v` logs; tier0-3 168/168 | PASS |
| Tier 1 (CC old vs new, 5 seeds) | geomean < 1, no cell > 1.25 | 0.842 (process floor) | PASS |
| Tier 2 | same | 0.998, max 1.032 (GB_144_12_12) | PASS (neutral) |
| Tier 3 | same | 0.748, max 1.023 (TN_144); BB_288 0.547 | PASS |
| Tier 4 | same | 0.945, max 0.982 (LP_714); TN_250 0.910 | PASS |
| Tier 5 (6 h) | no cell worse; bounds consistent | 0 science problems; no cell lost a bound; BB_756/864/1080 lb 28 -> 30 (reproduced with relabeled seeds); TN_468 lb 22 -> 23; solved codes 0.40-0.99x except two sub-10-s floor cells; TN time to the old final lb 0.75-1.14x (2 of 16 above 1.0) | PASS |

**Recommendation.**
1. **Keep `overlap` in the CC default rule set** (the branch already has it: `-cc-rules` default
   `excl,pack,orbf,parity,leaf,overlap`). `-engine=cc` stays optional (PI decision of GH-124). The rule is exact,
   never adds nodes, and gives 1.8-4.4x on BB (the open BB codes gain two certified levels in 6 h), 1.4-1.8x on LP codes
   with a hard level, and 4-33 % fewer nodes on TN. On TN its time gain is smaller than its node gain because each
   node does more counter work (+2-4 % Mac, +6-9 % server); tier 2 is neutral for that reason.
2. **PI decisions:** (a) merge the branch (CC default rule set gains `overlap`; MaxSAT path untouched);
   (b) whether BB_756/864/1080 (`ge28`) should go to `ge30` and TN_468 (`ge17`) record lb 23, under the same
   PLAUSIBLE status as the earlier CC bounds.
3. **Next CC round, from these numbers.** On TN the rule binds rarely (weight-9 rows, limit 4), and pair sums of
   rows cost more than they save. Remaining levers: (i) cheaper counter maintenance on TN (e.g. update only rows
   whose slack can reach 0 within the remaining budget); (ii) an overlap-aware packing bound, which counts how many
   qubits each stabilizer row can still take instead of only forbidding full rows; (iii) Proposal 2 of the issue
   (an in-house upper-bound finder for the TN stop rule). For the BB codes, level 30 now needs ~1e5 core-s and only a
   parallel partition search moves it within 6 h.

**Scientific semantics changed:** no. **PI action required:** yes, decisions (2a) and (2b) above.

## 7. Reproduction

Build: `make clean && make CXX="c++ -Wno-reserved-user-defined-literal"` (Mac) / `make -j8` (yfclab2, g++). Tests:
`make test-cc`, `make test-cc-flags`, `./build/test_cc_engine 1500 600`. Identity: `S0/ident_mac.py
../frozen-main-c914ef5/distqldpc ../frozen-cand138/distqldpc.fc41a01 OUT`. Mac S0: `caffeinate -i -s python3 -I
S0/s0_mac.py S0/mac/jobs.jsonl S0/mac/results.tsv 2` (the job file names `../frozen-cand138/distqldpc`, which was
`fc41a01`; it was renamed `distqldpc.fc41a01` to cancel the last four jobs). Server (from a worktree of `fc41a01`):
`python3 -I s1_queue.py --bin frozen/server-gh138-fc41a01/distqldpc --cpus 100-123 --jobs S1/runner/jobs_cc.jsonl
--out gh138-s1/cc` (panel then Tier 5); `--cpus 100-103 --jobs S1/runner/jobs_xcheck.jsonl` (cross-checks);
`S1/runner/answers.sh BIN 123` (tier0-3 answers). Every server process: `taskset -c CORE prlimit --as=4294967296 --
BIN ARGS`. Summaries: `S1/runner/analyze_panel.py`, `S1/runner/analyze_tier5.py`, `S0/analyze_s0mac.py`.
