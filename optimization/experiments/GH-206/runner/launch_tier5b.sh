#!/bin/bash
# GH-206 Tier 5 confirmation (6 h, default seed) with the final binary fca5d3c (one probe per half, the default), same-session
# references from the same binary: tb on the TN codes, tbmrvbfs on the BB codes and TN_496. yfclab2 cores 24-35, 37-39, 41-43
# (36: a root process uses ~16 % of it; 40: avoided). Short jobs first.
F=~/mac-agent-20261009/frozen; B=$F/server-gh206-fca5d3c
R=~/mac-agent-20261009/gh206v3-runs/tier5
mkdir -p $R
M=optimization/experiments/GH-206/runner/make_jobs.py
python3 $M tier5 $R/j1.jsonl $F/server-main-6083e66 $B auto LP_1020_136_16 LP_1054_140_20 LP_1122_148_20 LP_1428_184_24 LP_1768_224_22 LP_2610_744_16 BB_360_12_24 TN_180_2_17 TN_216_4_18
python3 $M tier5 $R/j2.jsonl $F/server-main-6083e66 $B tb TN_180_2_17 TN_216_4_18
python3 $M tier5 $R/j3.jsonl $F/server-main-6083e66 $B auto BB_756_16_30to34 BB_864_4_30to40 BB_1080_4_30to48 TN_252_2_21 TN_288_2_22to24 TN_496_2_23to30
python3 $M tier5 $R/j4.jsonl $F/server-main-6083e66 $B tb TN_252_2_21 TN_288_2_22to24
python3 $M tier5 $R/j5.jsonl $F/server-main-6083e66 $B tbmrvbfs BB_756_16_30to34 BB_864_4_30to40 BB_1080_4_30to48 TN_496_2_23to30
cat $R/j1.jsonl $R/j2.jsonl $R/j3.jsonl $R/j4.jsonl $R/j5.jsonl > $R/jobs.jsonl
nohup python3 optimization/experiments/GH-206/runner/gh206_queue.py --bin $B --cpus 24-35,37-39,41-43 --jobs $R/jobs.jsonl --out $R > $R/queue.out 2>&1 < /dev/null &
