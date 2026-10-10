#!/bin/bash
# GH-94 Tier0 science sweep on the Mac (correctness only). Waits for the coordinator's timing lock
# to be absent, takes it for the whole sweep, releases it at the end (also on interrupt).
L=/private/tmp/claude-501/-Users-yfc-Library-Application-Support-Claude-scratch-workspaces-1417068f-a9d4-4e40-a6ba-6b2464faa27e-de902d21-d9e1-45a1-a1dd-f95718bf744f-scratch-2026-10-08-ce0ddb/0c1b524e-a9a2-4adc-9aa0-a630e73d8d02/scratchpad/coord/TIMING_LOCK
W="/Users/yfc/Library/Application Support/Claude/scratch-workspaces/1417068f-a9d4-4e40-a6ba-6b2464faa27e/de902d21-d9e1-45a1-a1dd-f95718bf744f/scratch-2026-10-08-ce0ddb"
BIN=/private/tmp/claude-501/-Users-yfc-Library-Application-Support-Claude-scratch-workspaces-1417068f-a9d4-4e40-a6ba-6b2464faa27e-de902d21-d9e1-45a1-a1dd-f95718bf744f-scratch-2026-10-08-ce0ddb/0c1b524e-a9a2-4adc-9aa0-a630e73d8d02/scratchpad/gh94/bin
cd "$W/cand94"; E=optimization/experiments/GH-94; O=$E/raw/tier0-science-01
echo "waiting for lock $(date)"
while [ -e "$L" ]; do sleep 30; done
echo "GH-94 Tier0 science sweep $(date)" > "$L"; trap 'rm -f "$L"' EXIT
echo "lock taken $(date): $(cat "$L")"
python3 -B $E/tier0_science.py --base $BIN/base --cand $BIN/cand --out $O --limit 60 --jobs 4
echo "sweep rc=$? $(date)"
python3 -B $E/posthoc_science.py $O/science.json > $O/posthoc.txt 2>&1; echo "posthoc rc=$?"; cat $O/posthoc.txt
python3 -B $E/check_sweep.py $O/science.json > $O/check_sweep.txt 2>&1; echo "check_sweep rc=$?"; cat $O/check_sweep.txt
