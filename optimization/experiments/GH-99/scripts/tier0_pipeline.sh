#!/bin/bash
# GH-99 Tier0 long batches on the Mac (correctness only; walls are not timing evidence).
# Each batch waits until the coordinator's timing lock is absent, takes it, and releases it when done.
# usage: tier0_pipeline.sh OUTROOT [STEP...]   steps: noskip exact check science fuzz
L=/private/tmp/claude-501/-Users-yfc-Library-Application-Support-Claude-scratch-workspaces-1417068f-a9d4-4e40-a6ba-6b2464faa27e-de902d21-d9e1-45a1-a1dd-f95718bf744f-scratch-2026-10-08-ce0ddb/0c1b524e-a9a2-4adc-9aa0-a630e73d8d02/scratchpad/coord/TIMING_LOCK
W="/Users/yfc/Library/Application Support/Claude/scratch-workspaces/1417068f-a9d4-4e40-a6ba-6b2464faa27e/de902d21-d9e1-45a1-a1dd-f95718bf744f/scratch-2026-10-08-ce0ddb"
R="$W/cand99"; E="$R/optimization/experiments/GH-99"; S="$E/scripts"; O="$1"; shift
EXACT="$W/frozen99/exact/distqldpc"; FAST="$W/frozen99/fast/distqldpc"
mkdir -p "$O"
lock() { echo "[$(date)] waiting for lock ($1)"; while [ -e "$L" ]; do sleep 30; done
         echo "GH-99 $1 $(date)" > "$L"; echo "[$(date)] lock taken: $(cat "$L")"; }
unlock() { rm -f "$L"; echo "[$(date)] lock released"; }
trap 'rm -f "$L"; exit 1' INT TERM
for step in "$@"; do
  case "$step" in
    noskip) lock "Tier0 -no-lkskip identity batch (200 runs)"
            "$S/batch.sh" "$EXACT" "$O/noskip" 20 "$R" -no-lkskip "$S/full200.list" 4; unlock;;
    exact)  lock "Tier0 exact identity batch (200 runs)"
            "$S/batch.sh" "$EXACT" "$O/exact" 20 "$R" none "$S/full200.list" 4; unlock;;
    check)  lock "Tier0 self-check batches (2x200 runs)"
            "$S/batch.sh" "$O/../bins/check/distqldpc" "$O/check_exact" 20 "$R" -lkskip=exact "$S/full200.list" 4
            "$S/batch.sh" "$O/../bins/check/distqldpc" "$O/check_fast" 20 "$R" -lkskip=fast "$S/full200.list" 4; unlock;;
    science) lock "Tier0 science sweep fast vs main7e (200 cases x 2 binaries, 60 s)"
            (cd "$R" && python3 -B "$E/tier0_science.py" --base "$W/frozen-main7e/distqldpc" --cand "$FAST" --out "$O/science" --limit 60 --jobs 4) > "$O/science.log" 2>&1
            echo "science rc=$?"; unlock
            python3 -B "$E/posthoc_science.py" "$O/science/science.json" > "$O/science_posthoc.txt" 2>&1; echo "posthoc rc=$?";;
  esac
done
echo "[$(date)] pipeline done"
