# GH-107 re-evaluation under the 2026-10-12 tiers — PASS on tiers 0-5 (coordinator, 2026-10-13)
Candidate frozen107/cand (68338e32…; server build 1155f098…). Main baseline: recorded Mac table / main's 2026-10-12 server tier5 run.
GH-107 changes only codes with a verified XZ-dual map; non-dual codes are search-identical (re-checked on the new layout:
TN_108_2_12 and LP_442_68_10, both modes, -v traces identical, raw/eval-v2b/identity).
Mac (raw/eval-v2b; caffeinate, serial, 2 GB; tiers 1-4 ran 21:58-23:10 with no pmset sleep event after 21:48):
| Tier | Case | no-card | card-mto |
|---|---|---:|---:|
| 0 | BB_72_12_6 / BB_90_8_10 / GB_144_12_8 / TN_36_8_4 | 0.86 / 0.61 / 0.71 / 0.87 | 0.86 / 0.47 / 0.68 / 0.87 |
| 1 | BB_108_8_10 | 0.805 | 0.818 |
| 1 | BB_144_12_12 | 0.496 | 0.474 |
| 3 | BB_144_14_14 | 0.615 | 0.542 |
| 3 | GB_144_12_12 | 0.910 | 0.953 |
| 4 | BB_288_12_18 | 0.491 (617.7 -> 303.5 s) | 0.532 (707.9 -> 376.9 s) |
All answers consistent with the stems; no non-overlapping regression; no drift outside the recorded range on tiers 1-4
(drift flags only on sub-0.2 s tier0 cells, which gate on correctness only).
yfclab2 tier5 (dual-map BB codes, 6 h): identical final bounds to main in all 8 cells (BB_360 17/24; BB_756, BB_864, BB_1080 lb 17).
Verdict: PASS on tiers 0-5 under the current policy => eligible to replace main (PI decision). After a merge, main's tier0-5
times must be re-recorded (PI 2026-10-13) and tier placement re-checked.
Note: the first Mac attempt (raw/eval-v2-INVALID-mac-slept) is void (system sleep).
