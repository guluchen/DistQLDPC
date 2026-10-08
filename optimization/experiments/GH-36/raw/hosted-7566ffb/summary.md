# DistQLDPC cross-repo benchmark

Scientific results match: **YES**

Timing is informational only; shared CI runners are noisy.

| Stem | Config | Baseline | Candidate | Cand/Base time | Semantic match |
|---|---|---:|---:|---:|---|
| LP_136_32_4 | no-card | d=4 (0.13s) | d=4 (0.10s) | 0.77x | YES |
| LP_136_32_4 | card-mto | d=4 (0.20s) | d=4 (0.21s) | 1.05x | YES |
| BB_108_8_10 | no-card | d=10 (3.03s) | d=10 (3.15s) | 1.04x | YES |
| BB_108_8_10 | card-mto | d=10 (3.82s) | d=10 (3.37s) | 0.88x | YES |
