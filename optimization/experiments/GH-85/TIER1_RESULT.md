# GH-85 Tier1 result (coordinator, corrected baseline 72d1fe1) — numerically POSITIVE, no regression flag
Mac, frozen base 3f2fbc42… vs cand 1c6f028a…, bound-soundness runner, 208/208 correct, timing lock held.
| Case | OFF base -> cand (s) | OFF ratio | MTO base -> cand (s) | MTO ratio | GH-73 alone OFF/MTO |
|---|---|---:|---|---:|---|
| BB_90_8_10 | 1.807 -> 0.150 | 0.0830 | 1.617 -> 0.135 | 0.0833 | 0.4643 / 0.8858 |
| GB_144_12_8 | 0.656 -> 0.091 | 0.1384 | 1.106 -> 0.085 | 0.0764 | 0.4260 / 0.2945 |
| BB_108_8_10 | 2.261 -> 0.368 | 0.1629 | 2.316 -> 0.464 | 0.2004 | 0.6128 / 0.4608 |
| LP_238_44_6 | 1.194 -> 0.407 | 0.3411 | 1.136 -> 0.395 | 0.3473 | 0.4557 / 0.5098 |
| geomean / envelope | | 0.1590 / 0.1608 | | 0.1451 / 0.1486 | 0.4848 / 0.4975 |
Replication: OFF 0.1587 / MTO 0.1420. All gate cells non-overlapping improvements. Fixed judge: positive both modes.
Attribution (same host, separate runs): the per-half symmetry breaking adds a further ~3x on top of the split.
