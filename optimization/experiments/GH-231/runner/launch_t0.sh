#!/bin/bash
# GH-231 Tier 0 launcher (yfclab2; logical CPUs 96-127 only; the queue checks each core and its sibling c+128 idle before
# every launch, the fixed-core jobs below are checked once by cpubusy.py and recorded). Run from the candidate worktree root.
# usage: launch_t0.sh CANDTAG MAINTAG CORE_TEST CORE_FLAGS CORE_IDENT QUEUE_CPUS
TAG=$1; MTAG=$2; CT=$3; CF=$4; CI=$5; QC=$6
F=~/mac-agent-20261009/frozen
M=$F/server-gh231-$MTAG/distqldpc
CAND=$F/server-gh231-$TAG/distqldpc
R=~/mac-agent-20261009/gh231-runs/t0-$TAG
RUN=optimization/experiments/GH-231/runner
mkdir -p $R
python3 ~/mac-agent-20261009/cpubusy.py 2 $CT $CF $CI $((CT+128)) $((CF+128)) $((CI+128)) > $R/idle_at_launch.txt
nohup taskset -c $CT prlimit --as=4294967296 -- $F/server-gh231-$TAG/test_cc_engine > $R/test_cc_engine.txt 2>&1 < /dev/null &
nohup taskset -c $CF prlimit --as=4294967296 -- bash tests/test_cc_flags.sh $CAND > $R/test_cc_flags.txt 2>&1 < /dev/null &
nohup taskset -c $CI python3 $RUN/ident.py $M $CAND $R/ident $CI > $R/identity_tier01.txt 2>&1 < /dev/null &
STEMS=$(for t in 0 1 2 3; do ls data/matrices/tier$t/*_Hx.txt; done | xargs -n1 basename | sed 's/_Hx.txt//')
python3 $RUN/make_jobs.py answers $R/answers_jobs.jsonl $M $CAND $STEMS
nohup taskset -c $QC python3 $RUN/gh231_queue.py --bin $CAND --cpus $QC --jobs $R/answers_jobs.jsonl --out $R/answers > $R/answers_queue.out 2>&1 < /dev/null &
