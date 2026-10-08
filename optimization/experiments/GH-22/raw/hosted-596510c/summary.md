# DistQLDPC cross-repo benchmark

Scientific results match: **YES**

Timing is informational only; shared CI runners are noisy.

| Stem | Config | Baseline | Candidate | Cand/Base time | Semantic match |
|---|---|---:|---:|---:|---|
| LP_136_32_4 | no-card | d=4 (0.15s) | d=4 (0.15s) | 1.00x | YES |
| LP_136_32_4 | card-mto | d=4 (0.25s) | d=4 (0.18s) | 0.72x | YES |
| BB_108_8_10 | no-card | d=10 (3.44s) | d=10 (3.73s) | 1.08x | YES |
| BB_108_8_10 | card-mto | d=10 (4.43s) | d=10 (3.96s) | 0.89x | YES |
