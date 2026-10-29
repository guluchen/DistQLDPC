#!/bin/bash
# GH-206 Tier 1-4 seed panel (yfclab2; cores 33-39, 41-43). Run from the worktree root.
F=~/mac-agent-20261009/frozen
R=~/mac-agent-20261009/gh206v2-runs/panel
mkdir -p $R
python3 optimization/experiments/GH-206/runner/make_jobs.py panel $R/jobs.jsonl $F/server-main-6083e66 $F/server-gh206-14ec146 main,tb,tbmrvbfs,auto,autoa
nohup python3 optimization/experiments/GH-206/runner/gh206_queue.py --bin $F/server-gh206-14ec146 --cpus 33-39,41-43 --jobs $R/jobs.jsonl --out $R > $R/queue.out 2>&1 < /dev/null &
