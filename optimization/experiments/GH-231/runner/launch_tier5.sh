#!/bin/bash
# GH-231 Tier 5 (yfclab2, logical CPUs 96-127 only, idle check per launch in the queue): 6 h, default seed, both modes.
# First the codes main's MaxSAT solves within 6 h (TN_180, TN_216, BB_360, LP_1122, COLOR_331): main (M) and the candidate
# arm adjacent (they start together on two cores); then every open tier5 code with the candidate arm only (main's lbs on
# them are the recorded 6 h table of optimization/baselines/SERVER.md). usage: launch_tier5.sh CANDTAG MAINTAG ARM CPUS NAME
TAG=$1; MTAG=$2; ARM=$3; CPUS=$4; NAME=$5
F=~/mac-agent-20261009/frozen
M=$F/server-gh231-$MTAG/distqldpc
CAND=$F/server-gh231-$TAG/distqldpc
R=~/mac-agent-20261009/gh231-runs/$NAME
RUN=optimization/experiments/GH-231/runner
mkdir -p $R
SOLVED="TN_180_2_17 TN_216_4_18 BB_360_12_24 LP_1122_148_20 COLOR_331_1_21"
OPEN=$(ls data/matrices/tier5/*_Hx.txt | xargs -n1 basename | sed 's/_Hx.txt//' | grep -v -E "^(TN_180_2_17|TN_216_4_18|BB_360_12_24|LP_1122_148_20|COLOR_331_1_21)$")
python3 $RUN/make_jobs.py tier5 $R/jobs_solved.jsonl $M $CAND M,$ARM no-card,card-mto 21600 $SOLVED
python3 $RUN/make_jobs.py tier5 $R/jobs_open.jsonl $M $CAND $ARM no-card,card-mto 21600 $OPEN
cat $R/jobs_solved.jsonl $R/jobs_open.jsonl > $R/jobs.jsonl
nohup taskset -c $CPUS python3 $RUN/gh231_queue.py --bin $CAND --cpus $CPUS --jobs $R/jobs.jsonl --out $R > $R/queue.out 2>&1 < /dev/null &
