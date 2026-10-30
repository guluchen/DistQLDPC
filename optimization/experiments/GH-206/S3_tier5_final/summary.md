# GH-206 Tier 5 confirmation: final binary fca5d3c, one probe per half (the default), 6 h, default seed

Setup:
- yfclab2 cores 24-35, 37-39, 41-43, one process per pinned core, 4 GB cap.
- References run in the same session from the same binary: tb = `-cc-rules=excl,pack,orbf,parity,leaf,overlap,tiebreak`; tbmrvbfs = tb + `mrv` + `-cc-roworder=bfs`.
- auto = tb rules + `-cc-roworder=auto`.

| Code | Reference | auto | Probe decisions (half: level -> choice) |
|---|---|---|---|
| BB_756_16_30to34 | tbmrvbfs: lb 32 @ 11952 s | lb 32 @ 12032 s (1.007) | X: 18 -> B |
| BB_864_4_30to40 | tbmrvbfs: lb 32 @ 11473 s | lb 32 @ 11539 s (1.006) | X: 18 -> B |
| BB_1080_4_30to48 | tbmrvbfs: lb 32 @ 8745 s | lb 32 @ 8949 s (1.023) | X: 18 -> B |
| TN_496_2_23to30 | tbmrvbfs: lb 24 @ 12224 s | lb 24 @ 12308 s (1.007) | X: 12 -> B |
| TN_252_2_21 | tb: d=21 @ 11477 s | d=21 @ 11376 s (0.991) | Z: 12 -> A, X: 12 -> A |
| TN_288_2_22to24 | tb: lb 22 @ 20645 s | lb 22 @ 20344 s (0.985) | Z: 12 -> A, X: 12 -> A |
| TN_216_4_18 | tb: d=18 @ 661 s | d=18 @ 426 s (0.644) | X: 11 -> B, Z: 12 -> A |
| TN_180_2_17 | tb: d=17 @ 235 s | d=17 @ 176 s | X: 11 -> A, Z: 12 -> A |
| BB_360_12_24 | - | d=24 @ 34 s | X: 16 -> B |
| LP_1020 / 1054 / 1122 / 1428 / 1768 / 2610 | see `../S2_tier5_growth30/lp_ref_core34.txt` | 0.3 / 1.9 / 5.2 / 125.0 / 16.5 / 5.0 s | all A |

Notes:
- **Node identity.** At the largest common level, auto's node counts equal those of the configuration it chose, on every code: BB L30, TN_252 L20, TN_180 L16, the LP levels.
- **TN_180.** auto runs exactly tb's search there, so its time difference vs tb (176 vs 235 s) is core-to-core speed variance.
- **LP.** auto runs tb's search on every LP code. Back to back on one clean core it costs tb + 0.2-0.5 s: LP_1428 124.2 vs 124.0 s, LP_1768 16.2 vs 15.9 s.

Answers, the cross-check and the final binary's unit and flag tests all agree: CC_ENGINE_TESTS PASS, CC_FLAG_TESTS PASS.
