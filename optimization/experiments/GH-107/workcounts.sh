#!/bin/bash
# GH-107 informational work counts (no timing claims): probes / engine conflicts per half and implied skips from
# -dualshare-stats, for -dualmode=off (= main's search), share (default) and skip (= GH-92's search).
# usage (repo root): workcounts.sh CAND OUTDIR ; serial, each run under the 2 GB cap.
B=$1; O=$2; mkdir -p "$O"
K="python3 -B optimization/experiments/GH-107/capped.py"
for code in BB_90_8_10 BB_108_8_10 GB_144_12_8 GB_144_12_12; do
  lim=120; [ $code = GB_144_12_12 ] && lim=300
  for m in no-card card-mto; do
    for v in off share skip; do
      $K "$O/$code.$m.$v.txt" $((lim + 100)) "$B" -v -cpu-lim=$lim -dualshare-stats -$m -dualmode=$v $code > /dev/null
      echo "$code $m $v | $(grep '^c dualshare stats:' "$O/$code.$m.$v.txt" | cut -c20-) | o=$(grep '^o ' "$O/$code.$m.$v.txt" | cut -c3-) $(grep -m1 TIMEOUT "$O/$code.$m.$v.txt")"
    done
  done
done
