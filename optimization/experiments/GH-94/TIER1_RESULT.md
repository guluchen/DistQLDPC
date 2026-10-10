# GH-94 Tier1 + Tier2 result (coordinator) — POSITIVE vs main 7eadd54; vs GH-89 mixed (one non-overlapping regression)
Mac, timing lock (runs 11:32:07–11:33:34, after GH-95's trace batch released the lock), frozen94/cand 4a15a105…, all samples correct.
Caveat: on main the Tier1 cases take 0.03–0.47 s, so process start-up is a visible share; LP340 / Tier3 carry more weight now.
## Gate vs main 7eadd54 (frozen-main7e 6bdcaa25…)
| Case | OFF ratio | MTO ratio |
|---|---:|---:|
| BB_90_8_10 | 0.416 | 0.449 |
| GB_144_12_8 | 0.359 | 0.429 |
| BB_108_8_10 | 0.657 | 0.278 |
| LP_238_44_6 | 0.770 | 0.620 |
Geomean OFF 0.523 (env 0.536), MTO 0.426 (env 0.433); replication 0.522 / 0.422. POSITIVE both modes.
Tier2 LP_340_56_8 vs main: OFF 0.546, MTO 0.548 (no dual map: same as GH-89's gain over GH-85).
## Attribution vs GH-89 (frozen89, primary in PROPOSAL)
| Case | OFF | MTO |
|---|---:|---:|
| BB_90_8_10 | 0.590 | 0.512 |
| GB_144_12_8 | 0.446 | 0.416 |
| BB_108_8_10 | **1.588 (non-overlapping regression)** | 0.676 |
| LP_238_44_6 | 1.013 | 1.025 |
Geomean OFF 0.805, MTO 0.622; LP340 1.004 / 0.995 (identical search, no dual map).
## Attribution vs GH-92 (frozen92)
OFF 0.813, MTO 0.684 (BB_108 0.85/0.35, LP_238 0.77/0.63; BB_90/GB_144 MTO ~1.0 — those are already solved by the dual path in both).
## Reading
The triple stack gets GH-92's dual-map gains (BB_90, GB_144) and GH-89's incremental gains on LP, as hypothesised, except
BB_108 no-card: GH-94 0.24 s vs GH-89 0.15 s. There GH-89 profits from interleaving both halves (the second half supplies an
earlier upper bound), which dual-half elimination removes. Hypothesis to test next: keep both halves when the dual map is found
but share bounds (dX = dZ), i.e. use the dual map for bounds, not to drop a half. Not adopted until that is resolved; Tier3 not started.
