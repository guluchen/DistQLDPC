# GH-181 cross-check of TN_496_2_23to30 lb 27 (coordinator request, 2026-10-30)

yfclab2, cores 4-9 (one pinned process per core, 4 GB cap), `-cpu-lim=28800` (8 h) each, started 2026-10-29 21:46 UTC.
Configurations deliberately differ from the run that found lb 27 (`sparse,sparseov,sparsemrv`, seeds 0/1/2, binary server-gh181-07b5e3d):

| Run | Binary | Rules (on top of excl,pack,orbf,parity,leaf,overlap) | Seed | Final lb | Levels proved | lb events (value@s, from 23) |
|---|---|---|---:|---:|---|---|
| (a) | server-gh181-9b237b0 | sparse | 3 | 25 | 1-24 EMPTY | 23@2627 24@7177 25@22347 |
| (a) | server-gh181-9b237b0 | sparse | 4 | 25 | 1-24 EMPTY | 23@2268 24@6246 25@18253 |
| (b) | server-gh181tb-5194646 (scratch merge with GH-162 tiebreak 97c86299) | sparse,sparseov,sparsemrv,tiebreak | 0 | **27** | 1-26 EMPTY | 23@268 24@748 25@1886 26@4655 27@11864 |
| (b) | server-gh181tb-5194646 | sparse,sparseov,sparsemrv,tiebreak | 3 | **27** | 1-26 EMPTY | 23@242 24@658 25@1721 26@4300 27@10739 |
| extra | server-gh181-9b237b0 | sparse,sparsemrv (no sparseov) | 3 | 26 | 1-25 EMPTY | 23@657 24@1823 25@4831 26@13089 |
| extra | server-gh181-9b237b0 | sparse,sparsemrv (no sparseov) | 4 | 26 | 1-25 EMPTY | 23@649 24@1815 25@4787 26@13042 |

Every level is X half (verified XZ-dual map; Z mirrored), contiguous from 1; no FOUND, INCONSISTENT, TRAP or error line;
runner science check ok on all 6 runs; upper bound 30 everywhere. (c) MaxSAT path started at level 23: skipped, no such entry
point exists (no lower-bound / start-cap flag; the dumps only give the full optimisation instance).

Verdict (coordinator criterion: an independent configuration reaches 27 with every level EMPTY): **REPRODUCED** by (b), seeds
0 and 3. (a) and the extra arm did not reach 27 within 8 h but are consistent (every completed level EMPTY). Caveat: all runs are
DistQLDPC's CC engine (same level framework and driver); (b) differs in binary, overlap rule (tiebreak) and search order. No stem
renamed; PI decides.

The server was heavily loaded (load average up to ~190 from other users' unpinned jobs) and sshd reset some connections; runs
were unaffected (all reached the 28800 s limit, rc 1 = time limit).
