# GH-102 Tier1/Tier2 result (coordinator) — POSITIVE vs main; dominates GH-89 (no regression)
Mac, timing lock, 2 GB cap, frozen102/cand (e1801a58…), all samples correct.
| Case | vs main OFF / MTO | vs GH-89 OFF / MTO | vs GH-94 OFF / MTO |
|---|---|---|---|
| BB_90_8_10 | 0.407 / 0.467 | 0.589 / 0.512 | 1.016 / 1.000 |
| GB_144_12_8 | 0.677 / 0.627 | 0.808 / 0.615 | **1.909 / 1.455** (0.033 -> 0.063 s / 0.048 s) |
| BB_108_8_10 | 0.204 / 0.201 | 0.576 / 0.511 | 0.303 / 0.699 |
| LP_238_44_6 | 0.775 / 0.606 | 0.997 / 0.988 | 0.987 / 1.004 |
| geomean | **0.456 / 0.435** (repl 0.463 / 0.431) | **0.722 / 0.631** | 0.873 / 1.005 |
Tier2 LP_340_56_8 vs main: 0.547 / 0.541 (no dual map; = GH-89).
Reading: bound sharing keeps GH-94's dual-map gains on BB_90 and removes GH-94's BB_108 regression (vs GH-89 every cell
improves or ties; LP identical by construction). vs GH-94 the only loss is GB_144_12_8, where the Z half still pays one
guaranteed-SAT probe (0.03 s absolute). Next: Tier3-equivalent on the Mac for the dual-map cases (BB_144_12_12, GB_144_12_12,
BB_144_14_14); on LP/TN codes without a dual map GH-102 runs GH-89's search, so GH-89's Mac Tier3 covers them
(note: GH-89 interim shows LP_442_68_10 card-mto 1.76x slower than main — inherited by GH-102 on LP codes).
