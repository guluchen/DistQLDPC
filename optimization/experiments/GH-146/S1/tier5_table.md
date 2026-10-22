| Code | Engine / mode | baseline (GH-140 CC / GH-144 MaxSAT) | lb | ub @ s | **new finder (-ub-isd=stern)** | lb | ub @ s | change |
|---|---|---|---:|---|---|---:|---|---|
| BB_360_12_24 | cc | d=24 @ 194 s | 24 | 24 @ 0.1 | d=24 @ 205 s | 24 | 24 @ 0.0 | 1.06x time |
| BB_360_12_24 | no-card | TIMEOUT | 18 | 24 @ 0.1 | TIMEOUT | 18 | 24 @ 0.1 |  |
| BB_360_12_24 | card-mto | TIMEOUT | 18 | 24 @ 0.2 | TIMEOUT | 18 | 24 @ 0.1 |  |
| BB_756_16_ge30 | cc | TIMEOUT | 30 | 34 @ 344.1 | TIMEOUT | 30 | 34 @ 5.8 |  |
| BB_756_16_ge30 | no-card | TIMEOUT | 18 | 34 @ 8.4 | TIMEOUT | 18 | 34 @ 9.6 |  |
| BB_756_16_ge30 | card-mto | TIMEOUT | 18 | 34 @ 8.3 | TIMEOUT | 18 | 34 @ 9.6 |  |
| BB_864_4_ge30 | cc | TIMEOUT | 30 | 42 @ 10870.0 | TIMEOUT | 30 | 42 @ 3849.5 |  |
| BB_864_4_ge30 | no-card | TIMEOUT | 18 | 52 @ 10.3 | TIMEOUT | 18 | 50 @ 12.6 | ub 52->50 |
| BB_864_4_ge30 | card-mto | TIMEOUT | 18 | 52 @ 12.1 | TIMEOUT | 18 | 50 @ 12.6 | ub 52->50 |
| BB_1080_4_ge30 | cc | TIMEOUT | 30 | 66 @ 0.1 | TIMEOUT | 30 | 66 @ 0.1 |  |
| BB_1080_4_ge30 | no-card | TIMEOUT | 18 | 70 @ 16.8 | TIMEOUT | 18 | 60 @ 30.1 | ub 70->60 |
| BB_1080_4_ge30 | card-mto | TIMEOUT | 18 | 70 @ 16.9 | TIMEOUT | 18 | 60 @ 27.5 | ub 70->60 |
| LP_1020_136_16 | cc | d=16 @ 0 s | 16 | 16 @ 0.3 | d=16 @ 1 s | 16 | 16 @ 0.1 | 0.52x time |
| LP_1020_136_16 | no-card | d=16 @ 1254 s | 16 | 16 @ 1.1 | d=16 @ 1082 s | 16 | 16 @ 0.6 | 0.86x time |
| LP_1020_136_16 | card-mto | d=16 @ 1247 s | 16 | 16 @ 1.1 | d=16 @ 1078 s | 16 | 16 @ 0.5 | 0.86x time |
| LP_1054_140_20 | cc | d=20 @ 18 s | 20 | 20 @ 0.5 | d=20 @ 19 s | 20 | 20 @ 1.0 | 1.04x time |
| LP_1054_140_20 | no-card | TIMEOUT | 18 | 20 @ 3.4 | TIMEOUT | 18 | 20 @ 0.9 |  |
| LP_1054_140_20 | card-mto | TIMEOUT | 18 | 20 @ 3.4 | TIMEOUT | 18 | 20 @ 0.9 |  |
| LP_1122_148_20 | cc | d=20 @ 25 s | 20 | 20 @ 0.5 | d=20 @ 17 s | 20 | 20 @ 0.2 | 0.67x time |
| LP_1122_148_20 | no-card | TIMEOUT | 18 | 20 @ 5.1 | TIMEOUT | 18 | 20 @ 0.9 |  |
| LP_1122_148_20 | card-mto | TIMEOUT | 18 | 20 @ 6.6 | TIMEOUT | 18 | 20 @ 0.9 |  |
| LP_1428_184_24 | cc | d=24 @ 531 s | 24 | 24 @ 6.4 | d=24 @ 551 s | 24 | 24 @ 6.1 | 1.04x time |
| LP_1428_184_24 | no-card | TIMEOUT | 18 | 24 @ 27.1 | TIMEOUT | 18 | 24 @ 12.1 |  |
| LP_1428_184_24 | card-mto | TIMEOUT | 18 | 24 @ 27.1 | TIMEOUT | 18 | 24 @ 14.3 |  |
| LP_1768_224_22 | cc | d=22 @ 65 s | 22 | 22 @ 65.0 | d=22 @ 66 s | 22 | 22 @ 49.9 | 1.01x time |
| LP_1768_224_22 | no-card | TIMEOUT | 18 | 22 @ 60.2 | TIMEOUT | 18 | 22 @ 53.2 |  |
| LP_1768_224_22 | card-mto | TIMEOUT | 18 | 22 @ 60.2 | TIMEOUT | 18 | 22 @ 53.4 |  |
| LP_2610_744_16 | cc | d=16 @ 7 s | 16 | 16 @ 0.4 | d=16 @ 8 s | 16 | 16 @ 0.7 | 1.11x time |
| LP_2610_744_16 | no-card | TIMEOUT | 10 | 16 @ 12.1 | TIMEOUT | 10 | 16 @ 8.2 |  |
| LP_2610_744_16 | card-mto | TIMEOUT | 10 | 16 @ 12.2 | TIMEOUT | 10 | 16 @ 8.3 |  |
| TN_180_2_17 | cc | d=17 @ 191 s | 17 | 17 @ 0.0 | d=17 @ 197 s | 17 | 17 @ 0.1 | 1.03x time |
| TN_180_2_17 | no-card | d=17 @ 5760 s | 17 | 17 @ 0.1 | d=17 @ 6341 s | 17 | 17 @ 0.2 | 1.10x time |
| TN_180_2_17 | card-mto | d=17 @ 9885 s | 17 | 17 @ 0.2 | d=17 @ 10986 s | 17 | 17 @ 0.2 | 1.11x time |
| TN_216_4_18 | cc | d=18 @ 596 s | 18 | 18 @ 0.1 | d=18 @ 612 s | 18 | 18 @ 0.1 | 1.03x time |
| TN_216_4_18 | no-card | d=18 @ 9161 s | 18 | 18 @ 0.1 | d=18 @ 10397 s | 18 | 18 @ 0.1 | 1.13x time |
| TN_216_4_18 | card-mto | d=18 @ 10066 s | 18 | 18 @ 0.1 | d=18 @ 11063 s | 18 | 18 @ 0.1 | 1.10x time |
| TN_252_2_21 | cc | d=21 @ 10464 s | 21 | 21 @ 5.6 | d=21 @ 11141 s | 21 | 21 @ 38.6 | 1.06x time |
| TN_252_2_21 | no-card | TIMEOUT | 17 | 21 @ 0.4 | TIMEOUT | 17 | 21 @ 0.6 |  |
| TN_252_2_21 | card-mto | TIMEOUT | 17 | 21 @ 0.4 | TIMEOUT | 17 | 21 @ 0.6 |  |
| TN_288_2_ge9 | cc | TIMEOUT | 20 | 24 @ 59.2 | TIMEOUT | 20 | 24 @ 52.8 |  |
| TN_288_2_ge9 | no-card | TIMEOUT | 9 | 24 @ 0.7 | TIMEOUT | 9 | 24 @ 0.8 |  |
| TN_288_2_ge9 | card-mto | TIMEOUT | 9 | 24 @ 0.7 | TIMEOUT | 9 | 24 @ 0.8 |  |
| TN_324_4_ge9 | cc | TIMEOUT | 20 | 25 @ 11.5 | TIMEOUT | 20 | 25 @ 0.9 |  |
| TN_324_4_ge9 | no-card | TIMEOUT | 9 | 25 @ 0.6 | TIMEOUT | 9 | 25 @ 0.9 |  |
| TN_324_4_ge9 | card-mto | TIMEOUT | 9 | 25 @ 0.6 | TIMEOUT | 9 | 25 @ 0.9 |  |
| TN_360_4_ge17 | cc | TIMEOUT | 22 | 24 @ 89.9 | TIMEOUT | 22 | 24 @ 32.9 |  |
| TN_360_4_ge17 | no-card | TIMEOUT | 17 | 24 @ 1.1 | TIMEOUT | 17 | 24 @ 1.1 |  |
| TN_360_4_ge17 | card-mto | TIMEOUT | 17 | 24 @ 1.1 | TIMEOUT | 17 | 24 @ 1.1 |  |
| TN_396_4_ge17 | cc | TIMEOUT | 22 | 26 @ 1684.1 | TIMEOUT | 22 | 26 @ 27.6 |  |
| TN_396_4_ge17 | no-card | TIMEOUT | 17 | 27 @ 1.5 | TIMEOUT | 17 | 26 @ 2.0 | ub 27->26 |
| TN_396_4_ge17 | card-mto | TIMEOUT | 17 | 27 @ 1.0 | TIMEOUT | 17 | 26 @ 2.0 | ub 27->26 |
| TN_432_8_ge9 | cc | TIMEOUT | 21 | 29 @ 10731.3 | TIMEOUT | 21 | 29 @ 306.9 |  |
| TN_432_8_ge9 | no-card | TIMEOUT | 9 | 32 @ 5.8 | TIMEOUT | 9 | 33 @ 1.6 | ub 32->33 (higher) |
| TN_432_8_ge9 | card-mto | TIMEOUT | 9 | 32 @ 5.9 | TIMEOUT | 9 | 33 @ 1.6 | ub 32->33 (higher) |
| TN_468_4_ge17 | cc | TIMEOUT | 23 | 29 @ 815.6 | TIMEOUT | 23 | 29 @ 185.1 |  |
| TN_468_4_ge17 | no-card | TIMEOUT | 17 | 33 @ 1.9 | TIMEOUT | 17 | 29 @ 10.4 | ub 33->29 |
| TN_468_4_ge17 | card-mto | TIMEOUT | 17 | 33 @ 1.3 | TIMEOUT | 17 | 29 @ 10.3 | ub 33->29 |
| TN_496_2_ge17 | cc | TIMEOUT | 22 | 30 @ 2283.6 | TIMEOUT | 22 | 30 @ 3227.0 |  |
| TN_496_2_ge17 | no-card | TIMEOUT | 17 | 34 @ 2.9 | TIMEOUT | 17 | 32 @ 2.5 | ub 34->32 |
| TN_496_2_ge17 | card-mto | TIMEOUT | 17 | 34 @ 2.9 | TIMEOUT | 17 | 32 @ 2.4 | ub 34->32 |
| TN_504_2_ge17 | cc | TIMEOUT | 23 | 37 @ 3263.1 | TIMEOUT | 23 | 34 @ 6197.5 | ub 37->34 |
| TN_504_2_ge17 | no-card | TIMEOUT | 17 | 45 @ 4.3 | TIMEOUT | 17 | 47 @ 1.8 | ub 45->47 (higher) |
| TN_504_2_ge17 | card-mto | TIMEOUT | 17 | 45 @ 2.9 | TIMEOUT | 17 | 47 @ 1.9 | ub 45->47 (higher) |
| TN_540_4_ge9 | cc | TIMEOUT | 21 | 40 @ 9172.6 | TIMEOUT | 21 | 34 @ 9682.4 | ub 40->34 |
| TN_540_4_ge9 | no-card | TIMEOUT | 9 | 46 @ 2.5 | TIMEOUT | 9 | 40 @ 3.8 | ub 46->40 |
| TN_540_4_ge9 | card-mto | TIMEOUT | 9 | 46 @ 2.4 | TIMEOUT | 9 | 40 @ 3.8 | ub 46->40 |
| TN_576_2_ge9 | cc | TIMEOUT | 22 | 50 @ 1419.4 | TIMEOUT | 22 | 38 @ 2601.4 | ub 50->38 |
| TN_576_2_ge9 | no-card | TIMEOUT | 9 | 54 @ 2.9 | TIMEOUT | 9 | 43 @ 2.6 | ub 54->43 |
| TN_576_2_ge9 | card-mto | TIMEOUT | 9 | 54 @ 2.9 | TIMEOUT | 9 | 43 @ 2.7 | ub 54->43 |
| TN_612_2_ge17 | cc | TIMEOUT | 24 | 47 @ 6542.5 | TIMEOUT | 24 | 41 @ 263.1 | ub 47->41 |
| TN_612_2_ge17 | no-card | TIMEOUT | 17 | 62 @ 3.2 | TIMEOUT | 17 | 41 @ 4.7 | ub 62->41 |
| TN_612_2_ge17 | card-mto | TIMEOUT | 17 | 62 @ 3.2 | TIMEOUT | 17 | 41 @ 4.5 | ub 62->41 |
| TN_648_10_9to52 | cc | TIMEOUT | 21 | 33 @ 1380.8 | TIMEOUT | 21 | 33 @ 1902.6 |  |
| TN_648_10_9to52 | no-card | TIMEOUT | 9 | 65 @ 3.5 | TIMEOUT | 9 | 47 @ 3.7 | ub 65->47 |
| TN_648_10_9to52 | card-mto | TIMEOUT | 9 | 65 @ 3.5 | TIMEOUT | 9 | 47 @ 3.4 | ub 65->47 |
| TN_648_14_ge9 | cc | TIMEOUT | 21 | 32 @ 1848.1 | TIMEOUT | 21 | 31 @ 45.4 | ub 32->31 |
| TN_648_14_ge9 | no-card | TIMEOUT | 9 | 40 @ 3.2 | TIMEOUT | 9 | 31 @ 4.9 | ub 40->31 |
| TN_648_14_ge9 | card-mto | TIMEOUT | 9 | 40 @ 3.2 | TIMEOUT | 9 | 31 @ 4.9 | ub 40->31 |
| TN_684_2_ge9 | cc | TIMEOUT | 22 | 29 @ 8685.0 | TIMEOUT | 22 | 29 @ 3060.8 |  |
| TN_684_2_ge9 | no-card | TIMEOUT | 9 | 31 @ 14.6 | TIMEOUT | 9 | 31 @ 3.8 |  |
| TN_684_2_ge9 | card-mto | TIMEOUT | 9 | 31 @ 10.4 | TIMEOUT | 9 | 31 @ 3.8 |  |

solved cells: baseline 16, new 16; ub lower on 25, higher on 4; final lb higher on 0, lower on 0; science problems: []
