#!/bin/bash
# GH-217 Tier 5 (6 h = 21600 s, default seed; yfclab2 cores 84-111), arms main and A of each code adjacent (they start together).
# Codes solved by main's CC default in earlier rounds first (LP watch list, BB_360, TN_180/216/252), then the open ones.
F=~/mac-agent-20261009/frozen
MAIN=$F/server-gh217-main-02879a9/distqldpc
CAND=$F/server-gh217-bb3e2ef/distqldpc
R=~/mac-agent-20261009/gh217-runs/tier5
mkdir -p $R
FIRST="LP_2610_744_16 LP_1428_184_24 LP_1122_148_20 LP_1768_224_22 LP_1020_136_16 LP_1054_140_20 BB_360_12_24 TN_180_2_17 TN_216_4_18 TN_252_2_21"
REST=$(ls data/matrices/tier5/*_Hx.txt | xargs -n1 basename | sed 's/_Hx.txt//' | grep -v -x -F "$(echo $FIRST | tr ' ' '\n')")
python3 optimization/experiments/GH-217/runner/make_jobs.py tier5 $R/jobs.jsonl $MAIN $CAND main,A 21600 $FIRST $REST
nohup python3 optimization/experiments/GH-217/runner/gh217_queue.py --bin $CAND --cpus 84-111 --jobs $R/jobs.jsonl --out $R > $R/queue.out 2>&1 < /dev/null &
