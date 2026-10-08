# DistQLDPC cross-repo benchmark

Scientific results match: **YES**

Timing is informational only; shared CI runners are noisy.

| Stem | Config | Baseline | Candidate | Cand/Base time | Semantic match |
|---|---|---:|---:|---:|---|
| LP_136_32_4 | no-card | d=4 (0.19s) | d=4 (0.19s) | 1.00x | YES |
| LP_136_32_4 | card-mto | d=4 (0.31s) | d=4 (0.32s) | 1.03x | YES |
| BB_108_8_10 | no-card | d=10 (4.46s) | d=10 (4.57s) | 1.03x | YES |
| BB_108_8_10 | card-mto | d=10 (5.70s) | d=10 (5.88s) | 1.03x | YES |
