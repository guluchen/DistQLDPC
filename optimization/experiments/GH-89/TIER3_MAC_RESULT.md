# GH-89 Mac Tier3-equivalent vs main 7eadd54 — FAIL (5 non-overlapping regressions), geomean 0.816 / 0.892
Mac, per-case timing lock, 2 GB cap, frozen-main7e (6bdcaa25…) vs frozen89/cand (fb6846d0…), 3+3, limit 1800 s.
All 72 runs completed with o = d; no timeouts, no MEMOUT.
| Case | no-card base -> cand (s) | ratio | card-mto base -> cand (s) | ratio |
|---|---|---:|---|---:|
| BB_144_12_12 | 0.5 -> 0.6 | **1.114 (reg)** | 1.2 -> 0.7 | 0.588 |
| GB_144_12_12 | 66.6 -> 57.6 | 0.865 | 107.5 -> 48.2 | 0.449 |
| BB_144_14_14 | 49.0 -> 57.6 | **1.175 (reg)** | 51.7 -> 51.0 | 0.986 |
| LP_442_68_10 | 32.8 -> 13.9 | 0.425 | 20.8 -> 36.5 | **1.756 (reg)** |
| LP_544_80_12 | 225.4 -> 42.9 | 0.190 | 55.6 -> 75.1 | **1.350 (reg)** |
| TN_144_2_13 | 71.7 -> 231.1 | **3.225 (reg)** | 160.7 -> 131.3 | 0.817 |
Per-mode geomean: no-card 0.816, card-mto 0.892. TN_250_10_15 not run (see plan).
Verdict under the GH-85 rule: FAIL (non-overlapping regressions in 5 of 12 cells). The incremental half solver gives very
large wins (LP_544 no-card 5.3x, LP_442 no-card 2.4x, GB_144_12_12 MTO 2.2x) and large losses (TN_144 no-card 3.2x) —
behaviour is case-dependent, i.e. carried-over solver state changes trajectories. Diagnosis/fix: issue #106.
Disclosures: (1) GH-103's profiling script attached `sample` for ~3 s to one GH-89 child in the GB_144_12_12 cell (~22:59, 10-10);
(2) GH-102/GH-92/GH-103 timing interleaved between cases (never concurrently: per-case lock).
