#!/bin/sh
# usage: traces.sh BASE GH76 GH85 CAND OUTDIR [LOCKFILE]   (run from repo root; serial, one solver process at a time)
# -joint vs fresh 72d1fe1 and -no-symbreak vs fresh GH-76 b3d6b5d must be byte-identical; GH-85 and default
# candidate traces are recorded for inspection (not expected identical: different probe engine).
B=$1; I=$2; Y=$3; C=$4; O=$5; LOCK=${6:-/nonexistent}; mkdir -p $O
w() { while [ -e "$LOCK" ]; do sleep 30; done; }
for code in LP_34_20_2 BB_72_12_6 TN_36_8_4 BB_90_8_10 GB_144_12_8; do
  for m in default no-card; do
    f=""; [ $m = no-card ] && f="-no-card"
    w; $B -v -cpu-lim=120 $f $code > $O/$code.$m.base.txt 2>&1
    w; $C -v -cpu-lim=120 -joint $f $code > $O/$code.$m.cand-joint.txt 2>&1
    if cmp -s $O/$code.$m.base.txt $O/$code.$m.cand-joint.txt; then j=IDENTICAL; else j=DIFFER; fi
    case $code in BB_90_8_10|GB_144_12_8) echo "$code $m joint-vs-base=$j base_o=$(grep '^o ' $O/$code.$m.base.txt)"; continue;; esac
    w; $I -v -cpu-lim=120 $f $code > $O/$code.$m.gh76.txt 2>&1
    w; $C -v -cpu-lim=120 -no-symbreak $f $code > $O/$code.$m.cand-nosb.txt 2>&1
    w; $Y -v -cpu-lim=120 $f $code > $O/$code.$m.gh85.txt 2>&1
    w; $C -v -cpu-lim=120 $f $code > $O/$code.$m.cand.txt 2>&1
    if cmp -s $O/$code.$m.gh76.txt $O/$code.$m.cand-nosb.txt; then s=IDENTICAL; else s=DIFFER; fi
    echo "$code $m joint-vs-base=$j nosymbreak-vs-gh76=$s base_o=$(grep '^o ' $O/$code.$m.base.txt) gh85_o=$(grep '^o ' $O/$code.$m.gh85.txt) cand_o=$(grep '^o ' $O/$code.$m.cand.txt) builds=$(grep -o 'solver builds.*' $O/$code.$m.cand.txt)"
  done
done
