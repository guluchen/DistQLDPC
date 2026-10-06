# DistQLDPC cross-repo benchmark

Scientific results match: **YES**

Timing is informational only; shared CI runners are noisy.

| Stem | Config | Baseline | Candidate | Cand/Base time | Semantic match |
|---|---|---:|---:|---:|---|
| LP_136_32_4 | no-card | d=4 (0.13s) | d=4 (0.13s) | 1.00x | YES |
| LP_136_32_4 | card-mto | d=4 (0.21s) | d=4 (0.09s) | 0.43x | YES |
| BB_108_8_10 | no-card | d=10 (3.08s) | d=10 (2.63s) | 0.85x | YES |
| BB_108_8_10 | card-mto | d=10 (3.91s) | d=10 (3.10s) | 0.79x | YES |
