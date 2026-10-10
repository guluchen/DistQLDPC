# GH-92 vs main 7eadd54 on Tier3 codes without a dual map (coordinator, Mac, 2026-10-11)
`-v -cpu-lim=30`, frozen-main7e vs frozen92/cand, comparison after dropping the `dualskip` report line and normalising detect_cpu.
LP_442_68_10, LP_544_80_12, TN_144_2_13, TN_250_10_15 x no-card/card-mto: 8/8 IDENTICAL (266-454 lines each).
=> On these Tier3 cells GH-92's search equals main's; their Tier3 timing equals main by construction.
