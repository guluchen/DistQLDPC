#!/bin/sh
# GH-87 trace identity checks. usage: traces.sh BASE GH73 CAND OUTDIR [WAITLOCK]
# Run from the repo root; serial (one solver process at a time). If WAITLOCK is a path, wait while it exists.
B=$1; G=$2; C=$3; O=$4; L=${5:-}; mkdir -p "$O"
wl() { if [ -n "$L" ]; then while [ -e "$L" ]; do sleep 30; done; fi; }
for code in LP_34_20_2 BB_72_12_6 TN_36_8_4; do
  for m in default no-card; do
    f=""; [ $m = no-card ] && f="-no-card"
    wl; "$B" -v -cpu-lim=120 $f $code > "$O/$code.$m.base.txt" 2>&1
    wl; "$C" -v -cpu-lim=120 -joint $f $code > "$O/$code.$m.cand-joint.txt" 2>&1
    wl; "$G" -v -cpu-lim=120 $f $code > "$O/$code.$m.gh73.txt" 2>&1
    wl; "$C" -v -cpu-lim=120 -no-dualskip $f $code > "$O/$code.$m.cand-nodual.txt" 2>&1
    wl; "$C" -v -cpu-lim=120 $f $code > "$O/$code.$m.cand.txt" 2>&1
    if cmp -s "$O/$code.$m.base.txt" "$O/$code.$m.cand-joint.txt"; then j=IDENTICAL; else j=DIFFER; fi
    if cmp -s "$O/$code.$m.gh73.txt" "$O/$code.$m.cand-nodual.txt"; then s=IDENTICAL; else s=DIFFER; fi
    if grep -v '^c dualskip:' "$O/$code.$m.cand.txt" | cmp -s - "$O/$code.$m.gh73.txt"; then x=IDENTICAL_MOD_DUALSKIP_LINE; else x=DIFFER; fi
    echo "$code $m joint-vs-base=$j nodualskip-vs-gh73=$s default-vs-gh73=$x $(grep '^c dualskip:' "$O/$code.$m.cand.txt" | cut -c1-60) base_o=$(grep '^o ' "$O/$code.$m.base.txt") cand_o=$(grep '^o ' "$O/$code.$m.cand.txt")"
  done
done
