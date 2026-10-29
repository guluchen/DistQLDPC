#!/bin/bash
# GH-206 Tier 5 (6 h, default seed; yfclab2 cores 33-39, 41-43). Short jobs first. References: main / tb from GH-162's
# Tier 5 (BB, LP), tbmrvbfs and TN_252 / TN_288 main / tb from GH-183's Tier 5; TN_180 / TN_216 get tb and tbmrvbfs here.
F=~/mac-agent-20261009/frozen
R=~/mac-agent-20261009/gh206-runs/tier5
mkdir -p $R
M=optimization/experiments/GH-206/runner/make_jobs.py
python3 $M tier5 $R/j1.jsonl $F/server-main-6083e66 $F/server-gh206-ab91aac auto LP_1020_136_16 LP_1054_140_20 LP_1122_148_20 LP_1428_184_24 LP_1768_224_22 LP_2610_744_16 BB_360_12_24 TN_180_2_17 TN_216_4_18
python3 $M tier5 $R/j2.jsonl $F/server-main-6083e66 $F/server-gh206-ab91aac tb,tbmrvbfs TN_180_2_17 TN_216_4_18
python3 $M tier5 $R/j3.jsonl $F/server-main-6083e66 $F/server-gh206-ab91aac auto BB_756_16_30to34 BB_864_4_30to40 BB_1080_4_30to48 TN_252_2_21 TN_288_2_22to24
python3 $M tier5 $R/j4.jsonl $F/server-main-6083e66 $F/server-gh206-ab91aac autoa BB_360_12_24 BB_756_16_30to34 BB_864_4_30to40 BB_1080_4_30to48
cat $R/j1.jsonl $R/j2.jsonl $R/j3.jsonl $R/j4.jsonl > $R/jobs.jsonl
nohup python3 optimization/experiments/GH-206/runner/gh206_queue.py --bin $F/server-gh206-ab91aac --cpus 33-39,41-43 --jobs $R/jobs.jsonl --out $R > $R/queue.out 2>&1 < /dev/null &
