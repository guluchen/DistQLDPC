#!/bin/sh
# GH-106 Tier0 science sweep on the Mac (correctness only; walls are not timing evidence).
# 50 codes x 4 modes, 60 s, --jobs 4, candidate frozen106 vs main 7eadd54 (frozen-main7e); 2 GB cap per process.
# Run in 9 chunks of <= 6 codes; each chunk takes the timing lock (noclobber) and releases it when done,
# so no single hold exceeds ~13 minutes (worst case 6 rounds x 2 x 60 s).
W="/Users/yfc/Library/Application Support/Claude/scratch-workspaces/1417068f-a9d4-4e40-a6ba-6b2464faa27e/de902d21-d9e1-45a1-a1dd-f95718bf744f/scratch-2026-10-08-ce0ddb"
L=/private/tmp/claude-501/-Users-yfc-Library-Application-Support-Claude-scratch-workspaces-1417068f-a9d4-4e40-a6ba-6b2464faa27e-de902d21-d9e1-45a1-a1dd-f95718bf744f-scratch-2026-10-08-ce0ddb/0c1b524e-a9a2-4adc-9aa0-a630e73d8d02/scratchpad/coord/TIMING_LOCK
cd "$W/cand106"; E=optimization/experiments/GH-106; O=$E/raw/tier0-science
STEMS=$(ls data/matrices | grep '_Hx.txt$' | sed 's/_Hx.txt$//' | sort)
k=0; chunk=""; n=0
run_chunk() {
  k=$((k+1))
  while :; do
    if ( set -o noclobber; echo "GH-106 Tier0 science sweep chunk $k/9 ($1) $(date)" > "$L" ) 2>/dev/null; then break; fi
    sleep 20
  done
  echo "chunk $k took lock $(date): $1"
  python3 -B $E/tier0_science.py --base "$W/frozen-main7e/distqldpc" --cand "$W/frozen106/cand/distqldpc" --out $O/chunk$k --limit 60 --jobs 4 --stems "$1"
  echo "chunk $k rc=$? released $(date)"
  rm -f "$L"
  sleep 30   # let waiting timing batches take the lock
}
for s in $STEMS; do
  chunk="${chunk:+$chunk,}$s"; n=$((n+1))
  if [ $n -eq 6 ]; then run_chunk "$chunk"; chunk=""; n=0; fi
done
[ -n "$chunk" ] && run_chunk "$chunk"
python3 -B $E/merge_science.py $O
python3 -B $E/posthoc_science.py $O/science.json > $O/posthoc.txt 2>&1; echo "posthoc rc=$?"; cat $O/posthoc.txt
python3 -B $E/check_sweep.py $O/science.json > $O/check_sweep.txt 2>&1; echo "check_sweep rc=$?"; cat $O/check_sweep.txt
