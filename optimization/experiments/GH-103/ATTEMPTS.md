# GH-103 attempts — kept and reverted changes (agent measurements)

Mac (12 CPUs), `sample` at 1 ms on the solving child for 60 s, full solve under the 2 GB cap, each round
under the Mac timing lock (r1gb 23:10-23:17, r1lp 00:25-00:30, r2 00:41-00:52, r3 01:21-01:30). Both cases
complete (GB_144_12_12 no-card d=12, LP_544_80_12 card-mto d=12), and every build is search-identical
(quick trace check 13/13 per build), so the child's user CPU for the whole solve is directly comparable.
`user` includes the 1 ms sampling overhead, the same for every build. Function counts are self samples
(leaf attribution of the call graph, `scripts/leaf.py`); full tables in `raw/fntab.md`, profiles in
`raw/profiles.tar.gz`.

Builds: base = GH-95 `b3f40b4` (`__text` identical to frozen95); c1 = +C1; c2 = +C1+C2; c4-enq = +C1+C2+C4;
c3-ins = c4-enq+C3; c6-hoist = c3-ins+C6; c4only = base+C4; **c14 = base+C1+C4 = final candidate**.

## Whole-solve user CPU (s)

| build | GB_144_12_12 no-card | LP_544_80_12 card-mto |
|---|---|---|
| base | 65.57, 65.49, 65.46, 65.51 (mean 65.51) | 51.16, 51.14, 51.00, 50.98 (mean 51.07) |
| c1 (C1) | 66.42, 66.37 (**+1.4%**) | 50.70, 50.67 (-0.7%) |
| c2 (C1+C2) | 65.36 | 50.91 |
| c4-enq (C1+C2+C4) | 64.74 | 49.81 |
| c3-ins (+C3) | 65.64 | - |
| c6-hoist (+C3+C6) | 65.42 | 49.64 |
| c4only (C4) | 64.75, 64.93 (-1.0%) | 49.93, 49.90 (-2.3%) |
| **c14 (C1+C4)** | 64.37, 64.47, 64.37 (**-1.7%**) | 49.43, 49.46, 49.42 (**-3.2%**) |

Spread of repeated runs of the same binary: <= 0.3%.

## Per change

**C1 keyed heap — KEPT.** pickAuxiVar self samples -10..-13% (GB 2553/2520/2486 -> 2217-2414 in c14 builds;
LP 3751/3709/3696 -> 3282/3333/3431), heap insert +5..+10% (16-byte slots), resetConflicts/bumpConflVars
unchanged. Alone on GB_144 it is +1.4% (propagateForLK self samples +2%, unchanged code: code/data layout);
on top of C4 it is -0.6% (GB) and -1.0% (LP) versus c4only, so it is kept in the combination only.

**C2 bottom-up removeMin — REVERTED** (commit 87f7d71). No gain over C1 (GB pick ~2300 vs 2217; LP ~3370 vs
3265). activityLB is 0 for most variables, so the standard percolateDown usually stops after one level on a
tie, while the bottom-up variant always walks to a leaf.

**C4 uncheckedEnqueueForLK soft test `softLits[v] == ~p`, soft branch out of line — KEPT.** The fast path
becomes a leaf and is inlined into propagateForLK: uncheckedEnqueueForLK's 1000-1270 self samples disappear,
propagateForLK grows by only ~150-600, falsifiedSoftVarForLK costs 80-230. Whole solve -1.0% (GB) / -2.3% (LP).

**C3 insertAuxiVarOrder single branch, pre-sized index — REVERTED** (commit b415af2). No change in
lookbackResetTrail (GB 3363 -> 3358) or heap insert (665 -> 674); c3-ins whole solve +1.4% vs c4-enq on GB
(within the layout noise seen for C1, no gain).

**C6 lookbackResetTrail loop invariants in locals — REVERTED** (commit f3da1c9). lookbackResetTrail
unchanged (GB 3358 -> 3362, LP 4045 -> 3969 with C3+C6 together), whole solve within 0.3%.

## Why lookbackResetTrail did not move

Instrumented copy (counters only, not committed; 25 s): LP_544 card-mto walks 183 trail entries per
lookbackResetTrail call (40 seen, 48 non-seen auxiliary, 31 reinserted); GB_144 45 entries (14 seen, 10
non-seen auxiliary, 6 reinserted). pickAuxiVar pops 0.94-0.96 heap entries per call (25% (LP) and 37% (GB) of pops are
assigned/locked variables that are discarded and later reinserted). The walk is the touched range only and
every step (unassign, conditional ordered reinsert) is needed for an identical heap; with all arrays
L1-resident the remaining cost is the data-dependent branches, which C3/C6 do not remove.
