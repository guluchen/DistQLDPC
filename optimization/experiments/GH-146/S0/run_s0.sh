#!/bin/bash
# GH-146 S0 chain on yfclab2 (from the gh146-4f16e0d worktree root): known-d 60 s, pre-pass 60 s, open codes 3600 s.
set -u
B=../frozen/server-gh146-4f16e0d/distqldpc
C=2-13,15,17-19,21-49,51-73,75-77,79-87,89-99
python3 -I S0/queue.py --bin $B --cpus $C --jobs S0/jobs/knownd60.jsonl --out res/knownd60 > res/knownd60.out 2>&1
python3 -I S0/prepass_runs.py --bin $B --cpus $C --budget 60 --seeds 0,1,2,3,4 --out res/prepass_old > res/prepass_old.out 2>&1
python3 -I S0/prepass_runs.py --bin $B --cpus $C --budget 60 --seeds 0,1,2,3,4 --extra=-ub-isd=stern --out res/prepass_stern > res/prepass_stern.out 2>&1
python3 -I S0/queue.py --bin $B --cpus $C --jobs S0/jobs/open3600.jsonl --out res/open3600 > res/open3600.out 2>&1
touch res/S0_CHAIN_DONE
