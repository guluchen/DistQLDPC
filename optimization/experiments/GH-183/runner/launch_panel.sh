#!/bin/bash
# GH-183 Tier 1-4 seed panel (yfclab2; cores 29-32, 34-43). Run from the worktree root.
F=~/mac-agent-20261009/frozen
R=~/mac-agent-20261009/gh183-runs/panel
mkdir -p $R
python3 optimization/experiments/GH-183/runner/make_jobs.py panel $R/jobs.jsonl $F/server-main-6083e66 $F/server-gh183-d26070d
nohup python3 optimization/experiments/GH-183/runner/gh183_queue.py --bin $F/server-gh183-d26070d --cpus 29-32,34-43 --jobs $R/jobs.jsonl --out $R > $R/queue.out 2>&1 < /dev/null &
