# GH-225 follow-up: lb push runs (12-36 h, yfclab2 CPUs 64-95)

Runs stopped early by hand (rc -15) were relabelled `-seed=1/2` arms that ran 1.5-2x slower; they were replaced by the
main 1239e9a2 arms after about 4 h, or BB_1080 runs stopped once lb 34 was reproduced. "+erasure" = 1239e9a2 CC default plus ungated erasure.

## BB_1080_4_32to48

| run | binary | args | rc | final lb | lb > stem lb (time s) | last EMPTY level: nodes X / Z |
|---|---|---|---:|---:|---|---|
| push.BB_1080_4_32to48.s2 | main 755e0c21 (gated erasure default) | -seed=2 | -15 | 32 | - | 30: 8676284945 / - |
| push.BB_1080_4_32to48.s1 | main 755e0c21 (gated erasure default) | -seed=1 | -15 | 32 | - | 30: 9234464712 / - |
| push.BB_1080_4_32to48.s0 | main 755e0c21 (gated erasure default) | (default) | 1 | 34 | 34@40586 | 32: 36358215471 / - |
| push2.BB_1080_4_32to48.E | main 1239e9a2 | +erasure | 1 | 32 | - | 30: 1297431327 / - |
| push3.BB_1080_4_32to48.C.idx | main 755e0c21 (gated erasure default) | -cc-roworder=index | -15 | 32 | - | 30: 20042461635 / - |
| push3.BB_1080_4_32to48.E | main 1239e9a2 | +erasure | -15 | 34 | 34@44390 | 32: 7104419654 / - |

## BB_756_16_32to34

| run | binary | args | rc | final lb | lb > stem lb (time s) | last EMPTY level: nodes X / Z |
|---|---|---|---:|---:|---|---|
| push3.BB_756_16_32to34.C | main 755e0c21 (gated erasure default) | (default) | 0 | 34 | 34@59834 | 32: 55153739257 / - |
| push3.BB_756_16_32to34.E | main 1239e9a2 | +erasure | 0 | 34 | 34@65917 | 32: 10495398704 / - |

## BB_864_4_32to40

| run | binary | args | rc | final lb | lb > stem lb (time s) | last EMPTY level: nodes X / Z |
|---|---|---|---:|---:|---|---|
| push3.BB_864_4_32to40.C | main 755e0c21 (gated erasure default) | (default) | 1 | 34 | 34@58134 | 32: 51306136754 / - |
| push3.BB_864_4_32to40.E | main 1239e9a2 | +erasure | 1 | 34 | 34@64158 | 32: 9986115503 / - |

## COLOR_1027_1_31to37

| run | binary | args | rc | final lb | lb > stem lb (time s) | last EMPTY level: nodes X / Z |
|---|---|---|---:|---:|---|---|
| push.COLOR_1027_1_31to37.s0 | main 755e0c21 (gated erasure default) | (default) | 1 | 32 | 32@38288 | 31: 18143487651 / - |
| push3.COLOR_1027_1_31to37.C | main 755e0c21 (gated erasure default) | (default) | 1 | 33 | 32@37528, 33@78893 | 32: 37999317739 / - |
| push3.COLOR_1027_1_31to37.E.idx | main 1239e9a2 | +erasure -cc-roworder=index | 1 | 33 | 32@37124, 33@77146 | 32: 36324869862 / - |

## COLOR_2791_1_26to61

| run | binary | args | rc | final lb | lb > stem lb (time s) | last EMPTY level: nodes X / Z |
|---|---|---|---:|---:|---|---|
| lb.COLOR_2791_1_26to61.C.bfs | main 755e0c21 (gated erasure default) | -cc-roworder=bfs | 1 | 29 | 27@7551, 28@16919, 29@37963 | 28: 25424894782 / - |
| lb.COLOR_2791_1_26to61.C.idx | main 755e0c21 (gated erasure default) | -cc-roworder=index | 1 | 29 | 27@4266, 28@9466, 29@20425 | 28: 15566810462 / - |

## COLOR_2791_1_28to61

| run | binary | args | rc | final lb | lb > stem lb (time s) | last EMPTY level: nodes X / Z |
|---|---|---|---:|---:|---|---|
| push3.COLOR_2791_1_28to61.C.bfs | main 755e0c21 (gated erasure default) | -cc-roworder=bfs | 1 | 30 | 29@36930, 30@79340 | 29: 54922250700 / - |
| push3.COLOR_2791_1_28to61.C | main 755e0c21 (gated erasure default) | (default) | 1 | 31 | 29@20415, 30@42701, 31@88551 | 30: 71055634766 / - |

## TN_288_2_22to24

| run | binary | args | rc | final lb | lb > stem lb (time s) | last EMPTY level: nodes X / Z |
|---|---|---|---:|---:|---|---|
| push.TN_288_2_22to24.s2 | main 755e0c21 (gated erasure default) | -seed=2 | -15 | 22 | - | 21: 1381729407 / 1948165878 |
| push.TN_288_2_22to24.s1 | main 755e0c21 (gated erasure default) | -seed=1 | -15 | 22 | - | 21: 1835101345 / 1455896705 |
| push.TN_288_2_22to24.s0 | main 755e0c21 (gated erasure default) | (default) | 1 | 23 | 23@30093 | 22: 3601872449 / 2749935505 |
| push2.TN_288_2_22to24.E | main 1239e9a2 | +erasure | 1 | 23 | 23@30030 | 22: 2035589738 / 1362764654 |
| push3.TN_288_2_22to24.C | main 755e0c21 (gated erasure default) | (default) | 0 | 24 | 23@29449, 24@98733 | 23: 11565140311 / 8401509440 |
| push3.TN_288_2_22to24.E | main 1239e9a2 | +erasure | 0 | 24 | 23@30037, 24@100460 | 23: 7100913307 / 4641655303 |

## TN_324_4_23to25

| run | binary | args | rc | final lb | lb > stem lb (time s) | last EMPTY level: nodes X / Z |
|---|---|---|---:|---:|---|---|
| push.TN_324_4_23to25.s0 | main 755e0c21 (gated erasure default) | (default) | -15 | 22 | - | 22: - / 1751428775 |
| push.TN_324_4_23to25.s2 | main 755e0c21 (gated erasure default) | -seed=2 | -15 | 22 | - | 21: 1082177056 / 1313428023 |
| push.TN_324_4_23to25.s1 | main 755e0c21 (gated erasure default) | -seed=1 | -15 | 22 | - | 21: 1325693896 / 1033627016 |
| push3.TN_324_4_23to25.C | main 755e0c21 (gated erasure default) | (default) | 1 | 24 | 24@72074 | 23: 6629936924 / 5144029513 |
| push3.TN_324_4_23to25.E | main 1239e9a2 | +erasure | 1 | 24 | 24@72807 | 23: 4432944643 / 3064952410 |

## TN_360_4_23to24

| run | binary | args | rc | final lb | lb > stem lb (time s) | last EMPTY level: nodes X / Z |
|---|---|---|---:|---:|---|---|
| push3.TN_360_4_23to24.C | main 755e0c21 (gated erasure default) | (default) | 0 | 24 | 24@47415 | 23: 5295942522 / 6155905680 |
| push3.TN_360_4_23to24.E | main 1239e9a2 | +erasure | 0 | 24 | 24@48186 | 23: 2414959502 / 2588582833 |

## TN_396_4_23to26

| run | binary | args | rc | final lb | lb > stem lb (time s) | last EMPTY level: nodes X / Z |
|---|---|---|---:|---:|---|---|
| push3.TN_396_4_23to26.E | main 1239e9a2 | +erasure | 1 | 24 | 24@47923 | 24: - / 4675911214 |
| push3.TN_396_4_23to26.C | main 755e0c21 (gated erasure default) | (default) | 1 | 24 | 24@47489 | 24: - / 10964865881 |

## TN_432_8_23to29

| run | binary | args | rc | final lb | lb > stem lb (time s) | last EMPTY level: nodes X / Z |
|---|---|---|---:|---:|---|---|
| push.TN_432_8_23to29.s1 | main 755e0c21 (gated erasure default) | -seed=1 | -15 | 22 | - | 22: 2068114942 / - |
| push.TN_432_8_23to29.s2 | main 755e0c21 (gated erasure default) | -seed=2 | -15 | 22 | - | 22: 2680006511 / - |
| push.TN_432_8_23to29.s0 | main 755e0c21 (gated erasure default) | (default) | 1 | 24 | 24@29251 | 23: 4888469824 / 3731404803 |
| push2.TN_432_8_23to29.E | main 1239e9a2 | +erasure | 1 | 24 | 24@29784 | 23: 1519847817 / 1190498822 |
| push2.TN_432_8_23to29.A | main 1239e9a2 | (default) | 1 | 24 | 24@38938 | 23: 22000372680 / 18230181099 |
| push4.TN_432_8_23to29.C | main 755e0c21 (gated erasure default) | (default) | 1 | 25 | 24@27189, 25@87063 | 24: 14914764905 / 10463736079 |
| push4.TN_432_8_23to29.E | main 1239e9a2 | +erasure | 1 | 25 | 24@28040, 25@89519 | 24: 4845268867 / 3789436575 |

## TN_468_4_23to29

| run | binary | args | rc | final lb | lb > stem lb (time s) | last EMPTY level: nodes X / Z |
|---|---|---|---:|---:|---|---|
| push.TN_468_4_23to29.s2 | main 755e0c21 (gated erasure default) | -seed=2 | -15 | 22 | - | 22: 2377822465 / - |
| push.TN_468_4_23to29.s1 | main 755e0c21 (gated erasure default) | -seed=1 | -15 | 22 | - | 22: - / 2616156245 |
| push.TN_468_4_23to29.s0 | main 755e0c21 (gated erasure default) | (default) | 1 | 24 | 24@38806 | 23: 5286599869 / 2721134843 |
| push2.TN_468_4_23to29.E | main 1239e9a2 | +erasure | 1 | 24 | 24@38061 | 23: 3068271837 / 882909828 |
| push5.TN_468_4_23to29.C | main 755e0c21 (gated erasure default) | (default) | 1 | 25 | 24@35993, 25@107865 | 24: 21548460276 / 7424402278 |
| push5.TN_468_4_23to29.E | main 1239e9a2 | +erasure | 1 | 25 | 24@36774, 25@110270 | 24: 9417516340 / 2555277643 |

## TN_496_2_28to30

| run | binary | args | rc | final lb | lb > stem lb (time s) | last EMPTY level: nodes X / Z |
|---|---|---|---:|---:|---|---|
| push3.TN_496_2_28to30.C | main 755e0c21 (gated erasure default) | (default) | 0 | 30 | 29@46997, 30@117232 | 29: 17173985980 / - |
| push3.TN_496_2_28to30.E | main 1239e9a2 | +erasure | 0 | 30 | 29@47826, 30@119072 | 29: 8063078912 / - |

## TN_504_2_24to34

| run | binary | args | rc | final lb | lb > stem lb (time s) | last EMPTY level: nodes X / Z |
|---|---|---|---:|---:|---|---|
| push3.TN_504_2_24to34.C | main 755e0c21 (gated erasure default) | (default) | 1 | 25 | 25@54147 | 25: - / 23904799897 |
| push3.TN_504_2_24to34.E | main 1239e9a2 | +erasure | 1 | 25 | 25@56955 | 25: - / 7150476219 |

## TN_540_4_24to34

| run | binary | args | rc | final lb | lb > stem lb (time s) | last EMPTY level: nodes X / Z |
|---|---|---|---:|---:|---|---|
| push3.TN_540_4_24to34.C | main 755e0c21 (gated erasure default) | (default) | 1 | 25 | 25@57564 | 25: - / 24249989588 |
| push3.TN_540_4_24to34.E | main 1239e9a2 | +erasure | 1 | 25 | 25@63505 | 25: - / 7122884430 |

## TN_576_2_24to37

| run | binary | args | rc | final lb | lb > stem lb (time s) | last EMPTY level: nodes X / Z |
|---|---|---|---:|---:|---|---|
| push.TN_576_2_24to37.s2 | main 755e0c21 (gated erasure default) | -seed=2 | -15 | 23 | - | 23: 2633784033 / - |
| push.TN_576_2_24to37.s1 | main 755e0c21 (gated erasure default) | -seed=1 | -15 | 23 | - | 23: - / 2361733896 |
| push.TN_576_2_24to37.s0 | main 755e0c21 (gated erasure default) | (default) | 1 | 25 | 25@28223 | 24: 6564101977 / 4532664093 |
| push2.TN_576_2_24to37.E | main 1239e9a2 | +erasure | 1 | 25 | 25@30871 | 24: 1497891875 / 919098952 |
| push2.TN_576_2_24to37.A | main 1239e9a2 | (default) | 1 | 25 | 25@34316 | 24: 19941990462 / 13450108065 |
| push4.TN_576_2_24to37.C | main 755e0c21 (gated erasure default) | (default) | 1 | 26 | 25@26157, 26@79691 | 25: 19704086985 / 11904852835 |
| push4.TN_576_2_24to37.E | main 1239e9a2 | +erasure | 1 | 26 | 25@29372, 26@88962 | 25: 4551391160 / 2721364908 |

## TN_612_2_24to40

| run | binary | args | rc | final lb | lb > stem lb (time s) | last EMPTY level: nodes X / Z |
|---|---|---|---:|---:|---|---|
| push.TN_612_2_24to40.s1 | main 755e0c21 (gated erasure default) | -seed=1 | -15 | 23 | - | 23: 3347572883 / - |
| push.TN_612_2_24to40.s2 | main 755e0c21 (gated erasure default) | -seed=2 | -15 | 23 | - | 23: - / 3062322393 |
| push.TN_612_2_24to40.s0 | main 755e0c21 (gated erasure default) | (default) | 1 | 25 | 25@35008 | 24: 6617104279 / 5522050378 |
| push2.TN_612_2_24to40.E | main 1239e9a2 | +erasure | 1 | 25 | 25@37476 | 24: 1804483791 / 1171962586 |
| push2.TN_612_2_24to40.A | main 1239e9a2 | (default) | 1 | 25 | 25@42105 | 24: 24920442849 / 16099508229 |
| push5.TN_612_2_24to40.E | main 1239e9a2 | +erasure | 1 | 26 | 25@36062, 26@107037 | 25: 5419829019 / 3498839951 |
| push5.TN_612_2_24to40.C | main 755e0c21 (gated erasure default) | (default) | 1 | 26 | 25@32844, 26@97484 | 25: 22297669611 / 14660377055 |

## TN_648_10_22to32

| run | binary | args | rc | final lb | lb > stem lb (time s) | last EMPTY level: nodes X / Z |
|---|---|---|---:|---:|---|---|
| push3.TN_648_10_22to32.E | main 1239e9a2 | +erasure | 1 | 23 | 23@58436 | 23: - / 5374332560 |
| push3.TN_648_10_22to32.C | main 755e0c21 (gated erasure default) | (default) | 1 | 23 | 23@53620 | 23: 37763826791 / - |

## TN_648_14_22to28

| run | binary | args | rc | final lb | lb > stem lb (time s) | last EMPTY level: nodes X / Z |
|---|---|---|---:|---:|---|---|
| push3.TN_648_14_22to28.E | main 1239e9a2 | +erasure | 1 | 23 | 23@63576 | 23: - / 6443285841 |
| push3.TN_648_14_22to28.C | main 755e0c21 (gated erasure default) | (default) | 1 | 23 | 23@70302 | 23: - / 29411675255 |

## TN_684_2_24to29

| run | binary | args | rc | final lb | lb > stem lb (time s) | last EMPTY level: nodes X / Z |
|---|---|---|---:|---:|---|---|
| push3.TN_684_2_24to29.E.s1 | main 1239e9a2 | +erasure -seed=1 | 1 | 25 | 25@106893 | 24: 4521923485 / 6464110927 |
| push3.TN_684_2_24to29.E.s2 | main 1239e9a2 | +erasure -seed=2 | 1 | 25 | 25@105414 | 24: 4533374012 / 5958189067 |

