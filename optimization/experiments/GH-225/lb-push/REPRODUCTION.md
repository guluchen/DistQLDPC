# GH-225 follow-up: pushing open Tier 5 lower bounds (2026-11-06/07)

12 h runs on yfclab2, logical CPUs 64-95. Each run had one pinned core and a 4 GB cap. Before each launch the runner
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

**Not reached in 12 h:**
- TN_324 lb 24 (two levels away);
- TN_684 lb 25: about 3x the 39 000 s that lb 24 took, so far beyond 12 h. No run was started for it.

`summary.md` (from `runner/summ_push.py`) lists every run with its time to each lb and the node counts of its last level. `logs.tgz` holds the full solver output.

## push3: 24-36 h runs (started 2026-11-07)

`push3/` holds two arms per code, each a different tree:
- C = main 755e0c21's default;
- E = main 1239e9a2 plus ungated erasure.

There are three exceptions:
- TN_684: E with `-seed=1` and `-seed=2`;
- COLOR_2791: C and C `-cc-roworder=bfs`;
- COLOR_1027: C and E `-cc-roworder=index`.

Limits: 36 h, except BB_1080 at 24 h. The logs in `push3/logs/` are an interim copy and are refreshed when the runs end.

Lower bounds reproduced so far (both arms, time to lb in s):

| Code | New stem | C | E |
|---|---|---:|---:|
| TN_360_4 | TN_360_4_24 (solved, d = 24; both runs print `o 24`) | 47 415 | 48 186 |
| TN_396_4 | TN_396_4_24to26 | 47 489 | 47 923 |
| TN_496_2 | TN_496_2_29to30 | 46 997 | 47 826 |
| TN_504_2 | TN_504_2_25to34 | 54 147 | 56 955 |
| TN_648_10 | TN_648_10_23to32 | 53 620 | 58 436 |
| BB_756_16 | BB_756_16_34 (solved, d = 34; both runs print `o 34`) | 59 834 | 65 917 |
| BB_864_4 | BB_864_4_34to40 | 58 134 | 64 158 |
| TN_324_4 | TN_324_4_24to25 | 72 074 | 72 807 |
| TN_540_4 | TN_540_4_25to34 | 57 564 | 63 505 |
| TN_648_14 | TN_648_14_23to28 | 70 302 | 63 576 |
| COLOR_1027_1 | COLOR_1027_1_33to37 | 78 893 | E index 77 146 |
| COLOR_2791_1 | COLOR_2791_1_30to61 | 42 701 | C bfs 79 340 |
