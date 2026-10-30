#!/bin/bash
# GH-183 TN diagnostic (row-weight-9 TN codes): arms back to back on one pinned core, every completed level: nodes, seconds.
# usage: tn_arms.sh CORE OUT LIMIT STEM... (from a worktree root)
F=~/mac-agent-20261009/frozen; TB=excl,pack,orbf,parity,leaf,overlap,tiebreak; CORE=$1; OUT=$2; LIM=$3; shift 3
for c in "$@"; do
  for a in tb tbmrv tbbfs tbmrvbfs; do
    case $a in tb) X="-cc-rules=$TB";; tbmrv) X="-cc-rules=$TB,mrv";; tbbfs) X="-cc-rules=$TB -cc-roworder=bfs";;
      tbmrvbfs) X="-cc-rules=$TB,mrv -cc-roworder=bfs";; esac
    taskset -c $CORE prlimit --as=4294967296 -- $F/server-gh183-d26070d -engine=cc -cc-stats $X -cpu-lim=$LIM $c < /dev/null \
      | grep -E "level [0-9]+ (EMPTY|FOUND) nodes" | sed -E "s/.*(level [0-9]+ [A-Z]+) nodes ([0-9]+) .* time ([0-9.]+)s.*/$c $a \1 nodes \2 time \3/" >> $OUT
  done
done
echo DONE >> $OUT
