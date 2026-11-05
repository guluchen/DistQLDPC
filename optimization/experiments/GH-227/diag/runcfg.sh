#!/bin/bash
# usage: runcfg.sh BIN LIM TAG STEM "ARGS..."   (ARGS word-split)
BIN=$1; LIM=$2; TAG=$3; s=$4; shift 4
code=$(ls mat/*/${s}_Hx.txt | head -1); code=${code%_Hx.txt}
t0=$(python3 -c 'import time;print(time.time())')
( ulimit -v 2097152 2>/dev/null; $BIN -engine=cc -cc-stats -cpu-lim=$LIM $@ $code ) > $s.$TAG.out 2>&1
t1=$(python3 -c 'import time;print(time.time())')
echo "$s $TAG wall $(python3 -c "print(round($t1-$t0,3))") $(grep -E '^o ' $s.$TAG.out | head -1) $(grep 'total nodes' $s.$TAG.out)"
