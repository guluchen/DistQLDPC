# GH-106 diagnosis: why the persistent half solver (GH-76 inside GH-89) regresses on large codes

Issue #106 (hub #15). Base: GH-89 source `09d8bc2` (branch `experiment/gh-106-incremental-regression`).
Comparison: main `7eadd54` (CSS split + per-half symmetry breaking, one fresh `SimpSolver` per probe).
All numbers are deterministic search counters, never wall time. Every solver process ran alone (one at a
time, one core), under the 2 GB cap (`memlimit.py`), with a fixed `-cpu-lim` (300 s large cells, 120 s
Tier1 cells); every run completed with the named distance except the `m1` runs of F5.
Deviation: for about 45 s two diagnostic solver processes overlapped (an ablation batch was started before
the previous one had finished; the older batch was killed; its remaining runs (`f1m8` on TN, the `m68` config) were
not run there; `m68` was rerun later as `abl5-m68`). Counters are unaffected by CPU contention.

## Method

* Counter builds (scratch only, never part of a candidate binary): `diag/counter_build_gh89.diff` (on
  `09d8bc2`) and `diag/counter_build_main.diff` (on `7eadd54`) add `Solver::gh106Dump()` and call it before
  and after every half probe in `run_css_half`. It prints conflicts, decisions, propagations, restarts
  (`starts`), lookahead calls (`LOOKAHEAD`) and their successes and propagations, learnt-DB sizes
  (core/tier2/local), cardinality/hardening/iset clauses, variables, level-0 trail, reduce/simplify
  schedules (`coreLimit`, `next_L_reduce`, `curSimplify`, ...), VSIDS/LRB state (`var_inc`, `var_decay`,
  `timer`, `step_size`, `lbd_queue`, `global_lbd_sum`), lookahead statistics (`lk_thres`, `lk_coef`,
  `lk_nbSample`, `lk_sumLB`, `lk_maxSuccLB`, `lk_myLH`, `lk_mySucc`), activity summaries (VSIDS, CHB,
  `activityLB`) and the number of `polarity` bits set. Per probe: delta = post - pre of that solver.
* Identity check: with the dump lines removed, the counter builds' `-v` output is byte-identical to
  `frozen89/cand` and `frozen-main7e` (LP_340_56_8, LP_442_68_10 no-card), so the counters describe the
  real searches.
* The GH-89 counter build also has environment-controlled ablations (diagnostic only):
  `GH106_RESET` = bit mask of state reset at the start of a probe (2 lookahead statistics + `activityLB`;
  4 decision heuristics = VSIDS/CHB activities, saved phases restored to their post-`incPrepare` values,
  `var_inc`/`var_decay`/`timer`/`step_size`; 8 drop local+tier2 learnts; 16 also core learnts;
  32 reduce/simplify schedules; 1 re-run the VSIDS initial phase; 64 = apply on every probe, otherwise
  only after the half's first solution) and `GH106_FRESHPRE` (1: fresh solver for every probe until the
  half's solver has found a solution; 2: additionally a fresh solver for every feasibility probe).
* Raw: `raw/per_probe.csv` (1454 probe rows: config, cell, probe, half, cap, outcome, value, counter deltas,
  pre/post state), `raw/diag-runs.tar.gz` (all stdout, runner logs). Tools: `diag/` (runner, parsers).

## 1. Per-probe behaviour, regressing cells

TN_144_2_13 no-card, main (fresh solver per probe):
| # | half | cap | lb | 1st | out | d_confl | d_dec | d_prop(M) | d_lk | d_lkprop(M) | d_starts | pre core/t2/loc | post core/t2/loc | pre_trail | lk_maxS | polT | step |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 0 | X | 1 | 1 | 1 | FALSE | 9 | 27 | 0.0 | 2 | 0.0 | 1 | 0/0/0 | 0/0/0 | 74 | 0->0 | 791->764 | 0.4->0.4 |
| 1 | Z | 1 | 1 | 1 | FALSE | 4 | 3 | 0.0 | 2 | 0.0 | 1 | 0/0/0 | 0/0/0 | 74 | 0->0 | 817->774 | 0.4->0.4 |
| 2 | X | 2 | 2 | 1 | FALSE | 267 | 705 | 0.0 | 15 | 0.0 | 2 | 0/0/0 | 0/0/0 | 74 | 0->2 | 791->732 | 0.4->0.4 |
| 3 | Z | 2 | 2 | 1 | FALSE | 198 | 492 | 0.0 | 3 | 0.0 | 1 | 0/0/0 | 0/0/0 | 74 | 0->2 | 817->757 | 0.4->0.4 |
| 4 | X | 4 | 3 | 1 | FALSE | 662 | 1271 | 0.0 | 437 | 0.1 | 7 | 0/0/0 | 0/0/0 | 74 | 0->5 | 791->702 | 0.4->0.4 |
| 5 | Z | 4 | 3 | 1 | FALSE | 916 | 1544 | 0.0 | 615 | 0.1 | 7 | 0/0/0 | 0/0/0 | 74 | 0->4 | 817->775 | 0.4->0.4 |
| 6 | X | 8 | 5 | 1 | FALSE | 14077 | 18633 | 0.4 | 17193 | 6.4 | 86 | 0/0/0 | 0/0/0 | 74 | 0->9 | 791->715 | 0.4->0.3959 |
| 7 | Z | 8 | 5 | 1 | FALSE | 13354 | 17593 | 0.4 | 16501 | 6.3 | 85 | 0/0/0 | 0/0/0 | 74 | 0->9 | 817->741 | 0.4->0.3966 |
| 8 | X | 16 | 9 | 1 | TRUE | 16 | 19 | 0.0 | 1 | 0.0 | 1 | 0/0/0 | 16/0/0 | 74 | 0->0 | 791->726 | 0.4->0.4 |
| 9 | Z | 16 | 9 | 1 | TRUE | 19 | 28 | 0.0 | 1 | 0.0 | 1 | 0/0/0 | 19/0/0 | 74 | 0->0 | 817->780 | 0.4->0.4 |
| 10 | X | 15 | 9 | 1 | TRUE | 458610 | 515813 | 10.8 | 638695 | 242.4 | 1079 | 0/0/0 | 16307/1645/23237 | 74 | 0->16 | 791->715 | 0.4->0.06 |
| 11 | Z | 12 | 9 | 1 | FALSE | 253542 | 285224 | 6.0 | 348937 | 130.8 | 613 | 0/0/0 | 0/0/0 | 74 | 0->13 | 817->719 | 0.4->0.1565 |
| 12 | X | 13 | 9 | 0 | FALSE | 409124 | 459172 | 9.9 | 568702 | 215.1 | 1016 | 0/0/0 | 5451/730/190 | 74 | 0->14 | 791->684 | 0.4->0.06 |
| total | | | | | | 1150798 | 1300524 | 27.5 | 1591104 | 601.3 | 2900 | | | | | | |

TN_144_2_13 no-card, GH-89 (persistent):
| # | half | cap | lb | 1st | out | d_confl | d_dec | d_prop(M) | d_lk | d_lkprop(M) | d_starts | pre core/t2/loc | post core/t2/loc | pre_trail | lk_maxS | polT | step |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 0 | X | 1 | 1 | 1 | NONE | 9 | 27 | 0.0 | 1 | 0.0 | 1 | 0/0/0 | 0/0/0 | 78 | 0->0 | 791->764 | 0.4->0.4 |
| 1 | Z | 1 | 1 | 1 | NONE | 4 | 3 | 0.0 | 1 | 0.0 | 1 | 0/0/0 | 0/0/0 | 78 | 0->0 | 817->774 | 0.4->0.4 |
| 2 | X | 2 | 2 | 1 | NONE | 248 | 718 | 0.0 | 3 | 0.0 | 4 | 0/0/0 | 0/0/0 | 78 | 0->2 | 764->736 | 0.4->0.4 |
| 3 | Z | 2 | 2 | 1 | NONE | 186 | 516 | 0.0 | 0 | 0.0 | 1 | 0/0/0 | 0/0/0 | 78 | 0->0 | 774->774 | 0.4->0.4 |
| 4 | X | 4 | 3 | 1 | NONE | 1609 | 2589 | 0.0 | 1420 | 0.2 | 15 | 0/0/0 | 0/0/0 | 78 | 2->3 | 736->688 | 0.4->0.4 |
| 5 | Z | 4 | 3 | 1 | NONE | 484 | 786 | 0.0 | 419 | 0.1 | 5 | 0/0/0 | 0/0/0 | 78 | 0->3 | 774->747 | 0.4->0.4 |
| 6 | X | 8 | 5 | 1 | NONE | 15721 | 21405 | 0.4 | 19650 | 7.3 | 131 | 0/0/0 | 0/0/0 | 78 | 3->9 | 688->702 | 0.4->0.3943 |
| 7 | Z | 8 | 5 | 1 | NONE | 11752 | 15804 | 0.3 | 14579 | 5.6 | 94 | 0/0/0 | 0/0/0 | 78 | 3->10 | 747->725 | 0.4->0.3983 |
| 8 | X | 16 | 9 | 1 | FOUND | 365692 | 413330 | 8.9 | 514244 | 195.9 | 963 | 0/0/0 | 8402/2366/20189 | 78 | 9->17 | 702->687 | 0.3943->0.06 |
| 9 | Z | 16 | 9 | 1 | FOUND | 269440 | 306237 | 6.3 | 376325 | 136.5 | 725 | 0/0/0 | 6985/5039/28697 | 78 | 10->18 | 725->686 | 0.3983->0.1388 |
| 10 | X | 15 | 9 | 1 | FOUND | 1150618 | 1332453 | 25.6 | 1616663 | 615.7 | 3762 | 8402/2366/20189 | 25655/1791/15859 | 78 | 17->15 | 687->699 | 0.06->0.06 |
| 11 | Z | 14 | 9 | 1 | FOUND | 166384 | 184686 | 3.9 | 235565 | 85.7 | 415 | 6985/5039/28697 | 16166/4938/15098 | 78 | 18->16 | 686->690 | 0.1388->0.06 |
| 12 | Z | 14 | 9 | 0 | OPT | 391788 | 428323 | 9.2 | 555290 | 201.5 | 735 | 16166/4938/15098 | 10173/2065/1417 | 78 | 16->16 | 690->718 | 0.06->0.06 |
| 13 | X | 13 | 9 | 0 | OPT | 411179 | 459658 | 9.2 | 573493 | 221.1 | 822 | 25655/1791/15859 | 19473/2645/1710 | 78 | 15->14 | 699->641 | 0.06->0.06 |
| total | | | | | | 2785114 | 3166535 | 64.0 | 3907653 | 1469.5 | 7674 | | | | | | |

LP_442_68_10 card-mto, main:
| # | half | cap | lb | 1st | out | d_confl | d_dec | d_prop(M) | d_lk | d_lkprop(M) | d_starts | pre core/t2/loc | post core/t2/loc | pre_trail | lk_maxS | polT | step |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 0 | X | 1 | 1 | 1 | FALSE | 5 | 5 | 0.0 | 2 | 0.0 | 1 | 0/0/0 | 0/0/0 | 263 | 0->0 | 3558->3790 | 0.4->0.4 |
| 1 | Z | 1 | 1 | 1 | FALSE | 3 | 3 | 0.0 | 2 | 0.0 | 1 | 0/0/0 | 0/0/0 | 263 | 0->0 | 3558->3782 | 0.4->0.4 |
| 2 | X | 2 | 2 | 1 | FALSE | 341 | 1650 | 0.2 | 1 | 0.0 | 4 | 0/0/0 | 0/0/0 | 263 | 0->0 | 3558->4785 | 0.4->0.4 |
| 3 | Z | 2 | 2 | 1 | FALSE | 265 | 950 | 0.1 | 1 | 0.0 | 3 | 0/0/0 | 0/0/0 | 263 | 0->0 | 3558->4846 | 0.4->0.4 |
| 4 | X | 4 | 3 | 1 | FALSE | 878 | 3077 | 0.1 | 566 | 0.5 | 9 | 0/0/0 | 0/0/0 | 263 | 0->5 | 3558->5231 | 0.4->0.4 |
| 5 | Z | 4 | 3 | 1 | FALSE | 1021 | 2655 | 0.1 | 746 | 0.7 | 13 | 0/0/0 | 0/0/0 | 263 | 0->5 | 3558->5219 | 0.4->0.4 |
| 6 | X | 8 | 5 | 1 | FALSE | 7210 | 15410 | 0.5 | 8245 | 11.8 | 60 | 0/0/0 | 0/0/0 | 263 | 0->9 | 3558->5024 | 0.4->0.4 |
| 7 | Z | 8 | 5 | 1 | FALSE | 14991 | 31170 | 0.9 | 17175 | 24.6 | 131 | 0/0/0 | 0/0/0 | 263 | 0->10 | 3558->5271 | 0.4->0.395 |
| 8 | X | 16 | 9 | 1 | TRUE | 34090 | 49323 | 1.8 | 37085 | 39.5 | 85 | 0/0/0 | 2319/1893/15053 | 263 | 0->17 | 3558->5213 | 0.4->0.3759 |
| 9 | Z | 16 | 9 | 1 | TRUE | 27311 | 44709 | 1.3 | 32577 | 47.8 | 149 | 0/0/0 | 1549/38/18878 | 263 | 0->17 | 3558->5563 | 0.4->0.3827 |
| 10 | X | 15 | 9 | 1 | TRUE | 49316 | 77638 | 2.2 | 59584 | 81.8 | 209 | 0/0/0 | 1919/1419/17148 | 263 | 0->16 | 3558->5267 | 0.4->0.3607 |
| 11 | Z | 13 | 9 | 1 | TRUE | 2544 | 5930 | 0.2 | 2617 | 3.9 | 24 | 0/0/0 | 1516/1227/2255 | 263 | 0->13 | 3558->5249 | 0.4->0.4 |
| 12 | Z | 12 | 9 | 0 | FALSE | 46051 | 79184 | 2.3 | 54999 | 78.3 | 208 | 0/0/0 | 1684/84/1099 | 263 | 0->13 | 3558->7188 | 0.4->0.364 |
| 13 | X | 10 | 9 | 0 | FALSE | 21643 | 40456 | 1.2 | 25463 | 34.5 | 136 | 0/0/0 | 4641/1222/11227 | 263 | 0->12 | 3558->6980 | 0.4->0.3876 |
| total | | | | | | 205669 | 352160 | 10.8 | 239063 | 323.5 | 1033 | | | | | | |

LP_442_68_10 card-mto, GH-89:
| # | half | cap | lb | 1st | out | d_confl | d_dec | d_prop(M) | d_lk | d_lkprop(M) | d_starts | pre core/t2/loc | post core/t2/loc | pre_trail | lk_maxS | polT | step |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 0 | X | 1 | 1 | 1 | NONE | 5 | 5 | 0.0 | 1 | 0.0 | 1 | 0/0/0 | 0/0/0 | 265 | 0->0 | 3558->3790 | 0.4->0.4 |
| 1 | Z | 1 | 1 | 1 | NONE | 3 | 3 | 0.0 | 1 | 0.0 | 1 | 0/0/0 | 0/0/0 | 263 | 0->0 | 3558->3782 | 0.4->0.4 |
| 2 | X | 2 | 2 | 1 | NONE | 233 | 1334 | 0.1 | 13 | 0.0 | 2 | 0/0/0 | 0/0/0 | 265 | 0->3 | 3790->4836 | 0.4->0.4 |
| 3 | Z | 2 | 2 | 1 | NONE | 316 | 1996 | 0.2 | 1 | 0.0 | 4 | 0/0/0 | 0/0/0 | 263 | 0->0 | 3782->4646 | 0.4->0.4 |
| 4 | X | 4 | 3 | 1 | NONE | 729 | 2059 | 0.1 | 756 | 1.0 | 11 | 0/0/0 | 0/0/0 | 265 | 3->5 | 4836->4790 | 0.4->0.4 |
| 5 | Z | 4 | 3 | 1 | NONE | 1210 | 3949 | 0.1 | 1147 | 1.0 | 19 | 0/0/0 | 0/0/0 | 263 | 0->5 | 4646->4811 | 0.4->0.4 |
| 6 | X | 8 | 5 | 1 | NONE | 9645 | 19500 | 0.5 | 11296 | 16.0 | 80 | 0/0/0 | 0/0/0 | 265 | 5->9 | 4790->4759 | 0.4->0.4 |
| 7 | Z | 8 | 5 | 1 | NONE | 15129 | 29526 | 0.8 | 17813 | 26.2 | 114 | 0/0/0 | 0/0/0 | 263 | 5->9 | 4811->5392 | 0.4->0.3949 |
| 8 | X | 16 | 9 | 1 | FOUND | 16315 | 29605 | 0.8 | 19429 | 29.1 | 117 | 0/0/0 | 1600/1532/8362 | 265 | 9->18 | 4759->5264 | 0.4->0.3937 |
| 9 | Z | 16 | 9 | 1 | FOUND | 28006 | 44760 | 1.2 | 33768 | 48.7 | 150 | 0/0/0 | 972/8/20027 | 263 | 9->19 | 5392->5145 | 0.3949->0.3769 |
| 10 | X | 15 | 9 | 1 | FOUND | 123174 | 176770 | 5.7 | 152944 | 216.8 | 313 | 1600/1532/8362 | 15531/3292/18639 | 265 | 18->18 | 5264->7629 | 0.3937->0.2705 |
| 11 | Z | 13 | 9 | 1 | FOUND | 82955 | 117629 | 3.8 | 101283 | 142.1 | 192 | 972/8/20027 | 1179/359/8980 | 263 | 19->16 | 5145->7383 | 0.3769->0.2939 |
| 12 | Z | 12 | 9 | 0 | OPT | 23225 | 40599 | 1.1 | 28223 | 39.5 | 79 | 1179/359/8980 | 636/81/1662 | 272 | 16->13 | 7383->9508 | 0.2939->0.2707 |
| 13 | X | 10 | 9 | 0 | OPT | 12014 | 22241 | 0.6 | 14692 | 19.9 | 38 | 15531/3292/18639 | 3046/780/1474 | 265 | 18->14 | 7629->9358 | 0.2705->0.2585 |
| total | | | | | | 312959 | 489976 | 14.9 | 381367 | 540.4 | 1121 | | | | | | |

(`out` TRUE/FALSE = main's `solveLimited` result, FOUND/NONE/OPT = `incProbe`; `pre/post core/t2/loc` = learnt
DB at probe start/end; `lk_maxS` = `lk_maxSuccLB`, the lookahead threshold statistic; `polT` = polarity bits
set (fresh solver: all variables); `step` = LRB step size. Values found: see `raw/per_probe.csv`.)

## 2. Per-probe behaviour, winning cells

GB_144_12_12 card-mto, main:
| # | half | cap | lb | 1st | out | d_confl | d_dec | d_prop(M) | d_lk | d_lkprop(M) | d_starts | pre core/t2/loc | post core/t2/loc | pre_trail | lk_maxS | polT | step |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 0 | X | 1 | 1 | 1 | FALSE | 0 | 0 | 0.0 | 1 | 0.0 | 1 | 0/0/0 | 0/0/0 | 78 | 0->0 | 1005->1005 | 0.4->0.4 |
| 1 | Z | 1 | 1 | 1 | FALSE | 0 | 0 | 0.0 | 1 | 0.0 | 1 | 0/0/0 | 0/0/0 | 78 | 0->0 | 1016->1016 | 0.4->0.4 |
| 2 | X | 2 | 2 | 1 | FALSE | 7 | 18 | 0.0 | 2 | 0.0 | 1 | 0/0/0 | 0/0/0 | 78 | 0->0 | 1005->980 | 0.4->0.4 |
| 3 | Z | 2 | 2 | 1 | FALSE | 4 | 5 | 0.0 | 2 | 0.0 | 1 | 0/0/0 | 0/0/0 | 78 | 0->0 | 1016->1080 | 0.4->0.4 |
| 4 | X | 4 | 3 | 1 | FALSE | 349 | 701 | 0.1 | 10 | 0.0 | 1 | 0/0/0 | 0/0/0 | 78 | 0->3 | 1005->1243 | 0.4->0.4 |
| 5 | Z | 4 | 3 | 1 | FALSE | 407 | 857 | 0.1 | 9 | 0.0 | 4 | 0/0/0 | 0/0/0 | 78 | 0->3 | 1016->1314 | 0.4->0.4 |
| 6 | X | 8 | 5 | 1 | FALSE | 3843 | 5823 | 0.1 | 3957 | 1.2 | 36 | 0/0/0 | 0/0/0 | 78 | 0->8 | 1005->1401 | 0.4->0.4 |
| 7 | Z | 8 | 5 | 1 | FALSE | 3229 | 5123 | 0.1 | 3406 | 1.1 | 32 | 0/0/0 | 0/0/0 | 78 | 0->8 | 1016->1397 | 0.4->0.4 |
| 8 | X | 16 | 9 | 1 | TRUE | 70725 | 84686 | 1.6 | 94841 | 33.2 | 263 | 0/0/0 | 1842/1718/24017 | 78 | 0->16 | 1005->1449 | 0.4->0.3393 |
| 9 | Z | 16 | 9 | 1 | TRUE | 302781 | 345513 | 6.7 | 415640 | 145.6 | 774 | 0/0/0 | 11224/6793/16930 | 78 | 0->16 | 1016->1457 | 0.4->0.1072 |
| 10 | X | 15 | 9 | 0 | FALSE | 1292157 | 1499067 | 27.3 | 1770757 | 613.3 | 3774 | 0/0/0 | 28624/6012/14433 | 78 | 0->15 | 1005->2655 | 0.4->0.06 |
| 11 | Z | 12 | 9 | 0 | FALSE | 104163 | 122576 | 2.3 | 138537 | 48.2 | 324 | 0/0/0 | 1471/4/48 | 78 | 0->13 | 1016->1449 | 0.4->0.3058 |
| total | | | | | | 1777665 | 2064369 | 38.3 | 2427163 | 842.6 | 5212 | | | | | | |

GB_144_12_12 card-mto, GH-89:
| # | half | cap | lb | 1st | out | d_confl | d_dec | d_prop(M) | d_lk | d_lkprop(M) | d_starts | pre core/t2/loc | post core/t2/loc | pre_trail | lk_maxS | polT | step |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 0 | X | 1 | 1 | 1 | NONE | 0 | 0 | 0.0 | 0 | 0.0 | 1 | 0/0/0 | 0/0/0 | 78 | 0->0 | 1005->1005 | 0.4->0.4 |
| 1 | Z | 1 | 1 | 1 | NONE | 0 | 0 | 0.0 | 0 | 0.0 | 1 | 0/0/0 | 0/0/0 | 78 | 0->0 | 1016->1016 | 0.4->0.4 |
| 2 | X | 2 | 2 | 1 | NONE | 7 | 18 | 0.0 | 1 | 0.0 | 1 | 0/0/0 | 0/0/0 | 78 | 0->0 | 1005->980 | 0.4->0.4 |
| 3 | Z | 2 | 2 | 1 | NONE | 4 | 5 | 0.0 | 1 | 0.0 | 1 | 0/0/0 | 0/0/0 | 78 | 0->0 | 1016->1080 | 0.4->0.4 |
| 4 | X | 4 | 3 | 1 | NONE | 315 | 960 | 0.0 | 97 | 0.0 | 4 | 0/0/0 | 0/0/0 | 78 | 0->3 | 980->1399 | 0.4->0.4 |
| 5 | Z | 4 | 3 | 1 | NONE | 394 | 1276 | 0.0 | 171 | 0.0 | 5 | 0/0/0 | 0/0/0 | 78 | 0->3 | 1080->1381 | 0.4->0.4 |
| 6 | X | 8 | 5 | 1 | NONE | 2112 | 3359 | 0.0 | 2387 | 0.7 | 26 | 0/0/0 | 0/0/0 | 78 | 3->8 | 1399->1282 | 0.4->0.4 |
| 7 | Z | 8 | 5 | 1 | NONE | 3065 | 4758 | 0.0 | 3489 | 1.0 | 35 | 0/0/0 | 0/0/0 | 78 | 3->8 | 1381->1277 | 0.4->0.4 |
| 8 | X | 16 | 9 | 1 | FOUND | 63908 | 77169 | 1.4 | 86510 | 30.5 | 260 | 0/0/0 | 896/1138/17647 | 78 | 8->16 | 1282->1450 | 0.4->0.3461 |
| 9 | Z | 16 | 9 | 1 | FOUND | 102723 | 121103 | 2.3 | 139392 | 49.1 | 359 | 0/0/0 | 3990/794/26344 | 78 | 8->16 | 1277->1452 | 0.4->0.3073 |
| 10 | X | 15 | 9 | 1 | FOUND | 133315 | 152678 | 3.0 | 182255 | 63.6 | 347 | 896/1138/17647 | 7953/4425/16252 | 78 | 16->15 | 1450->2074 | 0.3461->0.2128 |
| 11 | Z | 14 | 9 | 1 | FOUND | 233230 | 263107 | 5.1 | 320816 | 112.1 | 517 | 3990/794/26344 | 5999/38/19730 | 78 | 16->16 | 1452->2043 | 0.3073->0.0741 |
| 12 | Z | 14 | 9 | 0 | OPT | 353181 | 395249 | 7.6 | 490119 | 167.6 | 726 | 5999/38/19730 | 2217/176/675 | 79 | 16->12 | 2043->2714 | 0.0741->0.06 |
| 13 | X | 12 | 9 | 0 | OPT | 35601 | 41254 | 0.8 | 47765 | 16.7 | 3 | 7953/4425/16252 | 5120/2459/4220 | 78 | 15->13 | 2074->2693 | 0.2128->0.1772 |
| total | | | | | | 927855 | 1060936 | 20.3 | 1273003 | 441.4 | 2286 | | | | | | |

LP_340_56_8 no-card, main:
| # | half | cap | lb | 1st | out | d_confl | d_dec | d_prop(M) | d_lk | d_lkprop(M) | d_starts | pre core/t2/loc | post core/t2/loc | pre_trail | lk_maxS | polT | step |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 0 | X | 1 | 1 | 1 | FALSE | 1 | 0 | 0.0 | 2 | 0.0 | 1 | 0/0/0 | 0/0/0 | 206 | 0->0 | 2589->2589 | 0.4->0.4 |
| 1 | Z | 1 | 1 | 1 | FALSE | 1 | 0 | 0.0 | 2 | 0.0 | 1 | 0/0/0 | 0/0/0 | 206 | 0->0 | 2589->2589 | 0.4->0.4 |
| 2 | X | 2 | 2 | 1 | FALSE | 237 | 874 | 0.0 | 46 | 0.0 | 3 | 0/0/0 | 0/0/0 | 206 | 0->3 | 2589->2537 | 0.4->0.4 |
| 3 | Z | 2 | 2 | 1 | FALSE | 237 | 1548 | 0.0 | 32 | 0.0 | 1 | 0/0/0 | 0/0/0 | 206 | 0->3 | 2589->2514 | 0.4->0.4 |
| 4 | X | 4 | 3 | 1 | FALSE | 1353 | 3657 | 0.1 | 1119 | 1.1 | 19 | 0/0/0 | 0/0/0 | 206 | 0->5 | 2589->2460 | 0.4->0.4 |
| 5 | Z | 4 | 3 | 1 | FALSE | 1455 | 4365 | 0.1 | 1174 | 0.9 | 20 | 0/0/0 | 0/0/0 | 206 | 0->4 | 2589->2496 | 0.4->0.4 |
| 6 | X | 8 | 5 | 1 | TRUE | 870 | 1712 | 0.1 | 756 | 0.7 | 7 | 0/0/0 | 1117/501/600 | 206 | 0->9 | 2589->2219 | 0.4->0.4 |
| 7 | Z | 8 | 5 | 1 | TRUE | 1582 | 2948 | 0.1 | 1365 | 1.0 | 11 | 0/0/0 | 1192/860/1221 | 206 | 0->8 | 2589->2318 | 0.4->0.4 |
| 8 | X | 7 | 5 | 1 | FALSE | 4328 | 8542 | 0.3 | 4903 | 5.0 | 33 | 0/0/0 | 0/0/0 | 206 | 0->8 | 2589->2467 | 0.4->0.4 |
| 9 | Z | 7 | 5 | 1 | FALSE | 10155 | 20208 | 0.5 | 11661 | 13.4 | 103 | 0/0/0 | 0/0/0 | 206 | 0->8 | 2589->2341 | 0.4->0.3999 |
| total | | | | | | 20219 | 43854 | 1.2 | 21060 | 22.1 | 199 | | | | | | |

LP_340_56_8 no-card, GH-89:
| # | half | cap | lb | 1st | out | d_confl | d_dec | d_prop(M) | d_lk | d_lkprop(M) | d_starts | pre core/t2/loc | post core/t2/loc | pre_trail | lk_maxS | polT | step |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 0 | X | 1 | 1 | 1 | NONE | 1 | 0 | 0.0 | 1 | 0.0 | 1 | 0/0/0 | 0/0/0 | 208 | 0->0 | 2589->2589 | 0.4->0.4 |
| 1 | Z | 1 | 1 | 1 | NONE | 1 | 0 | 0.0 | 1 | 0.0 | 1 | 0/0/0 | 0/0/0 | 206 | 0->0 | 2589->2589 | 0.4->0.4 |
| 2 | X | 2 | 2 | 1 | NONE | 277 | 1476 | 0.1 | 31 | 0.0 | 3 | 0/0/0 | 0/0/0 | 208 | 0->3 | 2589->2533 | 0.4->0.4 |
| 3 | Z | 2 | 2 | 1 | NONE | 241 | 1383 | 0.1 | 30 | 0.0 | 3 | 0/0/0 | 0/0/0 | 206 | 0->2 | 2589->2520 | 0.4->0.4 |
| 4 | X | 4 | 3 | 1 | NONE | 821 | 2422 | 0.0 | 724 | 0.4 | 13 | 0/0/0 | 0/0/0 | 208 | 3->4 | 2533->2476 | 0.4->0.4 |
| 5 | Z | 4 | 3 | 1 | NONE | 1401 | 3864 | 0.1 | 1320 | 1.0 | 21 | 0/0/0 | 0/0/0 | 206 | 2->5 | 2520->2431 | 0.4->0.4 |
| 6 | X | 8 | 5 | 1 | FOUND | 1251 | 2350 | 0.0 | 1289 | 0.8 | 6 | 0/0/0 | 604/13/947 | 208 | 4->9 | 2476->2317 | 0.4->0.4 |
| 7 | Z | 8 | 5 | 1 | FOUND | 202 | 278 | 0.0 | 209 | 0.2 | 1 | 0/0/0 | 52/26/134 | 206 | 5->6 | 2431->2229 | 0.4->0.4 |
| 8 | X | 7 | 5 | 1 | NONE | 3799 | 5888 | 0.2 | 4679 | 5.4 | 19 | 604/13/947 | 1563/431/3968 | 209 | 9->9 | 2317->2441 | 0.4->0.3962 |
| 9 | Z | 7 | 5 | 1 | NONE | 4815 | 7441 | 0.2 | 5821 | 6.5 | 25 | 52/26/134 | 537/149/819 | 206 | 6->8 | 2229->2425 | 0.4->0.3952 |
| total | | | | | | 12809 | 25102 | 0.7 | 14105 | 14.3 | 93 | | | | | | |

## 3. Findings

**F1. Before a half's first solution the persistent solver carries only heuristic state, and that state is
what breaks the first FOUND probe on TN_144.** On every refutation before the first solution GH-76 performs
`solve_()`'s fail-path reset (`cancelUntilBeginning` + `removeLearntClauses`), so the pre-solution probes
start with an empty learnt DB in both binaries (`pre core/t2/loc` = 0/0/0). What survives are the VSIDS/CHB
activities, the saved phases, VSIDS decay/LRB step, lookahead statistics and reduce schedules. On TN_144 the
cap-16 feasibility probes then cost **365,692 + 269,440 conflicts (514k + 376k lookaheads)** in GH-89 versus
**16 + 19 conflicts (1 + 1 lookahead)** with a fresh solver, which finds a weight-16 logical almost
immediately from the default phases (`polT` 791 = all variables; GH-89 starts the probe with 89 saved phases
flipped, `lk_maxSuccLB` 9, LRB step 0.394). Attribution on TN_144 (ablations applied on every probe, `m64|x`):

| variant | total conflicts | X16 feasibility | Z16 feasibility |
|---|---:|---:|---:|
| main (fresh per probe) | 1150798 | 16 | 19 |
| GH-89 | 2785114 | 365692 | 269440 |
| reset decision heuristics every probe (68) | 1234071 | 11 | 19 |
| reset lookahead statistics every probe (66) | 1275283 | 396731 | 32580 |
| reset reduce/simplify schedules every probe (96) | 2972946 | 358907 | 310422 |
| fresh solver until first solution (FRESHPRE=1) | 1725750 | 16 | 19 |

Resetting the decision heuristics (activities + saved phases + VSIDS/LRB parameters) restores the 16/19-conflict
FOUND; resetting lookahead statistics does not (X16 397k) and reduce schedules are irrelevant. Learnt clauses
cannot be the cause here (there are none). The same carry-over is mildly helpful on small codes (LP_340: GH-89
12.8k vs 16.5k conflicts with fresh pre-solution probes), i.e. it is a high-variance perturbation of the
search, not a systematic gain.

**F2. After the first solution, persistent feasibility probes return a solution exactly at the cap, so the
tie-break descends one unit per probe.** In every large cell the post-solution feasibility probes of GH-89 return
value = cap (TN: 16 -> 15 -> 14; GB_144: 16 -> 15 -> 14; LP_442: 16 -> 14 -> 12 where caps were 15/13), whereas
fresh probes land lower (TN X cap 15 -> 13, GB X cap 16 -> 15). The schedule therefore makes more probes, each
expensive: TN X15 tie-break 1,150,618 conflicts (persistent, starting with 8402/2366/20189 learnts, LRB step at
its 0.06 floor, VSIDS initial phase skipped) vs 458,610 (fresh, found 13). This behaviour survives resetting the
decision heuristics (TN `m68`: X15 found 15, then Z14 448k), so it is tied to the persistent clause/bound state
(learnts, hardening, on-the-fly reduced originals once `feasible`), not to activities. It is the residual cost
when only F1 is fixed (TN 1.50x main, below).

**F3. After the first solution, learnt clauses do pay off on optimisation and refutation probes.** GB_144 card-mto
X optimise cap 15: 1,292,157 conflicts fresh vs 434,729 when the solver of the preceding FOUND probe continues
(FRESHPRE=1), 699,379 when only core learnts are kept (`m8`). LP_442 no-card Z optimise cap 14: 225,033 fresh vs
38,970 persistent. LP_340 post-solution refutations X7/Z7: 4,328/10,155 fresh vs 3,799/4,815 persistent. This is
GH-76's intended effect and where its wins come from.

**F4. Other candidate causes, ruled out.** Reduce/simplify schedules driven by cumulative counters (`m96`: no
improvement on TN). Learnt clauses from earlier caps before the first solution: none exist (dropped on every
raise). knownLB/initUB handling: a fresh `incPrepare`+`incProbe` reproduces main's per-probe search exactly
(conflicts, decisions, restarts and lookahead calls identical on every pre-solution probe of 5 cells; only the
preprocessing propagations are attributed to the probe in main and to `incPrepare` here), so the GH-76 bound
plumbing is equivalent to main's `initLB/strictUB/startAtCap` path. Growing variable count with card-mto (dynamic
cardinality variables, 3.5k -> 12k on LP_442) occurs in both binaries.

**F5. Re-running the VSIDS initial phase inside a post-solution probe (`m1`) is unsafe in this engine**: 5 of 8
runs produced a model with unassigned variables (cost 0), caught by the GH-76 witness check (UNKNOWN). Policies
must stick to state transitions the engine already performs.

## 4. Policy screen (diagnostic counter build, total conflicts / main)

Large cells (300 s limit; all complete, all distances correct):
| cell | main confl (lk) [probes] o | gh89 confl (lk) [probes] o | postsol confl (lk) [probes] o | feasfresh confl (lk) [probes] o | heurreset confl (lk) [probes] o | gh89/main | postsol/main | feasfresh/main | heurreset/main |
|---|---|---|---|---|---|---|---|---|---|
| TN_144_2_13.no-card | 1150798 (1591104) [13] 13 | 2785114 (3907653) [14] 13 | 1725750 (2400731) [14] 13 | 936044 (1293961) [13] 13 | 1234071 (1718734) [14] 13 | 2.42 | 1.50 | 0.81 | 1.07 |
| LP_442_68_10.card-mto | 205669 (239063) [14] 10 | 312959 (381367) [14] 10 | 194776 (229193) [14] 10 | 191663 (224064) [14] 10 | 158964 (191456) [14] 10 | 1.52 | 0.95 | 0.93 | 0.77 |
| BB_144_14_14.no-card | 1032177 (1398681) [13] 14 | 1121446 (1537325) [13] 14 | 851174 (1159899) [13] 14 | 1059588 (1442775) [13] 14 | 1615588 (2211876) [13] 14 | 1.09 | 0.82 | 1.03 | 1.57 |
| BB_144_12_12.no-card | 19072 (22263) [12] 12 | 19911 (24619) [14] 12 | 18148 (21131) [12] 12 | 18148 (21131) [12] 12 | 17361 (21578) [12] 12 | 1.04 | 0.95 | 0.95 | 0.91 |
| GB_144_12_12.card-mto | 1777665 (2427163) [12] 12 | 927855 (1273003) [14] 12 | 933010 (1273171) [12] 12 | 933010 (1273171) [12] 12 | 852193 (1165447) [12] 12 | 0.52 | 0.52 | 0.52 | 0.48 |
| LP_442_68_10.no-card | 291609 (349229) [12] 10 | 134580 (161453) [14] 10 | 102330 (119554) [12] 10 | 102330 (119554) [12] 10 | 176421 (212523) [14] 10 | 0.46 | 0.35 | 0.35 | 0.60 |
| LP_340_56_8.no-card | 20219 (21060) [10] 8 | 12809 (14105) [10] 8 | 16475 (17320) [10] 8 | 20219 (21050) [10] 8 | 12453 (13754) [10] 8 | 0.63 | 0.81 | 1.00 | 0.62 |
| LP_340_56_8.card-mto | 23422 (23061) [10] 8 | 13600 (14352) [10] 8 | 15905 (15364) [10] 8 | 23422 (23051) [10] 8 | 13910 (14204) [10] 8 | 0.58 | 0.68 | 1.00 | 0.59 |
| geomean |  |  |  |  |  | 0.88 | 0.76 | 0.78 | 0.77 |

Tier1 cells (120 s limit):
| cell | main confl (lk) [probes] o | gh89 confl (lk) [probes] o | postsol confl (lk) [probes] o | feasfresh confl (lk) [probes] o | heurreset confl (lk) [probes] o | gh89/main | postsol/main | feasfresh/main | heurreset/main |
|---|---|---|---|---|---|---|---|---|---|
| BB_90_8_10.no-card | 8427 (8442) [12] 10 | 6437 (7083) [14] 10 | 7393 (7055) [12] 10 | 8427 (8430) [12] 10 | 5571 (6040) [12] 10 | 0.76 | 0.88 | 1.00 | 0.66 |
| BB_90_8_10.card-mto | 7808 (7684) [12] 10 | 6914 (7490) [14] 10 | 6702 (6070) [12] 10 | 7808 (7672) [12] 10 | 5754 (6249) [12] 10 | 0.89 | 0.86 | 1.00 | 0.74 |
| GB_144_12_8.no-card | 4364 (3190) [10] 8 | 4426 (4037) [10] 8 | 3468 (2556) [10] 8 | 4364 (3180) [10] 8 | 2898 (2522) [10] 8 | 1.01 | 0.79 | 1.00 | 0.66 |
| GB_144_12_8.card-mto | 4000 (2756) [10] 8 | 3135 (2772) [10] 8 | 2647 (1682) [10] 8 | 4000 (2746) [10] 8 | 2114 (1616) [10] 8 | 0.78 | 0.66 | 1.00 | 0.53 |
| BB_108_8_10.no-card | 15851 (17661) [13] 10 | 8263 (9297) [14] 10 | 6897 (6304) [13] 10 | 14315 (16156) [13] 10 | 7103 (7920) [13] 10 | 0.52 | 0.44 | 0.90 | 0.45 |
| BB_108_8_10.card-mto | 18054 (20480) [13] 10 | 9086 (9231) [14] 10 | 8577 (8571) [13] 10 | 16336 (18692) [13] 10 | 5522 (5652) [13] 10 | 0.50 | 0.48 | 0.90 | 0.31 |
| LP_238_44_6.no-card | 10663 (9139) [11] 6 | 7970 (7959) [11] 6 | 7658 (6608) [11] 6 | 9250 (7949) [11] 6 | 5155 (4794) [10] 6 | 0.75 | 0.72 | 0.87 | 0.48 |
| LP_238_44_6.card-mto | 9630 (7185) [11] 6 | 6246 (5724) [11] 6 | 7531 (5834) [11] 6 | 8895 (6716) [11] 6 | 6183 (4372) [10] 6 | 0.65 | 0.78 | 0.92 | 0.64 |
| geomean |  |  |  |  |  | 0.72 | 0.68 | 0.95 | 0.54 |

`postsol` = FRESHPRE=1 (fresh solver until the half's first solution, persistent afterwards); `feasfresh` =
FRESHPRE=2 (fresh for every feasibility probe, persistent only for optimisation probes, which continue from the
half's latest solver); `heurreset` = GH-89 with decision heuristics reset on every probe (`m68`, engine change).

Reading: no policy dominates cell by cell (chaotic search). `postsol` removes the F1 pathology (TN 2.42 -> 1.50,
LP_442 card-mto 1.52 -> 0.95, BB_144_14 1.09 -> 0.82) and keeps or improves the small-code gains (Tier1 0.68,
LP_340 0.81/0.68, GH-89 0.72 and 0.63/0.58). `feasfresh` also removes F2 (worst cell 1.03) but gives back the
small-code gains (Tier1 0.95, LP_340 1.00). `heurreset` has the best small-code geomean (0.54) but a new 1.57
regression on BB_144_14_14 and needs a new engine transition.

## 5. Root cause (summary)

The large-code regressions are not caused by stale learnt clauses: GH-76 already discards all learnt state on
every bound raise. They come from (a) **CDCL decision-heuristic state (activities + saved phases) carried through
the pre-solution refutation probes**, which on TN_144 turns a 35-conflict first FOUND into 635k conflicts, and
(b) **post-solution feasibility probes on the persistent instance returning solutions exactly at the cap**, which
lengthens the tie-break chain with expensive probes (TN, LP_442 card-mto). (a) is avoidable at no cost because
persistence before the first solution has nothing but heuristic state to offer; (b) trades against GH-76's real
benefit (F3).
