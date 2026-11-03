#!/bin/bash
# GH-206 same-session LP references for Tier 5: tb and tbmrvbfs (and auto with -cc-probe-growth=0) on the Tier 5 LP codes,
# back to back on one pinned core (free during the Tier 5 run). usage: lp_ref.sh CORE OUT (from a worktree root)
F=~/mac-agent-20261009/frozen; B=$F/server-gh206-14ec146; TB=excl,pack,orbf,parity,leaf,overlap,tiebreak; CORE=$1; OUT=$2
for c in LP_1054_140_20 LP_1122_148_20 LP_2610_744_16 LP_1768_224_22 LP_1428_184_24; do
  for a in tb tbmrvbfs auto0; do
    case $a in tb) X="-cc-rules=$TB";; tbmrvbfs) X="-cc-rules=$TB,mrv -cc-roworder=bfs";; auto0) X="-cc-rules=$TB -cc-roworder=auto -cc-probe-growth=0";; esac
    t0=$(date +%s.%N)
    L=$(taskset -c $CORE prlimit --as=4294967296 -- $B -engine=cc -cc-stats $X -cpu-lim=1800 $c < /dev/null | grep -E "^o |total nodes" | tr "\n" " ")
    echo "$c $a wall $(echo "$(date +%s.%N) - $t0" | bc) $L" >> $OUT
  done
done
echo DONE >> $OUT
