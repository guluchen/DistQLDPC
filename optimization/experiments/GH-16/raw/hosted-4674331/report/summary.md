# DistQLDPC cross-repo benchmark

Scientific results match: **YES**

Timing is informational only; shared CI runners are noisy.

| Stem | Config | Baseline | Candidate | Cand/Base time | Semantic match |
|---|---|---:|---:|---:|---|
| LP_136_32_4 | no-card | d=4 (0.15s) | d=4 (0.15s) | 1.00x | YES |
| LP_136_32_4 | card-mto | d=4 (0.23s) | d=4 (0.22s) | 0.96x | YES |
| BB_108_8_10 | no-card | d=10 (3.46s) | d=10 (3.35s) | 0.97x | YES |
| BB_108_8_10 | card-mto | d=10 (4.43s) | d=10 (4.32s) | 0.98x | YES |
