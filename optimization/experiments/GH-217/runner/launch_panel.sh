#!/bin/bash
# GH-217 Tier 1-4 seed panel (yfclab2): arms main, A, B adjacent per (code, seed); seeds 0-4; limit 1800 s (tier 1-3) and
# 5000 s (tier 4). usage: launch_panel.sh CPUS OUTNAME STEM...  (from the candidate worktree root; tier taken from the directory)
CPUS=$1; NAME=$2; shift 2
F=~/mac-agent-20261009/frozen
MAIN=$F/server-gh217-main-02879a9/distqldpc
CAND=$F/server-gh217-bb3e2ef/distqldpc
R=~/mac-agent-20261009/gh217-runs/$NAME
mkdir -p $R
: > $R/jobs.jsonl
for s in "$@"; do
    d=$(dirname $(ls data/matrices/*/${s}_Hx.txt)); lim=1800; [[ $d == */tier4 ]] && lim=5000
    python3 optimization/experiments/GH-217/runner/make_jobs.py panel $R/j.tmp $MAIN $CAND main,A,B 5 $lim $s > /dev/null
    cat $R/j.tmp >> $R/jobs.jsonl
done
rm -f $R/j.tmp; wc -l $R/jobs.jsonl
nohup python3 optimization/experiments/GH-217/runner/gh217_queue.py --bin $CAND --cpus $CPUS --jobs $R/jobs.jsonl --out $R > $R/queue.out 2>&1 < /dev/null &
