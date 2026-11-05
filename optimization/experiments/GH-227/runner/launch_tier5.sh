#!/bin/bash
# GH-227 Tier 5 (6 h = 21600 s, default seed), arms M (frozen main 1239e9a2) and C (candidate) of each code adjacent (they
# start together). Part a: the 11 codes main solves (GH-225 Tier 5 table) first, then the first open codes; part b: the
# remaining open codes. usage: launch_tier5.sh a|b CPUS CANDTAG [NOPEN_A]   (from the candidate worktree root)
PART=$1; CPUS=$2; TAG=$3; NA=${4:-11}
F=~/mac-agent-20261009/frozen
M=$F/server-gh227-main-1239e9a/distqldpc
CAND=$F/server-gh227-$TAG/distqldpc
R=~/mac-agent-20261009/gh227-runs/tier5$PART
RUN=optimization/experiments/GH-227/runner
mkdir -p $R
SOLVED="TN_252_2_21 LP_1428_184_24 TN_216_4_18 TN_180_2_17 BB_360_12_24 LP_1768_224_22 COLOR_331_1_21 LP_1122_148_20 HGP_1105_1_24 LP_2610_744_16 LP_1054_140_20"
OPEN=$(ls data/matrices/tier5/*_Hx.txt | xargs -n1 basename | sed 's/_Hx.txt//' | grep -v -x -F "$(echo $SOLVED | tr ' ' '\n')")
if [[ $PART == a ]]; then CODES="$SOLVED $(echo $OPEN | tr ' ' '\n' | head -$NA)"
else CODES="$(echo $OPEN | tr ' ' '\n' | tail -n +$((NA + 1)))"; fi
python3 $RUN/make_jobs.py tier5 $R/jobs.jsonl $M $CAND M,C 21600 $CODES
nohup taskset -c $CPUS python3 $RUN/gh227_queue.py --bin $CAND --cpus $CPUS --jobs $R/jobs.jsonl --out $R > $R/queue.out 2>&1 < /dev/null &
