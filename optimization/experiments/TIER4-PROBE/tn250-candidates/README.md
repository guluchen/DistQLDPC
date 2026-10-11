# TN_250_10_15 on the Mac: main vs candidates (coordinator, 2026-10-11, informational)
8 runs in parallel on the Mac (Apple M6, 12 CPUs), one run per binary x mode, -cpu-lim=1800, 2 GB cap (memlimit.py), run.py here.
Parallel load means times are indicative only (not a controlled comparison).
| Binary | no-card | card-mto |
|---|---|---|
| main 7eadd54 (frozen-main7e) | solved d=15 in 1496 s | solved d=15 in 1383 s |
| GH-106 postsol (frozen106/cand) | solved 1384 s | solved 1132 s |
| GH-89 (frozen89/cand) | solved 1027 s | solved 1677 s |
| GH-98 native XOR (frozen98/cand) | solved 1380 s | TIMEOUT 1800 s (lb 9, ub 15) |
Peak RSS 190-280 MB. On yfclab2 (GH-85 Tier3, 2026-10-09) main's source (GH-85) timed out at 1800 s on TN_250 in both modes
(lb 9): the Mac core is markedly faster, so Tier 4 limits must be calibrated on the server once it is back.
