#!/bin/bash
# usage: run3.sh BIN DATAROOT OUTDIR CPULIM TAG STEM...   (configs: M = default, N = +erasure gate none, C = +erasure gate cost)
BIN=$1; ROOT=$2; OUT=$3; LIM=$4; TAG=$5; shift 5
D=excl,pack,orbf,parity,leaf,overlap,charge,tiebreak,sparse,sparseov,sparsemrv
for s in "$@"; do
  code=$(ls $ROOT/*/${s}_Hx.txt | head -1); code=${code%_Hx.txt}
  for cfg in ${CFGS:-M N C}; do
    case $cfg in M) a=();; N) a=(-cc-rules=$D,erasure -cc-erasure-gate=none);; C) a=(-cc-rules=$D,erasure ${EXTRA});; esac
    t0=$(python3 -c 'import time;print(time.time())')
    ( ulimit -v 2097152 2>/dev/null; $BIN -engine=cc -cc-stats -cpu-lim=$LIM "${a[@]}" $code ) > $OUT/$s.$cfg$TAG.out 2>&1
    t1=$(python3 -c 'import time;print(time.time())')
    echo "$s $cfg$TAG wall $(python3 -c "print(round($t1-$t0,3))") $(grep -E '^o ' $OUT/$s.$cfg$TAG.out | head -1) $(grep 'total nodes' $OUT/$s.$cfg$TAG.out)"
  done
done
