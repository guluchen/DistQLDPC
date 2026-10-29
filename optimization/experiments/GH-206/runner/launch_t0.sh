#!/bin/bash
# GH-206 Tier 0 launcher (yfclab2; cores 33-39, 41-43). Run from the worktree root.
F=~/mac-agent-20261009/frozen
R=~/mac-agent-20261009/gh206-runs
mkdir -p $R/t0 $R/answers/traces
nohup taskset -c 33 prlimit --as=4294967296 -- $F/server-gh206-ab91aac-test_cc_engine > $R/t0/test_cc_default.txt 2>&1 < /dev/null &
nohup taskset -c 34 python3 optimization/experiments/GH-206/runner/ident.py $F/server-gh183-d26070d $F/server-gh206-ab91aac $R/t0/ident 34 > $R/t0/identity_tier01.txt 2>&1 < /dev/null &
nohup taskset -c 35 prlimit --as=4294967296 -- bash tests/test_cc_flags.sh $F/server-gh206-ab91aac > $R/t0/test_cc_flags.txt 2>&1 < /dev/null &
python3 optimization/experiments/GH-206/runner/make_jobs.py answers $R/answers/jobs.jsonl $F/server-main-6083e66 $F/server-gh206-ab91aac
sed -i "s#TRACEDIR#$R/answers/traces#g" $R/answers/jobs.jsonl
nohup python3 optimization/experiments/GH-206/runner/gh206_queue.py --bin $F/server-gh206-ab91aac --cpus 36-39,41-43 --jobs $R/answers/jobs.jsonl --out $R/answers > $R/answers/queue.out 2>&1 < /dev/null &
