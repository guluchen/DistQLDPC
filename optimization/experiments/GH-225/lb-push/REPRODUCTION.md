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
| COLOR_2791_1 | 29 | 755e0c21 default (GH-227 C, 6 h) 20 721, and with `-cc-roworder=index` 20 425; 755e0c21 `-cc-roworder=bfs` 37 963 |

**Still PLAUSIBLE (one tree): BB_1080 lb 34.**
- 755e0c21 s0 reached it at 40 586 s, with levels up to 32 EMPTY (X half under the verified dual map; odd levels skipped by parity).
- The 1239e9a2 E run reached only lb 32 in 12 h.
- Reproducing it needs a run longer than 12 h, or a faster different order.

**Not reached in 12 h:**
- TN_324 lb 24 (two levels away);
- TN_684 lb 25: about 3x the 39 000 s that lb 24 took, so far beyond 12 h. No run was started for it.

`summary.md` (from `runner/summ_push.py`) lists every run with its time to each lb and the node counts of its last level. `logs.tgz` holds the full solver output.
