#!/bin/bash
# ident.sh CORE TIERGLOB...: answers + identity (stdout and FRONTIER stderr) main vs cand default vs cand -stab-overlap-c4=off
core=$1; shift
cd ~/mac-agent-20261009/gh218-60fec5b
M=~/mac-agent-20261009/frozen/server-main-02879a93/distqldpc; C=~/mac-agent-20261009/frozen/server-gh218-60fec5b/distqldpc
O=~/mac-agent-20261009/gh218-runs/ident; mkdir -p $O
for t in "$@"; do for hx in data/matrices/$t/*_Hx.txt; do stem=${hx%_Hx.txt}; b=$(basename $stem); for md in -no-card -card-mto; do
  for arm in main cand c4off; do
    bin=$C; extra=""; [ $arm = main ] && bin=$M; [ $arm = c4off ] && extra="-stab-overlap-c4=off"
    taskset -c $core prlimit --as=4294967296 -- $bin $md $extra -frontier-stats -cpu-lim=600 $stem > $O/$b$md.$arm.out 2> $O/$b$md.$arm.err < /dev/null
    grep -E "FRONTIER|OVERLAP" $O/$b$md.$arm.err > $O/$b$md.$arm.fr
  done
  ans=$(grep "^o " $O/$b$md.cand.out); want=${b##*_}
  s1=$(cmp -s $O/$b$md.main.out $O/$b$md.cand.out && echo same || echo DIFF); s2=$(cmp -s $O/$b$md.main.out $O/$b$md.c4off.out && echo same || echo DIFF)
  f1=$(cmp -s $O/$b$md.main.fr $O/$b$md.cand.fr && echo same || echo DIFF); f2=$(cmp -s $O/$b$md.main.fr $O/$b$md.c4off.fr && echo same || echo DIFF)
  echo "$b $md answer[$ans want $want] stdout cand:$s1 c4off:$s2 probes cand:$f1 c4off:$f2"
done; done; done
echo DONE
