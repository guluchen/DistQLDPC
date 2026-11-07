# Benchmark matrices

The 29 library codes of GH-153/154/156/159/199 (repetition and cycle HGP, triangular 6.6.6 color, twisted-torus BB,
collapsed 4D abelian multi-cycle AMC; the last five from #214, placed by the PI on 2026-11-04),
which lived in [untiered/](untiered/README.md), were measured with main 02879a93 on yfclab2 together with every
bundled code and placed into the tiers on 2026-11-04 (PI plan of 2026-11-04; placement table in
[untiered/README.md](untiered/README.md#placement-2026-11-04)). Their generators, MANIFEST.csv (now with
`placed_tier` / `placed_stem` columns), validation evidence and provenance documents stay in untiered/, which
holds no matrices any more. New, unmeasured codes are added there first and stay out of the tier sets and the
QDistSAT mirror until a PI-approved tier assignment; use their full path when invoking DistQLDPC.

Each code `<stem>` is four text files `<stem>_Hx.txt`, `<stem>_Hz.txt`, `<stem>_Gx.txt`,
`<stem>_Gz.txt` (format: [README](../../README.md#input-four-matrix-files)). The 80 bundled
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
| tier0 | correctness / smoke; main < 1 s on yfclab2 | COLOR_7_1_3 [[7,1,3]], HGP_13_1_3 [[13,1,3]], COLOR_19_1_5 [[19,1,5]], BB_30_4_6 [[30,4,6]], LP_34_20_2 [[34,20,2]], TN_36_8_3 [[36,8,3]], TN_36_8_4 [[36,8,4]], HGP_41_1_5 [[41,1,5]], HGP_45_9_3 [[45,9,3]], TN_54_11_4 [[54,11,4]], BB_72_12_6 [[72,12,6]], TN_72_14_4 [[72,14,4]], TN_72_8_8 [[72,8,8]], BB_90_8_10 [[90,8,10]], HGP_106_16_4 [[106,16,4]], AMC_108_6_9 [[108,6,9]], BB_108_8_10 [[108,8,10]], HGP_113_1_8 [[113,1,8]], BB_120_8_12 [[120,8,12]], LP_136_32_4 [[136,32,4]], BB_144_12_12 [[144,12,12]], GB_144_12_8 [[144,12,8]], AMC_216_6_12 [[216,6,12]], LP_238_44_6 [[238,44,6]], HGP_306_36_5 [[306,36,5]], AMC_330_6_14 [[330,6,14]] |
| tier1 | lightweight performance filter; main 1–10 s on yfclab2 | COLOR_127_1_13 [[127,1,13]], GB_144_12_12 [[144,12,12]], BB_186_10_14 [[186,10,14]], HGP_265_1_12 [[265,1,12]], BB_288_12_18 [[288,12,18]], LP_340_56_8 [[340,56,8]], AMC_438_6_17 [[438,6,17]], LP_442_68_10 [[442,68,10]], HGP_610_64_6 [[610,64,6]] |
| tier2 | medium filter; main 10–100 s on yfclab2 | TN_108_2_12 [[108,2,12]], BB_144_14_14 [[144,14,14]], TN_144_2_13 [[144,2,13]], TN_200_10_10 [[200,10,10]], BB_248_10_18 [[248,10,18]], BB_340_16_18 [[340,16,18]], AMC_522_6_20 [[522,6,20]], LP_544_80_12 [[544,80,12]] |
| tier3 | decisive set; main 100–2000 s on yfclab2 | TN_250_10_15 [[250,10,15]], BB_294_10_20 [[294,10,20]], HGP_481_1_16 [[481,1,16]], LP_714_100_16 [[714,100,16]], LP_1020_136_16 [[1020,136,16]], HGP_1261_121_6 [[1261,121,6]], HGP_2866_256_8 [[2866,256,8]] |
| tier4 | hard; main 2000–5000 s on yfclab2; timeout 2000 s Mac / 5000 s yfclab2 | (none) |
| tier5 | open set; main > 5000 s or unsolved on yfclab2; timeout 21600 s (6 h) | TN_180_2_17 [[180,2,17]], TN_216_4_18 [[216,4,18]], TN_252_2_21 [[252,2,21]], TN_288_2_23to24 [[288,2,23–24]], TN_324_4_23to25 [[324,4,23–25]], COLOR_331_1_21 [[331,1,21]], BB_360_12_24 [[360,12,24]], TN_360_4_23to24 [[360,4,23–24]], TN_396_4_23to26 [[396,4,23–26]], TN_432_8_24to29 [[432,8,24–29]], TN_468_4_24to29 [[468,4,24–29]], TN_496_2_28to30 [[496,2,28–30]], TN_504_2_24to34 [[504,2,24–34]], TN_540_4_24to34 [[540,4,24–34]], TN_576_2_25to37 [[576,2,25–37]], TN_612_2_25to40 [[612,2,25–40]], TN_648_10_22to32 [[648,10,22–32]], TN_648_14_22to28 [[648,14,22–28]], TN_684_2_24to29 [[684,2,24–29]], BB_756_16_32to34 [[756,16,32–34]], BB_864_4_32to40 [[864,4,32–40]], COLOR_1027_1_32to37 [[1027,1,32–37]], LP_1054_140_20 [[1054,140,20]], BB_1080_4_34to48 [[1080,4,34–48]], HGP_1105_1_24 [[1105,1,24]], LP_1122_148_20 [[1122,148,20]], LP_1428_184_24 [[1428,184,24]], LP_1768_224_22 [[1768,224,22]], LP_2610_744_16 [[2610,744,16]], COLOR_2791_1_29to61 [[2791,1,29–61]] |

Counts: tier0 26, tier1 9, tier2 8, tier3 7, tier4 0, tier5 30 (total 80).

**Tier assignment rule (PI 2026-10-12):** by main's time on yfclab2 (slower of no-card / card-mto, `optimization/baselines/SERVER.md`): < 1 s tier0, 1–10 s tier1, 10–100 s tier2, 100–2000 s tier3, 2000–5000 s tier4, > 5000 s or unsolved tier5. Re-check placements when main changes. 2026-11-04 (main 02879a93 baseline of all 75 codes, 5000 s panel limit for every code, `optimization/baselines/SERVER.md`; PI plan 2026-11-04): BB_288_12_18 tier2 -> tier1 (9.58 s), GB_144_12_12 tier2 -> tier1 (1.10 s), TN_144_2_13 tier3 -> tier2 (88.17 s), TN_250_10_15 tier4 -> tier3 (1283 s), LP_1020_136_16 tier5 -> tier3 (393 s); the 29 library codes placed by the same rule (tier0: COLOR_7_1_3, HGP_13_1_3, COLOR_19_1_5, BB_30_4_6, HGP_41_1_5, HGP_45_9_3, HGP_106_16_4, AMC_108_6_9, HGP_113_1_8, BB_120_8_12, AMC_216_6_12, HGP_306_36_5, AMC_330_6_14; tier1: COLOR_127_1_13, BB_186_10_14, HGP_265_1_12, AMC_438_6_17, HGP_610_64_6; tier2: BB_248_10_18, BB_340_16_18, AMC_522_6_20; tier3: BB_294_10_20, HGP_481_1_16, HGP_1261_121_6, HGP_2866_256_8; tier5: COLOR_331_1_21, COLOR_1027_1_32to37, HGP_1105_1_24, COLOR_2791_1_29to61). Codes that main solves within 6 h but over 5000 s stay in tier5 (TN_180_2_17, TN_216_4_18, BB_360_12_24, LP_1122_148_20); HGP_1105_1_24 is in tier5 because MaxSAT does not solve it in 6 h (the CC engine does, in 72-189 s). COLOR_331_1_21 goes to tier 5: MaxSAT solves it in 4300-4600 s on some seeds but its slower-mode 5-seed median is >= 5000 s (no-card seeds 0 and 2 over 5000 s; seed 0 solved after 6472 s), so tier 4 is empty after this re-tier. 2026-10-23 (main c914ef5 baseline, PR #142; PI): LP_442_68_10 tier2 -> tier1, BB_288_12_18 tier3 -> tier2, LP_714_100_16 tier4 -> tier3 (LP_1020_136_16 pending a 5-seed measurement). 2026-10-21 (main cbb0642, -frontier=auto; PI): BB_108_8_10, BB_144_12_12, LP_238_44_6 tier1 -> tier0; GB_144_12_12, LP_544_80_12, TN_200_10_10 tier3 -> tier2; LP_714_100_16 tier5 -> tier4 (optimization/baselines/SERVER.md). 2026-10-14 (main 398054e, GH-107; PI): BB_144_14_14 tier3 -> tier2 (72.7 s), BB_288_12_18 tier4 -> tier3 (919 s).

**Timeouts.** tier4: 2000 s per instance on the Mac, 5000 s on yfclab2; tier5: 21600 s (6 h) per instance.
tier0–tier3 are the filtering tiers of the
[optimization loop policy](../../docs/OPTIMIZATION_LOOP_POLICY.md) (Tier 0 correctness/smoke,
Tier 1 lightweight filter, Tier 2 medium filter, Tier 3 decisive set); the policy fixes no
numeric wall-clock limit for them, so the limit is recorded in each experiment's
pre-registered plan and kept identical for baseline and candidate. 

## Naming rule

`{family}_{n}_{k}_{d}` with family in `AMC`, `BB`, `COLOR`, `GB`, `HGP`, `LP`, `TN` (`HGP` = hypergraph product, `COLOR` = 6.6.6 color code, `AMC` = abelian multi-cycle, all 2026-11-04; the twisted-torus codes keep `BB`); n = columns of Hx, k = rows
of Gx, d = minimum distance once our tool has found it (PI 2026-10-11), otherwise the current proven bounds: `{lb}to{ub}` when an upper bound (a logical operator of that weight) is known, `ge{lb}` when only a lower bound is known (PI 2026-10-11: "Unknown可以改成目前上下界"); names are updated when bounds improve; codes with equal n and k are first checked for being the same code (duplicates are removed); genuinely different codes would get a suffix `_a`, `_b`. `GB` keeps its own
prefix (not merged into `BB`). Former `PK_*` / `xu_*` codes are `LP_*`; former `QT_*`
codes are `TN_*`. Upstream ids and attribution are recorded in [NOTICE](../../NOTICE),
section 5.

## Rename history

**Independent validation credit (GH-150):** PolyLabs Research reported a separate,
clean-room check-driven cluster-search implementation confirming the earlier
`30 <= d <= 34` bounds for `BB_756_16` and `d = 24` for `BB_360_12`, with
independently GF(2)-checked witnesses. This checks the implementations within the
same method family, not an independent method, and does not validate the later
`BB_756_16` lower bound of 32. See the [original report](https://github.com/guluchen/DistQLDPC/issues/150)
and [credit request and per-pass records](https://github.com/guluchen/DistQLDPC/issues/150#issuecomment-6631689406).

| Date | Old | New | Note |
|------|-----|-----|------|
| 2026-11-07 | BB_1080_4_32to48 | BB_1080_4_34to48 | lb 34: main 755e0c21's CC default (gated erasure), 12 h: lb 34 at 40 586 s; main 1239e9a2's CC default plus ungated `erasure`, 24 h: lb 34 at 44 390 s; level 32 EMPTY in both (X half under the verified dual map; odd levels skipped by the parity rule), 36.4G vs 7.1G nodes at level 32 (different trees); same engine, not an independent second method; records `optimization/experiments/GH-225/lb-push/`. ub unchanged (GH-146 witness; copy in `optimization/experiments/GH-146/witnesses/renamed-2026-11-07/`) |
| 2026-11-07 | TN_288_2_22to24 | TN_288_2_23to24 | lb 23: CC lower bound from the GH-225 follow-up (12 h, yfclab2, seed 0; records `optimization/experiments/GH-225/lb-push/`): main 755e0c21's CC default (gated erasure) lb 23 at 30 093 s, and main 1239e9a2's CC default plus ungated `erasure` lb 23 at 30 030 s; level 22 EMPTY on both halves in both runs, with different node counts (different trees); same engine, not an independent second method. ub unchanged (GH-146 witness; copy under the new stem in `optimization/experiments/GH-146/witnesses/renamed-2026-11-07/`) |
| 2026-11-07 | TN_432_8_23to29 | TN_432_8_24to29 | lb 24 (as above): 755e0c21 default 29 251 s; 1239e9a2 plus erasure 29 784 s; 1239e9a2 default without erasure 38 938 s; ub unchanged |
| 2026-11-07 | TN_468_4_23to29 | TN_468_4_24to29 | lb 24 (as above): 755e0c21 default 38 806 s; 1239e9a2 plus erasure 38 061 s; ub unchanged |
| 2026-11-07 | TN_576_2_24to37 | TN_576_2_25to37 | lb 25 (as above): 755e0c21 default 28 223 s; 1239e9a2 plus erasure 30 871 s; 1239e9a2 default without erasure 34 316 s; ub unchanged |
| 2026-11-07 | TN_612_2_24to40 | TN_612_2_25to40 | lb 25 (as above): 755e0c21 default 35 008 s; 1239e9a2 plus erasure 37 476 s; 1239e9a2 default without erasure 42 105 s; ub unchanged |
| 2026-11-07 | COLOR_1027_1_31to37 | COLOR_1027_1_32to37 | lb 32: 755e0c21 default (gated erasure), 12 h: lb 32 at 38 288 s; 1239e9a2 plus ungated erasure with `-cc-roworder=index` (the tree of the GH-225 erasure run; `optimization/experiments/GH-225/lb-repro/`): lb 32 at 37 190 s; level 31 EMPTY (X half only, Hx = Hz), node counts differ; same engine, not an independent second method; ub unchanged (family formula d = 37) |
| 2026-11-07 | COLOR_2791_1_28to61 | COLOR_2791_1_29to61 | lb 29: 755e0c21 default (GH-227 arm C, 6 h: 20 721 s; repeated with `-cc-roworder=index`, 12 h: 20 425 s, essentially the same order) and 755e0c21 with `-cc-roworder=bfs` (12 h, a different tree): lb 29 at 37 963 s; level 28 EMPTY (X half only); same engine, not an independent second method; ub unchanged (family formula d = 61) |
| 2026-11-06 | TN_324_4_22to25 | TN_324_4_23to25 | lb 23: CC lower bound first reached by the GH-225 erasure arm (issue #225; binary 5a201fd = the GH-217 CC default plus `erasure`, yfclab2, 6 h, seed 0): lb 23 at 20 985 s. Reproduction (12 h, main 1239e9a2 with `-cc-rules=excl,pack,orbf,parity,leaf,overlap,charge,tiebreak,sparse,sparseov,sparsemrv,erasure`, ungated): relabelled qubits and rows `-seed=1` lb 23 at 30 309 s, `-seed=2` at 31 369 s; level 22 EMPTY on both halves; node counts differ from the original at every high level; same engine, not an independent second method; records `optimization/experiments/GH-225/lb-repro/`. Without erasure: lb 22 (6 h seed 0; 12 h `-seed=1`). ub unchanged (GH-146 witness; copy under the new stem in `optimization/experiments/GH-146/witnesses/renamed-2026-11-06/`) |
| 2026-11-06 | TN_496_2_27to30 | TN_496_2_28to30 | lb 28 (as above): GH-225 erasure arm 17 996 s; GH-227 candidate (#227, main 755e0c21, gated erasure in the default) 19 683 s; reproduction with erasure `-seed=1` 20 699 s, `-seed=2` 19 095 s (`-cc-roworder=bfs` 19 856 s, the same tree as the GH-225 run); without erasure lb 27 at seed 0 (6 h) but lb 28 with `-seed=1` (24 919 s, 12 h); X half under the verified XZ-dual map; ub unchanged |
| 2026-11-06 | TN_540_4_23to34 | TN_540_4_24to34 | lb 24 (as above): GH-225 erasure arm 19 168 s; GH-227 candidate 18 399 s; reproduction with erasure `-seed=1` 35 026 s, `-seed=2` 32 893 s; without erasure lb 23 at seed 0 (6 h), lb 24 with `-seed=1` (42 322 s, 12 h); both halves EMPTY; ub unchanged |
| 2026-11-06 | TN_648_14_21to28 | TN_648_14_22to28 | lb 22 (as above): GH-225 erasure arm 20 292 s; GH-227 candidate 19 331 s; reproduction with erasure `-seed=1` 35 385 s, `-seed=2` 36 573 s; without erasure lb 21 at seed 0 (6 h), lb 22 with `-seed=1` (36 164 s, 12 h); both halves EMPTY; ub unchanged |
| 2026-11-06 | TN_684_2_22to29 | TN_684_2_24to29 | lb 24: lb 23 was reached by all four 6 h runs of GH-225 / GH-227 (with and without erasure; 16 367-21 196 s). In the 12 h reproduction (main 1239e9a2 plus `erasure`), the relabelled runs `-seed=1` and `-seed=2` reached lb 23 at 13 945 s / 14 375 s and lb 24 at 39 232 s / 39 063 s; level 23 EMPTY on both halves in both runs, with different node counts (different trees); without erasure `-seed=1` reached lb 23 (17 570 s). Same engine, not an independent second method; ub unchanged |
| 2026-11-06 | COLOR_1027_1_28to37 | COLOR_1027_1_31to37 | lb 31 (as above): GH-225 erasure arm 16 090 s; GH-227 candidate (gated erasure) 18 190 s; reproduction with erasure and a different row order, `-cc-roworder=bfs`: lb 31 at 33 206 s (different tree). Without erasure lb 30 (6 h, seed 0). X half only (Hx = Hz, verified XZ-dual map). Relabelled runs (`-seed=1/2`) are much slower on this code and reached lb 29 in 12 h. A `-cc-roworder=index` run with erasure searched the same tree as the GH-225 erasure run and reached lb 32 at 37 190 s; lb 32 is a single tree and stays PLAUSIBLE. ub unchanged (family formula d = 37) |
| 2026-11-06 | COLOR_2791_1_26to61 | COLOR_2791_1_28to61 | lb 28: CC default without erasure (GH-225 arm A, binary 42d7d1d: 10 312 s; GH-227 arm M, main 1239e9a2: 11 706 s; the same tree) and the GH-227 candidate (main 755e0c21, gated erasure in the default; a different tree): lb 28 at 9 612 s; 6 h, seed 0; X half only (Hx = Hz). The candidate went on to lb 29 at 20 721 s; that is a single run and stays PLAUSIBLE. Same engine, not an independent second method; ub unchanged (family formula d = 61) |
| 2026-11-05 | TN_468_4_17to29 | TN_468_4_23to29 | lb 23: CC lower bound from GH-217 (issue #217, PR #220; yfclab2, 6 h, default seed): lb 23 at 19 263 s (main) / 19 518 s (candidate), reached both by main 02879a93's CC default (`excl,pack,orbf,parity,leaf,overlap,charge`, `-cc-roworder=index`) and by the GH-217 candidate bb3e2efc (`+tiebreak,sparse,sparseov,sparsemrv`, `-cc-roworder=auto`); every level EMPTY on both halves. Reproduction: candidate with relabelled qubits and rows (`-seed=1`, 30000 s; node counts differ at every high level); same engine, not an independent second method; `optimization/experiments/GH-217/` on branch `experiment/gh-217-cc-default-flip`. ub unchanged (GH-146 witness; copy under the new stem in `optimization/experiments/GH-146/witnesses/renamed-2026-11-05/`); relabelled lb 23 at 25 088 s |
| 2026-11-05 | TN_612_2_17to40 | TN_612_2_24to40 | lb 24 (GH-217 CC lower bound as above: main 15 922 s, candidate 15 676 s; relabelled 24 335 s); ub unchanged |
| 2026-11-05 | TN_648_14_9to28 | TN_648_14_21to28 | lb 21 (GH-217 CC lower bound as above: main 9 661 s, candidate 9 907 s; relabelled 12 933 s); ub unchanged |
| 2026-11-05 | TN_684_2_9to29 | TN_684_2_22to29 | lb 22 (GH-217 CC lower bound as above: main 12 181 s, candidate 9 035 s with a different tree; relabelled 6 279 s); ub unchanged |
| 2026-11-04 | untiered/COLOR_7_1_unknown | COLOR_7_1_3 | placed in tier0; d = 3 found by main 02879a93 on yfclab2 (MaxSAT slower-mode 5-seed median 0.04 s; CC default median 0.06 s); a weight-3 logical GF(2)-verified (pure-Python check); agrees with the claimed d = 3 |
| 2026-11-04 | untiered/HGP_13_1_unknown | HGP_13_1_3 | placed in tier0; d = 3 found by main 02879a93 on yfclab2 (MaxSAT slower-mode 5-seed median 0.05 s; CC default median 0.08 s); a weight-3 logical GF(2)-verified (pure-Python check); agrees with the claimed d = 3 |
| 2026-11-04 | untiered/COLOR_19_1_unknown | COLOR_19_1_5 | placed in tier0; d = 5 found by main 02879a93 on yfclab2 (MaxSAT slower-mode 5-seed median 0.06 s; CC default median 0.09 s); a weight-5 logical GF(2)-verified (pure-Python check); agrees with the claimed d = 5 |
| 2026-11-04 | untiered/BB_30_4_unknown | BB_30_4_6 | placed in tier0; d = 6 found by main 02879a93 on yfclab2 (MaxSAT slower-mode 5-seed median 0.05 s; CC default median 0.08 s); a weight-6 logical GF(2)-verified (pure-Python check); agrees with the claimed d = 6 |
| 2026-11-04 | untiered/HGP_41_1_unknown | HGP_41_1_5 | placed in tier0; d = 5 found by main 02879a93 on yfclab2 (MaxSAT slower-mode 5-seed median 0.08 s; CC default median 0.09 s); a weight-5 logical GF(2)-verified (pure-Python check); agrees with the claimed d = 5 |
| 2026-11-04 | untiered/HGP_45_9_unknown | HGP_45_9_3 | placed in tier0; d = 3 found by main 02879a93 on yfclab2 (MaxSAT slower-mode 5-seed median 0.06 s; CC default median 0.08 s); a weight-3 logical GF(2)-verified (pure-Python check); agrees with the claimed d = 3 |
| 2026-11-04 | untiered/HGP_106_16_unknown | HGP_106_16_4 | placed in tier0; d = 4 found by main 02879a93 on yfclab2 (MaxSAT slower-mode 5-seed median 0.11 s; CC default median 0.08 s); a weight-4 logical GF(2)-verified (pure-Python check); agrees with the claimed d = 4 |
| 2026-11-04 | untiered/AMC_108_6_unknown | AMC_108_6_9 | placed in tier0; d = 9 found by main 02879a93 on yfclab2 (MaxSAT slower-mode 5-seed median 0.14 s; CC default median 0.08 s); a weight-9 logical GF(2)-verified (pure-Python check); agrees with the claimed d = 9 |
| 2026-11-04 | untiered/HGP_113_1_unknown | HGP_113_1_8 | placed in tier0; d = 8 found by main 02879a93 on yfclab2 (MaxSAT slower-mode 5-seed median 0.11 s; CC default median 0.07 s); a weight-8 logical GF(2)-verified (pure-Python check); agrees with the claimed d = 8 |
| 2026-11-04 | untiered/BB_120_8_unknown | BB_120_8_12 | placed in tier0; d = 12 found by main 02879a93 on yfclab2 (MaxSAT slower-mode 5-seed median 0.59 s; CC default median 0.08 s); a weight-12 logical GF(2)-verified (pure-Python check); agrees with the claimed d = 12 |
| 2026-11-04 | untiered/AMC_216_6_unknown | AMC_216_6_12 | placed in tier0; d = 12 found by main 02879a93 on yfclab2 (MaxSAT slower-mode 5-seed median 0.37 s; CC default median 0.08 s); a weight-12 logical GF(2)-verified (pure-Python check); agrees with the published estimate 12 (randomized information sets, not a certified bound) |
| 2026-11-04 | untiered/HGP_306_36_unknown | HGP_306_36_5 | placed in tier0; d = 5 found by main 02879a93 on yfclab2 (MaxSAT slower-mode 5-seed median 0.42 s; CC default median 0.06 s); a weight-5 logical GF(2)-verified (pure-Python check); agrees with the claimed d = 5 |
| 2026-11-04 | untiered/AMC_330_6_unknown | AMC_330_6_14 | placed in tier0; d = 14 found by main 02879a93 on yfclab2 (MaxSAT slower-mode 5-seed median 0.82 s; CC default median 0.07 s); a weight-14 logical GF(2)-verified (pure-Python check); agrees with the published estimate 14 (randomized information sets, not a certified bound) |
| 2026-11-04 | untiered/COLOR_127_1_unknown | COLOR_127_1_13 | placed in tier1; d = 13 found by main 02879a93 on yfclab2 (MaxSAT slower-mode 5-seed median 1.60 s; CC default median 0.08 s); a weight-13 logical GF(2)-verified (pure-Python check); agrees with the claimed d = 13 |
| 2026-11-04 | untiered/BB_186_10_unknown | BB_186_10_14 | placed in tier1; d = 14 found by main 02879a93 on yfclab2 (MaxSAT slower-mode 5-seed median 1.22 s; CC default median 0.08 s); a weight-14 logical GF(2)-verified (pure-Python check); agrees with the claimed d = 14 |
| 2026-11-04 | untiered/HGP_265_1_unknown | HGP_265_1_12 | placed in tier1; d = 12 found by main 02879a93 on yfclab2 (MaxSAT slower-mode 5-seed median 1.93 s; CC default median 0.09 s); a weight-12 logical GF(2)-verified (pure-Python check); agrees with the claimed d = 12 |
| 2026-11-04 | untiered/AMC_438_6_unknown | AMC_438_6_17 | placed in tier1; d = 17 found by main 02879a93 on yfclab2 (MaxSAT slower-mode 5-seed median 9.08 s; CC default median 0.12 s); a weight-17 logical GF(2)-verified (pure-Python check); agrees with the published estimate 17 (randomized information sets, not a certified bound) |
| 2026-11-04 | untiered/HGP_610_64_unknown | HGP_610_64_6 | placed in tier1; d = 6 found by main 02879a93 on yfclab2 (MaxSAT slower-mode 5-seed median 9.53 s; CC default median 0.19 s); a weight-6 logical GF(2)-verified (pure-Python check); agrees with the claimed d = 6 |
| 2026-11-04 | untiered/BB_248_10_unknown | BB_248_10_18 | placed in tier2; d = 18 found by main 02879a93 on yfclab2 (MaxSAT slower-mode 5-seed median 33.00 s; CC default median 0.55 s); a weight-18 logical GF(2)-verified (pure-Python check); agrees with the claimed d = 18 |
| 2026-11-04 | untiered/BB_340_16_unknown | BB_340_16_18 | placed in tier2; d = 18 found by main 02879a93 on yfclab2 (MaxSAT slower-mode 5-seed median 28.85 s; CC default median 0.32 s); a weight-18 logical GF(2)-verified (pure-Python check); agrees with the claimed d = 18 |
| 2026-11-04 | untiered/AMC_522_6_unknown | AMC_522_6_20 | placed in tier2; d = 20 found by main 02879a93 on yfclab2 (MaxSAT slower-mode 5-seed median 55.43 s; CC default median 0.57 s); a weight-20 logical GF(2)-verified (pure-Python check); agrees with the published estimate 20 (randomized information sets, not a certified bound) |
| 2026-11-04 | untiered/BB_294_10_unknown | BB_294_10_20 | placed in tier3; d = 20 found by main 02879a93 on yfclab2 (MaxSAT slower-mode 5-seed median 610 s; CC default median 2.34 s); a weight-20 logical GF(2)-verified (pure-Python check); agrees with the claimed d = 20 |
| 2026-11-04 | untiered/HGP_481_1_unknown | HGP_481_1_16 | placed in tier3; d = 16 found by main 02879a93 on yfclab2 (MaxSAT slower-mode 5-seed median 120 s; CC default median 0.24 s); a weight-16 logical GF(2)-verified (pure-Python check); agrees with the claimed d = 16 |
| 2026-11-04 | untiered/HGP_1261_121_unknown | HGP_1261_121_6 | placed in tier3; d = 6 found by main 02879a93 on yfclab2 (MaxSAT slower-mode 5-seed median 107 s; CC default median 3.40 s); a weight-6 logical GF(2)-verified (pure-Python check); agrees with the claimed d = 6 |
| 2026-11-04 | untiered/HGP_2866_256_unknown | HGP_2866_256_8 | placed in tier3; d = 8 found by main 02879a93 on yfclab2 (MaxSAT slower-mode 5-seed median 562 s; CC default median 257 s); a weight-8 logical GF(2)-verified (pure-Python check); agrees with the claimed d = 8 |
| 2026-11-04 | untiered/COLOR_331_1_unknown | COLOR_331_1_21 | placed in tier5; d = 21 found by main 02879a93 on yfclab2 with the CC engine (`-engine=cc`, default rules, median 122 s; opt-in full rules median 13.65 s) and MaxSAT solves it on most seeds (seed 0: 6472 s no-card, 7914 s card-mto; seeds 1-4 about 4300-4600 s) with a slower-mode median >= 5000 s, hence tier 5; a weight-21 logical GF(2)-verified (pure-Python check); agrees with the claimed d = 21 |
| 2026-11-04 | untiered/COLOR_1027_1_unknown | COLOR_1027_1_28to37 | placed in tier5; lower bound 28: every level below 28 proven EMPTY by main 02879a93's CC engine in two different searches (default rules, 6 h: lb 29; opt-in full rules `-cc-rules=excl,pack,orbf,parity,leaf,overlap,charge,tiebreak,sparse,sparseov,sparsemrv -cc-roworder=auto`, 5000 s: lb 28); lb 29 is PLAUSIBLE only: a relabeled CC run (`-seed=1`) was 3-6x slower per level and was stopped at level 23; upper bound 37: a weight-37 logical (a row of the bundled Gz basis) GF(2)-verified; MaxSAT reaches only lb 17 in 6 h; consistent with the claimed d = 37 (claims never enter the stem) |
| 2026-11-04 | untiered/HGP_1105_1_unknown | HGP_1105_1_24 | placed in tier5; d = 24 found by main 02879a93 on yfclab2 with the CC engine (`-engine=cc`, default rules, median 181 s; opt-in full rules median 3.86 s) and MaxSAT does not solve it within 6 h in either mode (lb 17, ub 24), hence tier 5; a weight-24 logical GF(2)-verified (pure-Python check); agrees with the claimed d = 24 |
| 2026-11-04 | untiered/COLOR_2791_1_unknown | COLOR_2791_1_26to61 | placed in tier5; lower bound 26: every level below 26 proven EMPTY by main 02879a93's CC engine in two different searches (default rules, 6 h: lb 28; default rules 5000 s and opt-in full rules 5000 s: lb 26); lb 28 is PLAUSIBLE only: a relabeled CC run (`-seed=1`) was slower per level and was stopped at level 21; upper bound 61: a weight-61 logical (a row of the bundled Gz basis) GF(2)-verified; MaxSAT reaches lb 17 in 6 h; consistent with the claimed d = 61 |
| 2026-10-31 | TN_360_4_17to24 | TN_360_4_23to24 | lb 23: CC lower bound from GH-157 (issue #157, PR #161): DistQLDPC's optional CC engine with the `charge` rule (fractional LP-dual node bound; opt-in when found, default CC rule on main since PR #161); levels up to 22 completed EMPTY on both halves (yfclab2, 6 h, binary c3c315d). Reproduction: same binary c3c315d and labels, different search order (`-cc-rules=excl,pack,orbf,parity,leaf,overlap,charge,mrv`, 12 h), every level EMPTY, same lb; same engine and rule, not an independent second method; `optimization/experiments/GH-157/REPRODUCTION.md`. ub unchanged (GH-146 witness; copy under the new stem in `optimization/experiments/GH-146/witnesses/renamed-2026-10-31/`) (PI 2026-10-31) |
| 2026-10-31 | TN_396_4_17to26 | TN_396_4_23to26 | lb 23 (GH-157 CC lower bound with `charge`, reproduced with the `mrv` order, as above); ub unchanged |
| 2026-10-31 | TN_504_2_17to34 | TN_504_2_24to34 | lb 24 (GH-157 CC lower bound with `charge`, reproduced with the `mrv` order, as above); ub unchanged |
| 2026-10-31 | TN_648_10_9to32 | TN_648_10_22to32 | lb 22 (GH-157 CC lower bound with `charge`, no symmetry used, reproduced with the `mrv` order, as above); ub unchanged |
| 2026-10-31 | BB_1080_4_30to48 | BB_1080_4_32to48 | lb 32: CC lower bound from GH-162 (issue #162, PR #180): opt-in `tiebreak` rule (orbit-compatible even-weight overlap tie-break; not on main), seed 0, lb 32 at 19 378 s (yfclab2, 6 h, binary 97c8629); levels 2-30 EMPTY (X half under the verified dual map; odd levels skipped by the parity rule). Reproduction: two GH-183 Tier 5 runs (issue #183, PR #204, binary d26070d) with a different search order (`tiebreak,mrv`, `-cc-roworder=bfs`, one also `-cc-tbbase=asc`): lb 32 at 7 127 s and 6 739 s, every level EMPTY, node counts differ at every level from 6 on; same engine and `tiebreak` rule, not an independent second method. ub unchanged (GH-146 witness, copy as above) (PI 2026-10-31) |
| 2026-10-31 | BB_756_16_30to34 | BB_756_16_32to34 | lb 32: CC lower bound from GH-183 (issue #183, PR #204): opt-in `tiebreak` (GH-162) with `mrv` and `-cc-roworder=bfs` (not on main), binary d26070d, 6 h, lb 32 at 10 437 s; level 30 EMPTY certifies 32 (all column weights odd, parity rule). Reproduction: same binary and configuration with relabeled seeds 1-3 (different qubit and row order, different orbit representatives), 8 h, all three reach lb 32 with every level EMPTY (GH-183 cross-check, 9/9 runs REPRODUCED); same engine and rules, not an independent second method; `optimization/experiments/GH-183/S3_xcheck/` on branch `experiment/gh-183-cc-roworder`. ub unchanged (GH-146 witness, copy as above) (PI 2026-10-31) |
| 2026-10-31 | BB_864_4_30to40 | BB_864_4_32to40 | lb 32 (GH-183 CC lower bound, 6 h lb 32 at 9 951 s; reproduced with relabeled seeds 1-3, 8 h, as above); ub unchanged |
| 2026-10-31 | TN_496_2_23to30 | TN_496_2_27to30 | lb 27: CC lower bound from GH-181 (issue #181, PR #203): opt-in `sparse,sparseov,sparsemrv` rules (redundant pair-sum checks; not on main), 6 h, seeds 0, 1 and 2 all reach lb 27 (X half under the verified XZ-dual map). Cross-check by a different binary (`sparse,sparseov,sparsemrv,tiebreak`, scratch merge with GH-162 97c86299), seeds 0 and 3, 8 h: lb 27 at 11 864 s and 10 739 s, every level 1-26 EMPTY; same engine, not an independent second method; `optimization/experiments/GH-181/XC27/` on branch `experiment/gh-181-cc-sparse-rows` (commit f0afded3). ub unchanged (GH-146 witness, copy as above) (PI 2026-10-31) |
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
- **TN_648_10_22to32:** d <= 32 (GH-146 verified witness; the bundled bases contain weight-52
  nontrivial logicals); lb 22 from GH-157 (2026-10-31); the exact distance is unknown.
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
  Eight stems were renamed on 2026-10-31 (TN_360_4_23to24, TN_396_4_23to26, TN_504_2_24to34, TN_648_10_22to32,
  BB_1080_4_32to48, BB_756_16_32to34, BB_864_4_32to40, TN_496_2_27to30); their older copies in `renamed/` and
  `GH-152/witnesses/` no longer resolve, and copies under the current stems are in
  `optimization/experiments/GH-146/witnesses/renamed-2026-10-31/` (same supports, `VERIFY.txt`: 8/8 VALID), checked
  with the same command on `optimization/experiments/GH-146/witnesses/renamed-2026-10-31/*.w*.txt`.
  Five TN stems were renamed on 2026-11-06 (TN_324_4_23to25, TN_496_2_28to30, TN_540_4_24to34, TN_648_14_22to28,
  TN_684_2_24to29); copies of their witnesses under the current stems are in
  `optimization/experiments/GH-146/witnesses/renamed-2026-11-06/` (same supports, `VERIFY.txt`: 5/5 VALID).
  Six more stems were renamed on 2026-11-07 (TN_288_2_23to24, TN_432_8_24to29, TN_468_4_24to29, TN_576_2_25to37,
  TN_612_2_25to40, BB_1080_4_34to48); copies under the current stems are in
  `optimization/experiments/GH-146/witnesses/renamed-2026-11-07/` (same supports, `VERIFY.txt`: 6/6 VALID).
- **GH-152 lower bounds (2026-10-29):** the lower bounds of the six stems above come from the optional CC engine with
  `-cc-aut=on` (6 h, yfclab2) and were reproduced with a different search order (`mrv`, 12 h) on the same labels;
  this is the same algorithm, not an independent method. Record: issue #152 and
  `optimization/experiments/GH-152/REPRODUCTION.md` (branch `experiment/gh-152-tanner-aut`). TN_496 was renamed
  again on 2026-10-31 (TN_496_2_27to30, GH-181).
- **2026-10-31 lower bounds (GH-157, GH-162/GH-183, GH-181):** each lower bound of the eight stems renamed that day
  comes from DistQLDPC's own CC engine with a rule that was opt-in when the bound was found: `charge` (GH-157, the
  default CC rule on main since PR #161), and `tiebreak` with `mrv` / `-cc-roworder=bfs` (PRs #180 / #204) and
  `sparse,sparseov,sparsemrv` (PR #203), which are not yet on main. Each was reproduced with a different search order
  or binary of the same engine. This is not an independent second method. Records: issues
  #157, #162, #183, #181 and the rename-history rows above.
- **BB_288_12_18 / LP_714_100_16:** distances from main's solver (PI 2026-10-11: no strict cross-verification; partial internal checks agreed so far — `-no-symbreak` reached lb 17 / ub 18 on BB_288 and ub 16 on LP_714; re-check if a later run disagrees).

GH-199 cyclic collapsed4D AMC finite prescriptions (untiered work branch):
see [COLLAPSED_AMC.md](untiered/COLLAPSED_AMC.md). Source randomized
distance estimates remain distinct from exact claims and actual bounds.
