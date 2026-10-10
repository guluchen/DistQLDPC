#!/bin/bash
# GH-98 Tier0 long batches on the Mac (correctness only; walls are not timing evidence).
# Each batch waits until the coordinator's timing lock is absent, takes it, and releases it when done.
# usage: tier0_pipeline.sh OUTROOT CHECKBIN STEP...   steps: check noxor science
L=/private/tmp/claude-501/-Users-yfc-Library-Application-Support-Claude-scratch-workspaces-1417068f-a9d4-4e40-a6ba-6b2464faa27e-de902d21-d9e1-45a1-a1dd-f95718bf744f-scratch-2026-10-08-ce0ddb/0c1b524e-a9a2-4adc-9aa0-a630e73d8d02/scratchpad/coord/TIMING_LOCK
W="/Users/yfc/Library/Application Support/Claude/scratch-workspaces/1417068f-a9d4-4e40-a6ba-6b2464faa27e/de902d21-d9e1-45a1-a1dd-f95718bf744f/scratch-2026-10-08-ce0ddb"
R="$W/cand98"; E="$R/optimization/experiments/GH-98"; S="$E/scripts"; O="$1"; CHECK="$2"; shift 2
CAND="$W/frozen98/cand/distqldpc"
mkdir -p "$O"
lock() { echo "[$(date)] waiting for lock ($1)"; while [ -e "$L" ]; do sleep 30; done
         echo "GH-98 $1 $(date)" > "$L"; echo "[$(date)] lock taken: $(cat "$L")"; }
unlock() { rm -f "$L"; echo "[$(date)] lock released"; }
trap 'rm -f "$L"; exit 1' INT TERM
for step in "$@"; do
  case "$step" in
    check)  lock "Tier0 self-check batch (200 runs, 20 s)"
            "$S/batch.sh" "$CHECK" "$O/check" 20 "$R" none "$S/full200.list" 4; unlock;;
    noxor)  lock "Tier0 -no-xor identity batch (200 runs, 20 s)"
            "$S/batch.sh" "$CAND" "$O/noxor" 20 "$R" -no-xor "$S/full200.list" 4; unlock;;
    science) lock "Tier0 science sweep xor vs main7e (200 cases x 2 binaries, 60 s)"
            (cd "$R" && python3 -B "$E/tier0_science.py" --base "$W/frozen-main7e/distqldpc" --cand "$CAND" --out "$O/science" --limit 60 --jobs 4) > "$O/science.log" 2>&1
            echo "science rc=$?"; unlock
            python3 -B "$E/posthoc_science.py" "$O/science/science.json" > "$O/science_posthoc.txt" 2>&1; echo "posthoc rc=$?";;
  esac
done
echo "[$(date)] pipeline done"
