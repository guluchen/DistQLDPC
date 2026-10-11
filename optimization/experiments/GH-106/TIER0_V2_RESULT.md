# GH-106 v2 Tier0 result: `-inc-policy=budgettot` (default K=3, F=10000)

Follow-up to `TIMING_RESULT.md` (postsol: single Tier3 regression TN_144_2_13 no-card 1.74x). Preregistration
`PROPOSAL_V2.md` (`7884c70`, addendum K=2 -> 3 in `a3c7a87` before freezing). Candidate source `a3c7a87`.
Mac only; every solver/test process under the 2 GB cap; diagnostic and trace runs serial, one solver process.
State: **SCIENCE_PENDING**.

## Design
* Pre-solution probes: fresh solver per probe (= postsol).
* Post-solution feasibility probe on the kept solver: conflict limit `conflicts_now + max(K * C, F)`, C = conflicts spent
  so far by all half probes of the run; K = `-inc-budget` (3), F = `-inc-budget-floor` (10000). Limit reached -> the
  instance is discarded and the probe is answered by a freshly built instance (no limit). Optimisation probes and probes on
  fresh solvers are never limited. Deterministic (conflict counts, checked between `search()` calls).
* Engine: `Solver::inc_conflictLimit` (default UINT64_MAX), checked next to `asynch_interrupt` in `incProbe`'s phase
  loops; returns the existing `INC_INTERRUPTED`. With the default the engine behaves as before.
* Also available: gh89 (GH-89), postsol (v1 default), feasfresh, fresh, atcap, atcapfeas, budget (per-half scale).
* Frozen binary: `scratch-2026-10-08-ce0ddb/frozen106/v2/distqldpc` (read-only),
  sha256 `b3f4e3e4a0056dbdae46ac6c53b9a13e9674a876087dc324e88dfecb98bcb1c7`. v1 (`frozen106/cand`) unchanged.

## Counter screen: total conflicts / main 7eadd54 (counter build, search-identical to the frozen binaries)
Large cells (Tier3 set + LP_340; every run complete, all distances correct):
| cell | main confl (lk) [probes] o | gh89 confl (lk) [probes] o | postsol confl (lk) [probes] o | budgettot3 confl (lk) [probes] o | gh89/main | postsol/main | budgettot3/main |
|---|---|---|---|---|---|---|---|
| TN_144_2_13.no-card | 1150798 (1591104) [13] 13 | 2785114 (3907653) [14] 13 | 1725750 (2400731) [14] 13 | 1015362 (1403615) [14] 13 | 2.42 | 1.50 | 0.88 |
| TN_144_2_13.card-mto | 2391535 (3333835) [14] 13 | 1799862 (2515331) [14] 13 | 1271025 (1767922) [14] 13 | 1271025 (1767922) [14] 13 | 0.75 | 0.53 | 0.53 |
| BB_144_14_14.no-card | 1032177 (1398681) [13] 14 | 1121446 (1537325) [13] 14 | 851174 (1159899) [13] 14 | 986416 (1339169) [14] 14 | 1.09 | 0.82 | 0.96 |
| BB_144_14_14.card-mto | 1079492 (1466876) [13] 14 | 1038778 (1420286) [13] 14 | 920028 (1251896) [13] 14 | 920028 (1251896) [13] 14 | 0.96 | 0.85 | 0.85 |
| BB_144_12_12.no-card | 19072 (22263) [12] 12 | 19911 (24619) [14] 12 | 18148 (21131) [12] 12 | 18148 (21131) [12] 12 | 1.04 | 0.95 | 0.95 |
| BB_144_12_12.card-mto | 27583 (32869) [12] 12 | 22318 (26785) [14] 12 | 16751 (19820) [12] 12 | 16751 (19820) [12] 12 | 0.81 | 0.61 | 0.61 |
| GB_144_12_12.no-card | 1330558 (1806087) [14] 12 | 1097267 (1510643) [14] 12 | 603161 (815669) [14] 12 | 603161 (815669) [14] 12 | 0.82 | 0.45 | 0.45 |
| GB_144_12_12.card-mto | 1777665 (2427163) [12] 12 | 927855 (1273003) [14] 12 | 933010 (1273171) [12] 12 | 933010 (1273171) [12] 12 | 0.52 | 0.52 | 0.52 |
| LP_442_68_10.no-card | 291609 (349229) [12] 10 | 134580 (161453) [14] 10 | 102330 (119554) [12] 10 | 102330 (119554) [12] 10 | 0.46 | 0.35 | 0.35 |
| LP_442_68_10.card-mto | 205669 (239063) [14] 10 | 312959 (381367) [14] 10 | 194776 (229193) [14] 10 | 194776 (229193) [14] 10 | 1.52 | 0.95 | 0.95 |
| LP_544_80_12.no-card | 1420652 (1731018) [12] 12 | 309341 (373148) [14] 12 | 1337957 (1633932) [12] 12 | 1337957 (1633932) [12] 12 | 0.22 | 0.94 | 0.94 |
| LP_544_80_12.card-mto | 384552 (457055) [14] 12 | 483871 (584228) [14] 12 | 250482 (300104) [14] 12 | 250482 (300104) [14] 12 | 1.26 | 0.65 | 0.65 |
| LP_340_56_8.no-card | 20219 (21060) [10] 8 | 12809 (14105) [10] 8 | 16475 (17320) [10] 8 | 16475 (17320) [10] 8 | 0.63 | 0.81 | 0.81 |
| LP_340_56_8.card-mto | 23422 (23061) [10] 8 | 13600 (14352) [10] 8 | 15905 (15364) [10] 8 | 15905 (15364) [10] 8 | 0.58 | 0.68 | 0.68 |
| geomean |  |  |  |  | 0.81 | 0.71 | 0.69 |

Tier1 cells:
| cell | main confl (lk) [probes] o | gh89 confl (lk) [probes] o | postsol confl (lk) [probes] o | budgettot3 confl (lk) [probes] o | gh89/main | postsol/main | budgettot3/main |
|---|---|---|---|---|---|---|---|
| BB_90_8_10.no-card | 8427 (8442) [12] 10 | 6437 (7083) [14] 10 | 7393 (7055) [12] 10 | 7393 (7055) [12] 10 | 0.76 | 0.88 | 0.88 |
| BB_90_8_10.card-mto | 7808 (7684) [12] 10 | 6914 (7490) [14] 10 | 6702 (6070) [12] 10 | 6702 (6070) [12] 10 | 0.89 | 0.86 | 0.86 |
| GB_144_12_8.no-card | 4364 (3190) [10] 8 | 4426 (4037) [10] 8 | 3468 (2556) [10] 8 | 3468 (2556) [10] 8 | 1.01 | 0.79 | 0.79 |
| GB_144_12_8.card-mto | 4000 (2756) [10] 8 | 3135 (2772) [10] 8 | 2647 (1682) [10] 8 | 2647 (1682) [10] 8 | 0.78 | 0.66 | 0.66 |
| BB_108_8_10.no-card | 15851 (17661) [13] 10 | 8263 (9297) [14] 10 | 6897 (6304) [13] 10 | 6897 (6304) [13] 10 | 0.52 | 0.44 | 0.44 |
| BB_108_8_10.card-mto | 18054 (20480) [13] 10 | 9086 (9231) [14] 10 | 8577 (8571) [13] 10 | 8577 (8571) [13] 10 | 0.50 | 0.48 | 0.48 |
| LP_238_44_6.no-card | 10663 (9139) [11] 6 | 7970 (7959) [11] 6 | 7658 (6608) [11] 6 | 7658 (6608) [11] 6 | 0.75 | 0.72 | 0.72 |
| LP_238_44_6.card-mto | 9630 (7185) [11] 6 | 6246 (5724) [11] 6 | 7531 (5834) [11] 6 | 7531 (5834) [11] 6 | 0.65 | 0.78 | 0.78 |
| geomean |  |  |  |  | 0.72 | 0.68 | 0.68 |

`budgettot3` = counter build with `-inc-policy=budgettot -inc-budget=3 -inc-budget-floor=10000`; the frozen v2 default is
search-identical to it on LP_340 no-card, BB_144_14_14 both modes, TN_144 no-card and GB_144_12_12 no-card (`-v` equal
modulo dump and build-count lines). LP_544 no-card: the K=3 counter run hit the wall limit under host load (load ~10)
after 11 probes identical to the K=2 run; no budgeted probe occurs in its schedule, and the frozen v2 default's `-v`
output equals the completed K=2 counter run, whose numbers are shown. The fallback fires only on TN_144 no-card (X15:
persistent probe stopped at 91k conflicts, fresh probe finds 13; Z12 persistent refutation completes) and BB_144_14_14
no-card (Z13 persistent refutation stopped at 138k, redone fresh); every other cell equals postsol.
Worst cell 0.96 (postsol: 1.50; GH-89: 2.42). All policies screened (atcap, atcapfeas, budget K=2/4/8, budget K=4 F=50k,
budgettot K=1/2/3): PROPOSAL_V2.md and `raw/tier0-v2/screen-runs.tar.gz`.

## Checks
| Check | Result |
|---|---|
| Build (`make clean; make CXX=...`) | PASS, 34 warnings (= GH-89), none in `distqldpc.cc` |
| GH58 oracle (ci.yml compile line) | PASS, cases=80 |
| `test_incremental_probes` 20000 x {gh89, postsol, budgettot 3/10000, budgettot 0/0, budgettot 1/0, budget 3/10000, budget 0/0, atcap, atcapfeas} | all PASS, 0 failures; gh89 = GH-76 record (91872/154); fallback path exercised (budgettot 0/0: 3778 fallbacks, 1/0: 2872) |
| `test_incremental_symbreak` 20000 x the same policies (production `run_css_half`) | all PASS, 0 failures; gh89 = GH-89 record (106247/308, sym 4807/12134/3059); budgettot 0/0: 1556 extra rebuilds from fallbacks |
| `-inc-policy=gh89 -v` vs frozen89, 7 codes x 3 modes, `-cpu-lim=120` | **21/21 byte-identical** |
| `-joint -v` vs frozen89 `-joint -v` | **21/21 byte-identical** |
| `-inc-policy=postsol -v` vs frozen106 v1 (default postsol) | **21/21 byte-identical** |
| Default (budgettot) on the same 21 | all `o` equal to frozen89, v1 and the names |
| QDistSAT cross-repo `ci/xrepo-gh106v2` = `5569dd6` (tree of `a3c7a87`, parent 72d1fe1), run 38104544744 | success, scientific results match **YES** |
| Science sweep (`science_v2.sh`), 50 codes x 4 modes, 60 s, `--jobs 4`, 9 lock-held chunks, vs main 7eadd54 | SCIENCE_RESULT |

Raw: `raw/tier0-v2/` (oracles.txt, traces/ + SUMMARY.txt, traces_v2.log, screen-runs.tar.gz), counter-build patch
`diag/counter_build_v2.diff` (on the v2 driver before the default change; the screen passed all policy flags explicitly).

## Deviations
* The K=3 default was chosen after the preregistered K=2 (addendum committed before freezing; the reason is the
  BB_144_14_14 card-mto counter cell, 1.19 at K=2, added when the screen was extended to the full Tier3 cell list).
* LP_544 no-card K=3 counter run hit the wall limit (see above); covered by the identity argument and the frozen run.
* No timing by this agent.
