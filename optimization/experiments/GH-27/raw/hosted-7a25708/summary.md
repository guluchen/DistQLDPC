# DistQLDPC cross-repo benchmark

Scientific results match: **YES**

Timing is informational only; shared CI runners are noisy.

| Stem | Config | Baseline | Candidate | Cand/Base time | Semantic match |
|---|---|---:|---:|---:|---|
| LP_136_32_4 | no-card | d=4 (0.13s) | d=4 (0.13s) | 1.00x | YES |
| LP_136_32_4 | card-mto | d=4 (0.20s) | d=4 (0.19s) | 0.95x | YES |
| BB_108_8_10 | no-card | d=10 (2.87s) | d=10 (2.86s) | 1.00x | YES |
| BB_108_8_10 | card-mto | d=10 (3.73s) | d=10 (3.71s) | 0.99x | YES |
