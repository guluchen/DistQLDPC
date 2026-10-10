# DistQLDPC cross-repo benchmark

Scientific results match: **YES**

Timing is informational only; shared CI runners are noisy.

| Stem | Config | Baseline | Candidate | Cand/Base time | Semantic match |
|---|---|---:|---:|---:|---|
| LP_136_32_4 | no-card | d=4 (0.12s) | d=4 (0.11s) | 0.92x | YES |
| LP_136_32_4 | card-mto | d=4 (0.10s) | d=4 (0.10s) | 1.00x | YES |
| BB_108_8_10 | no-card | d=10 (0.78s) | d=10 (0.76s) | 0.98x | YES |
| BB_108_8_10 | card-mto | d=10 (0.90s) | d=10 (0.90s) | 1.00x | YES |
