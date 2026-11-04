#!/bin/bash
# usage: run1.sh CORE OUTNAME BIN "ENV" ARGS... ; runs in gh218-diag worktree (data path)
core=$1; out=$(readlink -f $2); bin=$3; envs=$4; shift 4
cd ~/mac-agent-20261009/gh218-diag
start=$(date +%s.%N)
echo "# start $start core $core env $envs cmd $bin $*" > $out
env $envs taskset -c $core prlimit --as=4294967296 -- /usr/bin/time -f "TIME %e %U %M" $bin "$@" < /dev/null >> $out 2>&1
echo "# rc $? end $(date +%s.%N)" >> $out
