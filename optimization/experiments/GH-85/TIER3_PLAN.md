# GH-85 Tier3 plan (preregistered before any Tier3 run)
PI decision 2026-10-09: "我們先跑完tier 3如果過了 我們把它設為預設" (run Tier3; if it passes, make GH-85 the default).
Host: PI's dedicated server yfclab2 (2x AMD EPYC 7742, 256 logical CPUs, SMT siblings i/i+128, Ubuntu 24.04,
GCC 13.3). Binaries built on the server from pinned commits, frozen read-only:
- baseline 72d1fe1 (corrected): ~/mac-agent-20261009/frozen/tier3/base/distqldpc b943c2c94d675745…
- candidate GH-85 src cc7e5ea: ~/mac-agent-20261009/frozen/tier3/cand/distqldpc beb1b72dcbbda2e5…
Cases (policy Tier3 set) and named distances: BB_144_12_12 (12), GB_144_12_12 (12), BB_144_14_14 (14),
LP_442_68_10 (10), LP_544_80_12 (12), TN_144_2_13 (13), TN_250_10_15 (15); modes -no-card and -card-mto.
Per case/mode: baseline 3 + candidate 3, AB/BA/AB, serially on ONE pinned logical CPU (taskset), its SMT sibling
left unused; the 14 case/mode workers run concurrently on distinct physical cores of NUMA node 1
(CPUs 64,65,67,68,70,71,73,74,77,78,79,80,82,86; siblings +128 idle at selection). Internal limit 1800 s,
watchdog 1830 s. Before each run: global idle > 50% and pinned CPU idle > 80% (wait up to 10 min, else stop);
telemetry every 5 s (global, pinned CPU, sibling). Other agents' server work is restricted to NUMA node 0.
No exclusive reservation exists (other users' processes may migrate): contention is recorded and reported.
Science (stop on violation): rc 0 and o == named distance, or TIMEOUT with every emitted d_lb <= d <= d_ub.
Decision rule (fixed now): per case/mode, timeouts are censored at the limit (never treated as solves).
PASS requires: (i) no science problem; (ii) in every case/mode the candidate median <= baseline median and no
non-overlapping regression; (iii) candidate never times out where the baseline completes in all 3 runs;
(iv) per-mode geometric mean of median ratios < 1. Censored baseline medians make the reported speedups lower
bounds. Any regression that is non-overlapping in a case/mode => Tier3 FAIL (reported, not hidden).
Single attempt; resource-guard stops are reported as INCONCLUSIVE for that case/mode, not retried silently.
