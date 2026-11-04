#!/bin/bash
# GH-225 Tier 1-3 seed panel (yfclab2): arms A (PR #220 head) and E (candidate) adjacent per (code, seed), so each pair starts
# together on two pinned cores; seeds 0-4; limit 1800 s. usage: launch_panel.sh CPUS OUTNAME   (from the candidate worktree root)
CPUS=$1; NAME=$2
F=~/mac-agent-20261009/frozen
A=$F/server-gh225-A-42d7d1d/distqldpc
CAND=$F/server-gh225-5a201fd/distqldpc
R=~/mac-agent-20261009/gh225-runs/$NAME
RUN=optimization/experiments/GH-225/runner
mkdir -p $R
STEMS=$(for t in 3 2 1; do ls data/matrices/tier$t/*_Hx.txt; done | xargs -n1 basename | sed 's/_Hx.txt//')
python3 $RUN/make_jobs.py panel $R/jobs.jsonl $A $CAND A,E 5 1800 $STEMS
nohup taskset -c $CPUS python3 $RUN/gh225_queue.py --bin $CAND --cpus $CPUS --jobs $R/jobs.jsonl --out $R > $R/queue.out 2>&1 < /dev/null &
