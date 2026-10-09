#!/bin/sh
# GH-92 flag-equivalence traces. usage (repo root): traces.sh BINDIR OUTDIR
# BINDIR holds space-free links: cand (GH-92), gh85 (frozen85), gh87 (frozen87), base (72d1fe1).
# Serial, one solver process at a time; the same -cpu-lim=120 on both sides of every comparison.
D=$1; O=$2; mkdir -p "$O"
lim=-cpu-lim=120
same() { if cmp -s "$1" "$2"; then echo IDENTICAL; else echo DIFFER; fi; }
modd() { if grep -v '^c dualskip:' "$1" | cmp -s - "$2"; then echo IDENTICAL_MOD_DUALSKIP_LINE; else echo DIFFER; fi; }
# (1) Tier1 cases: -no-dualskip == GH-85, -no-symbreak == GH-87
for code in BB_90_8_10 GB_144_12_8 BB_108_8_10 LP_238_44_6 LP_34_20_2 BB_72_12_6 TN_36_8_4; do
  for m in no-card card-mto default; do
    f=""; [ $m != default ] && f="-$m"
    "$D/gh85" -v $lim $f $code > "$O/$code.$m.gh85.txt" 2>&1
    "$D/cand" -v $lim -no-dualskip $f $code > "$O/$code.$m.cand-nodual.txt" 2>&1
    "$D/gh87" -v $lim $f $code > "$O/$code.$m.gh87.txt" 2>&1
    "$D/cand" -v $lim -no-symbreak $f $code > "$O/$code.$m.cand-nosb.txt" 2>&1
    "$D/cand" -v $lim $f $code > "$O/$code.$m.cand.txt" 2>&1
    echo "$code $m nodualskip-vs-gh85=$(same "$O/$code.$m.gh85.txt" "$O/$code.$m.cand-nodual.txt") nosymbreak-vs-gh87=$(same "$O/$code.$m.gh87.txt" "$O/$code.$m.cand-nosb.txt") default-vs-gh85=$(modd "$O/$code.$m.cand.txt" "$O/$code.$m.gh85.txt") lines=$(wc -l < "$O/$code.$m.cand.txt" | tr -d ' ') $(grep '^c dualskip:' "$O/$code.$m.cand.txt" | cut -c1-48) gh85_o=$(grep '^o ' "$O/$code.$m.gh85.txt") gh87_o=$(grep '^o ' "$O/$code.$m.gh87.txt") cand_o=$(grep '^o ' "$O/$code.$m.cand.txt")"
  done
done
# (2) no dual map: default == GH-85 modulo the single c dualskip line
for code in LP_340_56_8; do
  for m in no-card card-mto default; do
    f=""; [ $m != default ] && f="-$m"
    "$D/gh85" -v $lim $f $code > "$O/$code.$m.gh85.txt" 2>&1
    "$D/cand" -v $lim $f $code > "$O/$code.$m.cand.txt" 2>&1
    "$D/cand" -v $lim -no-dualskip $f $code > "$O/$code.$m.cand-nodual.txt" 2>&1
    echo "$code $m default-vs-gh85=$(modd "$O/$code.$m.cand.txt" "$O/$code.$m.gh85.txt") nodualskip-vs-gh85=$(same "$O/$code.$m.gh85.txt" "$O/$code.$m.cand-nodual.txt") $(grep '^c dualskip:' "$O/$code.$m.cand.txt" | cut -c1-48) gh85_o=$(grep '^o ' "$O/$code.$m.gh85.txt") cand_o=$(grep '^o ' "$O/$code.$m.cand.txt")"
  done
done
# (3) -joint == baseline 72d1fe1
for code in LP_34_20_2 BB_72_12_6 TN_36_8_4; do
  for m in default no-card; do
    f=""; [ $m = no-card ] && f="-no-card"
    "$D/base" -v $lim $f $code > "$O/$code.$m.base.txt" 2>&1
    "$D/cand" -v $lim -joint $f $code > "$O/$code.$m.cand-joint.txt" 2>&1
    echo "$code $m joint-vs-base=$(same "$O/$code.$m.base.txt" "$O/$code.$m.cand-joint.txt") base_o=$(grep '^o ' "$O/$code.$m.base.txt")"
  done
done
