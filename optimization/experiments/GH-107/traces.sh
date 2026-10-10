#!/bin/bash
# GH-107 flag-equivalence traces. usage (repo root): traces.sh BINDIR OUTDIR
# BINDIR holds space-free links: cand (frozen107), main7e (frozen-main7e), gh92 (frozen92).
# Serial, one solver process at a time, each under the 2 GB cap (capped.py); -cpu-lim=120 on both sides.
#   -dualmode=off == main 7eadd54 (byte-identical); -no-dualskip (alias) == main; -dualmode=skip == GH-92;
#   -joint == main -joint; default on codes without a dual map == main modulo the single 'c dualshare:' line;
#   default on dual-map codes: recorded (differs by design), o-value compared.
D=$1; O=$2; mkdir -p "$O"
C="python3 -B optimization/experiments/GH-107/capped.py"
lim=-cpu-lim=120
same() { if cmp -s "$1" "$2"; then echo IDENTICAL; else echo DIFFER; fi; }
modd() { if grep -v '^c dualshare:' "$1" | cmp -s - "$2"; then echo IDENTICAL_MOD_DUALSHARE_LINE; else echo DIFFER; fi; }
for code in BB_90_8_10 GB_144_12_8 BB_108_8_10 LP_238_44_6 LP_34_20_2 BB_72_12_6 TN_36_8_4; do
  for m in no-card card-mto default; do
    f=""; [ $m != default ] && f="-$m"
    P="$O/$code.$m"
    $C "$P.main7e.txt" 400 "$D/main7e" -v $lim $f $code > /dev/null
    $C "$P.cand-off.txt" 400 "$D/cand" -v $lim -dualmode=off $f $code > /dev/null
    $C "$P.cand-nodualskip.txt" 400 "$D/cand" -v $lim -no-dualskip $f $code > /dev/null
    $C "$P.gh92.txt" 400 "$D/gh92" -v $lim $f $code > /dev/null
    $C "$P.cand-skip.txt" 400 "$D/cand" -v $lim -dualmode=skip $f $code > /dev/null
    $C "$P.cand.txt" 400 "$D/cand" -v $lim $f $code > /dev/null
    $C "$P.main7e-joint.txt" 400 "$D/main7e" -v $lim -joint $f $code > /dev/null
    $C "$P.cand-joint.txt" 400 "$D/cand" -v $lim -joint $f $code > /dev/null
    echo "$code $m off-vs-main7e=$(same "$P.main7e.txt" "$P.cand-off.txt") nodualskip-vs-main7e=$(same "$P.main7e.txt" "$P.cand-nodualskip.txt") skip-vs-gh92=$(same "$P.gh92.txt" "$P.cand-skip.txt") joint-vs-main7e-joint=$(same "$P.main7e-joint.txt" "$P.cand-joint.txt") default-vs-main7e=$(modd "$P.cand.txt" "$P.main7e.txt") $(grep '^c dualshare: ' "$P.cand.txt" | head -1 | cut -c1-32) skips=$(grep -c 'skipped (' "$P.cand.txt") o: main=$(grep '^o ' "$P.main7e.txt" | cut -c3-) gh92=$(grep '^o ' "$P.gh92.txt" | cut -c3-) joint=$(grep '^o ' "$P.cand-joint.txt" | cut -c3-) off=$(grep '^o ' "$P.cand-off.txt" | cut -c3-) skip=$(grep '^o ' "$P.cand-skip.txt" | cut -c3-) share=$(grep '^o ' "$P.cand.txt" | cut -c3-)"
  done
done
