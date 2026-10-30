#!/bin/bash
# GH-183 LP diagnostic: the Tier 5 LP codes on one pinned core (40, free during the Tier 5 run), arms run back to back,
# deepest EMPTY level: nodes and level seconds. usage: lp_arms.sh CORE OUT (from a worktree root)
F=~/mac-agent-20261009/frozen; TB=excl,pack,orbf,parity,leaf,overlap,tiebreak; CORE=$1; OUT=$2
for c in LP_1054_140_20 LP_1122_148_20 LP_2610_744_16 LP_1768_224_22 LP_1428_184_24; do
  for a in main tb tbmrv tbbfs tbmrvbfs tbmrvbfsa; do
    case $a in main) B=$F/server-main-6083e66; X="";; tb) B=$F/server-gh183-d26070d; X="-cc-rules=$TB";;
      tbmrv) B=$F/server-gh183-d26070d; X="-cc-rules=$TB,mrv";; tbbfs) B=$F/server-gh183-d26070d; X="-cc-rules=$TB -cc-roworder=bfs";;
      tbmrvbfs) B=$F/server-gh183-d26070d; X="-cc-rules=$TB,mrv -cc-roworder=bfs";;
      tbmrvbfsa) B=$F/server-gh183-d26070d; X="-cc-rules=$TB,mrv -cc-roworder=bfs -cc-tbbase=asc";; esac
    t0=$(date +%s.%N)
    L=$(taskset -c $CORE prlimit --as=4294967296 -- $B -engine=cc -cc-stats $X -cpu-lim=1800 $c < /dev/null | grep -E "level [0-9]+ EMPTY" | tail -1 | sed -E "s/.*level ([0-9]+) EMPTY nodes ([0-9]+) .* time ([0-9.]+)s.*/L\1 nodes \2 time \3/")
    echo "$c $a $L wall $(echo "$(date +%s.%N) - $t0" | bc)" >> $OUT
  done
done
echo DONE >> $OUT
