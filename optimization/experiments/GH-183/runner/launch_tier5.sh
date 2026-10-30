#!/bin/bash
# GH-183 Tier 5 (6 h, default seed; yfclab2 cores 29-32, 34-39, 41-43; 28, 33 and 40 are taken by other users). Short jobs first (LP codes, BB_360), then the long ones.
# Reference arms main and tb for the BB, LP and TN_496 codes are GH-162's Tier 5 runs on the same server (2026-10-29,
# optimization/experiments/GH-162/S1/tier5_results.jsonl); TN_252 and TN_288 (row weight 9) get main and tb arms here.
F=~/mac-agent-20261009/frozen
R=~/mac-agent-20261009/gh183-runs/tier5
mkdir -p $R
M=optimization/experiments/GH-183/runner/make_jobs.py
python3 $M tier5 $R/j1.jsonl $F/server-main-6083e66 $F/server-gh183-d26070d tbmrvbfs LP_1020_136_16 LP_1054_140_20 LP_1122_148_20 LP_1428_184_24 LP_1768_224_22 LP_2610_744_16 BB_360_12_24
python3 $M tier5 $R/j2.jsonl $F/server-main-6083e66 $F/server-gh183-d26070d tbmrvbfsa BB_360_12_24
python3 $M tier5 $R/j3.jsonl $F/server-main-6083e66 $F/server-gh183-d26070d tbmrvbfs BB_756_16_30to34 BB_864_4_30to40 BB_1080_4_30to48 TN_496_2_23to30 TN_252_2_21 TN_288_2_22to24
python3 $M tier5 $R/j4.jsonl $F/server-main-6083e66 $F/server-gh183-d26070d tbmrvbfsa BB_756_16_30to34 BB_864_4_30to40 BB_1080_4_30to48
python3 $M tier5 $R/j5.jsonl $F/server-main-6083e66 $F/server-gh183-d26070d main,tb TN_252_2_21 TN_288_2_22to24
cat $R/j1.jsonl $R/j2.jsonl $R/j3.jsonl $R/j4.jsonl $R/j5.jsonl > $R/jobs.jsonl
nohup python3 optimization/experiments/GH-183/runner/gh183_queue.py --bin $F/server-gh183-d26070d --cpus 29-32,34-39,41-43 --jobs $R/jobs.jsonl --out $R > $R/queue.out 2>&1 < /dev/null &
