#!/bin/bash
# GH-107: both independent checkers on all bundled codes with the candidate binary, and report modes compared with
# GH-92 (cpu-time fields masked). Report modes only (no solving); each command under the 2 GB cap.
# usage (repo root): reports.sh CAND GH92 OUTDIR
C=$1; G=$2; O=$3; mkdir -p "$O/automorphisms" "$O/dualmaps" "$O/gh92-reports"
K="python3 -B optimization/experiments/GH-107/capped.py"
$K "$O/automorphisms.log" 1800 python3 -B optimization/experiments/GH-107/verify_half_autos.py "$C" "$O/automorphisms"; echo "verify_half_autos $(tail -1 "$O/automorphisms.log")"
for f in data/matrices/*_Hx.txt; do code=$(basename "$f" _Hx.txt); $K "$O/dualmaps/$code.report.txt" 120 "$C" -dualskip-report "$code" > /dev/null; done
$K "$O/dualmaps.log" 1800 python3 -B optimization/experiments/GH-107/check_dual_maps.py . "$O/dualmaps"; echo "check_dual_maps $(tail -1 "$O/dualmaps.log")"
mask() { sed -E 's/cpu[= ]?[0-9.]+s/cpu=MASKs/g; s/detect_cpu=[0-9.]+s/detect_cpu=MASKs/g; s/[0-9]+\.[0-9]+s\b/MASKs/g' "$1"; }
same=0; diff=0
for f in data/matrices/*_Hx.txt; do code=$(basename "$f" _Hx.txt)
  for r in symbreak-report dualskip-report; do
    $K "$O/gh92-reports/$code.$r.cand.txt" 120 "$C" -$r "$code" > /dev/null
    $K "$O/gh92-reports/$code.$r.gh92.txt" 120 "$G" -$r "$code" > /dev/null
    if [ "$(mask "$O/gh92-reports/$code.$r.cand.txt")" = "$(mask "$O/gh92-reports/$code.$r.gh92.txt")" ]; then same=$((same+1)); else diff=$((diff+1)); echo "REPORT_DIFFER $code $r"; fi
  done
done
echo "reports vs gh92 (cpu masked): identical=$same differ=$diff"
