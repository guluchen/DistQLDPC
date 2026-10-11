# Tier 4 feasibility probe: main 7eadd54, 6-hour limit (coordinator, Mac, 2026-10-11)
6 runs in parallel on the Mac (Apple M6, 12 CPUs), frozen-main7e (6bdcaa25…), -cpu-lim=21600, 2 GB cap (RSS poll), stdout with
elapsed-time stamps (*.log), run.py here. Started 10:14:55, all done by 10:43:02 (CST).
| Case | Mode | Result | Time to final (s) | First UB = final (s) | Peak RSS |
|---|---|---|---:|---:|---:|
| TN_250_10_15 | no-card | d = 15 | 1342 | 596 | 227 MB |
| TN_250_10_15 | card-mto | d = 15 | 1232 | 338 | 207 MB |
| BB_288_12_unknown | no-card | d = 18 | 804 | 148 | 262 MB |
| BB_288_12_unknown | card-mto | d = 18 | 913 | 153 | 245 MB |
| LP_714_100_unknown | no-card | d = 16 | 1687 | 44 | 341 MB |
| LP_714_100_unknown | card-mto | d = 16 | 1687 | 43 | 355 MB |
All three cases are solved well inside 6 h (longest 28 min under 6-way parallel load). Most time is spent proving the
lower bound after the optimum is already found.
SCIENTIFIC NOTE: BB_288 and LP_714 have uncertified distances in the benchmark set ("unknown"); these runs report d = 18 and
d = 16. Per the Tier 4 rule these must be independently verified before being reported or used to rename benchmarks.
Cross-checks started: same binary with -no-symbreak (split without symmetry breaking) and -joint (original encoding).
Timing reference: on the Mac, main needs ~14-28 min per Tier 4 case (parallel load); yfclab2 cores are markedly slower
(TN_250 timed out at 1800 s there), so the Tier 4 limit must be calibrated on the server.
