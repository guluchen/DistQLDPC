#!/bin/bash
# GH-217 Tier 0 launcher (yfclab2; cores 72-111). Run from the candidate worktree root.
# 72: make test-cc binary (candidate); 73: test_cc_flags.sh (candidate); 74: identity vs main (old-default flags, MaxSAT);
# 75-79: answers + witness traces on tier0..tier3 codes (candidate variants).
F=~/mac-agent-20261009/frozen
MAIN=$F/server-gh217-main-02879a9/distqldpc
CAND=$F/server-gh217-bb3e2ef/distqldpc
R=~/mac-agent-20261009/gh217-runs
mkdir -p $R/t0 $R/answers/traces
nohup taskset -c 72 prlimit --as=4294967296 -- $F/server-gh217-bb3e2ef/test_cc_engine > $R/t0/test_cc_engine.txt 2>&1 < /dev/null &
nohup taskset -c 73 prlimit --as=4294967296 -- bash tests/test_cc_flags.sh $CAND > $R/t0/test_cc_flags.txt 2>&1 < /dev/null &
nohup taskset -c 74 python3 optimization/experiments/GH-217/runner/ident.py $MAIN $CAND $R/t0/ident 74 > $R/t0/identity_tier01.txt 2>&1 < /dev/null &
STEMS=$(for t in 0 1 2 3; do ls data/matrices/tier$t/*_Hx.txt; done | xargs -n1 basename | sed 's/_Hx.txt//')
python3 optimization/experiments/GH-217/runner/make_jobs.py answers $R/answers/jobs.jsonl $MAIN $CAND $STEMS
sed -i "s#TRACEDIR#$R/answers/traces#g" $R/answers/jobs.jsonl
nohup python3 optimization/experiments/GH-217/runner/gh217_queue.py --bin $CAND --cpus 75-79 --jobs $R/answers/jobs.jsonl --out $R/answers > $R/answers/queue.out 2>&1 < /dev/null &
