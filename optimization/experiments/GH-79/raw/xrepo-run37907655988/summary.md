# DistQLDPC cross-repo benchmark

Scientific results match: **YES**

Timing is informational only; shared CI runners are noisy.

| Stem | Config | Baseline | Candidate | Cand/Base time | Semantic match |
|---|---|---:|---:|---:|---|
| LP_136_32_4 | no-card | d=4 (0.13s) | d=4 (0.09s) | 0.70x | YES |
| LP_136_32_4 | card-mto | d=4 (0.20s) | d=4 (0.18s) | 0.90x | YES |
| BB_108_8_10 | no-card | d=10 (2.99s) | d=10 (2.86s) | 0.96x | YES |
| BB_108_8_10 | card-mto | d=10 (3.75s) | d=10 (2.85s) | 0.76x | YES |
