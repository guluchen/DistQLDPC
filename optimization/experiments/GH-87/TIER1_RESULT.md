# GH-87 Tier1 result (coordinator, corrected baseline 72d1fe1) — numerically POSITIVE, no regression flag
Mac, frozen base 3f2fbc42… vs cand 167dd0ce…, bound-soundness runner, 208/208 correct, timing lock held.
| Case | OFF ratio | MTO ratio | GH-73 OFF/MTO | dual map |
|---|---:|---:|---|---|
| BB_90_8_10 | 0.4085 | 0.4123 | 0.4643 / 0.8858 | yes |
| GB_144_12_8 | 0.1369 | 0.1756 | 0.4260 / 0.2945 | yes |
| BB_108_8_10 | 0.2607 | 0.2851 | 0.6128 / 0.4608 | yes |
| LP_238_44_6 | 0.4520 | 0.5068 | 0.4557 / 0.5098 | no (= GH-73 path) |
| geomean / envelope | 0.2849 / 0.2905 | 0.3198 / 0.3225 | 0.4848 / 0.4975 | |
Replication OFF 0.2862 / MTO 0.3202. All gate cells non-overlapping improvements. Positive both modes.
Compared with GH-85 (0.159/0.145, same host): dual-half elimination alone is weaker than per-half symmetry
breaking; the two are complementary (GH-87 helps only BB/GB codes that have an XZ-dual map).
