#!/bin/bash
# GH-225 brief tuning (yfclab2 CPUs 104-127): A vs A + erasure with -cc-erasure-start 4096 / 16384 (default) / 65536.
# A few Tier 1-3 codes with seeds 0-2, a few Tier 5 codes (and HGP_2866) with the default seed. Run from the A worktree root.
F=~/mac-agent-20261009/frozen
A=$F/server-gh225-A-42d7d1d/distqldpc
R=~/mac-agent-20261009/gh225-runs/tune
RUN=optimization/experiments/GH-225/runner
mkdir -p $R
ARMS=A,Es4096,Es16384,Es65536
python3 $RUN/make_jobs.py panel $R/j1 $A $A $ARMS 3 1800 LP_442_68_10 HGP_265_1_12 BB_144_14_14 TN_144_2_13 AMC_522_6_20 TN_200_10_10 \
    BB_294_10_20 TN_250_10_15 HGP_481_1_16 LP_1020_136_16
python3 $RUN/make_jobs.py tier5 $R/j2 $A $A $ARMS 3600 LP_1428_184_24 TN_216_4_18 TN_180_2_17 HGP_2866_256_8 BB_360_12_24 COLOR_331_1_21 HGP_1105_1_24
cat $R/j2 $R/j1 > $R/jobs.jsonl; rm $R/j1 $R/j2; wc -l $R/jobs.jsonl
nohup taskset -c 104-127 python3 $RUN/gh225_queue.py --bin $A --cpus 104-127 --jobs $R/jobs.jsonl --out $R > $R/queue.out 2>&1 < /dev/null &
