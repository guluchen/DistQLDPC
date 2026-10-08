# DistQLDPC cross-repo benchmark

Scientific results match: **YES**

Timing is informational only; shared CI runners are noisy.

| Stem | Config | Baseline | Candidate | Cand/Base time | Semantic match |
|---|---|---:|---:|---:|---|
| LP_136_32_4 | no-card | d=4 (0.96s) | d=4 (0.96s) | 1.00x | YES |
| LP_136_32_4 | card-mto | d=4 (1.46s) | d=4 (1.45s) | 0.99x | YES |
| BB_108_8_10 | no-card | d=10 (22.00s) | d=10 (22.32s) | 1.01x | YES |
| BB_108_8_10 | card-mto | d=10 (28.35s) | d=10 (28.47s) | 1.00x | YES |
