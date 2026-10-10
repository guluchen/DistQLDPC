# GH-106 Tier0 result

Issue #106; branch `experiment/gh-106-incremental-regression`. Diagnosis `fa06270`, preregistration `c7c4a29`,
candidate source `1e69eeb` (evidence commits after it change no source). Mac only (yfclab2 down); every solver/test
process under the PI 2 GB cap (`memlimit.py`); diagnostic and trace runs serial, one solver process at a time.
State: **SCIENCE_PENDING** (see below).

## Candidate
* `-inc-policy=postsol` (default), `gh89`, `feasfresh`, `fresh`; driver-only (`src/core/distqldpc.cc`), engine
  (`src/solver/`) byte-identical to GH-89 `09d8bc2`. Design and soundness: `PROPOSAL.md`.
* Frozen binary: `scratch-2026-10-08-ce0ddb/frozen106/cand/distqldpc` (read-only),
  sha256 `820145fb859c587a70a3377f01d7f1d34f81488c3bc1872e277702e616cddf7f`.

## Checks
| Check | Result |
|---|---|
| Build `make clean; make CXX="c++ -Wno-reserved-user-defined-literal"` | PASS; 34 warnings (= GH-89), none in `distqldpc.cc` |
| `scripts/smoke_test.sh` | PASS |
| `python3 -B scripts/test_partition_soft_literals.py` | PASS (fixture + 11 adjacent oracles) |
| GH58 oracle `tests/test_partition_soft_literals.cc` (ci.yml compile line) | PASS, `GH58_PARTITION_ORACLE_PASS cases=80` |
| `tests/test_incremental_probes.cc` 20000 x {gh89, postsol, feasfresh, fresh} | PASS, 0 failures each; gh89 = GH-76/GH-89 record (91872 probes, 154 rebuilds) |
| `tests/test_incremental_symbreak.cc` 20000 x {gh89, postsol, feasfresh, fresh} | PASS, 0 failures each; gh89 = GH-89 record (106247 probes, 308 rebuilds, sym 4807/12134/3059) |
| `-inc-policy=gh89 -v` vs `frozen89/cand -v`, 7 codes x {no-card, card-mto, default}, `-cpu-lim=120` | **21/21 byte-identical** |
| `-joint -v` vs `frozen89/cand -joint -v`, same 21 | **21/21 byte-identical** |
| Default (`postsol`) on the same 21 | all `o` equal to frozen89 and to the names |
| Default vs counter-build `postsol` (GH106_FRESHPRE=1), 6 large cells | search-identical (`-v` equal modulo dump/build-count lines) |
| QDistSAT cross-repo, `ci/xrepo-gh106` = `5bfa9c8` (tree of `1e69eeb`, parent 72d1fe1), run 38078968215 | success, **scientific results match YES** |
| Science sweep (`science.sh`), 50 codes x 4 modes, 60 s, `--jobs 4`, vs main 7eadd54 | SCIENCE_RESULT |

Oracle lines: `raw/tier0/oracles.txt`. Traces: `raw/tier0/traces/` (`SUMMARY.txt`). Candidate `-v` runs on the
diagnosis cells: `raw/tier0/cand106-runs/`.

## Informational counter comparison (not timing)
Total conflicts (lookahead calls) [probes] and final `o` per run; `postsol` counters come from the counter build
with GH106_FRESHPRE=1, which is search-identical to the candidate default on these cells; main = 7eadd54 counter
build; gh89 = 09d8bc2 counter build (both search-identical to their frozen binaries).

Diagnosis cells:
| cell | main confl (lk) [probes] o | gh89 confl (lk) [probes] o | postsol confl (lk) [probes] o | gh89/main | postsol/main |
|---|---|---|---|---|---|
| TN_144_2_13.no-card | 1150798 (1591104) [13] 13 | 2785114 (3907653) [14] 13 | 1725750 (2400731) [14] 13 | 2.42 | 1.50 |
| LP_442_68_10.card-mto | 205669 (239063) [14] 10 | 312959 (381367) [14] 10 | 194776 (229193) [14] 10 | 1.52 | 0.95 |
| GB_144_12_12.card-mto | 1777665 (2427163) [12] 12 | 927855 (1273003) [14] 12 | 933010 (1273171) [12] 12 | 0.52 | 0.52 |
| LP_340_56_8.no-card | 20219 (21060) [10] 8 | 12809 (14105) [10] 8 | 16475 (17320) [10] 8 | 0.63 | 0.81 |
| LP_340_56_8.card-mto | 23422 (23061) [10] 8 | 13600 (14352) [10] 8 | 15905 (15364) [10] 8 | 0.58 | 0.68 |
| geomean |  |  |  | 0.93 | 0.84 |

Other GH-89 Tier3 regression/win cells:
| cell | main confl (lk) [probes] o | gh89 confl (lk) [probes] o | postsol confl (lk) [probes] o | gh89/main | postsol/main |
|---|---|---|---|---|---|
| BB_144_14_14.no-card | 1032177 (1398681) [13] 14 | 1121446 (1537325) [13] 14 | 851174 (1159899) [13] 14 | 1.09 | 0.82 |
| BB_144_12_12.no-card | 19072 (22263) [12] 12 | 19911 (24619) [14] 12 | 18148 (21131) [12] 12 | 1.04 | 0.95 |
| LP_442_68_10.no-card | 291609 (349229) [12] 10 | 134580 (161453) [14] 10 | 102330 (119554) [12] 10 | 0.46 | 0.35 |
| geomean |  |  |  | 0.81 | 0.65 |

Tier1 cells:
| cell | main confl (lk) [probes] o | gh89 confl (lk) [probes] o | postsol confl (lk) [probes] o | gh89/main | postsol/main |
|---|---|---|---|---|---|
| BB_90_8_10.no-card | 8427 (8442) [12] 10 | 6437 (7083) [14] 10 | 7393 (7055) [12] 10 | 0.76 | 0.88 |
| BB_90_8_10.card-mto | 7808 (7684) [12] 10 | 6914 (7490) [14] 10 | 6702 (6070) [12] 10 | 0.89 | 0.86 |
| GB_144_12_8.no-card | 4364 (3190) [10] 8 | 4426 (4037) [10] 8 | 3468 (2556) [10] 8 | 1.01 | 0.79 |
| GB_144_12_8.card-mto | 4000 (2756) [10] 8 | 3135 (2772) [10] 8 | 2647 (1682) [10] 8 | 0.78 | 0.66 |
| BB_108_8_10.no-card | 15851 (17661) [13] 10 | 8263 (9297) [14] 10 | 6897 (6304) [13] 10 | 0.52 | 0.44 |
| BB_108_8_10.card-mto | 18054 (20480) [13] 10 | 9086 (9231) [14] 10 | 8577 (8571) [13] 10 | 0.50 | 0.48 |
| LP_238_44_6.no-card | 10663 (9139) [11] 6 | 7970 (7959) [11] 6 | 7658 (6608) [11] 6 | 0.75 | 0.72 |
| LP_238_44_6.card-mto | 9630 (7185) [11] 6 | 6246 (5724) [11] 6 | 7531 (5834) [11] 6 | 0.65 | 0.78 |
| geomean |  |  |  | 0.72 | 0.68 |

`postsol` removes the LP_442 card-mto, BB_144_14_14 and BB_144_12_12 regressions in conflicts, keeps GB_144 card-mto
at GH-89's level (0.52) and LP_442 no-card below it (0.35 vs 0.46), and keeps the small-code gains (Tier1 geomean 0.68 vs GH-89 0.72). TN_144
no-card improves from 2.42x to 1.50x main but remains a regression (DIAGNOSIS F2: post-solution feasibility probes
stop at the cap); `-inc-policy=feasfresh` gives 0.81 there (worst cell 1.03 in the screen) at the cost of the
small-code gains. Caveat for timing: `postsol` builds a fresh half instance for every pre-solution probe (e.g.
BB_90_8_10: 5+5 builds vs 1+1), the same number main builds; on the tiny Tier1 codes build time is not captured by
conflict counts, so Tier1 wall-time ratios may differ from the conflict ratios above.

## Deviations
* For about 45 s two diagnostic solver processes overlapped (an ablation batch started before the previous one
  ended; the older batch was killed). Counter results unaffected.
* Two short exploratory oracle runs (`test_incremental_probes 2000`, `test_incremental_symbreak 1000`, < 2 s,
  < 150 MB) were run without the memlimit wrapper; all official oracle runs used it.
* The science sweep was split into 9 chunks (`tier0_science.py --stems`, merged by `merge_science.py`) so that each
  timing-lock hold stays below ~13 minutes; the harness is otherwise the GH-102 copy.
* No timing comparison was made.
