#!/bin/sh
# GH-94: both independent checkers on all 50 bundled codes with the candidate binary, and report modes
# compared with GH-92 (cpu-time fields masked). usage (repo root): reports.sh CAND GH92 OUTDIR
C=$1; G=$2; O=$3; mkdir -p "$O/automorphisms" "$O/dualmaps" "$O/gh92-reports"
python3 -B optimization/experiments/GH-94/verify_half_autos.py "$C" "$O/automorphisms" > "$O/automorphisms.log" 2>&1; echo "verify_half_autos rc=$? $(tail -1 "$O/automorphisms.log")"
for f in data/matrices/*_Hx.txt; do code=$(basename "$f" _Hx.txt); "$C" -dualskip-report "$code" > "$O/dualmaps/$code.report.txt" 2>&1; done
python3 -B optimization/experiments/GH-94/check_dual_maps.py . "$O/dualmaps" > "$O/dualmaps.log" 2>&1; echo "check_dual_maps rc=$? $(tail -1 "$O/dualmaps.log")"
mask() { sed -E 's/cpu[= ]?[0-9.]+s/cpu=MASKs/g; s/detect_cpu=[0-9.]+s/detect_cpu=MASKs/g; s/[0-9]+\.[0-9]+s\b/MASKs/g' "$1"; }
same=0; diff=0
for f in data/matrices/*_Hx.txt; do code=$(basename "$f" _Hx.txt)
  for r in symbreak-report dualskip-report; do
    "$C" -$r "$code" > "$O/gh92-reports/$code.$r.cand.txt" 2>&1
    "$G" -$r "$code" > "$O/gh92-reports/$code.$r.gh92.txt" 2>&1
    if [ "$(mask "$O/gh92-reports/$code.$r.cand.txt")" = "$(mask "$O/gh92-reports/$code.$r.gh92.txt")" ]; then same=$((same+1)); else diff=$((diff+1)); echo "REPORT_DIFFER $code $r"; fi
  done
done
echo "reports vs gh92 (cpu masked): identical=$same differ=$diff"
