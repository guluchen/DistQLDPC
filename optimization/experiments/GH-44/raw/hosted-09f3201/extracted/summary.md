# DistQLDPC cross-repo benchmark

Scientific results match: **YES**

Timing is informational only; shared CI runners are noisy.

| Stem | Config | Baseline | Candidate | Cand/Base time | Semantic match |
|---|---|---:|---:|---:|---|
| LP_136_32_4 | no-card | d=4 (0.18s) | d=4 (0.18s) | 1.00x | YES |
| LP_136_32_4 | card-mto | d=4 (0.29s) | d=4 (0.28s) | 0.97x | YES |
| BB_108_8_10 | no-card | d=10 (4.20s) | d=10 (4.88s) | 1.16x | YES |
| BB_108_8_10 | card-mto | d=10 (5.48s) | d=10 (4.94s) | 0.90x | YES |
