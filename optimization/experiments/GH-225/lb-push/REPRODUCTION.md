# GH-225 follow-up: pushing open Tier 5 lower bounds (2026-11-06/07)

12 h runs on a dedicated server. Each run had one pinned core and a 4 GB cap. Before each launch the runner
checked that the core and its SMT sibling were idle (runner: `../lb-repro/runner/gh225lb_queue.py`).
Data: main a79d7c89 (the stems after #230).

- **`push1/`**: main 755e0c21 (CC default with gated erasure), frozen as `frozen/server-gh225lb-main-755e0c2`.
  - Arms: `s0` (default seed) plus relabelled `-seed=1` / `-seed=2` on TN_288, TN_324, TN_432, TN_468, TN_576, TN_612 and BB_1080; `s0` only on COLOR_1027.
  - The seeded arms ran 1.5-2x slower per level and could not reach a new lb in 12 h, so they were stopped after about 4 h (rc -15). TN_324 `s0` was also stopped: its next lb is two levels away.
- **`push2/`**: main 1239e9a2, started about 4 h after push1, on the freed cores.
  - Arm `E`: the CC default plus ungated `erasure`, on TN_288, TN_432, TN_468, TN_576, TN_612 and BB_1080.
  - Arm `A`: the CC default without erasure, on TN_432, TN_576 and TN_612.
  - Gated and ungated erasure search different trees: the node counts differ by 2-5x at every high level.
- **`repro3/`**: COLOR_2791 on main 755e0c21 with `-cc-roworder=bfs` (a different tree) and `-cc-roworder=index`.
  - The index run gives node counts close to GH-227 C's (the gate is timing-based). It is the same order as C, so it is not counted as a separate order.

A lower bound is used for a rename only when two runs with different trees reached it, with the last level EMPTY on
both halves (X half only for the color codes, Hx = Hz). This is the same engine, not an independent second method.

| Code | New lb | Runs (time to lb, s) |
|---|---:|---|
| TN_288_2 | 23 | 755e0c21 s0 30 093; 1239e9a2 E 30 030 |
| TN_432_8 | 24 | 755e0c21 s0 29 251; 1239e9a2 E 29 784; 1239e9a2 A 38 938 |
| TN_468_4 | 24 | 755e0c21 s0 38 806; 1239e9a2 E 38 061 |
| TN_576_2 | 25 | 755e0c21 s0 28 223; 1239e9a2 E 30 871; 1239e9a2 A 34 316 |
| TN_612_2 | 25 | 755e0c21 s0 35 008; 1239e9a2 E 37 476; 1239e9a2 A 42 105 |
| COLOR_1027_1 | 32 | 755e0c21 s0 38 288; 1239e9a2 E `-cc-roworder=index` 37 190 (`../lb-repro/repro2/`, the GH-225 erasure tree) |
| BB_1080_4 | 34 | 755e0c21 s0 40 586; 1239e9a2 E (24 h run) 44 390 |
| COLOR_2791_1 | 29 | 755e0c21 default (GH-227 C, 6 h) 20 721, and with `-cc-roworder=index` 20 425; 755e0c21 `-cc-roworder=bfs` 37 963 |

**BB_1080 lb 34 (added 2026-11-07, `push3/`).**
- 755e0c21 s0 (push1) reached it at 40 586 s.
- A 24 h run of 1239e9a2 E reached it at 44 390 s. This is a different tree: level 32 has 36.4G vs 7.1G nodes.
- Both have level 32 EMPTY (X half under the verified dual map; odd levels skipped by parity).
- After lb 34 was reproduced, I stopped the E run and the companion 755e0c21 `-cc-roworder=index` run (rc -15, 47 015 s); lb 36 is far out of reach.

**Not reached in 12 h:** TN_324 lb 24 and TN_684 lb 25. Both were reached in the 36 h runs below.

`summary.md` (from `runner/summ_push.py`) lists every run with its time to each lb and the node counts of its last level. `logs.tgz` holds the full solver output.

## push3, push4, push5: 24-36 h runs (2026-11-07 to 2026-11-09)

Two arms per code, each a different tree. C = main 755e0c21's CC default (gated erasure), frozen as
`frozen/server-gh225lb-main-755e0c2`. E = main 1239e9a2's CC default plus ungated `erasure`, frozen as
`frozen/server-gh225lb-main-1239e9a`. Exceptions: TN_684 uses E with `-seed=1` and `-seed=2`; COLOR_2791 uses C and C with
`-cc-roworder=bfs`; COLOR_1027 uses C and E with `-cc-roworder=index`. Limit 36 h (BB_1080 24 h, stopped by hand at
47 015 s once lb 34 was reproduced). Data: stems of main a79d7c89, so the run ids carry the older stem names.

Final state of the stems renamed on 2026-11-07. Times are s to the new lb (or to the solved value).

| Stem on this branch | Was (main) | Arm 1 | Arm 2 | Runs |
|---|---|---:|---:|---|
| BB_1080_4_34to48 | BB_1080_4_32to48 | C 40 586 (push1) | E 44 390 | push1 / push3 |
| BB_756_16_34 (d = 34) | BB_756_16_32to34 | C 59 834 | E 65 917 | push3 |
| BB_864_4_34to40 | BB_864_4_32to40 | C 58 134 | E 64 158 | push3 |
| COLOR_1027_1_33to37 | COLOR_1027_1_31to37 | C 78 893 | E index 77 146 | push3 |
| COLOR_2791_1_30to61 | COLOR_2791_1_28to61 | C 42 701 | C bfs 79 340 | push3 |
| TN_288_2_24 (d = 24) | TN_288_2_22to24 | C 98 733 | E 100 460 | push3 |
| TN_324_4_24to25 | TN_324_4_23to25 | C 72 074 | E 72 807 | push3 |
| TN_360_4_24 (d = 24) | TN_360_4_23to24 | C 47 415 | E 48 186 | push3 |
| TN_396_4_24to26 | TN_396_4_23to26 | C 47 489 | E 47 923 | push3 |
| TN_432_8_25to29 | TN_432_8_23to29 | C 87 063 | E 89 519 | push4 |
| TN_468_4_25to29 | TN_468_4_23to29 | C 107 865 | E 110 270 | push5 |
| TN_496_2_30 (d = 30) | TN_496_2_28to30 | C 117 232 | E 119 072 | push3 |
| TN_504_2_25to34 | TN_504_2_24to34 | C 54 147 | E 56 955 | push3 |
| TN_540_4_25to34 | TN_540_4_24to34 | C 57 564 | E 63 505 | push3 |
| TN_576_2_26to37 | TN_576_2_24to37 | C 79 691 | E 88 962 | push4 |
| TN_612_2_26to40 | TN_612_2_24to40 | C 97 484 | E 107 037 | push5 |
| TN_648_10_23to32 | TN_648_10_22to32 | C 53 620 | E 58 436 | push3 |
| TN_648_14_23to28 | TN_648_14_22to28 | C 70 302 | E 63 576 | push3 |
| TN_684_2_25to29 | TN_684_2_24to29 | E s1 106 893 | E s2 105 414 | push3 |

Not renamed (one tree, PLAUSIBLE): COLOR_2791 lb 31 (C only, 88 551 s).

Checks:
- `verify_levels.txt` (from `runner/verify_lb.py`): in all 71 runs of push1-5 and repro3 every recorded level is EMPTY. The levels missing below the final lb are the odd levels of the BB codes (parity rule).
- `verify_parity.txt` (from `runner/parity_check.py`, pure Python): every column of Hx and Hz has odd weight on BB_756, BB_864 and BB_1080, so all kernel vectors have even weight.
- XZ-dual maps, for the codes searched on the X half only:
  - BB_756, BB_864, BB_1080 (`halfswap-inverse Z_l x Z_m`) and COLOR_1027, COLOR_2791 (identity, Hx = Hz) are re-checked in pure Python in `verify_dual.txt` (`runner/dual_check.py`);
  - TN_496 uses a Tanner-graph map (`tanner-swap`). The map was dumped from a scratch one-line patch of 755e0c21 (not part of any commit) to `dual/TN_496_dual_perm.txt` and re-checked in pure Python in `verify_dual.txt` (`runner/dual_check_perm.py`).
  - Result for all six: the map is a permutation, ranks of Hx and Hz are equal, and pi(rows of Hz) lies in rs Hx and pi(rows of Hx) in rs Hz, so dX = dZ. TN_684 and the other TN codes searched both halves.
- The upper bounds of all renamed TN and BB stems are the GH-146 witnesses, re-verified in pure Python under the new stems: `optimization/experiments/GH-146/witnesses/renamed-2026-11-07/VERIFY.txt`, 17/17 VALID. That covers the four solved stems.

Caveats:
- All of this is the same CC engine family, not an independent second method.
- C and E both use the erasure rule (GH-195; gated on C, ungated on E). They differ in binary and gating and search different trees, but a soundness bug in code they share would affect both. Non-erasure (A) runs reached only the lower values noted in the rename history (TN_432 24, TN_576 25, TN_612 25).
- On COLOR_1027 the two arms have the same row order and differ only in gating and binary (level 32: 38.0G vs 36.3G nodes), so that pair is the weakest of the set.
