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

`[[n, k, d]]`: n = columns of Hx, k = rows of Gx, d = certified distance (`unknown` if not
certified).

| Tier | Purpose / timeout | Codes `[[n, k, d]]` |
|------|-------------------|---------------------|
| tier0 | correctness / smoke (small) | LP_34_20_2 [[34,20,2]], TN_36_8_3 [[36,8,3]], TN_36_8_4 [[36,8,4]], TN_54_11_4 [[54,11,4]], BB_72_12_6 [[72,12,6]], TN_72_14_4 [[72,14,4]], TN_72_8_8 [[72,8,8]], TN_108_2_12 [[108,2,12]], LP_136_32_4 [[136,32,4]], TN_200_10_10 [[200,10,10]] |
| tier1 | lightweight performance filter | BB_90_8_10 [[90,8,10]], BB_108_8_10 [[108,8,10]], GB_144_12_8 [[144,12,8]], LP_238_44_6 [[238,44,6]] |
| tier2 | medium filter | LP_340_56_8 [[340,56,8]] |
| tier3 | decisive set | BB_144_12_12 [[144,12,12]], BB_144_14_14 [[144,14,14]], GB_144_12_12 [[144,12,12]], TN_144_2_13 [[144,2,13]], LP_442_68_10 [[442,68,10]], LP_544_80_12 [[544,80,12]] |
| tier4 | hard; timeout 2000 s | TN_250_10_15 [[250,10,15]], BB_288_12_unknown [[288,12,?]], LP_714_100_unknown [[714,100,?]] |
| tier5 | very hard; timeout 21600 s (6 h) | TN_180_2_17 [[180,2,17]], TN_216_4_18 [[216,4,18]], TN_252_2_21 [[252,2,21]], TN_288_2_24 [[288,2,24]], TN_324_4_25 [[324,4,25]], BB_360_12_unknown [[360,12,?]], TN_360_4_24 [[360,4,24]], TN_396_4_26 [[396,4,26]], TN_432_8_33 [[432,8,33]], TN_468_4_31 [[468,4,31]], TN_496_2_32 [[496,2,32]], TN_504_2_45 [[504,2,45]], TN_540_4_40 [[540,4,40]], TN_576_2_57 [[576,2,57]], TN_576_2_59 [[576,2,59]], TN_612_2_52 [[612,2,52]], TN_648_10_unknown [[648,10,?]], TN_648_14_50 [[648,14,50]], TN_684_2_29 [[684,2,29]], BB_756_16_34 [[756,16,34]], BB_864_4_40 [[864,4,40]], LP_1020_136_unknown [[1020,136,?]], LP_1054_140_unknown [[1054,140,?]], BB_1080_4_54 [[1080,4,54]], LP_1428_184_unknown [[1428,184,?]], LP_1768_224_unknown [[1768,224,?]] |

Counts: tier0 10, tier1 4, tier2 1, tier3 6, tier4 3, tier5 26 (total 50).

**Timeouts.** tier4: 2000 s per instance; tier5: 21600 s (6 h) per instance.
tier0–tier3 are the filtering tiers of the
[optimization loop policy](../../docs/OPTIMIZATION_LOOP_POLICY.md) (Tier 0 correctness/smoke,
Tier 1 lightweight filter, Tier 2 medium filter, Tier 3 decisive set); the policy fixes no
numeric wall-clock limit for them, so the limit is recorded in each experiment's
pre-registered plan and kept identical for baseline and candidate. Note that the policy's
Tier 3 decision set also lists `TN_250_10_15`, which is stored in `tier4/` under the
2026-10-11 layout.

## Naming rule

`{family}_{n}_{k}_{d}` with family in `BB`, `GB`, `LP`, `TN`; n = columns of Hx, k = rows
of Gx, d = certified minimum distance, or `unknown` if not certified. `GB` keeps its own
prefix (not merged into `BB`). Former `PK_*` / `xu_*` codes are `LP_*`; former `QT_*`
codes are `TN_*`. Upstream ids and attribution are recorded in [NOTICE](../../NOTICE),
section 5.

## Rename history

| Date | Old | New | Note |
|------|-----|-----|------|
| 2026-10-11 | PK_31 | LP_1054_140_unknown | n=1054, k=140 |
| 2026-10-11 | xu_30 | LP_1020_136_unknown | n=1020, k=136 |
| 2026-10-11 | xu_42 | LP_1428_184_unknown | n=1428, k=184 |
| 2026-10-11 | TN_648_10_71 | TN_648_10_unknown | bundled logical bases contain weight-52 nontrivial logicals, so d <= 52; exact d unknown |
| earlier | BB_144_14_0 | BB_144_14_14 | aligned with QDistSAT |
| earlier | BB_288_12_18 | BB_288_12_unknown | aligned with QDistSAT |
| earlier | BB_360_12_24 | BB_360_12_unknown | aligned with QDistSAT |
| earlier | GB_144_12_24 | GB_144_12_8 | aligned with QDistSAT |
| earlier | GB_144_12_37 | GB_144_12_12 | aligned with QDistSAT |
| earlier | QT_36_8_3, QT_54_11_4, QT_72_14_4, QT_200_10_10, QT_250_10_15 | TN_36_8_3, TN_54_11_4, TN_72_14_4, TN_200_10_10, TN_250_10_15 | QT -> TN |
| earlier | AJ_01, AJ_04, AJ_07, AJ_10, AJ_13, AJ_52; xu_16, xu_21 | LP_34_20_2, LP_136_32_4, LP_238_44_6, LP_340_56_8, LP_442_68_10, LP_1768_224_unknown; LP_544_80_12, LP_714_100_unknown | upstream codeDistancePYPI ids |

## Open items

- **TN_648_10_unknown:** d <= 52 (weight-52 nontrivial logicals in the bundled bases); the
  exact distance is unknown.
- **BB_288_12_unknown / LP_714_100_unknown:** current main reports d = 18 and d = 16
  respectively. These are pending results awaiting internal cross-checks; the stems will be
  renamed to `BB_288_12_18` / `LP_714_100_16` only after the cross-checks agree.
- **TN_360_4_24:** QDistSAT names this code `TN_360_4_unknown`. The discrepancy is
  unresolved and reported, not resolved here.
