# GH-106 v2 timing + answer plan (coordinator, preregistered 2026-10-12, before any v2 timing)
PI 2026-10-12: run GH-106 v2 entirely on the Mac; compare speed and correctness against the RECORDED Mac main baseline
(optimization/baselines/main_mac_reference.json on main); where main has no record, run main and record it first.
Candidate: frozen106/v2/distqldpc (b3f4e3e4…, -inc-policy=budgettot K=3 default). Baseline binary: frozen-main7e (6bdcaa25…).
Runner: tier_cached_mac.py (3 candidate runs + 1 main drift sample per cell; drift > 3% outside the recorded range => that
cell is re-run as a full AB/BA/AB comparison) with stem-based answer checks on every run (solved d and all emitted lb/ub
must agree with the stem's d / {lb}to{ub} / ge{lb}); 2 GB cap; matrices passed by resolved path; run from a main checkout
(a3fe591, tier directories). This replaces the separate 60 s science sweep (PI: "比速度的時候可以順便比答案").
Order: (0) record main tier0 (3 serial runs, limit 600 s); (1) tier0 cached comparison; (2) tier1-tier3 (limit 1800 s);
(3) tier4 (limit 2000 s); (4) tier5 (limit 21600 s) — schedule to be decided with the PI (main record + candidate on 25 codes
x 2 modes at up to 6 h each is ~100 h serial on the Mac).
Pass rule per tier (GH-85 rule adapted to cached baselines): no answer inconsistency; every cell candidate median <= recorded
main median with no non-overlapping regression (candidate min > recorded max); per-mode geomean < 1; DRIFT cells re-run in full.

Addendum (PI 2026-10-12, before any tier5 run): tier5 runs on yfclab2 once it is reachable — main and GH-106 v2 on all
25 tier5 codes x 2 modes = 100 processes AT ONCE (one pinned physical core each, 2 GB cap via prlimit, 21600 s wall limit),
runner tier5_server.py. On the Mac the same work would take ~4 days, so the Mac does tier0-tier4 only. The server tier5 run
also records main's tier5 baseline (separate server table). Comparison per cell: time to result when both solve; otherwise
bounds reached at the limit (a candidate is worse if it proves a weaker final bound than main in a cell).

Addendum 2 (PI 2026-10-12, before any server run): server tasks use a 4 GB memory cap (server usage rule), not 2 GB; tier5_server.py updated.
