# GH-225 follow-up: lb push runs (12 h, yfclab2 CPUs 64-95)

Runs stopped early by hand (rc -15) were relabelled `-seed=1/2` arms that ran 1.5-2x slower; they were replaced by the
main 1239e9a2 arms after about 4 h. "+erasure" = 1239e9a2 CC default plus ungated erasure.

## BB_1080_4_32to48

| run | binary | args | rc | final lb | lb > stem lb (time s) | last EMPTY level: nodes X / Z |
|---|---|---|---:|---:|---|---|
| push.BB_1080_4_32to48.s2 | main 755e0c21 (gated erasure default) | -seed=2 | -15 | 32 | - | 30: 8676284945 / - |
| push.BB_1080_4_32to48.s1 | main 755e0c21 (gated erasure default) | -seed=1 | -15 | 32 | - | 30: 9234464712 / - |
| push.BB_1080_4_32to48.s0 | main 755e0c21 (gated erasure default) | (default) | 1 | 34 | 34@40586 | 32: 36358215471 / - |
| push2.BB_1080_4_32to48.E | main 1239e9a2 | +erasure | 1 | 32 | - | 30: 1297431327 / - |

## COLOR_1027_1_31to37

| run | binary | args | rc | final lb | lb > stem lb (time s) | last EMPTY level: nodes X / Z |
|---|---|---|---:|---:|---|---|
| push.COLOR_1027_1_31to37.s0 | main 755e0c21 (gated erasure default) | (default) | 1 | 32 | 32@38288 | 31: 18143487651 / - |

## COLOR_2791_1_26to61

| run | binary | args | rc | final lb | lb > stem lb (time s) | last EMPTY level: nodes X / Z |
|---|---|---|---:|---:|---|---|
| lb.COLOR_2791_1_26to61.C.bfs | main 755e0c21 (gated erasure default) | -cc-roworder=bfs | 1 | 29 | 27@7551, 28@16919, 29@37963 | 28: 25424894782 / - |
| lb.COLOR_2791_1_26to61.C.idx | main 755e0c21 (gated erasure default) | -cc-roworder=index | 1 | 29 | 27@4266, 28@9466, 29@20425 | 28: 15566810462 / - |

## TN_288_2_22to24

| run | binary | args | rc | final lb | lb > stem lb (time s) | last EMPTY level: nodes X / Z |
|---|---|---|---:|---:|---|---|
| push.TN_288_2_22to24.s2 | main 755e0c21 (gated erasure default) | -seed=2 | -15 | 22 | - | 21: 1381729407 / 1948165878 |
| push.TN_288_2_22to24.s1 | main 755e0c21 (gated erasure default) | -seed=1 | -15 | 22 | - | 21: 1835101345 / 1455896705 |
| push.TN_288_2_22to24.s0 | main 755e0c21 (gated erasure default) | (default) | 1 | 23 | 23@30093 | 22: 3601872449 / 2749935505 |
| push2.TN_288_2_22to24.E | main 1239e9a2 | +erasure | 1 | 23 | 23@30030 | 22: 2035589738 / 1362764654 |

## TN_324_4_23to25

| run | binary | args | rc | final lb | lb > stem lb (time s) | last EMPTY level: nodes X / Z |
|---|---|---|---:|---:|---|---|
| push.TN_324_4_23to25.s0 | main 755e0c21 (gated erasure default) | (default) | -15 | 22 | - | 22: - / 1751428775 |
| push.TN_324_4_23to25.s2 | main 755e0c21 (gated erasure default) | -seed=2 | -15 | 22 | - | 21: 1082177056 / 1313428023 |
| push.TN_324_4_23to25.s1 | main 755e0c21 (gated erasure default) | -seed=1 | -15 | 22 | - | 21: 1325693896 / 1033627016 |

## TN_432_8_23to29

| run | binary | args | rc | final lb | lb > stem lb (time s) | last EMPTY level: nodes X / Z |
|---|---|---|---:|---:|---|---|
| push.TN_432_8_23to29.s1 | main 755e0c21 (gated erasure default) | -seed=1 | -15 | 22 | - | 22: 2068114942 / - |
| push.TN_432_8_23to29.s2 | main 755e0c21 (gated erasure default) | -seed=2 | -15 | 22 | - | 22: 2680006511 / - |
| push.TN_432_8_23to29.s0 | main 755e0c21 (gated erasure default) | (default) | 1 | 24 | 24@29251 | 23: 4888469824 / 3731404803 |
| push2.TN_432_8_23to29.E | main 1239e9a2 | +erasure | 1 | 24 | 24@29784 | 23: 1519847817 / 1190498822 |
| push2.TN_432_8_23to29.A | main 1239e9a2 | (default) | 1 | 24 | 24@38938 | 23: 22000372680 / 18230181099 |

## TN_468_4_23to29

| run | binary | args | rc | final lb | lb > stem lb (time s) | last EMPTY level: nodes X / Z |
|---|---|---|---:|---:|---|---|
| push.TN_468_4_23to29.s2 | main 755e0c21 (gated erasure default) | -seed=2 | -15 | 22 | - | 22: 2377822465 / - |
| push.TN_468_4_23to29.s1 | main 755e0c21 (gated erasure default) | -seed=1 | -15 | 22 | - | 22: - / 2616156245 |
| push.TN_468_4_23to29.s0 | main 755e0c21 (gated erasure default) | (default) | 1 | 24 | 24@38806 | 23: 5286599869 / 2721134843 |
| push2.TN_468_4_23to29.E | main 1239e9a2 | +erasure | 1 | 24 | 24@38061 | 23: 3068271837 / 882909828 |

## TN_576_2_24to37

| run | binary | args | rc | final lb | lb > stem lb (time s) | last EMPTY level: nodes X / Z |
|---|---|---|---:|---:|---|---|
| push.TN_576_2_24to37.s2 | main 755e0c21 (gated erasure default) | -seed=2 | -15 | 23 | - | 23: 2633784033 / - |
| push.TN_576_2_24to37.s1 | main 755e0c21 (gated erasure default) | -seed=1 | -15 | 23 | - | 23: - / 2361733896 |
| push.TN_576_2_24to37.s0 | main 755e0c21 (gated erasure default) | (default) | 1 | 25 | 25@28223 | 24: 6564101977 / 4532664093 |
| push2.TN_576_2_24to37.E | main 1239e9a2 | +erasure | 1 | 25 | 25@30871 | 24: 1497891875 / 919098952 |
| push2.TN_576_2_24to37.A | main 1239e9a2 | (default) | 1 | 25 | 25@34316 | 24: 19941990462 / 13450108065 |

## TN_612_2_24to40

| run | binary | args | rc | final lb | lb > stem lb (time s) | last EMPTY level: nodes X / Z |
|---|---|---|---:|---:|---|---|
| push.TN_612_2_24to40.s1 | main 755e0c21 (gated erasure default) | -seed=1 | -15 | 23 | - | 23: 3347572883 / - |
| push.TN_612_2_24to40.s2 | main 755e0c21 (gated erasure default) | -seed=2 | -15 | 23 | - | 23: - / 3062322393 |
| push.TN_612_2_24to40.s0 | main 755e0c21 (gated erasure default) | (default) | 1 | 25 | 25@35008 | 24: 6617104279 / 5522050378 |
| push2.TN_612_2_24to40.E | main 1239e9a2 | +erasure | 1 | 25 | 25@37476 | 24: 1804483791 / 1171962586 |
| push2.TN_612_2_24to40.A | main 1239e9a2 | (default) | 1 | 25 | 25@42105 | 24: 24920442849 / 16099508229 |

