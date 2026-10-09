# GH-85 attribution head-to-head vs GH-73 (informational, same Mac session, 3+3 AB/BA/AB)
"Baseline" = GH-73 (split only), "candidate" = GH-85 (split + per-half symmetry breaking). All 60 solves correct.
| Case | OFF ratio | MTO ratio |
|---|---:|---:|
| BB_90_8_10 | 0.176 | 0.093 |
| GB_144_12_8 | 0.328 | 0.235 |
| BB_108_8_10 | 0.265 | 0.434 |
| LP_238_44_6 | 0.738 | 0.681 |
| geomean | 0.326 | 0.283 |
| LP_340_56_8 | 0.461 | 0.479 |
No regression flag. The symmetry breaking alone contributes ~3x (Tier1 cases) and ~2.1x (LP340) on top of the
split, consistent with the separate-run estimate (review MINOR 3 resolved).
