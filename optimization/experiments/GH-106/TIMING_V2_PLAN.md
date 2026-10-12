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
