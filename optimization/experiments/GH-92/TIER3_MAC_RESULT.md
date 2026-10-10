# GH-92 Mac Tier3-equivalent vs main 7eadd54 (dual-map cases) — FAIL (GB_144_12_12 no-card 1.95x)
Mac, per-case timing lock, 2 GB cap, frozen-main7e vs frozen92/cand (49e37dee…), 3+3, limit 1800 s; all runs correct.
| Case | no-card base -> cand (s) | ratio | card-mto base -> cand (s) | ratio |
|---|---|---:|---|---:|
| BB_144_12_12 | 0.5 -> 0.3 | 0.529 | 1.2 -> 0.6 | 0.498 |
| GB_144_12_12 | 72.6 -> 141.3 | **1.946 (non-overlapping regression)** | 114.6 -> 55.3 | 0.483 |
| BB_144_14_14 | 53.4 -> 34.7 | 0.649 | 56.5 -> 25.8 | 0.456 |
Non-dual Tier3 codes: search identical to main (raw/nondual-identity, 8/8). Verdict: FAIL under the GH-85 rule.
Reading: dual-half elimination always solves the X half; on GB_144_12_12 no-card the X half is much harder to search than
the Z half (main, which interleaves both, finishes in 72 s; X alone needs 141 s), although dX = dZ. GH-102 (both halves +
shared bounds, but with the incremental solver) had the opposite cell (MTO) regress. Next: main + dual-map bound sharing
without the incremental solver (race both halves, any half's LB is global) — issue #107.
