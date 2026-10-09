# GH-79 Tier1 result (coordinator, corrected baseline 72d1fe1) — REJECT (mixed)
Mac, frozen base 3f2fbc42… vs cand b8f31b36…, bound-soundness runner, 208/208 correct, timing lock held.
| Case | OFF ratio | MTO ratio |
|---|---:|---:|
| BB_90_8_10 | 0.8335 | 1.2433 (reg) |
| GB_144_12_8 | 1.0015 | 0.6099 |
| BB_108_8_10 | 1.0860 (reg) | 0.8503 |
| LP_238_44_6 | 0.8908 | 0.7563 |
| geomean | 0.9480 | 0.8356 |
Replication OFF 0.9502 / MTO 0.8351 with the same regression flags. Fixed judge: regressions => REJECT, no Tier2.
Consistent with the offline prediction (modest, inside a_j branches only) and with the #60/#69 lesson that
search-changing clause additions swing individual cells both ways.
