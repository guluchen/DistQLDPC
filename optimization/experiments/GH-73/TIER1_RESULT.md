# GH-73 Tier1 result (corrected baseline 72d1fe1) — numerically POSITIVE, no regression flag
Mac, frozen base 3f2fbc42… / cand adc3e31f…, bound-soundness runner, 208/208 correct, load 1.3–2.28, timing lock held.
| Case | OFF base -> cand (s) | OFF ratio (repl.) | MTO base -> cand (s) | MTO ratio (repl.) |
|---|---|---:|---|---:|
| BB_90_8_10 | 1.806 -> 0.839 | 0.4643 (0.4647) | 1.646 -> 1.458 | 0.8858 (0.8846) |
| GB_144_12_8 | 0.665 -> 0.283 | 0.4260 (0.4307) | 1.110 -> 0.327 | 0.2945 (0.2964) |
| BB_108_8_10 | 2.277 -> 1.395 | 0.6128 (0.6109) | 2.325 -> 1.071 | 0.4608 (0.4598) |
| LP_238_44_6 | 1.194 -> 0.544 | 0.4557 (0.4501) | 1.140 -> 0.581 | 0.5098 (0.5052) |
| geomean / envelope | | 0.4848 / 0.4879 | | 0.4975 / 0.5015 |
All gate cells non-overlapping improvements; replication reproduces all cells. Fixed judge: positive in both modes.
Compared informally with GH-71 (old baseline): slower on BB90/BB108/LP238, faster on GB144; GH-73 additionally
keeps anytime lower bounds and fixes asymmetric codes (Tier0).
