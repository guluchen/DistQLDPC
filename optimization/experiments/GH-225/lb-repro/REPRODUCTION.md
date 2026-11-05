# GH-225 lower-bound reproduction (2026-11-05/06)

The GH-225 Tier 5 runs (#225; records on branch `experiment/gh-225-cc-erasure-default`, `optimization/experiments/GH-225/`)
and the GH-227 open-code runs (#227, PR #229, `optimization/experiments/GH-227/tier5{a,b}/`) raised seven tier5 lower
bounds above their stems in single 6 h runs. This directory holds the reproduction runs and the comparison.

- Binary: main 1239e9a2 built on yfclab2 (`frozen/server-gh225lb-main-1239e9a`, sha256 f939bbb2...).
- Arms (12 h = 43 200 s each, one pinned core per run, 4 GB cap, idle check of the core and its SMT sibling before each launch):
  `E.s1` / `E.s2` = CC default plus `erasure` (ungated on this binary) with relabelled qubits and rows (`-seed=1`, `-seed=2`);
  `E.bfs` = the same rules with `-cc-roworder=bfs`; `A.s1` = the CC default without erasure, `-seed=1`;
  `E.idx` (COLOR_1027 only, `repro2/`) = erasure with `-cc-roworder=index`. It turned out to search the same tree as the
  GH-225 erasure run and was stopped after 42 721 s (rc -15), after it had reached lb 32.
- yfclab2 logical CPUs 64-95 (runner: `runner/gh225lb_queue.py`, a copy of the GH-225 runner with the core range changed).
- `analysis.md` (from `runner/analyze_lb.py`): time to each lb per run and whether each search tree differs from the
  original single runs (node counts per half and level). `orig/` holds the GH-225 results used for that comparison.
- `logs.tgz`: full solver output of every run. Every lb used for a rename has its last level EMPTY on both halves (X half
  only where a verified XZ-dual map is in use: TN_496 and the color codes).

A lower bound is used for a rename only when at least two runs with different search trees reached it (different seed,
row order, or binary and rule set). This is the same CC engine, not an independent second method.

| Code | Claimed (single run) | Renamed lb | Runs reaching it with different trees |
|---|---:|---:|---|
| TN_324_4 | 23 | 23 | GH-225 E 20 985 s; E.s1 30 309 s; E.s2 31 369 s |
| TN_496_2 | 28 | 28 | GH-225 E 17 996 s; GH-227 C 19 683 s; E.s1 20 699 s; E.s2 19 095 s; A.s1 24 919 s |
| TN_540_4 | 24 | 24 | GH-225 E 19 168 s; GH-227 C 18 399 s; E.s1 35 026 s; E.s2 32 893 s; A.s1 42 322 s |
| TN_648_14 | 22 | 22 | GH-225 E 20 292 s; GH-227 C 19 331 s; E.s1 35 385 s; E.s2 36 573 s; A.s1 36 164 s |
| COLOR_1027_1 | 31 | 31 | GH-225 E 16 090 s; GH-227 C 18 190 s; E.bfs 33 206 s |
| TN_684_2 | 23 | 24 | lb 24: E.s1 39 232 s; E.s2 39 063 s (lb 23: all GH-225 / GH-227 arms and E.s1, E.s2, A.s1) |
| COLOR_2791_1 | 28 / 29 | 28 | GH-225 A 10 312 s (same tree as GH-227 M 11 706 s); GH-227 C 9 612 s |

Still PLAUSIBLE (single tree): COLOR_1027 lb 32 (E.idx, same tree as GH-225 E), COLOR_2791 lb 29 (GH-227 C, 20 721 s).
Two COLOR_2791 runs on main 755e0c21 (`-cc-roworder=bfs` and `-cc-roworder=index`, 12 h, CPUs 65-66) were started on
2026-11-06 to check lb 29; they are not part of this record.
