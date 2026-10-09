#!/bin/sh
# usage: traces.sh BASE GH73 CAND OUTDIR   (run from repo root, serial, one solver process at a time)
B=$1; G=$2; C=$3; O=$4; mkdir -p $O
for code in LP_34_20_2 BB_72_12_6 TN_36_8_4; do
  for m in default no-card; do
    f=""; [ $m = no-card ] && f="-no-card"
    $B -v -cpu-lim=120 $f $code > $O/$code.$m.base.txt 2>&1
    $C -v -cpu-lim=120 -joint $f $code > $O/$code.$m.cand-joint.txt 2>&1
    $G -v -cpu-lim=120 $f $code > $O/$code.$m.gh73.txt 2>&1
    $C -v -cpu-lim=120 -no-symbreak $f $code > $O/$code.$m.cand-nosb.txt 2>&1
    $C -v -cpu-lim=120 $f $code > $O/$code.$m.cand.txt 2>&1
    if cmp -s $O/$code.$m.base.txt $O/$code.$m.cand-joint.txt; then j=IDENTICAL; else j=DIFFER; fi
    if cmp -s $O/$code.$m.gh73.txt $O/$code.$m.cand-nosb.txt; then s=IDENTICAL; else s=DIFFER; fi
    echo "$code $m joint-vs-base=$j nosymbreak-vs-gh73=$s base_o=$(grep '^o ' $O/$code.$m.base.txt) cand_o=$(grep '^o ' $O/$code.$m.cand.txt)"
  done
done
