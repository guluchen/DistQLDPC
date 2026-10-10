#!/bin/zsh
# usage: profbatch.sh ROUND TAG... : acquire timing lock, profile each tag on the two cases, release.
S=/private/tmp/claude-501/-Users-yfc-Library-Application-Support-Claude-scratch-workspaces-1417068f-a9d4-4e40-a6ba-6b2464faa27e-de902d21-d9e1-45a1-a1dd-f95718bf744f-scratch-2026-10-08-ce0ddb/0c1b524e-a9a2-4adc-9aa0-a630e73d8d02/scratchpad/gh103
LOCK=/private/tmp/claude-501/-Users-yfc-Library-Application-Support-Claude-scratch-workspaces-1417068f-a9d4-4e40-a6ba-6b2464faa27e-de902d21-d9e1-45a1-a1dd-f95718bf744f-scratch-2026-10-08-ce0ddb/0c1b524e-a9a2-4adc-9aa0-a630e73d8d02/scratchpad/coord/TIMING_LOCK
round="$1"; shift
mkdir -p "$S/prof/$round"
until ( set -C; echo "GH-103 sample profiles $round $(date)" > "$LOCK" ) 2>/dev/null; do sleep 3; done
echo "lock acquired $(date)"
trap 'rm -f "$LOCK"; echo "lock released $(date)"' EXIT
tags=("$@")
cases=(${(s:,:)CASES:-GB_144_12_12 nocard,LP_544_80_12 mto})
for c in $cases; do
  code=${c% *}; mode=${c#* }
  for t in $tags; do
    python3 -B "$S/prof.py" "$S/bins/$t/distqldpc" "$S/prof/$round/$t.$code.$mode" $code $mode 60
  done
done
