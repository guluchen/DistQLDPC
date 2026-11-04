# GH-224: parent wait loop without the 10 ms polling floor

Change: `solve_in_child_fork` (`src/core/distqldpc.cc`) used to wait for the solver child with `usleep(10000)` between checks. It now waits in `poll()` on the bounds pipe and on a SIGCHLD self-pipe. The timeout is the remaining `-cpu-lim` time, capped at 100 ms. The solver child is unchanged.

Binaries (yfclab2, frozen): old = main fecee8c9 (`frozen/server-gh224-main-fecee8c`), new = 2587b9de (`frozen/server-gh224-2587b9d`).

## Tier 0
- `make test-cc`: PASS on yfclab2 (`raw/t0tests/test_cc_new.txt`) and on the Mac (`raw/t0tests/mac_test_cc.txt`). The output equals main's except one timing-dependent counter: partE "levels abandoned" is 37 on main and 38 on new. This test never calls the changed function.
- `make test-cc-flags`: 566 checks, 0 failed (server and Mac).
- `scripts/smoke_test.sh` and `scripts/test_partition_soft_literals.py`: pass.
- Behaviour (`raw/behaviour/behaviour.txt`), old vs new, with identical output lines:
  - `-cpu-lim=3` timeout, MaxSAT and CC: TIMEOUT at 3.03 s with the same bounds.
  - Tighter `prlimit --as` (200 MB MaxSAT, 60 MB CC): the same UNKNOWN.
  - Child killed from outside with SIGKILL: UNKNOWN within 6-8 ms.
  - Child SIGSTOP/SIGCONT: finishes normally.
- Answers: 9450 + 216 panel runs, all rc 0 and all equal to the stem distance.

## Tier 0 + Tier 1 panel (`raw/t01/`)
Setup:
- Layout of main fecee8c9: 26 tier0 and 9 tier1 codes.
- Modes: MaxSAT default (mto), MaxSAT `-no-card`, CC default.
- Seeds 0-4, 9 repetitions.
- old and new run interleaved on one pinned core per (code, mode, seed), with rotating order; cores 72-101 only, each with an idle SMT sibling.
- Cell = median over repetitions, then median over seeds. Ratio = new / old.

| Tier | Mode | cells | geomean | worst cell | cells > 1.25 |
|---|---|---:|---:|---|---:|
| 0 | cc | 26 | 0.666 | 0.964 | 0 |
| 0 | mto | 26 | 0.849 | 1.032 | 0 |
| 0 | nocard | 26 | 0.853 | 1.086 | 0 |
| 1 | cc | 9 | 0.879 | 0.995 | 0 |
| 1 | mto | 9 | 0.978 | 0.987 | 0 |
| 1 | nocard | 9 | 0.981 | 0.993 | 0 |

**Logs.** stdout is byte-identical in every run of both arms for 522 of 525 units. The other 3 (all GB_144_12_12 CC) differ only in the order of a `c d_ub` line relative to the level lines. That order is timing-dependent: main's own runs vary the same way.

**Floor.** Wait slack = wall - user - sys, over runs shorter than 0.2 s (about 3300 per arm):

| Arm | median | p90 |
|---|---:|---:|
| old | 11.9 ms | 16.2 ms |
| new | 4.8 ms | 7.8 ms |

Wall times of the CC cells, in 1 ms bins:
- old LP_442 splits into two groups, 27-31 ms and 34-44 ms;
- new LP_442 is one contiguous group, 25-33 ms;
- old BB_186 is spread over 28-60 ms;
- new BB_186 is 21-30 ms.

The MaxSAT cells of 1-10 s also run about 2 % faster in CPU time: the parent no longer wakes up 100 times a second on the solver's core.

## Tier 2/3 spot check (`raw/spot_analysis.md`)
Tiers 2-5 are unaffected by construction: the solver child and the deadline path are unchanged, and the parent wakes up less often. This was spot-checked, not run in full; there was no Tier 5 run.

Setup: 3 seeds x 3 repetitions, interleaved.
- Tier 2: LP_544, TN_108 and BB_144_14_14, in all three modes.
- Tier 3: TN_250, LP_1020 and HGP_481, CC only.

| Tier | geomean | worst cell |
|---|---:|---|
| 2 | 0.952 | 1.001 (TN_108 CC) |
| 3 | 0.959 | 1.002 (TN_250 CC, 50.6 s) |

Every answer is correct. The log differences are the same timing-dependent line-order cases.

Runners: `runner/interleave.py`, `runner/analyze.py` and `runner/behaviour.sh`.
