#!/bin/zsh
# usage: lockedbatch.sh LABEL BIN OUTDIR CPULIM LIST : hold the Mac timing lock while running a 4-job trace batch.
S=/private/tmp/claude-501/-Users-yfc-Library-Application-Support-Claude-scratch-workspaces-1417068f-a9d4-4e40-a6ba-6b2464faa27e-de902d21-d9e1-45a1-a1dd-f95718bf744f-scratch-2026-10-08-ce0ddb/0c1b524e-a9a2-4adc-9aa0-a630e73d8d02/scratchpad/gh103
W="/Users/yfc/Library/Application Support/Claude/scratch-workspaces/1417068f-a9d4-4e40-a6ba-6b2464faa27e/de902d21-d9e1-45a1-a1dd-f95718bf744f/scratch-2026-10-08-ce0ddb"
LOCK=$S/../coord/TIMING_LOCK
MSG="GH-103 $1 $(date)"
until ( set -C; echo "$MSG" > "$LOCK" ) 2>/dev/null; do sleep 3; done
echo "lock acquired $(date)"
trap '[ "$(cat $LOCK 2>/dev/null)" = "$MSG" ] && rm -f "$LOCK"; echo "lock released $(date)"' EXIT
python3 -B $S/batch.py "$2" "$3" "$4" "$W/cand103" "$5" 4
