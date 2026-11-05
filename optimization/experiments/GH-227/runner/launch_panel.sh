#!/bin/bash
# GH-227 Tier 1-3 seed panel (yfclab2): arms M (frozen main 1239e9a2) and C (candidate) adjacent per (code, seed), so each
# pair starts together on two pinned cores; seeds 0-4; limit 1800 s. usage: launch_panel.sh CPUS OUTNAME CANDTAG
# (from the candidate worktree root)
CPUS=$1; NAME=$2; TAG=$3
F=~/mac-agent-20261009/frozen
M=$F/server-gh227-main-1239e9a/distqldpc
CAND=$F/server-gh227-$TAG/distqldpc
R=~/mac-agent-20261009/gh227-runs/$NAME
RUN=optimization/experiments/GH-227/runner
mkdir -p $R
STEMS=$(for t in 3 2 1; do ls data/matrices/tier$t/*_Hx.txt; done | xargs -n1 basename | sed 's/_Hx.txt//')
python3 $RUN/make_jobs.py panel $R/jobs.jsonl $M $CAND M,C 5 1800 $STEMS
nohup taskset -c $CPUS python3 $RUN/gh227_queue.py --bin $CAND --cpus $CPUS --jobs $R/jobs.jsonl --out $R > $R/queue.out 2>&1 < /dev/null &
