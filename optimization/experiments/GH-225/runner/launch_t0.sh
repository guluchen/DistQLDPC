#!/bin/bash
# GH-225 Tier 0 launcher (yfclab2; CPUs 104-111, each checked idle with its sibling before the launch). Run from the
# candidate worktree root. 104: test_cc_engine (candidate); 105: test_cc_flags.sh (candidate); 106: identity vs A (GH-217
# rules on the candidate, MaxSAT unchanged); 107-111: answers + witness traces on tier0..tier3 codes (candidate variants).
F=~/mac-agent-20261009/frozen
A=$F/server-gh225-A-42d7d1d/distqldpc
CAND=$F/server-gh225-5a201fd/distqldpc
R=~/mac-agent-20261009/gh225-runs
RUN=optimization/experiments/GH-225/runner
mkdir -p $R/t0 $R/answers/traces
python3 ~/mac-agent-20261009/cpubusy.py 2 104 105 106 232 233 234 > $R/t0/idle_at_launch.txt
nohup taskset -c 104 prlimit --as=4294967296 -- $F/server-gh225-5a201fd/test_cc_engine > $R/t0/test_cc_engine.txt 2>&1 < /dev/null &
nohup taskset -c 105 prlimit --as=4294967296 -- bash tests/test_cc_flags.sh $CAND > $R/t0/test_cc_flags.txt 2>&1 < /dev/null &
nohup taskset -c 106 python3 $RUN/ident.py $A $CAND $R/t0/ident 106 > $R/t0/identity_tier01.txt 2>&1 < /dev/null &
STEMS=$(for t in 0 1 2 3; do ls data/matrices/tier$t/*_Hx.txt; done | xargs -n1 basename | sed 's/_Hx.txt//')
python3 $RUN/make_jobs.py answers $R/answers/jobs.jsonl $A $CAND $STEMS
sed -i "s#TRACEDIR#$R/answers/traces#g" $R/answers/jobs.jsonl
nohup taskset -c 107-111 python3 $RUN/gh225_queue.py --bin $CAND --cpus 107-111 --jobs $R/answers/jobs.jsonl --out $R/answers > $R/answers/queue.out 2>&1 < /dev/null &
