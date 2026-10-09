# DistQLDPC cross-repo benchmark

Scientific results match: **YES**

Timing is informational only; shared CI runners are noisy.

| Stem | Config | Baseline | Candidate | Cand/Base time | Semantic match |
|---|---|---:|---:|---:|---|
| LP_136_32_4 | no-card | d=4 (0.14s) | d=4 (0.14s) | 1.00x | YES |
| LP_136_32_4 | card-mto | d=4 (0.22s) | d=4 (0.21s) | 0.95x | YES |
| BB_108_8_10 | no-card | d=10 (3.25s) | d=10 (3.31s) | 1.02x | YES |
| BB_108_8_10 | card-mto | d=10 (4.18s) | d=10 (4.16s) | 1.00x | YES |
