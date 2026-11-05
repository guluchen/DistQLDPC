# GH-225 lb reproduction: summary

Times are wall seconds from process start to the `c d_lb` event (yfclab2, one pinned core per run, 4 GB cap).
"tree" compares node counts per half and level with every original single run of the code at the deepest level both
finished: "differs" = differs from all of them at that level; "same as X" = identical to run X there.
Original runs: 6 h, default seed. Reproduction runs ("repro"): 12 h. "+erasure" = -cc-rules=excl,pack,orbf,parity,leaf,overlap,charge,tiebreak,sparse,sparseov,sparsemrv,erasure (ungated on 1239e9a2).

## TN_324_4_22to25

| run | binary / args | final lb | time to each lb > stem lb | tree |
|---|---|---:|---|---|
| GH-225 A | 42d7d1d (PR #220 head)  | 22 | - | same as GH-227 M (Z level 22) |
| GH-225 E | 5a201fd (A + erasure default)  | 23 | 23@20985 | differs (checked to level 22) |
| GH-227 M | main 1239e9a2  | 22 | - | same as GH-225 A (Z level 22) |
| GH-227 C | 755e0c21 (gated erasure default)  | 22 | - | differs (checked to level 22) |
| repro E.s1 | main 1239e9a2 +erasure -seed=1 | 23 | 23@30309 | differs (checked to level 22) |
| repro E.s2 | main 1239e9a2 +erasure -seed=2 | 23 | 23@31369 | differs (checked to level 22) |
| repro A.s1 | main 1239e9a2 -seed=1 | 22 | - | differs (checked to level 22) |
| repro E.bfs | main 1239e9a2 +erasure -cc-roworder=bfs | 22 | - | differs (checked to level 22) |

## TN_496_2_27to30

| run | binary / args | final lb | time to each lb > stem lb | tree |
|---|---|---:|---|---|
| GH-225 A | 42d7d1d (PR #220 head)  | 27 | - | same as GH-227 M (X level 26) |
| GH-225 E | 5a201fd (A + erasure default)  | 28 | 28@17996 | differs (checked to level 27) |
| GH-227 M | main 1239e9a2  | 27 | - | same as GH-225 A (X level 26) |
| GH-227 C | 755e0c21 (gated erasure default)  | 28 | 28@19683 | differs (checked to level 27) |
| repro E.s1 | main 1239e9a2 +erasure -seed=1 | 28 | 28@20699 | differs (checked to level 27) |
| repro E.bfs | main 1239e9a2 +erasure -cc-roworder=bfs | 28 | 28@19856 | same as GH-225 E (X level 27) |
| repro A.s1 | main 1239e9a2 -seed=1 | 28 | 28@24919 | differs (checked to level 27) |
| repro E.s2 | main 1239e9a2 +erasure -seed=2 | 28 | 28@19095 | differs (checked to level 27) |

## TN_540_4_23to34

| run | binary / args | final lb | time to each lb > stem lb | tree |
|---|---|---:|---|---|
| GH-225 E | 5a201fd (A + erasure default)  | 24 | 24@19168 | differs (checked to level 23) |
| GH-225 A | 42d7d1d (PR #220 head)  | 23 | - | same as GH-227 M (Z level 23) |
| GH-227 M | main 1239e9a2  | 23 | - | same as GH-225 A (Z level 23) |
| GH-227 C | 755e0c21 (gated erasure default)  | 24 | 24@18399 | differs (checked to level 23) |
| repro E.s1 | main 1239e9a2 +erasure -seed=1 | 24 | 24@35026 | differs (checked to level 23) |
| repro E.s2 | main 1239e9a2 +erasure -seed=2 | 24 | 24@32893 | differs (checked to level 23) |
| repro A.s1 | main 1239e9a2 -seed=1 | 24 | 24@42322 | differs (checked to level 23) |
| repro E.bfs | main 1239e9a2 +erasure -cc-roworder=bfs | 23 | - | differs (checked to level 22) |

## TN_648_14_21to28

| run | binary / args | final lb | time to each lb > stem lb | tree |
|---|---|---:|---|---|
| GH-225 E | 5a201fd (A + erasure default)  | 22 | 22@20292 | differs (checked to level 21) |
| GH-225 A | 42d7d1d (PR #220 head)  | 21 | - | same as GH-227 M (X level 21) |
| GH-227 M | main 1239e9a2  | 21 | - | same as GH-225 A (X level 21) |
| GH-227 C | 755e0c21 (gated erasure default)  | 22 | 22@19331 | differs (checked to level 21) |
| repro E.s1 | main 1239e9a2 +erasure -seed=1 | 22 | 22@35385 | differs (checked to level 21) |
| repro E.s2 | main 1239e9a2 +erasure -seed=2 | 22 | 22@36573 | differs (checked to level 21) |
| repro A.s1 | main 1239e9a2 -seed=1 | 22 | 22@36164 | differs (checked to level 21) |
| repro E.bfs | main 1239e9a2 +erasure -cc-roworder=bfs | 21 | - | differs (checked to level 20) |

## COLOR_1027_1_28to37

| run | binary / args | final lb | time to each lb > stem lb | tree |
|---|---|---:|---|---|
| GH-225 A | 42d7d1d (PR #220 head)  | 30 | 29@6698, 30@14256 | same as GH-227 M (X level 29) |
| GH-225 E | 5a201fd (A + erasure default)  | 31 | 29@3550, 30@7564, 31@16090 | differs (checked to level 30) |
| GH-227 M | main 1239e9a2  | 30 | 29@7633, 30@16208 | same as GH-225 A (X level 29) |
| GH-227 C | 755e0c21 (gated erasure default)  | 31 | 29@4032, 30@8572, 31@18190 | differs (checked to level 30) |
| repro E.s1 | main 1239e9a2 +erasure -seed=1 | 29 | 29@28751 | differs (checked to level 28) |
| repro E.s2 | main 1239e9a2 +erasure -seed=2 | 29 | 29@27806 | differs (checked to level 28) |
| repro A.s1 | main 1239e9a2 -seed=1 | 28 | - | differs (checked to level 27) |
| repro E.bfs | main 1239e9a2 +erasure -cc-roworder=bfs | 31 | 29@6726, 30@15170, 31@33206 | differs (checked to level 30) |
| repro E.idx | main 1239e9a2 +erasure -cc-roworder=index | 32 | 29@3990, 30@8474, 31@18004, 32@37190 | same as GH-225 E (X level 30) |

## TN_684_2_22to29

| run | binary / args | final lb | time to each lb > stem lb | tree |
|---|---|---:|---|---|
| GH-225 A | 42d7d1d (PR #220 head)  | 23 | 23@16367 | same as GH-227 M (Z level 22) |
| GH-225 E | 5a201fd (A + erasure default)  | 23 | 23@20207 | differs (checked to level 22) |
| GH-227 M | main 1239e9a2  | 23 | 23@17440 | same as GH-225 A (Z level 22) |
| GH-227 C | 755e0c21 (gated erasure default)  | 23 | 23@21196 | differs (checked to level 22) |
| repro E.s1 | main 1239e9a2 +erasure -seed=1 | 24 | 23@13945, 24@39232 | differs (checked to level 22) |
| repro E.s2 | main 1239e9a2 +erasure -seed=2 | 24 | 23@14375, 24@39063 | differs (checked to level 22) |
| repro A.s1 | main 1239e9a2 -seed=1 | 23 | 23@17570 | differs (checked to level 22) |
| repro E.bfs | main 1239e9a2 +erasure -cc-roworder=bfs | 22 | - | differs (checked to level 22) |

## COLOR_2791_1_26to61

| run | binary / args | final lb | time to each lb > stem lb | tree |
|---|---|---:|---|---|
| GH-225 A | 42d7d1d (PR #220 head)  | 28 | 27@4825, 28@10312 | same as GH-227 M (X level 27) |
| GH-225 E | 5a201fd (A + erasure default)  | 27 | 27@17220 | differs (checked to level 26) |
| GH-227 M | main 1239e9a2  | 28 | 27@5483, 28@11706 | same as GH-225 A (X level 27) |
| GH-227 C | 755e0c21 (gated erasure default)  | 29 | 27@4471, 28@9612, 29@20721 | differs (checked to level 27) |

