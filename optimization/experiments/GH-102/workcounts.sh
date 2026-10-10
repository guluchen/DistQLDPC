#!/bin/bash
# GH-102 informational work counts (no timing claims): probes / conflicts per half and implied-skip counts
# from -dualshare-stats, for -no-dualshare (= GH-89 search), variant A (default) and variant B.
# usage (repo root): workcounts.sh CAND OUTDIR ; serial, each run under the 2 GB cap.
B=$1; O=$2; mkdir -p "$O"
K="python3 -B optimization/experiments/GH-102/capped.py"
for code in BB_108_8_10 BB_90_8_10 GB_144_12_8; do
  for m in no-card card-mto; do
    for v in noshare A B; do
      case $v in noshare) f=-no-dualshare;; A) f=;; B) f=-dualshare-b;; esac
      $K "$O/$code.$m.$v.txt" 400 "$B" -v -cpu-lim=120 -dualshare-stats -$m $f $code > /dev/null
      echo "$code $m $v | $(grep '^c dualshare stats:' "$O/$code.$m.$v.txt" | cut -c20-) | probes: $(grep -c 'c CSS incremental: X half cap' "$O/$code.$m.$v.txt")X $(grep -c 'c CSS incremental: Z half cap' "$O/$code.$m.$v.txt")Z | o=$(grep '^o ' "$O/$code.$m.$v.txt" | cut -c3-)"
    done
  done
done
