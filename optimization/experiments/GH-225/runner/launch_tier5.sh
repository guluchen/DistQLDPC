#!/bin/bash
# GH-225 Tier 5 (6 h = 21600 s, default seed), arms A and E of each code adjacent (they start together).
# Two runners on disjoint cores: part a (CPUs 112-127): the 11 codes A solves (GH-217 Tier 5 table), then 11 codes A does
# not solve; part b (CPUs 104-111, launched after Tier 0 freed them): the other 8 open codes.
# usage: launch_tier5.sh a|b   (from the candidate worktree root)
PART=$1
F=~/mac-agent-20261009/frozen
A=$F/server-gh225-A-42d7d1d/distqldpc
CAND=$F/server-gh225-5a201fd/distqldpc
R=~/mac-agent-20261009/gh225-runs/tier5$PART
RUN=optimization/experiments/GH-225/runner
mkdir -p $R
SOLVED="TN_252_2_21 LP_1428_184_24 TN_216_4_18 TN_180_2_17 BB_360_12_24 LP_1768_224_22 COLOR_331_1_21 LP_1122_148_20 HGP_1105_1_24 LP_2610_744_16 LP_1054_140_20"
OPEN=$(ls data/matrices/tier5/*_Hx.txt | xargs -n1 basename | sed 's/_Hx.txt//' | grep -v -x -F "$(echo $SOLVED | tr ' ' '\n')")
if [[ $PART == a ]]; then CPUS=112-127; CODES="$SOLVED $(echo $OPEN | tr ' ' '\n' | head -11)"
else CPUS=104-111; CODES="$(echo $OPEN | tr ' ' '\n' | tail -n +12)"; fi
python3 $RUN/make_jobs.py tier5 $R/jobs.jsonl $A $CAND A,E 21600 $CODES
nohup taskset -c $CPUS python3 $RUN/gh225_queue.py --bin $CAND --cpus $CPUS --jobs $R/jobs.jsonl --out $R > $R/queue.out 2>&1 < /dev/null &
