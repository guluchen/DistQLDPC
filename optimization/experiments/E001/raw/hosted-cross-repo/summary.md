# DistQLDPC cross-repo benchmark

Scientific results match: **YES**

Timing is informational only; shared CI runners are noisy.

| Stem | Config | Baseline | Candidate | Cand/Base time | Semantic match |
|---|---|---:|---:|---:|---|
| LP_136_32_4 | no-card | d=4 (0.18s) | d=4 (0.17s) | 0.94x | YES |
| LP_136_32_4 | card-mto | d=4 (0.28s) | d=4 (0.12s) | 0.43x | YES |
| BB_108_8_10 | no-card | d=10 (4.20s) | d=10 (3.67s) | 0.87x | YES |
| BB_108_8_10 | card-mto | d=10 (5.41s) | d=10 (4.35s) | 0.80x | YES |
