# Benchmark matrices

New, unmeasured codes live separately in [untiered/](untiered/README.md), with
reproducible generators, provenance and validation in its MANIFEST.csv. They
are excluded from the tier sets below and from the QDistSAT mirror until
PI-approved tier assignment. Use their full path when invoking DistQLDPC.

Each code `<stem>` is four text files `<stem>_Hx.txt`, `<stem>_Hz.txt`, `<stem>_Gx.txt`,
`<stem>_Gz.txt` (format: [README](../../README.md#input-four-matrix-files)). The 50 bundled
codes are organized by benchmark tier in `tier0/` … `tier5/` (PI decision 2026-10-11).
Every code is in exactly one tier.

`bin/distqldpc <stem>` resolves a bare name to `data/matrices/<stem>` if `<stem>_Hx.txt`
is there, else to the first of `tier0` … `tier5` that contains it; a name containing `/`
is used as given (`./bin/distqldpc data/matrices/tier1/BB_144_12_12`).
`scripts/benchmark_matrices.py` searches the same way (`--matrices-dir data/matrices/tierN`
restricts it to one tier). `scripts/compute_logicals.py --dir` and
`scripts/preprocess_matrices.py --src` take one flat directory, e.g. `data/matrices/tier0`.

## Tiers

`[[n, k, d]]`: n = columns of Hx, k = rows of Gx, d = certified distance (`{lb}to{ub}` or `ge{lb}` if not
certified).

| Tier | Purpose / timeout | Codes `[[n, k, d]]` |
|------|-------------------|---------------------|
| tier0 | correctness / smoke; main < 1 s on yfclab2 | LP_34_20_2 [[34,20,2]], TN_36_8_3 [[36,8,3]], TN_36_8_4 [[36,8,4]], TN_54_11_4 [[54,11,4]], BB_72_12_6 [[72,12,6]], TN_72_14_4 [[72,14,4]], TN_72_8_8 [[72,8,8]], BB_90_8_10 [[90,8,10]], BB_108_8_10 [[108,8,10]], LP_136_32_4 [[136,32,4]], BB_144_12_12 [[144,12,12]], GB_144_12_8 [[144,12,8]], LP_238_44_6 [[238,44,6]] |
| tier1 | lightweight performance filter; main 1–10 s on yfclab2 | LP_340_56_8 [[340,56,8]], LP_442_68_10 [[442,68,10]] |
| tier2 | medium filter; main 10–100 s on yfclab2 | TN_108_2_12 [[108,2,12]], BB_144_14_14 [[144,14,14]], GB_144_12_12 [[144,12,12]], TN_200_10_10 [[200,10,10]], BB_288_12_18 [[288,12,18]], LP_544_80_12 [[544,80,12]] |
| tier3 | decisive set; main 100–2000 s on yfclab2 | TN_144_2_13 [[144,2,13]], LP_714_100_16 [[714,100,16]] |
| tier4 | hard; main 2000–5000 s on yfclab2; timeout 2000 s Mac / 5000 s yfclab2 | TN_250_10_15 [[250,10,15]] |
| tier5 | open set; main > 5000 s or unsolved on yfclab2; timeout 21600 s (6 h) | TN_180_2_17 [[180,2,17]], TN_216_4_18 [[216,4,18]], TN_252_2_21 [[252,2,21]], TN_288_2_22to24 [[288,2,22–24]], TN_324_4_22to25 [[324,4,22–25]], BB_360_12_24 [[360,12,24]], TN_360_4_17to24 [[360,4,17–24]], TN_396_4_17to26 [[396,4,17–26]], TN_432_8_23to29 [[432,8,23–29]], TN_468_4_17to29 [[468,4,17–29]], TN_496_2_23to30 [[496,2,23–30]], TN_504_2_17to34 [[504,2,17–34]], TN_540_4_23to34 [[540,4,23–34]], TN_576_2_24to37 [[576,2,24–37]], TN_612_2_17to40 [[612,2,17–40]], TN_648_10_9to32 [[648,10,9–32]], TN_648_14_9to28 [[648,14,9–28]], TN_684_2_9to29 [[684,2,9–29]], BB_756_16_30to34 [[756,16,30–34]], BB_864_4_30to40 [[864,4,30–40]], LP_1020_136_16 [[1020,136,16]], LP_1054_140_20 [[1054,140,20]], BB_1080_4_30to48 [[1080,4,30–48]], LP_1428_184_24 [[1428,184,24]], LP_1768_224_22 [[1768,224,22]], LP_1122_148_20 [[1122,148,20]], LP_2610_744_16 [[2610,744,16]] |

Counts: tier0 13, tier1 2, tier2 6, tier3 2, tier4 1, tier5 27 (total 51).

**Tier assignment rule (PI 2026-10-12):** by main's time on yfclab2 (slower of no-card / card-mto, `optimization/baselines/SERVER.md`): < 1 s tier0, 1–10 s tier1, 10–100 s tier2, 100–2000 s tier3, 2000–5000 s tier4, > 5000 s or unsolved tier5. Re-check placements when main changes. 2026-10-23 (main c914ef5 baseline, PR #142; PI): LP_442_68_10 tier2 -> tier1, BB_288_12_18 tier3 -> tier2, LP_714_100_16 tier4 -> tier3 (LP_1020_136_16 pending a 5-seed measurement). 2026-10-21 (main cbb0642, -frontier=auto; PI): BB_108_8_10, BB_144_12_12, LP_238_44_6 tier1 -> tier0; GB_144_12_12, LP_544_80_12, TN_200_10_10 tier3 -> tier2; LP_714_100_16 tier5 -> tier4 (optimization/baselines/SERVER.md). 2026-10-14 (main 398054e, GH-107; PI): BB_144_14_14 tier3 -> tier2 (72.7 s), BB_288_12_18 tier4 -> tier3 (919 s).

**Timeouts.** tier4: 2000 s per instance on the Mac, 5000 s on yfclab2; tier5: 21600 s (6 h) per instance.
tier0–tier3 are the filtering tiers of the
[optimization loop policy](../../docs/OPTIMIZATION_LOOP_POLICY.md) (Tier 0 correctness/smoke,
Tier 1 lightweight filter, Tier 2 medium filter, Tier 3 decisive set); the policy fixes no
numeric wall-clock limit for them, so the limit is recorded in each experiment's
pre-registered plan and kept identical for baseline and candidate. 

## Naming rule

`{family}_{n}_{k}_{d}` with family in `BB`, `GB`, `LP`, `TN`; n = columns of Hx, k = rows
of Gx, d = minimum distance once our tool has found it (PI 2026-10-11), otherwise the current proven bounds: `{lb}to{ub}` when an upper bound (a logical operator of that weight) is known, `ge{lb}` when only a lower bound is known (PI 2026-10-11: "Unknown可以改成目前上下界"); names are updated when bounds improve; codes with equal n and k are first checked for being the same code (duplicates are removed); genuinely different codes would get a suffix `_a`, `_b`. `GB` keeps its own
prefix (not merged into `BB`). Former `PK_*` / `xu_*` codes are `LP_*`; former `QT_*`
codes are `TN_*`. Upstream ids and attribution are recorded in [NOTICE](../../NOTICE),
section 5.

## Rename history

| Date | Old | New | Note |
|------|-----|-----|------|
| 2026-10-29 | TN_288_2_9to24 | TN_288_2_22to24 | lb 22: CC lower bound from GH-152 (issue #152): DistQLDPC's optional CC engine with `-cc-aut=on` (Tanner-graph automorphism candidates for the orbit seeds and the XZ-dual map, each GF(2)-verified before use); levels up to 21 completed EMPTY (yfclab2, 6 h, binary dfd0717). Reproduction: same binary and labels, different search order (`-cc-rules=excl,pack,orbf,parity,leaf,overlap,mrv`, 12 h), every level EMPTY, same lb; genuinely different tree (node counts differ at every level), same algorithm, not a second method; `optimization/experiments/GH-152/REPRODUCTION.md` on branch `experiment/gh-152-tanner-aut`. ub unchanged (GH-146 witness; copy under the new stem in `optimization/experiments/GH-152/witnesses/`) (PI 2026-10-29) |
| 2026-10-29 | TN_324_4_9to25 | TN_324_4_22to25 | lb 22 (GH-152 CC lower bound with `-cc-aut=on`, reproduced with the `mrv` order, as above); ub unchanged |
| 2026-10-29 | TN_432_8_9to29 | TN_432_8_23to29 | lb 23 (GH-152 CC lower bound with `-cc-aut=on`, reproduced with the `mrv` order, as above); ub unchanged |
| 2026-10-29 | TN_496_2_17to30 | TN_496_2_23to30 | lb 23 (GH-152 CC lower bound with `-cc-aut=on`, X half only under the verified Tanner XZ-swap map; reproduced with the `mrv` order, as above); ub unchanged |
| 2026-10-29 | TN_540_4_9to34 | TN_540_4_23to34 | lb 23 (GH-152 CC lower bound with `-cc-aut=on`, reproduced with the `mrv` order, as above); ub unchanged |
| 2026-10-29 | TN_576_2_9to37 | TN_576_2_24to37 | lb 24 (GH-152 CC lower bound with `-cc-aut=on`, reproduced with the `mrv` order, as above); ub unchanged |
| 2026-10-23 | BB_1080_4_ge30 | BB_1080_4_30to48 | ub 48: nontrivial logical of weight 48 from the GH-146 finder, independently verified (pure-Python GF(2) check `verify_witnesses.py`: Hz e = 0 / Hx e = 0 and e not in the stabilizer row space); witnesses in `optimization/experiments/GH-146/witnesses/renamed/`; lower bound unchanged (PI 2026-10-23) |
| 2026-10-23 | BB_756_16_ge30 | BB_756_16_30to34 | ub 34 (GH-146 verified witness, as above); lb unchanged |
| 2026-10-23 | BB_864_4_ge30 | BB_864_4_30to40 | ub 40 (GH-146 verified witness, as above); lb unchanged |
| 2026-10-23 | TN_288_2_ge9 | TN_288_2_9to24 | ub 24 (GH-146 verified witness, as above); lb unchanged |
| 2026-10-23 | TN_324_4_ge9 | TN_324_4_9to25 | ub 25 (GH-146 verified witness, as above); lb unchanged |
| 2026-10-23 | TN_360_4_ge17 | TN_360_4_17to24 | ub 24 (GH-146 verified witness, as above); lb unchanged |
| 2026-10-23 | TN_396_4_ge17 | TN_396_4_17to26 | ub 26 (GH-146 verified witness, as above); lb unchanged |
| 2026-10-23 | TN_432_8_ge9 | TN_432_8_9to29 | ub 29 (GH-146 verified witness, as above); lb unchanged |
| 2026-10-23 | TN_468_4_ge17 | TN_468_4_17to29 | ub 29 (GH-146 verified witness, as above); lb unchanged |
| 2026-10-23 | TN_496_2_ge17 | TN_496_2_17to30 | ub 30 (GH-146 verified witness, as above); lb unchanged |
| 2026-10-23 | TN_504_2_ge17 | TN_504_2_17to34 | ub 34 (GH-146 verified witness, as above); lb unchanged |
| 2026-10-23 | TN_540_4_ge9 | TN_540_4_9to34 | ub 34 (GH-146 verified witness, as above); lb unchanged |
| 2026-10-23 | TN_576_2_ge9 | TN_576_2_9to37 | ub 37 (GH-146 verified witness, as above); lb unchanged |
| 2026-10-23 | TN_612_2_ge17 | TN_612_2_17to40 | ub 40 (GH-146 verified witness, as above); lb unchanged |
| 2026-10-23 | TN_648_10_9to52 | TN_648_10_9to32 | ub 52 -> 32 (GH-146 verified witness, as above); lb unchanged |
| 2026-10-23 | TN_648_14_ge9 | TN_648_14_9to28 | ub 28 (GH-146 verified witness, as above); lb unchanged |
| 2026-10-23 | TN_684_2_ge9 | TN_684_2_9to29 | ub 29 (GH-146 verified witness, as above); lb unchanged |
| 2026-10-22 | BB_756_16_ge28 | BB_756_16_ge30 | lb 30: levels 28 and 29 proven empty by the optional CC engine with GH-138's overlap rule (yfclab2, 6 h; reproduced with relabeled seeds 1-3, i.e. different search trees; same algorithm, not a second method; PI 2026-10-22) |
| 2026-10-22 | BB_864_4_ge28 | BB_864_4_ge30 | lb 30, as above |
| 2026-10-22 | BB_1080_4_ge28 | BB_1080_4_ge30 | lb 30, as above |
| 2026-10-21 | BB_756_16_ge17 | BB_756_16_ge28 | lb 28: level 28 proven empty by the optional CC engine with GH-133's parity rule (yfclab2, 6669-7938 s; single canonical search, not cross-validated by a second method; PI 2026-10-21) |
| 2026-10-21 | BB_864_4_ge17 | BB_864_4_ge28 | lb 28, as above |
| 2026-10-21 | BB_1080_4_ge17 | BB_1080_4_ge28 | lb 28, as above |
| 2026-10-18 | (new) | LP_1122_148_20 | added: lp20^{3,5} [[1122,148]] of Cain et al., arXiv:2603.28627 (seed matrix Eq. (A3), as listed in C. Crocker, Zenodo doi:10.5281/zenodo.23445463, which first established d = 20); d = 20 re-verified by DistQLDPC (-engine=cc, 28 s, Mac; Crocker's weight-20 witnesses GF(2)-checked). Tier provisional (tier5) until main's server time is recorded |
| 2026-10-18 | (new) | LP_2610_744_16 | added: lp16^{3,7} [[2610,744]] of Cain et al., arXiv:2603.28627 (seed matrix Eq. (A5), as listed in C. Crocker, Zenodo doi:10.5281/zenodo.23445463, which first established d = 16); d = 16 re-verified by DistQLDPC (-engine=cc, 8 s, Mac; Crocker's weight-16 witnesses GF(2)-checked). Tier provisional (tier5) until main's server time is recorded |
| 2026-10-16 | BB_360_12_17to24 | BB_360_12_24 | d = 24 confirmed (GH-124 -engine=cc in-repo, 1993 s on yfclab2; prototype + 2 clean-room reimplementations; witnesses GF(2)-verified); matches the original upstream name |
| 2026-10-16 | TN_252_2_17to28 | TN_252_2_21 | d = 21 confirmed (dX = 21, dZ >= 22; GH-124 -engine=cc sequential schedule 17116 s; prototype + 2 reimplementations); matches the original upstream name |
| 2026-10-16 | LP_1054_140_17to32 | LP_1054_140_20 | d = 20 confirmed (GH-124 -engine=cc 83 s, also without orbit seeds 1552 s; prototype + 2 reimplementations). The same value was published earlier, independently, by C. Crocker (Zenodo, doi:10.5281/zenodo.23379787, v1.0, 14 Oct 2026; v1.1 doi:10.5281/zenodo.23445463) |
| 2026-10-16 | LP_1428_184_ge17 | LP_1428_184_24 | d = 24 confirmed (GH-124 -engine=cc 4235 s; prototype + 2 reimplementations) |
| 2026-10-16 | LP_1768_224_ge17 | LP_1768_224_22 | d = 22 confirmed (GH-124 -engine=cc 345 s; prototype + 2 reimplementations) |
| 2026-10-12 | TN_180_2_ge9 | TN_180_2_17 | d = 17 solved by main on yfclab2 (10282 s no-card) and by GH-106 v2 |
| 2026-10-12 | TN_216_4_ge9 | TN_216_4_18 | d = 18 solved by main on yfclab2 (13553 s no-card, 19170 s card-mto) |
| 2026-10-12 | TN_252_2_ge9 | TN_252_2_17to28 | lb 17, ub 28 (yfclab2 6 h) |
| 2026-10-12 | BB_1080_4_ge9 | BB_1080_4_ge17 | lb 17 (yfclab2 6 h) |
| 2026-10-12 | BB_756_16_ge9 | BB_756_16_ge17 | lb 17 (yfclab2 6 h) |
| 2026-10-12 | BB_864_4_ge9 | BB_864_4_ge17 | lb 17 (yfclab2 6 h) |
| 2026-10-12 | TN_360_4_ge9 | TN_360_4_ge17 | lb 17 (yfclab2 6 h) |
| 2026-10-12 | TN_396_4_ge9 | TN_396_4_ge17 | lb 17 (yfclab2 6 h) |
| 2026-10-12 | TN_468_4_ge9 | TN_468_4_ge17 | lb 17 (yfclab2 6 h) |
| 2026-10-12 | TN_496_2_ge9 | TN_496_2_ge17 | lb 17 (yfclab2 6 h) |
| 2026-10-12 | TN_504_2_ge9 | TN_504_2_ge17 | lb 17 (yfclab2 6 h) |
| 2026-10-12 | TN_612_2_ge9 | TN_612_2_ge17 | lb 17 (yfclab2 6 h) |
| 2026-10-11 | BB_1080_4_unknown | BB_1080_4_ge17 | current bounds: lb 9 (60 s sweeps) |
| 2026-10-11 | BB_360_12_unknown | BB_360_12_17to24 | current bounds: lb 17, ub 24 (6 h probe, card-mto) |
| 2026-10-11 | BB_756_16_unknown | BB_756_16_ge17 | current bounds: lb 9 (60 s sweeps) |
| 2026-10-11 | BB_864_4_unknown | BB_864_4_ge17 | current bounds: lb 9 (60 s sweeps) |
| 2026-10-11 | LP_1020_136_unknown | LP_1020_136_16 | current bounds: d = 16 solved by main (6 h probe, 2674-2679 s both modes); independently recomputed later by C. Crocker (Zenodo, doi:10.5281/zenodo.23445463) |
| 2026-10-11 | LP_1054_140_unknown | LP_1054_140_17to32 | current bounds: lb 17, ub 32 (6 h probe, still running) |
| 2026-10-11 | LP_1428_184_unknown | LP_1428_184_ge17 | current bounds: lb 17 (6 h probe, still running) |
| 2026-10-11 | LP_1768_224_unknown | LP_1768_224_ge17 | current bounds: lb 17 (6 h probe) |
| 2026-10-11 | TN_180_2_unknown | TN_180_2_17 | current bounds: lb 9 (60 s sweeps) |
| 2026-10-11 | TN_216_4_unknown | TN_216_4_18 | current bounds: lb 9 (60 s sweeps) |
| 2026-10-11 | TN_252_2_unknown | TN_252_2_17to28 | current bounds: lb 9 (60 s sweeps) |
| 2026-10-11 | TN_288_2_unknown | TN_288_2_ge9 | current bounds: lb 9 (60 s sweeps) |
| 2026-10-11 | TN_324_4_unknown | TN_324_4_ge9 | current bounds: lb 9 (60 s sweeps) |
| 2026-10-11 | TN_360_4_unknown | TN_360_4_ge17 | current bounds: lb 9 (60 s sweeps) |
| 2026-10-11 | TN_396_4_unknown | TN_396_4_ge17 | current bounds: lb 9 (60 s sweeps) |
| 2026-10-11 | TN_432_8_unknown | TN_432_8_ge9 | current bounds: lb 9 (60 s sweeps) |
| 2026-10-11 | TN_468_4_unknown | TN_468_4_ge17 | current bounds: lb 9 (60 s sweeps) |
| 2026-10-11 | TN_496_2_unknown | TN_496_2_ge17 | current bounds: lb 9 (60 s sweeps) |
| 2026-10-11 | TN_504_2_unknown | TN_504_2_ge17 | current bounds: lb 9 (60 s sweeps) |
| 2026-10-11 | TN_540_4_unknown | TN_540_4_ge9 | current bounds: lb 9 (60 s sweeps) |
| 2026-10-11 | TN_576_2_unknown | TN_576_2_ge9 | current bounds: lb 9 (60 s sweeps) |
| 2026-10-11 | TN_612_2_unknown | TN_612_2_ge17 | current bounds: lb 9 (60 s sweeps) |
| 2026-10-11 | TN_648_10_unknown | TN_648_10_9to52 | current bounds: lb 9 (60 s sweeps), ub 52 (weight-52 logical in the bundled basis) |
| 2026-10-11 | TN_648_14_unknown | TN_648_14_ge9 | current bounds: lb 9 (60 s sweeps) |
| 2026-10-11 | TN_684_2_unknown | TN_684_2_ge9 | current bounds: lb 9 (60 s sweeps) |
| 2026-10-11 | BB_288_12_unknown | BB_288_12_18 | d = 18 found by main 7eadd54 (Mac, 804 s no-card / 913 s card-mto); PI: written without strict cross-verification, re-check only if an inconsistency appears |
| 2026-10-11 | LP_714_100_unknown | LP_714_100_16 | d = 16 found by main 7eadd54 (Mac, 1687 s both modes); same policy; independently recomputed later by C. Crocker (Zenodo, doi:10.5281/zenodo.23445463) |
| 2026-10-11 | PK_31 | LP_1054_140_17to32 | n=1054, k=140 |
| 2026-10-11 | xu_30 | LP_1020_136_16 | n=1020, k=136 |
| 2026-10-11 | xu_42 | LP_1428_184_ge17 | n=1428, k=184 |
| 2026-10-11 | TN_360_4_24 | TN_360_4_ge17 | matrices identical to QDistSAT's `data/tier5/TN_360_4_ge17_*` (Hx/Hz byte-identical; Gx/Gz header comment aligned, so all four files are byte-identical); d not certified |
| 2026-10-11 | TN_648_10_71 | TN_648_10_9to52 | bundled logical bases contain weight-52 nontrivial logicals, so d <= 52; exact d unknown |
| 2026-10-11 | BB_756_16_34 | BB_756_16_ge17 | numeric field not confirmed by DistQLDPC; renamed (distance not confirmed by DistQLDPC) |
| 2026-10-11 | BB_864_4_40 | BB_864_4_ge17 | numeric field not confirmed by DistQLDPC; renamed (distance not confirmed by DistQLDPC) |
| 2026-10-11 | BB_1080_4_54 | BB_1080_4_ge17 | numeric field not confirmed by DistQLDPC; renamed (distance not confirmed by DistQLDPC) |
| 2026-10-11 | TN_180_2_17 | TN_180_2_17 | numeric field not confirmed by DistQLDPC; renamed (distance not confirmed by DistQLDPC) |
| 2026-10-11 | TN_216_4_18 | TN_216_4_18 | numeric field not confirmed by DistQLDPC; renamed (distance not confirmed by DistQLDPC) |
| 2026-10-11 | TN_252_2_21 | TN_252_2_17to28 | numeric field not confirmed by DistQLDPC; renamed (distance not confirmed by DistQLDPC) |
| 2026-10-11 | TN_288_2_24 | TN_288_2_ge9 | numeric field not confirmed by DistQLDPC; renamed (distance not confirmed by DistQLDPC) |
| 2026-10-11 | TN_324_4_25 | TN_324_4_ge9 | numeric field not confirmed by DistQLDPC; renamed (distance not confirmed by DistQLDPC) |
| 2026-10-11 | TN_396_4_26 | TN_396_4_ge17 | numeric field not confirmed by DistQLDPC; renamed (distance not confirmed by DistQLDPC) |
| 2026-10-11 | TN_432_8_33 | TN_432_8_ge9 | numeric field not confirmed by DistQLDPC; renamed (distance not confirmed by DistQLDPC) |
| 2026-10-11 | TN_468_4_31 | TN_468_4_ge17 | numeric field not confirmed by DistQLDPC; renamed (distance not confirmed by DistQLDPC) |
| 2026-10-11 | TN_496_2_32 | TN_496_2_ge17 | numeric field not confirmed by DistQLDPC; renamed (distance not confirmed by DistQLDPC) |
| 2026-10-11 | TN_504_2_45 | TN_504_2_ge17 | numeric field not confirmed by DistQLDPC; renamed (distance not confirmed by DistQLDPC) |
| 2026-10-11 | TN_540_4_40 | TN_540_4_ge9 | numeric field not confirmed by DistQLDPC; renamed (distance not confirmed by DistQLDPC) |
| 2026-10-11 | TN_576_2_57 | TN_576_2_ge9 | numeric field not confirmed by DistQLDPC; renamed (distance not confirmed by DistQLDPC) |
| 2026-10-11 | TN_576_2_59 | (removed) | duplicate of TN_576_2_57: Hx/Hz byte-identical and the logical bases span the same space modulo the stabilizers (rank 289 each and jointly), i.e. the same code; the two names claimed different distances (57 vs 59) |
| 2026-10-11 | TN_612_2_52 | TN_612_2_ge17 | numeric field not confirmed by DistQLDPC; renamed (distance not confirmed by DistQLDPC) |
| 2026-10-11 | TN_648_14_50 | TN_648_14_ge9 | numeric field not confirmed by DistQLDPC; renamed (distance not confirmed by DistQLDPC) |
| 2026-10-11 | TN_684_2_29 | TN_684_2_ge9 | numeric field not confirmed by DistQLDPC; renamed (distance not confirmed by DistQLDPC) |
| earlier | BB_144_14_0 | BB_144_14_14 | aligned with QDistSAT |
| earlier | BB_288_12_18 | BB_288_12_unknown | aligned with QDistSAT (renamed BB_288_12_18 again on 2026-10-11) |
| earlier | BB_360_12_24 | BB_360_12_17to24 | aligned with QDistSAT |
| earlier | GB_144_12_24 | GB_144_12_8 | aligned with QDistSAT |
| earlier | GB_144_12_37 | GB_144_12_12 | aligned with QDistSAT |
| earlier | QT_36_8_3, QT_54_11_4, QT_72_14_4, QT_200_10_10, QT_250_10_15 | TN_36_8_3, TN_54_11_4, TN_72_14_4, TN_200_10_10, TN_250_10_15 | QT -> TN |
| earlier | AJ_01, AJ_04, AJ_07, AJ_10, AJ_13, AJ_52; xu_16, xu_21 | LP_34_20_2, LP_136_32_4, LP_238_44_6, LP_340_56_8, LP_442_68_10, LP_1768_224_ge17; LP_544_80_12, LP_714_100_unknown | upstream codeDistancePYPI ids |

## Open items

- **Former numeric tier5 names** (BB_756_16_34, BB_864_4_40, BB_1080_4_54, TN_180_2_17 ... TN_684_2_29): the old third field may be a literature value or an upstream index; it is kept in the rename history but not in the stem until DistQLDPC confirms the distance.
- **TN_648_10_9to32:** d <= 32 (GH-146 verified witness; the bundled bases contain weight-52
  nontrivial logicals); the exact distance is unknown.
- **Upper-bound witnesses (`{lb}to{ub}` stems):** the upper bounds of the tier5 `{lb}to{ub}` stems renamed on
  2026-10-23 come from the GH-146 finder; one nontrivial logical per stem is stored as
  `optimization/experiments/GH-146/witnesses/renamed/<stem>.<X|Z>.w<ub>.txt` (0-based qubit indices) and can be
  re-checked with `python3 optimization/experiments/GH-146/witnesses/verify_witnesses.py data/matrices
  optimization/experiments/GH-146/witnesses/renamed/*.txt` (pure Python, independent of DistQLDPC's code).
  Six of those stems were renamed again on 2026-10-29 (GH-152 lower bounds; TN_288_2_22to24, TN_324_4_22to25,
  TN_432_8_23to29, TN_496_2_23to30, TN_540_4_23to34, TN_576_2_24to37). Their 2026-10-23 copies in `renamed/` keep
  the older stem and no longer resolve under `data/matrices`; copies under the current stems are in
  `optimization/experiments/GH-152/witnesses/` (same supports, `VERIFY.txt`: 6/6 VALID) and are checked with the same
  command on `optimization/experiments/GH-152/witnesses/*.txt`.
- **GH-152 lower bounds (2026-10-29):** the lower bounds of the six stems above come from the optional CC engine with
  `-cc-aut=on` (6 h, yfclab2) and were reproduced with a different search order (`mrv`, 12 h) on the same labels;
  this is the same algorithm, not an independent method. Record: issue #152 and
  `optimization/experiments/GH-152/REPRODUCTION.md` (branch `experiment/gh-152-tanner-aut`).
- **BB_288_12_18 / LP_714_100_16:** distances from main's solver (PI 2026-10-11: no strict cross-verification; partial internal checks agreed so far — `-no-symbreak` reached lb 17 / ub 18 on BB_288 and ub 16 on LP_714; re-check if a later run disagrees).
