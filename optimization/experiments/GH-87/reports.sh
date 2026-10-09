#!/bin/sh
# GH-87: -dualskip-report for every bundled code, then the independent Python checker.
# usage (repo root): reports.sh CAND OUTDIR
C=$1; O=$2; mkdir -p "$O"
for f in data/matrices/*_Hx.txt; do code=$(basename "$f" _Hx.txt); "$C" -dualskip-report "$code" > "$O/$code.report.txt" 2>&1; done
python3 -B optimization/experiments/GH-87/check_dual_maps.py . "$O"
