# Benchmark matrices

Each code `<stem>` is four text files `<stem>_Hx.txt`, `<stem>_Hz.txt`, `<stem>_Gx.txt`,
`<stem>_Gz.txt` (format: [README](../../README.md#input-four-matrix-files)). The 50 bundled
codes are organized by benchmark tier in `tier0/` … `tier5/` (PI decision 2026-10-11).
Every code is in exactly one tier.

`bin/distqldpc <stem>` resolves a bare name to `data/matrices/<stem>` if `<stem>_Hx.txt`
is there, else to the first of `tier0` … `tier5` that contains it; a name containing `/`
is used as given (`./bin/distqldpc data/matrices/tier3/BB_144_12_12`).
`scripts/benchmark_matrices.py` searches the same way (`--matrices-dir data/matrices/tierN`
restricts it to one tier). `scripts/compute_logicals.py --dir` and
`scripts/preprocess_matrices.py --src` take one flat directory, e.g. `data/matrices/tier0`.

## Tiers

`[[n, k, d]]`: n = columns of Hx, k = rows of Gx, d = certified distance (`{lb}to{ub}` or `ge{lb}` if not
certified).

| Tier | Purpose / timeout | Codes `[[n, k, d]]` |
|------|-------------------|---------------------|
| tier0 | correctness / smoke (small) | LP_34_20_2 [[34,20,2]], TN_36_8_3 [[36,8,3]], TN_36_8_4 [[36,8,4]], TN_54_11_4 [[54,11,4]], BB_72_12_6 [[72,12,6]], TN_72_14_4 [[72,14,4]], TN_72_8_8 [[72,8,8]], TN_108_2_12 [[108,2,12]], LP_136_32_4 [[136,32,4]], TN_200_10_10 [[200,10,10]] |
| tier1 | lightweight performance filter | BB_90_8_10 [[90,8,10]], BB_108_8_10 [[108,8,10]], GB_144_12_8 [[144,12,8]], LP_238_44_6 [[238,44,6]] |
| tier2 | medium filter | LP_340_56_8 [[340,56,8]] |
| tier3 | decisive set | BB_144_12_12 [[144,12,12]], BB_144_14_14 [[144,14,14]], GB_144_12_12 [[144,12,12]], TN_144_2_13 [[144,2,13]], LP_442_68_10 [[442,68,10]], LP_544_80_12 [[544,80,12]] |
| tier4 | hard; timeout 2000 s | TN_250_10_15 [[250,10,15]], BB_288_12_18 [[288,12,18]] |
| tier5 | very hard; timeout 21600 s (6 h) | TN_180_2_17 [[180,2,17]], TN_216_4_18 [[216,4,18]], TN_252_2_17to28 [[252,2,17–28]], TN_288_2_ge9 [[288,2,≥9]], TN_324_4_ge9 [[324,4,≥9]], BB_360_12_17to24 [[360,12,17–24]], TN_360_4_ge17 [[360,4,≥17]], TN_396_4_ge17 [[396,4,≥17]], TN_432_8_ge9 [[432,8,≥9]], TN_468_4_ge17 [[468,4,≥17]], TN_496_2_ge17 [[496,2,≥17]], TN_504_2_ge17 [[504,2,≥17]], TN_540_4_ge9 [[540,4,≥9]], TN_576_2_ge9 [[576,2,≥9]], TN_612_2_ge17 [[612,2,≥17]], TN_648_10_9to52 [[648,10,9–52]], TN_648_14_ge9 [[648,14,≥9]], TN_684_2_ge9 [[684,2,≥9]], BB_756_16_ge17 [[756,16,≥17]], BB_864_4_ge17 [[864,4,≥17]], LP_1020_136_16 [[1020,136,16]], LP_1054_140_17to32 [[1054,140,17–32]], BB_1080_4_ge17 [[1080,4,≥17]], LP_1428_184_ge17 [[1428,184,≥17]], LP_1768_224_ge17 [[1768,224,≥17]], LP_714_100_16 [[714,100,16]] (moved from tier4 2026-10-12: times out at 5000 s on yfclab2) |

Counts: tier0 10, tier1 4, tier2 1, tier3 6, tier4 2, tier5 26 (total 49).

**Timeouts.** tier4: 2000 s per instance on the Mac, 5000 s on yfclab2; tier5: 21600 s (6 h) per instance.
tier0–tier3 are the filtering tiers of the
[optimization loop policy](../../docs/OPTIMIZATION_LOOP_POLICY.md) (Tier 0 correctness/smoke,
Tier 1 lightweight filter, Tier 2 medium filter, Tier 3 decisive set); the policy fixes no
numeric wall-clock limit for them, so the limit is recorded in each experiment's
pre-registered plan and kept identical for baseline and candidate. Note that the policy's
Tier 3 decision set also lists `TN_250_10_15`, which is stored in `tier4/` under the
2026-10-11 layout.

## Naming rule

`{family}_{n}_{k}_{d}` with family in `BB`, `GB`, `LP`, `TN`; n = columns of Hx, k = rows
of Gx, d = minimum distance once our tool has found it (PI 2026-10-11), otherwise the current proven bounds: `{lb}to{ub}` when an upper bound (a logical operator of that weight) is known, `ge{lb}` when only a lower bound is known (PI 2026-10-11: "Unknown可以改成目前上下界"); names are updated when bounds improve; codes with equal n and k are first checked for being the same code (duplicates are removed); genuinely different codes would get a suffix `_a`, `_b`. `GB` keeps its own
prefix (not merged into `BB`). Former `PK_*` / `xu_*` codes are `LP_*`; former `QT_*`
codes are `TN_*`. Upstream ids and attribution are recorded in [NOTICE](../../NOTICE),
section 5.

## Rename history

| Date | Old | New | Note |
|------|-----|-----|------|
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
| 2026-10-11 | LP_1020_136_unknown | LP_1020_136_16 | current bounds: d = 16 solved by main (6 h probe, 2674-2679 s both modes) |
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
| 2026-10-11 | LP_714_100_unknown | LP_714_100_16 | d = 16 found by main 7eadd54 (Mac, 1687 s both modes); same policy |
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
- **TN_648_10_9to52:** d <= 52 (weight-52 nontrivial logicals in the bundled bases); the
  exact distance is unknown.
- **BB_288_12_18 / LP_714_100_16:** distances from main's solver (PI 2026-10-11: no strict cross-verification; partial internal checks agreed so far — `-no-symbreak` reached lb 17 / ub 18 on BB_288 and ub 16 on LP_714; re-check if a later run disagrees).