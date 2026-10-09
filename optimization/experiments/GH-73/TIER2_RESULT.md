# GH-73 Tier2 result (corrected baseline 72d1fe1) — PASS (local diagnostic)
LP_340_56_8, 12/12 correct (d = 8, sound bounds), timing lock held, load 1.14–1.68.
| Mode | Baseline s | Candidate s | Ratio | Envelope |
|---|---|---|---:|---:|
| no-card | 85.166, 85.494, 85.467 | 3.334, 3.329, 3.330 | 0.0390 | 0.0392 |
| card-mto | 59.453, 59.538, 59.459 | 3.385, 3.384, 3.388 | 0.0569 | 0.0570 |
Direction consistent with Tier1, no regression => Tier2 PASS. No Tier3 launched (needs PI/integrator decision).
