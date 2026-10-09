#!/bin/sh
# GH-92: both independent checkers on all 50 bundled codes with the stacked binary.
# usage (repo root): reports.sh CAND OUTDIR
C=$1; O=$2; mkdir -p "$O/automorphisms" "$O/dualmaps"
python3 -B optimization/experiments/GH-92/verify_half_autos.py "$C" "$O/automorphisms" > "$O/automorphisms.log" 2>&1; echo "verify_half_autos rc=$? $(tail -1 "$O/automorphisms.log")"
for f in data/matrices/*_Hx.txt; do code=$(basename "$f" _Hx.txt); "$C" -dualskip-report "$code" > "$O/dualmaps/$code.report.txt" 2>&1; done
python3 -B optimization/experiments/GH-92/check_dual_maps.py . "$O/dualmaps" > "$O/dualmaps.log" 2>&1; echo "check_dual_maps rc=$? $(tail -1 "$O/dualmaps.log")"
