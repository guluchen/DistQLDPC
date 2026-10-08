# DistQLDPC cross-repo benchmark

Scientific results match: **YES**

Timing is informational only; shared CI runners are noisy.

| Stem | Config | Baseline | Candidate | Cand/Base time | Semantic match |
|---|---|---:|---:|---:|---|
| LP_136_32_4 | no-card | d=4 (0.18s) | d=4 (0.15s) | 0.83x | YES |
| LP_136_32_4 | card-mto | d=4 (0.28s) | d=4 (0.26s) | 0.93x | YES |
| BB_108_8_10 | no-card | d=10 (4.20s) | d=10 (4.35s) | 1.03x | YES |
| BB_108_8_10 | card-mto | d=10 (5.39s) | d=10 (4.65s) | 0.86x | YES |
