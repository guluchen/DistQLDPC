# GH-76 Tier2 result (coordinator, corrected baseline 72d1fe1) — PASS (local diagnostic)
LP_340_56_8, 12/12 correct (d = 8), timing lock held.
| Mode | Baseline s | Candidate s | Ratio | Envelope |
|---|---|---|---:|---:|
| no-card | 85.786, 85.692, 85.412 | 2.544, 2.532, 2.536 | 0.0296 | 0.0298 |
| card-mto | 59.448, 59.430, 59.477 | 2.815, 2.814, 2.821 | 0.0474 | 0.0475 |
Direction consistent with Tier1, no regression => Tier2 PASS. (GH-73 alone: 0.039 / 0.057.)
