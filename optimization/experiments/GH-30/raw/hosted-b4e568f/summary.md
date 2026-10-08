# DistQLDPC cross-repo benchmark

Scientific results match: **YES**

Timing is informational only; shared CI runners are noisy.

| Stem | Config | Baseline | Candidate | Cand/Base time | Semantic match |
|---|---|---:|---:|---:|---|
| LP_136_32_4 | no-card | d=4 (0.18s) | d=4 (0.18s) | 1.00x | YES |
| LP_136_32_4 | card-mto | d=4 (0.28s) | d=4 (0.22s) | 0.79x | YES |
| BB_108_8_10 | no-card | d=10 (4.19s) | d=10 (4.20s) | 1.00x | YES |
| BB_108_8_10 | card-mto | d=10 (5.45s) | d=10 (4.79s) | 0.88x | YES |
