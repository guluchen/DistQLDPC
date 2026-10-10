#!/bin/bash
# GH-102 flag-equivalence traces. usage (repo root): traces.sh BINDIR OUTDIR
# BINDIR holds space-free links: cand (GH-102 frozen), gh89 (frozen89), gh94 (frozen94), main7e (frozen-main7e),
# base72 (72d1fe1, frozen73n/base). Serial, one solver process at a time, each under the 2 GB cap (capped.py);
# the same -cpu-lim=120 on both sides of every comparison.
#   -no-dualshare == GH-89 (byte-identical); -joint == main 7eadd54 -joint and == 72d1fe1 default (joint encoding);
#   default == GH-89 modulo the single 'c dualshare:' report line on codes without a dual map (LP);
#   default / -dualshare-b on dual-map codes: recorded, o-value compared with GH-89 and GH-94.
D=$1; O=$2; mkdir -p "$O"
C="python3 -B optimization/experiments/GH-102/capped.py"
lim=-cpu-lim=120
same() { if cmp -s "$1" "$2"; then echo IDENTICAL; else echo DIFFER; fi; }
modd() { if grep -v '^c dualshare:' "$1" | cmp -s - "$2"; then echo IDENTICAL_MOD_DUALSHARE_LINE; else echo DIFFER; fi; }
for code in BB_90_8_10 GB_144_12_8 BB_108_8_10 LP_238_44_6 LP_34_20_2 BB_72_12_6 TN_36_8_4; do
  for m in no-card card-mto default; do
    f=""; [ $m != default ] && f="-$m"
    P="$O/$code.$m"
    $C "$P.gh89.txt" 400 "$D/gh89" -v $lim $f $code > /dev/null
    $C "$P.cand-noshare.txt" 400 "$D/cand" -v $lim -no-dualshare $f $code > /dev/null
    $C "$P.cand.txt" 400 "$D/cand" -v $lim $f $code > /dev/null
    $C "$P.cand-b.txt" 400 "$D/cand" -v $lim -dualshare-b $f $code > /dev/null
    $C "$P.gh94.txt" 400 "$D/gh94" -v $lim $f $code > /dev/null
    $C "$P.base72.txt" 400 "$D/base72" -v $lim $f $code > /dev/null
    $C "$P.main7e-joint.txt" 400 "$D/main7e" -v $lim -joint $f $code > /dev/null
    $C "$P.cand-joint.txt" 400 "$D/cand" -v $lim -joint $f $code > /dev/null
    echo "$code $m noshare-vs-gh89=$(same "$P.gh89.txt" "$P.cand-noshare.txt") joint-vs-main7e-joint=$(same "$P.main7e-joint.txt" "$P.cand-joint.txt") joint-vs-72d1fe1=$(same "$P.base72.txt" "$P.cand-joint.txt") default-vs-gh89=$(modd "$P.cand.txt" "$P.gh89.txt") nshare=$(grep -c '^c dualshare:' "$P.cand.txt") $(grep '^c dualshare: ' "$P.cand.txt" | head -1 | cut -c1-40) skips=$(grep -c 'skipped (' "$P.cand.txt") builds=[$(grep -o 'solver builds.*' "$P.cand.txt")] o: gh89=$(grep '^o ' "$P.gh89.txt" | cut -c3-) gh94=$(grep '^o ' "$P.gh94.txt" | cut -c3-) base72=$(grep '^o ' "$P.base72.txt" | cut -c3-) joint=$(grep '^o ' "$P.cand-joint.txt" | cut -c3-) cand=$(grep '^o ' "$P.cand.txt" | cut -c3-) candB=$(grep '^o ' "$P.cand-b.txt" | cut -c3-)"
  done
done
