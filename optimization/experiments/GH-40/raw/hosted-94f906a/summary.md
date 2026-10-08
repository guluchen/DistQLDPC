# DistQLDPC cross-repo benchmark

Scientific results match: **YES**

Timing is informational only; shared CI runners are noisy.

| Stem | Config | Baseline | Candidate | Cand/Base time | Semantic match |
|---|---|---:|---:|---:|---|
| LP_136_32_4 | no-card | d=4 (0.14s) | d=4 (0.14s) | 1.00x | YES |
| LP_136_32_4 | card-mto | d=4 (0.21s) | d=4 (0.21s) | 1.00x | YES |
| BB_108_8_10 | no-card | d=10 (3.23s) | d=10 (3.24s) | 1.00x | YES |
| BB_108_8_10 | card-mto | d=10 (4.43s) | d=10 (4.48s) | 1.01x | YES |
