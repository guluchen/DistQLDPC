# DistQLDPC cross-repo benchmark

Scientific results match: **YES**

Timing is informational only; shared CI runners are noisy.

| Stem | Config | Baseline | Candidate | Cand/Base time | Semantic match |
|---|---|---:|---:|---:|---|
| LP_136_32_4 | no-card | d=4 (0.18s) | d=4 (0.18s) | 1.00x | YES |
| LP_136_32_4 | card-mto | d=4 (0.28s) | d=4 (0.28s) | 1.00x | YES |
| BB_108_8_10 | no-card | d=10 (4.20s) | d=10 (4.17s) | 0.99x | YES |
| BB_108_8_10 | card-mto | d=10 (5.36s) | d=10 (5.39s) | 1.01x | YES |
