#!/bin/bash
# GH-183 Tier 0 launcher (yfclab2; cores 29-32, 34-43; 28 and 33 are taken by other users). Run from the worktree root.
F=~/mac-agent-20261009/frozen
R=~/mac-agent-20261009/gh183-runs
mkdir -p $R/t0 $R/answers/traces
nohup taskset -c 29 prlimit --as=4294967296 -- $F/server-gh183-d26070d-test_cc_engine > $R/t0/test_cc_default.txt 2>&1 < /dev/null &
nohup taskset -c 30 prlimit --as=4294967296 -- $F/server-gh183-d26070d-test_cc_engine 0 0 0 0 0 2000 > $R/t0/test_cc_partR_2000.txt 2>&1 < /dev/null &
nohup taskset -c 31 python3 optimization/experiments/GH-183/runner/ident.py $F/server-gh162-97c8629 $F/server-gh183-d26070d $R/t0/ident 31 > $R/t0/identity_tier01.txt 2>&1 < /dev/null &
nohup taskset -c 32 prlimit --as=4294967296 -- bash tests/test_cc_flags.sh $F/server-gh183-d26070d > $R/t0/test_cc_flags.txt 2>&1 < /dev/null &
python3 optimization/experiments/GH-183/runner/make_jobs.py answers $R/answers/jobs.jsonl $F/server-main-6083e66 $F/server-gh183-d26070d
sed -i "s#TRACEDIR#$R/answers/traces#g" $R/answers/jobs.jsonl
nohup python3 optimization/experiments/GH-183/runner/gh183_queue.py --bin $F/server-gh183-d26070d --cpus 34-43 --jobs $R/answers/jobs.jsonl --out $R/answers > $R/answers/queue.out 2>&1 < /dev/null &
