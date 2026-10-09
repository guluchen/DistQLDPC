# GH-87 Tier2 result — PASS (local), identical to GH-73 path as preregistered
LP_340_56_8, Mac, frozen base 3f2fbc42… vs cand 167dd0ce…, 12/12 correct (d = 8), timing lock held, load 1.31–2.40.
| Mode | Baseline s | Candidate s | Ratio | Envelope |
|---|---|---|---:|---:|
| no-card | 84.962, 85.189, 85.299 | 3.361, 3.323, 3.323 | 0.0390 | 0.0396 |
| card-mto | 59.371, 59.335, 59.319 | 3.384, 3.374, 3.388 | 0.0570 | 0.0571 |
LP340 has no verified XZ-dual map, so GH-87 runs the GH-73 path; GH-73's own Tier2 was 0.0390 (no-card).
No regression from the dual-map search overhead. Raw: raw/tier2-01/.
