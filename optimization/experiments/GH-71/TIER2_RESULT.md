# GH-71 Tier2 result — PASS (local diagnostic): LP_340_56_8 5.7x OFF / 2.7x MTO

Standard Tier2 per TIER2_PLAN.md after a numerically positive Tier1. Same frozen binaries, bound-soundness
runner, quiet host (load 1.09–1.81), 12/12 solves rc 0 and d = 8 with sound emitted bounds; inputs re-verified.

| Mode | Baseline s (AB/BA/AB) | Candidate s | Median ratio | Envelope |
|---|---|---|---:|---:|
| no-card | 85.348, 85.562, 85.527 | 15.017, 15.224, 15.027 | 0.1757 | 0.1784 |
| card-mto | 59.446, 59.628, 59.436 | 21.684, 21.667, 21.709 | 0.3648 | 0.3653 |

Direction consistent with Tier1, no regression => **Tier2 PASS** (local, diagnostic host). No Tier3
launched; research-grade claims still need controlled dedicated-server runs. Known adverse family:
asymmetric codes where the first-solved half has the larger distance (TN_200_10_10: 10.6 s -> ~58 s).
