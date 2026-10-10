#!/bin/sh
# GH-94 flag-equivalence traces. usage (repo root): traces.sh BINDIR OUTDIR
# BINDIR holds space-free links: cand (GH-94), gh89 (frozen89), gh92 (frozen92), base (72d1fe1).
# Serial, one solver process at a time; the same -cpu-lim=120 on both sides of every comparison.
#   -no-dualskip == GH-89 (byte-identical); -joint == 72d1fe1 (byte-identical);
#   default == GH-89 modulo the single 'c dualskip:' line on codes without a dual map (LP);
#   default on dual-map codes: recorded, o-value compared with GH-89 and GH-92.
D=$1; O=$2; mkdir -p "$O"
lim=-cpu-lim=120
same() { if cmp -s "$1" "$2"; then echo IDENTICAL; else echo DIFFER; fi; }
modd() { if grep -v '^c dualskip:' "$1" | cmp -s - "$2"; then echo IDENTICAL_MOD_DUALSKIP_LINE; else echo DIFFER; fi; }
for code in BB_90_8_10 GB_144_12_8 BB_108_8_10 LP_238_44_6 LP_34_20_2 BB_72_12_6 TN_36_8_4; do
  for m in no-card card-mto default; do
    f=""; [ $m != default ] && f="-$m"
    "$D/gh89" -v $lim $f $code > "$O/$code.$m.gh89.txt" 2>&1
    "$D/cand" -v $lim -no-dualskip $f $code > "$O/$code.$m.cand-nodual.txt" 2>&1
    "$D/cand" -v $lim $f $code > "$O/$code.$m.cand.txt" 2>&1
    "$D/gh92" -v $lim $f $code > "$O/$code.$m.gh92.txt" 2>&1
    "$D/base" -v $lim $f $code > "$O/$code.$m.base.txt" 2>&1
    "$D/cand" -v $lim -joint $f $code > "$O/$code.$m.cand-joint.txt" 2>&1
    echo "$code $m nodualskip-vs-gh89=$(same "$O/$code.$m.gh89.txt" "$O/$code.$m.cand-nodual.txt") joint-vs-base=$(same "$O/$code.$m.base.txt" "$O/$code.$m.cand-joint.txt") default-vs-gh89=$(modd "$O/$code.$m.cand.txt" "$O/$code.$m.gh89.txt") ndual=$(grep -c '^c dualskip:' "$O/$code.$m.cand.txt") $(grep '^c dualskip:' "$O/$code.$m.cand.txt" | cut -c1-48) builds=[$(grep -o 'solver builds.*' "$O/$code.$m.cand.txt")] gh89_o=$(grep '^o ' "$O/$code.$m.gh89.txt") gh92_o=$(grep '^o ' "$O/$code.$m.gh92.txt") base_o=$(grep '^o ' "$O/$code.$m.base.txt") cand_o=$(grep '^o ' "$O/$code.$m.cand.txt")"
  done
done
