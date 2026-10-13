# GH-121 PIB — parity-row iset bound: S0 / S1 report

Branch `experiment/gh-121-pib` (base main 398054e). Counts only; no timing comparison was made here
(runs were 4-way parallel on the Mac; the coordinator times later).

## Design

* `run_css_half()` passes the half's parity rows `Hpar` (qubit vars 0..n-1 per row) to the engine
  (`Solver::setPibRows`) when any PIB flag is set.
* `Solver::pibBound(need)`: for each row, A = assigned vars, U = unassigned vars. If the parity of the
  true vars in A is odd and U is non-empty and every u in U is an active unit soft var
  (`softLits[u] == ~x_u`; rows touching a retired/partitioned soft var are skipped), then some u in U is
  true: `{~x_u : u in U}` is an iset. Candidates are taken greedily by increasing |U| (ties by row
  index) when U is disjoint from the U sets already taken. S = number taken. Only current values are
  used (decisions and propagations alike); U vars are unassigned, hence disjoint from `falseLits`.
* S1 prune (`-pib`): in `lookahead()`, at the generic iset-search point (after the engine's `lb == 1`
  and `lb > thres` exits), if S >= lb = UB - |falseLits| the generic search is skipped and
  `pibPrune(lb)` produces a soft conflict for the engine's own `analyzeSoftConflict()`
  (`UBconflictFlag = softConflictFlag = true`, as a generic lookahead success):
  conflict literals = `falseLits` (paid cost) + `involvedLits` = for each of lb chosen rows, the
  currently false literal of every assigned var of the row with level > 0 (x_a = 1 gives ~x_a, x_a = 0
  gives x_a). Among the S rows the lb rows with the fewest level>0 assigned vars are used (shorter
  reason). The engine then does its normal 1-UIP analysis, learnt-clause storage and backjump. The
  clause says "these assignments imply cost >= UB": valid while UB does not increase, exactly like
  the generic lookahead's soft learnts (they live in the same learnt lists that
  `removeLearntClauses()` clears on a UB change).
* Threshold bookkeeping: a PIB prune at the generic point performs the generic success's adaptive
  threshold update (`LOOKAHEAD++` already done, `nbLKsuccess++`, `totalPrunedLB`, sampled
  `maxSuccLB`/`coef` update, `mySucc`). **Without this (first version) the sampled lookaheads were
  mostly answered by PIB, `maxSuccLB` stayed ~0, the generic lookahead starved and conflicts rose
  2-50x (tier0/1 geomean conflict ratio 3.67, max 50.1).**
* `-pib=2` additionally tries PIB at the two shortcut exits (`lb == 1`, `lb > thres`), without any
  threshold bookkeeping there.
* `-pib-stats`: counters only, printed per probe to stderr as `c PIB <half> cap <c> ...` (plus a
  cumulative `c PIBp` line every >= 10 s CPU). Search with only `-pib-stats` is identical to main.
* `-pib-check` (runtime debug flag): re-verifies each PIB conflict (lb = UB - |falseLits|; every used
  row has odd assigned parity, non-empty U of active unit soft vars, pairwise disjoint U; all reason
  literals false) and, in `search()`, that the analysed learnt clause is falsified by the current
  assignment before backjumping. Failures are counted (`checkFails`) and printed.

## Commands

```
make clean && make CXX="c++ -Wno-reserved-user-defined-literal"
# per case C, mode M in {-no-card, -card-mto}; tier0/1 limit 120 s, tier2 600 s, GB_144_12_12 300 s
main@398054e:  bin/distqldpc -v -cpu-lim=120 M C          # reference log
branch:        bin/distqldpc -v -cpu-lim=120 -pib-stats M C   # S0 (log diffed vs main, PIB lines removed)
               bin/distqldpc -cpu-lim=120 M C                 # no flag
               bin/distqldpc -cpu-lim=L -pib -pib-stats -pib-check M C     # S1
               bin/distqldpc -cpu-lim=L -pib=2 -pib-stats -pib-check M C   # S1 variant
```
At most 4 solver processes at a time, with an RSS watchdog at 2 GB (never triggered).

## S0 search identity

For all 14 tier0+tier1 codes x {no-card, card-mto} (28 pairs) the full `-v` solver log of
`-pib-stats` (minus `c PIB` lines) is byte-identical to main 398054e's `-v` log (it contains the
per-UB conflict counts). Result lines also identical.

## Correctness (o N vs distance in the stem name)

All runs PASS; `checkFails` = 0 everywhere (every PIB conflict and every PIB learnt clause verified).

| case | mode | expected d | no flag | -pib-stats | -pib | -pib=2 | -pib checkFails | -pib=2 checkFails |
|---|---|---|---|---|---|---|---|---|
| BB_108_8_10 | card-mto | 10 | 10 | 10 | 10 | 10 | 0 | 0 |
| BB_108_8_10 | no-card | 10 | 10 | 10 | 10 | 10 | 0 | 0 |
| BB_144_12_12 | card-mto | 12 | 12 | 12 | 12 | 12 | 0 | 0 |
| BB_144_12_12 | no-card | 12 | 12 | 12 | 12 | 12 | 0 | 0 |
| BB_72_12_6 | card-mto | 6 | 6 | 6 | 6 | 6 | 0 | 0 |
| BB_72_12_6 | no-card | 6 | 6 | 6 | 6 | 6 | 0 | 0 |
| BB_90_8_10 | card-mto | 10 | 10 | 10 | 10 | 10 | 0 | 0 |
| BB_90_8_10 | no-card | 10 | 10 | 10 | 10 | 10 | 0 | 0 |
| GB_144_12_8 | card-mto | 8 | 8 | 8 | 8 | 8 | 0 | 0 |
| GB_144_12_8 | no-card | 8 | 8 | 8 | 8 | 8 | 0 | 0 |
| LP_136_32_4 | card-mto | 4 | 4 | 4 | 4 | 4 | 0 | 0 |
| LP_136_32_4 | no-card | 4 | 4 | 4 | 4 | 4 | 0 | 0 |
| LP_238_44_6 | card-mto | 6 | 6 | 6 | 6 | 6 | 0 | 0 |
| LP_238_44_6 | no-card | 6 | 6 | 6 | 6 | 6 | 0 | 0 |
| LP_340_56_8 | card-mto | 8 | 8 | 8 | 8 | 8 | 0 | 0 |
| LP_340_56_8 | no-card | 8 | 8 | 8 | 8 | 8 | 0 | 0 |
| LP_34_20_2 | card-mto | 2 | 2 | 2 | 2 | 2 | 0 | 0 |
| LP_34_20_2 | no-card | 2 | 2 | 2 | 2 | 2 | 0 | 0 |
| TN_36_8_3 | card-mto | 3 | 3 | 3 | 3 | 3 | 0 | 0 |
| TN_36_8_3 | no-card | 3 | 3 | 3 | 3 | 3 | 0 | 0 |
| TN_36_8_4 | card-mto | 4 | 4 | 4 | 4 | 4 | 0 | 0 |
| TN_36_8_4 | no-card | 4 | 4 | 4 | 4 | 4 | 0 | 0 |
| TN_54_11_4 | card-mto | 4 | 4 | 4 | 4 | 4 | 0 | 0 |
| TN_54_11_4 | no-card | 4 | 4 | 4 | 4 | 4 | 0 | 0 |
| TN_72_14_4 | card-mto | 4 | 4 | 4 | 4 | 4 | 0 | 0 |
| TN_72_14_4 | no-card | 4 | 4 | 4 | 4 | 4 | 0 | 0 |
| TN_72_8_8 | card-mto | 8 | 8 | 8 | 8 | 8 | 0 | 0 |
| TN_72_8_8 | no-card | 8 | 8 | 8 | 8 | 8 | 0 | 0 |
| GB_144_12_12 | card-mto | 12 | - | 12 | 12 | 12 | 0 | 0 |
| GB_144_12_12 | no-card | 12 | - | 12 | 12 | 12 | 0 | 0 |
| LP_442_68_10 | card-mto | 10 | - | 10 | 10 | 10 | 0 | 0 |
| LP_442_68_10 | no-card | 10 | - | 10 | 10 | 10 | 0 | 0 |
| TN_108_2_12 | card-mto | 12 | - | 12 | 12 | 12 | 0 | 0 |
| TN_108_2_12 | no-card | 12 | - | 12 | 12 | 12 | 0 | 0 |

## S0 counters (from the `-pib-stats` run = main's search)

Columns: *calls* = lookahead calls reaching the generic iset search; *generic pruned* = of those, the
generic lookahead returned false; *S>=lb*; *joint* = S>=lb and generic pruned; *coverage* =
joint / generic pruned = fraction of generic-pruning lookaheads S alone would have pruned;
*skipped* = calls leaving early (lb == 1 or lb > thres) and how many of them had S >= lb; *S time* =
CPU seconds spent computing S at the generic point (summed over probes). Variant columns: ratios of
summed engine conflicts and `LOOKAHEAD` counters vs the `-pib-stats` (= main) run; *generic-run* =
(LOOKAHEAD - PIB prunes at the generic point) / main LOOKAHEAD.

### tier0 + tier1

| case | mode | o | probes | lookahead calls (generic pt) | generic pruned | S>=lb | joint | coverage joint/genPruned | skipped calls | skipped S>=lb | S time s | pib o | pib conflicts ratio | pib LOOKAHEAD ratio | pib generic-run ratio | pib PIB prunes (early) | pib2 o | pib2 conflicts ratio | pib2 LOOKAHEAD ratio | pib2 generic-run ratio | pib2 PIB prunes (early) |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| BB_108_8_10 | card-mto | 10 | 8 | 16982 | 13110 | 6403 | 6341 | 0.484 | 17876 | 3979 | 0.01 | 10 | 0.401 (5836/14553) | 0.348 (5914/16990) | 0.204 | 2447 (0) | 10 | 0.353 (5140/14553) | 0.305 (5179/16990) | 0.181 | 2613 (501) |
| BB_108_8_10 | no-card | 10 | 8 | 13459 | 10377 | 5205 | 5152 | 0.496 | 14132 | 3588 | 0.01 | 10 | 0.377 (4356/11551) | 0.301 (4059/13467) | 0.154 | 1988 (0) | 10 | 0.675 (7795/11551) | 0.682 (9179/13467) | 0.456 | 3600 (566) |
| BB_144_12_12 | card-mto | 12 | 7 | 16132 | 12552 | 5492 | 5453 | 0.434 | 16729 | 2420 | 0.01 | 12 | 0.984 (13504/13722) | 1.027 (16571/16139) | 0.731 | 4775 (0) | 12 | 0.942 (12922/13722) | 0.983 (15871/16139) | 0.695 | 5007 (350) |
| BB_144_12_12 | no-card | 12 | 7 | 11369 | 8800 | 4156 | 4136 | 0.470 | 11996 | 3965 | 0.01 | 12 | 0.846 (8381/9903) | 0.874 (9948/11376) | 0.591 | 3223 (0) | 12 | 1.398 (13843/9903) | 1.482 (16857/11376) | 1.013 | 5907 (571) |
| BB_72_12_6 | card-mto | 6 | 6 | 119 | 118 | 115 | 115 | 0.975 | 1183 | 921 | 0.00 | 6 | 0.918 (590/643) | 0.576 (72/125) | 0.080 | 62 (0) | 6 | 0.224 (144/643) | 0.056 (7/125) | 0.056 | 87 (87) |
| BB_72_12_6 | no-card | 6 | 6 | 220 | 220 | 219 | 219 | 0.995 | 1451 | 1216 | 0.00 | 6 | 0.812 (610/751) | 0.487 (110/226) | 0.071 | 94 (0) | 6 | 0.164 (123/751) | 0.035 (8/226) | 0.031 | 95 (94) |
| BB_90_8_10 | card-mto | 10 | 7 | 3579 | 2817 | 1602 | 1593 | 0.565 | 4927 | 2130 | 0.00 | 10 | 1.151 (4237/3681) | 1.185 (4251/3586) | 0.673 | 1836 (0) | 10 | 0.846 (3113/3681) | 0.938 (3364/3586) | 0.617 | 1509 (356) |
| BB_90_8_10 | no-card | 10 | 7 | 4746 | 3821 | 2300 | 2277 | 0.596 | 6060 | 2653 | 0.00 | 10 | 0.893 (4174/4673) | 0.854 (4058/4753) | 0.454 | 1900 (0) | 10 | 0.647 (3022/4673) | 0.658 (3129/4753) | 0.393 | 1654 (392) |
| GB_144_12_8 | card-mto | 8 | 6 | 1701 | 1597 | 1312 | 1306 | 0.818 | 4283 | 2735 | 0.00 | 8 | 0.964 (2342/2430) | 1.041 (1777/1707) | 0.422 | 1057 (0) | 8 | 0.457 (1111/2430) | 0.421 (719/1707) | 0.223 | 496 (157) |
| GB_144_12_8 | no-card | 8 | 6 | 2352 | 2145 | 1577 | 1568 | 0.731 | 4497 | 2434 | 0.00 | 8 | 0.660 (2023/3063) | 0.544 (1282/2358) | 0.134 | 965 (0) | 8 | 0.372 (1139/3063) | 0.369 (870/2358) | 0.157 | 792 (293) |
| LP_136_32_4 | card-mto | 4 | 8 | 188 | 172 | 119 | 118 | 0.686 | 5679 | 1629 | 0.00 | 4 | 1.015 (2381/2346) | 1.383 (271/196) | 0.719 | 130 (0) | 4 | 1.126 (2642/2346) | 1.617 (317/196) | 0.628 | 561 (367) |
| LP_136_32_4 | no-card | 4 | 8 | 1128 | 1103 | 788 | 787 | 0.714 | 6929 | 3877 | 0.00 | 4 | 0.796 (2298/2887) | 0.497 (565/1136) | 0.142 | 404 (0) | 4 | 0.421 (1215/2887) | 0.251 (285/1136) | 0.046 | 586 (353) |
| LP_238_44_6 | card-mto | 6 | 11 | 7174 | 6015 | 3329 | 3305 | 0.549 | 22490 | 3020 | 0.01 | 6 | 0.907 (8736/9630) | 0.747 (5365/7185) | 0.387 | 2583 (0) | 6 | 0.945 (9098/9630) | 1.056 (7587/7185) | 0.603 | 3914 (663) |
| LP_238_44_6 | no-card | 6 | 11 | 9128 | 8067 | 5319 | 5286 | 0.655 | 22571 | 8879 | 0.01 | 6 | 0.815 (8694/10663) | 0.739 (6757/9139) | 0.263 | 4354 (0) | 6 | 0.589 (6279/10663) | 0.528 (4823/9139) | 0.214 | 4031 (1162) |
| LP_340_56_8 | card-mto | 8 | 10 | 23051 | 19445 | 11973 | 11874 | 0.611 | 47475 | 7909 | 0.03 | 8 | 0.779 (18246/23422) | 0.787 (18141/23061) | 0.460 | 7536 (0) | 8 | 0.687 (16081/23422) | 0.661 (15237/23061) | 0.374 | 7856 (1240) |
| LP_340_56_8 | no-card | 8 | 10 | 21050 | 17581 | 10531 | 10408 | 0.592 | 41965 | 8559 | 0.03 | 8 | 0.743 (15020/20219) | 0.735 (15480/21060) | 0.395 | 7151 (0) | 8 | 0.662 (13377/20219) | 0.698 (14696/21060) | 0.415 | 6898 (937) |
| LP_34_20_2 | card-mto | 2 | 4 | 2 | 0 | 0 | 0 | nan | 163 | 2 | 0.00 | 2 | 1.000 (91/91) | 1.000 (6/6) | 1.000 | 0 (0) | 2 | 1.033 (94/91) | 1.000 (6/6) | 1.000 | 1 (1) |
| LP_34_20_2 | no-card | 2 | 4 | 2 | 0 | 0 | 0 | nan | 303 | 0 | 0.00 | 2 | 1.000 (85/85) | 1.000 (6/6) | 1.000 | 0 (0) | 2 | 1.000 (85/85) | 1.000 (6/6) | 1.000 | 0 (0) |
| TN_36_8_3 | card-mto | 3 | 6 | 2 | 0 | 0 | 0 | nan | 506 | 176 | 0.00 | 3 | 1.000 (273/273) | 1.000 (8/8) | 1.000 | 0 (0) | 3 | 1.121 (306/273) | 1.000 (8/8) | 1.000 | 27 (27) |
| TN_36_8_3 | no-card | 3 | 7 | 2 | 0 | 0 | 0 | nan | 486 | 165 | 0.00 | 3 | 1.000 (311/311) | 1.000 (9/9) | 1.000 | 0 (0) | 3 | 0.547 (170/311) | 1.000 (9/9) | 1.000 | 38 (38) |
| TN_36_8_4 | card-mto | 4 | 5 | 3 | 1 | 1 | 1 | 1.000 | 1703 | 456 | 0.00 | 4 | 0.990 (1130/1141) | 1.750 (14/8) | 1.000 | 6 (0) | 4 | 0.680 (776/1141) | 3.125 (25/8) | 2.000 | 111 (102) |
| TN_36_8_4 | no-card | 4 | 5 | 73 | 71 | 67 | 66 | 0.930 | 1012 | 372 | 0.00 | 4 | 0.981 (704/718) | 0.795 (62/78) | 0.154 | 50 (0) | 4 | 0.671 (482/718) | 0.705 (55/78) | 0.462 | 122 (103) |
| TN_54_11_4 | card-mto | 4 | 8 | 87 | 83 | 83 | 83 | 1.000 | 2325 | 570 | 0.00 | 4 | 0.987 (1284/1301) | 1.116 (106/95) | 0.737 | 36 (0) | 4 | 0.809 (1053/1301) | 0.379 (36/95) | 0.358 | 126 (124) |
| TN_54_11_4 | no-card | 4 | 8 | 151 | 141 | 127 | 127 | 0.901 | 1904 | 934 | 0.00 | 4 | 0.912 (1086/1191) | 0.572 (91/159) | 0.346 | 36 (0) | 4 | 0.517 (616/1191) | 0.208 (33/159) | 0.132 | 293 (281) |
| TN_72_14_4 | card-mto | 4 | 8 | 227 | 148 | 45 | 45 | 0.304 | 4022 | 1024 | 0.00 | 4 | 1.157 (2125/1836) | 0.604 (142/235) | 0.336 | 63 (0) | 4 | 0.772 (1418/1836) | 0.387 (91/235) | 0.251 | 177 (145) |
| TN_72_14_4 | no-card | 4 | 8 | 182 | 165 | 98 | 98 | 0.594 | 2547 | 1059 | 0.00 | 4 | 0.976 (1326/1359) | 0.916 (174/190) | 0.400 | 98 (0) | 4 | 0.564 (767/1359) | 0.474 (90/190) | 0.321 | 312 (283) |
| TN_72_8_8 | card-mto | 8 | 10 | 17004 | 12620 | 6054 | 5970 | 0.473 | 19400 | 1973 | 0.01 | 8 | 0.923 (15459/16749) | 0.878 (14946/17014) | 0.525 | 6018 (0) | 8 | 0.770 (12897/16749) | 0.685 (11655/17014) | 0.397 | 5952 (1050) |
| TN_72_8_8 | no-card | 8 | 10 | 11429 | 8547 | 4691 | 4643 | 0.543 | 13072 | 4083 | 0.01 | 8 | 0.920 (10350/11254) | 0.940 (10750/11439) | 0.545 | 4512 (0) | 8 | 0.959 (10796/11254) | 1.081 (12367/11439) | 0.725 | 4966 (888) |

### tier2 (LP_442_68_10, TN_108_2_12) and tier3 GB_144_12_12

| case | mode | o | probes | lookahead calls (generic pt) | generic pruned | S>=lb | joint | coverage joint/genPruned | skipped calls | skipped S>=lb | S time s | pib o | pib conflicts ratio | pib LOOKAHEAD ratio | pib generic-run ratio | pib PIB prunes (early) | pib2 o | pib2 conflicts ratio | pib2 LOOKAHEAD ratio | pib2 generic-run ratio | pib2 PIB prunes (early) |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| GB_144_12_12 | card-mto | 12 | 7 | 2285201 | 1653322 | 821522 | 796694 | 0.482 | 1643341 | 115084 | 2.73 | 12 | 0.501 (837106/1669862) | 0.500 (1143231/2285208) | 0.332 | 384620 (0) | 12 | 0.438 (732202/1669862) | 0.438 (1000893/2285208) | 0.302 | 321998 (11758) |
| GB_144_12_12 | no-card | 12 | 9 | 1648686 | 1196438 | 597524 | 580082 | 0.485 | 1178592 | 74256 | 1.91 | 12 | 0.456 (552498/1210887) | 0.455 (749851/1648695) | 0.303 | 249983 (0) | 12 | 1.028 (1244501/1210887) | 1.031 (1700618/1648695) | 0.695 | 574434 (19851) |
| LP_442_68_10 | card-mto | 10 | 14 | 239049 | 193459 | 103836 | 101711 | 0.526 | 327471 | 26145 | 0.45 | 10 | 0.774 (159127/205669) | 0.810 (193656/239063) | 0.479 | 79205 (0) | 10 | 0.731 (150309/205669) | 0.754 (180161/239063) | 0.465 | 70939 (2037) |
| LP_442_68_10 | no-card | 10 | 12 | 349217 | 286118 | 162089 | 158850 | 0.555 | 428386 | 36472 | 0.70 | 10 | 0.475 (138547/291609) | 0.487 (170096/349229) | 0.289 | 69259 (0) | 10 | 0.487 (141945/291609) | 0.502 (175360/349229) | 0.310 | 70033 (2974) |
| TN_108_2_12 | card-mto | 12 | 12 | 341398 | 235742 | 93282 | 91732 | 0.389 | 235557 | 16005 | 0.39 | 12 | 1.095 (271760/248276) | 1.105 (377212/341410) | 0.782 | 110247 (0) | 12 | 1.039 (258031/248276) | 1.041 (355389/341410) | 0.764 | 100876 (6394) |
| TN_108_2_12 | no-card | 12 | 12 | 283738 | 196773 | 76205 | 75096 | 0.382 | 193075 | 14456 | 0.32 | 12 | 1.096 (226829/207005) | 1.110 (314878/283750) | 0.789 | 91077 (0) | 12 | 1.093 (226303/207005) | 1.103 (313024/283750) | 0.808 | 89694 (5840) |

### Requested cases: coverage (joint / generic pruned)

| case | no-card | card-mto |
|---|---|---|
| BB_144_12_12 (tier1) | 0.470 (4136/8800) | 0.434 (5453/12552) |
| LP_340_56_8 (tier1) | 0.592 (10408/17581) | 0.611 (11874/19445) |
| TN_108_2_12 (tier2) | 0.382 (75096/196773) | 0.389 (91732/235742) |
| GB_144_12_12 (tier3) | 0.485 (580082/1196438) | 0.482 (796694/1653322) |

S >= lb almost only where the generic lookahead also prunes (S>=lb but generic fails: 0-3 % of the
S>=lb calls). S costs ~1-3 s CPU on GB_144_12_12 for 1.6-2.3 M evaluations (~1.2 us each, full
row scan, non-incremental).

## S1 summary (conflict / LOOKAHEAD counts vs main)

| set | variant | geomean conflicts ratio | geomean LOOKAHEAD ratio | cases with more conflicts |
|---|---|---|---|---|
| tier0+1 (28) | -pib | 0.866 | 0.790 | 3 |
| tier0+1 (28) | -pib=2 | 0.647 | 0.569 | 4 |
| tier2 + GB_144_12_12 (6) | -pib | 0.682 | 0.692 | 2 (TN_108_2_12 both modes, 1.095/1.096) |
| tier2 + GB_144_12_12 (6) | -pib=2 | 0.753 | 0.762 | 3 |

Per case (conflicts ratio, -pib / -pib=2): BB_144_12_12 no-card 0.846 / 1.398, card-mto 0.984 / 0.942;
LP_340_56_8 no-card 0.743 / 0.662, card-mto 0.779 / 0.687; TN_108_2_12 no-card 1.096 / 1.093,
card-mto 1.095 / 1.039; GB_144_12_12 no-card 0.456 / 1.028, card-mto 0.501 / 0.438;
LP_442_68_10 no-card 0.475 / 0.487, card-mto 0.774 / 0.731.

Each PIB prune replaces one generic iset search (82-85 % of runtime is `propagateForLK`): with `-pib`
the generic searches run drop to 0.15-0.8 of main's count while total conflicts mostly fall too.
Whether this is a wall-clock gain is for the coordinator's timing runs.

## Soundness notes / doubts

* The bound only uses rows whose unassigned vars are all active unit soft vars; partitioned soft vars
  (GH58 `partition()`, `softLits = lit_Undef`) make the row ineligible, so no cost is double counted.
  `falseLits` holds every currently false soft literal (main `uncheckedEnqueue`), and U vars are
  unassigned, so the isets are disjoint from paid cost and from each other.
* PIB learnts are UB-relative like the generic lookahead's soft learnts and go through the same
  analysis and learnt lists, so they are dropped by the same mechanism when UB changes.
* `-pib=2` prunes at `lb == 1` instead of the engine's `moreHarden()` there; this is a valid soft
  conflict but skips that hardening.
* No soundness issue observed: 0 check failures in 2.32 M verified PIB conflicts, all distances right.
