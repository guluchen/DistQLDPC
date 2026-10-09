# DistQLDPC cross-repo benchmark

Scientific results match: **YES**

Timing is informational only; shared CI runners are noisy.

| Stem | Config | Baseline | Candidate | Cand/Base time | Semantic match |
|---|---|---:|---:|---:|---|
| LP_136_32_4 | no-card | d=4 (0.19s) | d=4 (0.20s) | 1.05x | YES |
| LP_136_32_4 | card-mto | d=4 (0.28s) | d=4 (0.22s) | 0.79x | YES |
| BB_108_8_10 | no-card | d=10 (4.21s) | d=10 (5.11s) | 1.21x | YES |
| BB_108_8_10 | card-mto | d=10 (5.40s) | d=10 (4.47s) | 0.83x | YES |
