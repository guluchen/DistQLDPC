# GH-75 Tier2 result (coordinator, corrected baseline 72d1fe1) — PASS (local diagnostic)
LP_340_56_8, 12/12 correct (d = 8), timing lock held, load 1.31–2.13.
| Mode | Baseline s | Candidate s | Ratio | Envelope |
|---|---|---|---:|---:|
| no-card | 85.819, 85.629, 85.497 | 76.525, 76.061, 76.106 | 0.8888 | 0.8951 |
| card-mto | 59.549, 59.483, 59.484 | 46.736, 46.748, 46.775 | 0.7859 | 0.7864 |
Direction consistent with Tier1, no regression => Tier2 PASS. LP codes only get the 34-orbit chain (no transitive
group found), hence smaller gains than on BB/GB (unit clause). No Tier3 launched.
