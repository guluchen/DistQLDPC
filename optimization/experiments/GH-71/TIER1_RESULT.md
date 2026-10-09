# GH-71 Tier1 result — numeric filter POSITIVE (both modes), no regression flag

Frozen binaries (base ac43af52…, cand c89b243c…), bound-soundness runner, 208/208 correct (rc 0, named
distance, sound emitted bounds), inputs re-verified, load 1.16–1.72, one solve at a time.

| Case | OFF median b -> c (s) | OFF ratio (repl.) | MTO median b -> c (s) | MTO ratio (repl.) |
|---|---|---:|---|---:|
| BB_90_8_10 | 1.870 -> 0.605 | 0.3234 (0.3250) | 1.660 -> 0.706 | 0.4255 (0.4219) |
| GB_144_12_8 | 0.662 -> 0.645 | 0.9745 (0.9705) | 1.115 -> 0.866 | 0.7761 (0.7733) |
| BB_108_8_10 | 2.287 -> 0.937 | 0.4096 (0.4092) | 2.332 -> 0.975 | 0.4180 (0.4164) |
| LP_238_44_6 | 1.201 -> 0.388 | 0.3234 (0.3233) | 1.150 -> 0.310 | 0.2697 (0.2636) |
| geomean / envelope | | 0.4520 / 0.4572 | | 0.4393 / 0.4435 |

Every gate cell is a non-overlapping improvement; replication reproduces all cells within ~1%.
Fixed GH16 judge: all medians non-worse and envelope < 1 in both modes => **numerically positive**,
no regression flag. GB144 OFF (-2.5%) is only slightly beyond this host's layout floor for that cell
(2.1%, GH-67); all other cells are far beyond it. Diagnostic Mac host, not a controlled claim.

## Known adverse case outside Tier1: TN_200_10_10 (`raw/tn200-diagnostic/`)
default / MTO: baseline 10.6 s, split 57.7 / 58.3 s. The code is asymmetric (dX = 14, dZ = 10): the split
solves the X half first and spends most time proving dX = 14, although d is set by the Z half. Same
answer d = 10, sound bounds. Follow-up (GH-71-B): order the halves / cap the second half by the first
half's value (needs an `initUB` termination audit) — a separate experiment.
