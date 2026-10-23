#!/bin/bash
# GH-146 S1 on yfclab2 (from the gh146-4f16e0d worktree root), started after the S0 chain: Tier 5 (81 runs x 6 h) on
# 81 pinned cores and the Tier 1-4 panel (330 runs) on the remaining 11 cores (1, 90-99), concurrently.
set -u
until [ -f res/S0_CHAIN_DONE ]; do sleep 30; done
mkdir -p res/tier5_traces
python3 -I S1/runner/s1_queue.py --cpus 2-13,15,17-19,21-49,51-73,75-77,79-87,89 --jobs S1/runner/jobs_tier5.jsonl --out res/tier5 > res/tier5.out 2>&1 &
python3 -I S1/runner/s1_queue.py --cpus 1,90-99 --jobs S1/runner/jobs_panel.jsonl --out res/panel > res/panel.out 2>&1 &
wait
touch res/S1_DONE
