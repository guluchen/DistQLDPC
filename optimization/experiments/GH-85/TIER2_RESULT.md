# GH-85 Tier2 result (coordinator, corrected baseline 72d1fe1) — PASS (local diagnostic)
LP_340_56_8, 12/12 correct (d = 8), timing lock held.
| Mode | Baseline s | Candidate s | Ratio | Envelope |
|---|---|---|---:|---:|
| no-card | 84.951, 85.513, 85.379 | 1.531, 1.532, 1.529 | 0.0179 | 0.0180 |
| card-mto | 59.341, 59.393, 59.382 | 1.623, 1.611, 1.637 | 0.0273 | 0.0276 |
Direction consistent with Tier1, no regression => Tier2 PASS. (GH-73 alone: 0.039 / 0.057.)
