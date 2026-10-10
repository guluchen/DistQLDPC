#!/bin/bash
# GH-107 Tier0 science sweep on the Mac (correctness only; walls are not timing evidence).
# Waits until the serial correctness batch (mac.sh) has finished (at most 4 parallel jobs in total) and until the
# coordinator's timing lock is absent; takes it for the sweep, releases it at the end (also on
# interrupt). Every solver process runs under the 2 GB cap (tier0_science.py -> memlimit.run).
L=/private/tmp/claude-501/-Users-yfc-Library-Application-Support-Claude-scratch-workspaces-1417068f-a9d4-4e40-a6ba-6b2464faa27e-de902d21-d9e1-45a1-a1dd-f95718bf744f-scratch-2026-10-08-ce0ddb/0c1b524e-a9a2-4adc-9aa0-a630e73d8d02/scratchpad/coord/TIMING_LOCK
W="/Users/yfc/Library/Application Support/Claude/scratch-workspaces/1417068f-a9d4-4e40-a6ba-6b2464faa27e/de902d21-d9e1-45a1-a1dd-f95718bf744f/scratch-2026-10-08-ce0ddb"
cd "$W/cand107"; E=optimization/experiments/GH-107; O=$E/raw/tier0-science-01
echo "waiting for mac.sh $(date)"
until grep -q MAC_DONE $E/raw/mac/run1.log 2>/dev/null; do sleep 30; done
echo "waiting for lock $(date)"
while true; do
  while [ -e "$L" ]; do sleep 2; done
  if ( set -o noclobber; echo "GH-107 Tier0 science sweep (200 cases x 2 binaries, 60 s, jobs 4) $(date)" > "$L" ) 2>/dev/null; then break; fi
done
trap 'rm -f "$L"' EXIT
echo "lock taken $(date): $(cat "$L")"
python3 -B $E/tier0_science.py --base "$W/frozen-main7e/distqldpc" --cand "$W/frozen107/cand/distqldpc" --out $O --limit 60 --jobs 4
echo "sweep rc=$? $(date)"
rm -f "$L"; echo "lock released $(date)"
python3 -B $E/posthoc_science.py $O/science.json > $O/posthoc.txt 2>&1; echo "posthoc rc=$?"; cat $O/posthoc.txt
python3 -B $E/check_sweep.py $O/science.json > $O/check_sweep.txt 2>&1; echo "check_sweep rc=$?"; cat $O/check_sweep.txt
