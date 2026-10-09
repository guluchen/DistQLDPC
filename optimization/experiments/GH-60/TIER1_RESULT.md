# GH-60 Tier1 result — REJECT (general filter): large but mixed, search-path-driven effects

Frozen binaries baseline ac43af52… / candidate 225e5423… (re-verified after); inputs
re-verified; one solve at a time, 1-min load 1.2–1.71. Diagnostic Mac host, not controlled.

Attempt tier1-01 (standard runner) stopped after 54 correct solves because the candidate's
emitted upper-bound trajectory differs (e.g. GB144 OFF d_ub 15,12,11,10,9,8 vs
15,14,13,12,9,8; same final d=8). This was anticipated in TIER1_RUN.md; per that
preregistered rule the run was restarted once with `tier1_mac_dist.py` (rc 0, named
distance, every d_lb <= d <= every d_ub). Both kept: `raw/tier1-01-STOP-line-identity`,
`raw/tier1-02`.

Science (tier1-02): 208/208 rc 0, named distance, sound emitted bounds.

| Case | OFF median b -> c (s) | OFF ratio | MTO median b -> c (s) | MTO ratio |
|---|---|---:|---|---:|
| BB_90_8_10 | 1.876 -> 1.478 | 0.7876 | 1.664 -> 1.608 | 0.9667 |
| GB_144_12_8 | 0.664 -> 0.960 | **1.4459** | 1.118 -> 0.765 | 0.6844 |
| BB_108_8_10 | 2.287 -> 2.002 | 0.8752 | 2.337 -> 2.036 | 0.8709 |
| LP_238_44_6 | 1.200 -> 0.938 | 0.7814 | 1.145 -> 1.760 | **1.5367** |
| geomean / envelope | | 0.9394 / 0.9475 | | 0.9701 / 0.9753 |

All 16 gate cells are non-overlapping (6 improvements, 2 regressions), and the 10-pair
replication reproduces every direction and magnitude within ~1%. Fixed GH16 judge: not
positive in either mode, regression flags GB144 OFF and LP238 MTO. Policy: confirmed
regressions reject and stop advancement => **REJECT for the general filter, no Tier2**.

## Why (search statistics, `raw/tier1-02/searchstats.*`)
| Cell | Lookaheads b -> c | Lookahead propagations per lookahead b -> c |
|---|---|---|
| GB144 OFF (slower) | 16,678 -> 23,469 | 788 -> 691 (-12%) |
| LP238 MTO (slower) | 13,147 -> 17,471 | 1,478 -> 1,331 (-10%) |
| BB90 OFF (faster) | 55,629 -> 52,301 | 499 -> 419 (-16%) |

The intended mechanism works everywhere: each lookahead does 10–16% less propagation.
But keeping the prefix changes which inconsistent subsets are found (different probe
order/state), which changes LB strength, learnt/hardened clauses and the search tree.
Tree size swings of +33..41% dominate in the regressing cells. Timing variance is tiny,
so these are deterministic search-path effects, not noise.

Informational (Tier0 sweep, 4-way parallel, not evidence): LP_340_56_8 completed in all
4 modes within 60 s for the candidate (26–57 s) but in none for the baseline.
