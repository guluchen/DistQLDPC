# GH-92 Tier1 + Tier2 result (coordinator) — POSITIVE vs 72d1fe1; vs GH-85 better exactly where a dual map exists
Mac, timing lock, tier1_mac_dist.py; frozen92/cand 49e37dee…; all samples correct (o = d, sound bounds), stopped None, no regression flags.
## Tier1 gate vs 72d1fe1 (frozen 3f2fbc42…)
| Case | OFF base | OFF cand | OFF ratio | MTO base | MTO cand | MTO ratio |
|---|---:|---:|---:|---:|---:|---:|
| BB_90_8_10 | 1.848 | 0.092 | 0.0498 | 1.652 | 0.063 | 0.0381 |
| GB_144_12_8 | 0.663 | 0.033 | 0.0498 | 1.119 | 0.032 | 0.0286 |
| BB_108_8_10 | 2.291 | 0.288 | 0.1257 | 2.334 | 0.385 | 0.1650 |
| LP_238_44_6 | 1.205 | 0.406 | 0.3369 | 1.147 | 0.395 | 0.3444 |
Gate geomean OFF 0.1008 (env 0.1019), MTO 0.0889 (env 0.0939); replication 0.0995 / 0.0891. POSITIVE both modes.
## Attribution vs GH-85 (frozen85/cand 1c6f028a…), preregistered primary comparison
| Case | OFF ratio | MTO ratio | dual map |
|---|---:|---:|---|
| BB_90_8_10 | 0.6118 | 0.5547 | yes |
| GB_144_12_8 | 0.3333 | 0.4231 | yes |
| BB_108_8_10 | 0.7890 | 0.8305 | yes |
| LP_238_44_6 | 1.0075 | 0.9725 | no (same search as GH-85) |
Geomean OFF 0.637, MTO 0.659. The judge marks OFF "not positive" only because LP_238 (identical search) has median 1.0075; that cell is noise by construction.
## Tier2 LP_340_56_8 (600/615 s)
vs 72d1fe1: OFF 0.0181 (85.47 -> 1.55 s), MTO 0.0274. vs GH-85: OFF 1.0013, MTO 0.9982 (no dual map: identical search, as predicted). Tier2 PASS (local).
## Reading
Hypothesis confirmed: dual-half elimination composes with per-half symmetry breaking on BB/GB, neutral on LP.
GH-89 (incremental) and GH-92 (dual) help different cells vs GH-85: GH-89 is strongest on BB_108 (0.40) and LP (0.55-0.77),
GH-92 on GB (0.33-0.42) and BB_90 (0.55-0.61). A triple stack GH-85 + GH-76 + GH-87 is the natural next test.
