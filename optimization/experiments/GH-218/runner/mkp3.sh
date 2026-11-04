#!/bin/bash
# build pilot-cap panel jobs (cap 10 and 11) on cores given as args
cd ~/mac-agent-20261009/gh218-runs && mkdir -p p3
B=~/mac-agent-20261009/frozen/server-gh218-diag3/distqldpc; T5=data/matrices/tier5
cores=("$@"); nc=${#cores[@]}; i=0
for c in "${cores[@]}"; do rm -f jp3_$c.txt; done
for cap in 10 11; do for st in TN_216_4_18 TN_180_2_17; do for md in no-card card-mto; do for s in 0 1 2 3 4; do for h in X Z; do for a in auto off; do
  [ $st = TN_180_2_17 ] && [ $s -ge 3 ] && continue
  c=${cores[$((i % nc))]}; i=$((i+1)); o=""; [ $a = off ] && o="-stab-overlap=off"
  echo "$c p3/${st}_${h}${cap}_${md}_s${s}_$a.log $B DQ_DIAG=1|DQ_DIAG_PROBE=$h:$cap:9 -$md -seed=$s $o -frontier-stats -cpu-lim=3600 $T5/$st" >> jp3_$c.txt
done; done; done; done; done; done
for c in "${cores[@]}"; do setsid nohup ./seq.sh jp3_$c.txt >/dev/null 2>&1 < /dev/null & done
echo jobs $i
