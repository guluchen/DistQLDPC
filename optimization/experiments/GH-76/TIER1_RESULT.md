# GH-76 Tier1 result (coordinator, corrected baseline 72d1fe1) — numerically POSITIVE, no regression flag
Mac, frozen base 3f2fbc42… vs cand 67a7a7d7…, bound-soundness runner, 208/208 correct, timing lock held.
| Case | OFF ratio | MTO ratio | GH-73 OFF/MTO |
|---|---:|---:|---|
| BB_90_8_10 | 0.4520 | 0.6471 | 0.4643 / 0.8858 |
| GB_144_12_8 | 0.3594 | 0.2272 | 0.4260 / 0.2945 |
| BB_108_8_10 | 0.4408 | 0.4999 | 0.6128 / 0.4608 |
| LP_238_44_6 | 0.3438 | 0.4032 | 0.4557 / 0.5098 |
| geomean / envelope | 0.3961 / 0.4002 | 0.4149 / 0.4176 | 0.4848 / 0.4975 |
Replication OFF 0.3950 / MTO 0.4150. All gate cells non-overlapping improvements. Attribution: incremental probe
execution gives roughly a further 0.82x on top of GH-73's split (same host, separate runs).
