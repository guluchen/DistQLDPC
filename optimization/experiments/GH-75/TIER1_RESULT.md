# GH-75 Tier1 result (coordinator, corrected baseline 72d1fe1) — numerically POSITIVE, no regression flag
Mac, frozen base 3f2fbc42… vs cand 303407ec…, bound-soundness runner, 208/208 correct, timing lock held.
| Case | OFF base -> cand (s) | OFF ratio (repl.) | MTO base -> cand (s) | MTO ratio (repl.) |
|---|---|---:|---|---:|
| BB_90_8_10 | 1.874 -> 0.549 | 0.2929 (0.2882) | 1.665 -> 0.375 | 0.2251 (0.2260) |
| GB_144_12_8 | 0.660 -> 0.247 | 0.3732 (0.3739) | 1.117 -> 0.192 | 0.1714 (0.1745) |
| BB_108_8_10 | 2.283 -> 1.965 | 0.8608 (0.8599) | 2.322 -> 0.686 | 0.2955 (0.2948) |
| LP_238_44_6 | 1.204 -> 0.763 | 0.6339 (0.6314) | 1.150 -> 0.806 | 0.7009 (0.7057) |
| geomean / envelope | | 0.4942 / 0.5544 | | 0.2990 / 0.3014 |
All gate cells non-overlapping improvements; replication reproduces. Fixed judge: positive both modes.
