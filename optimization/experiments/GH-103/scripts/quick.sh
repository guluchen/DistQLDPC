#!/bin/zsh
# usage: quick.sh TAG   (copies cand103/bin/distqldpc to bins/TAG, runs quick.list, compares to frozen95 traces)
S=/private/tmp/claude-501/-Users-yfc-Library-Application-Support-Claude-scratch-workspaces-1417068f-a9d4-4e40-a6ba-6b2464faa27e-de902d21-d9e1-45a1-a1dd-f95718bf744f-scratch-2026-10-08-ce0ddb/0c1b524e-a9a2-4adc-9aa0-a630e73d8d02/scratchpad/gh103
W="/Users/yfc/Library/Application Support/Claude/scratch-workspaces/1417068f-a9d4-4e40-a6ba-6b2464faa27e/de902d21-d9e1-45a1-a1dd-f95718bf744f/scratch-2026-10-08-ce0ddb"
tag="$1"
mkdir -p "$S/bins/$tag"
cp -R "$W/cand103/bin/distqldpc" "$W/cand103/bin/distqldpc.dSYM" "$W/cand103/bin/maxcdcl" "$S/bins/$tag/"
python3 -B "$S/batch.py" "$S/bins/$tag/distqldpc" "$S/quick/$tag" 20 "$W/cand103" "$S/quick.list" 4 > "$S/quick/$tag.batch.log"
python3 -B "$S/cmp_traces.py" "$S/ref/cand" "$S/quick/$tag" "$S/quick.list" | tail -15
