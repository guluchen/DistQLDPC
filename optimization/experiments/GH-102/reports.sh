#!/bin/bash
# GH-102: both independent checkers on all 50 bundled codes with the candidate binary, and report modes compared
# with GH-94 (cpu-time fields masked). Report modes only (no solving); each command under the 2 GB cap.
# usage (repo root): reports.sh CAND GH94 OUTDIR
C=$1; G=$2; O=$3; mkdir -p "$O/automorphisms" "$O/dualmaps" "$O/gh94-reports"
K="python3 -B optimization/experiments/GH-102/capped.py"
$K "$O/automorphisms.log" 1800 python3 -B optimization/experiments/GH-102/verify_half_autos.py "$C" "$O/automorphisms"; echo "verify_half_autos $(tail -1 "$O/automorphisms.log")"
for f in data/matrices/*_Hx.txt; do code=$(basename "$f" _Hx.txt); $K "$O/dualmaps/$code.report.txt" 120 "$C" -dualskip-report "$code" > /dev/null; done
$K "$O/dualmaps.log" 1800 python3 -B optimization/experiments/GH-102/check_dual_maps.py . "$O/dualmaps"; echo "check_dual_maps $(tail -1 "$O/dualmaps.log")"
mask() { sed -E 's/cpu[= ]?[0-9.]+s/cpu=MASKs/g; s/detect_cpu=[0-9.]+s/detect_cpu=MASKs/g; s/[0-9]+\.[0-9]+s\b/MASKs/g' "$1"; }
same=0; diff=0
for f in data/matrices/*_Hx.txt; do code=$(basename "$f" _Hx.txt)
  for r in symbreak-report dualskip-report; do
    $K "$O/gh94-reports/$code.$r.cand.txt" 120 "$C" -$r "$code" > /dev/null
    $K "$O/gh94-reports/$code.$r.gh94.txt" 120 "$G" -$r "$code" > /dev/null
    if [ "$(mask "$O/gh94-reports/$code.$r.cand.txt")" = "$(mask "$O/gh94-reports/$code.$r.gh94.txt")" ]; then same=$((same+1)); else diff=$((diff+1)); echo "REPORT_DIFFER $code $r"; fi
  done
done
echo "reports vs gh94 (cpu masked): identical=$same differ=$diff"
