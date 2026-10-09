# GH-89 Tier3 plan (preregistered before any Tier3 timing) — same protocol as GH-85 TIER3_PLAN.md
Server yfclab2 (2x EPYC 7742), runner tier3_server.py (copied unchanged from GH-85, 3ec1ffc), cwd ~/mac-agent-20261009/tier3-gh85
(same matrices as GH-85 Tier3; input sha256 recorded per run). Starts only after GH-85 Tier3 has finished all 14 case-modes.
Binaries: base 72d1fe1 `frozen/tier3/base` (b943c2c9…), GH-85 `frozen/tier3/cand` (beb1b72d…), GH-89 `frozen/gh89/cand` (f3ce5b7e…, src 09d8bc2).
Cases (d): BB_144_12_12 (12), GB_144_12_12 (12), BB_144_14_14 (14), LP_442_68_10 (10), LP_544_80_12 (12), TN_144_2_13 (13), TN_250_10_15 (15); modes no-card, card-mto.
- Gate: base 72d1fe1 vs GH-89, 14 workers on NUMA node 0 physical cores 0,2,4,...,26 (SMT siblings idle).
- Attribution (informational): GH-85 vs GH-89, 14 workers on node 0 physical cores 32,34,...,58.
Each worker: AB/BA/AB 3+3 pinned with taskset, limit 1800 s, watchdog 1830 s, idle guards as GH-85.
PASS rule (gate, same as GH-85): no science problem; in every case/mode candidate median <= baseline median and no
non-overlapping regression; candidate never times out where baseline completes all 3; per-mode geomean < 1 (timeouts censored at the limit).
Results: ~/mac-agent-20261009/results/tier3-gh89/{gate,attr}/<case>.<mode>/.
Note: the INCONCLUSIVE retests run concurrently on node 1 CPUs 64-77 (separate socket).
