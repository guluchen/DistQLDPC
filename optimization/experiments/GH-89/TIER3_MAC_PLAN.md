# GH-89 Tier3-equivalent on the Mac (preregistered before timing) — replaces the lost yfclab2 run
PI 2026-10-10: yfclab2 is down until Monday; "從最有可能有效的開始跑 ... 之前的只能在mac跑". The yfclab2 Tier3 (TIER3_PLAN.md,
started after GH-85's) could not be collected (server unreachable). This is a Mac substitute, a disclosed deviation from the
policy's dedicated-server Tier3.
- Host: Mac (Apple M6, 12 CPUs), one solve at a time, timing lock taken per case (released between cases so other agents'
  correctness batches can run in the gaps). Runner tier1_mac_dist.py with memlimit.py (2 GB per-process cap, PI rule).
- Baseline: current main 7eadd54 (frozen-main7e 6bdcaa25…) — the policy baseline since PR #90. Candidate: frozen89/cand (fb6846d0…).
- Cases (d): BB_144_12_12 (12), GB_144_12_12 (12), BB_144_14_14 (14), LP_442_68_10 (10), LP_544_80_12 (12), TN_144_2_13 (13);
  modes no-card, card-mto; AB/BA/AB 3+3; limit 1800 s, watchdog 1815 s. TN_250_10_15 omitted (both main/GH-85 and the old
  baseline time out at 1800 s on yfclab2; 6 h of censored runs) — to be run on yfclab2 later.
- PASS rule = GH-85 TIER3_PLAN rule: no science problem; every case/mode candidate median <= baseline median with no
  non-overlapping regression; no candidate timeout where the baseline completes all 3; per-mode geomean < 1; timeouts censored.

PI approval (2026-10-10): "第四項在mac跑沒關係，這是特殊情況" — Mac Tier3-equivalent explicitly approved as a special case.
