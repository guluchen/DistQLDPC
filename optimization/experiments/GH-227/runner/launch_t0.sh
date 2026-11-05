#!/bin/bash
# GH-227 Tier 0 launcher (yfclab2; CPUs 96-103, each checked idle with its sibling before the launch). Run from the
# candidate worktree root. 96: test_cc_engine (candidate); 97: test_cc_flags.sh (candidate); 98: identity vs main (GH-217
# rules on the candidate, MaxSAT unchanged); 99-103: answers + witness traces on tier0..tier3 codes (candidate variants).
F=~/mac-agent-20261009/frozen
M=$F/server-gh227-main-1239e9a/distqldpc
CAND=$F/server-gh227-03113cb/distqldpc
R=~/mac-agent-20261009/gh227-runs
RUN=optimization/experiments/GH-227/runner
mkdir -p $R/t0 $R/answers/traces
python3 ~/mac-agent-20261009/cpubusy.py 2 96 97 98 99 100 101 102 103 224 225 226 227 228 229 230 231 > $R/t0/idle_at_launch.txt
nohup taskset -c 96 prlimit --as=4294967296 -- $F/server-gh227-03113cb/test_cc_engine > $R/t0/test_cc_engine.txt 2>&1 < /dev/null &
nohup taskset -c 97 prlimit --as=4294967296 -- bash tests/test_cc_flags.sh $CAND > $R/t0/test_cc_flags.txt 2>&1 < /dev/null &
nohup taskset -c 98 python3 $RUN/ident.py $M $CAND $R/t0/ident 98 > $R/t0/identity_tier01.txt 2>&1 < /dev/null &
STEMS=$(for t in 0 1 2 3; do ls data/matrices/tier$t/*_Hx.txt; done | xargs -n1 basename | sed 's/_Hx.txt//')
python3 $RUN/make_jobs.py answers $R/answers/jobs.jsonl $M $CAND $STEMS
sed -i "s#TRACEDIR#$R/answers/traces#g" $R/answers/jobs.jsonl
nohup taskset -c 99-103 python3 $RUN/gh227_queue.py --bin $CAND --cpus 99-103 --jobs $R/answers/jobs.jsonl --out $R/answers > $R/answers/queue.out 2>&1 < /dev/null &
