#!/bin/bash
# GH-98 work counts: counter build (-DXOR_STATS), 4 cases x {xor, -no-xor}, -cpu-lim=30, 4 parallel jobs.
# usage: workcounts.sh STATSBIN OUTDIR
W="/Users/yfc/Library/Application Support/Claude/scratch-workspaces/1417068f-a9d4-4e40-a6ba-6b2464faa27e/de902d21-d9e1-45a1-a1dd-f95718bf744f/scratch-2026-10-08-ce0ddb"
B="$1"; O="$2"; mkdir -p "$O"; cd "$W/cand98"
for m in -xor -no-xor; do for c in "GB_144_12_12 -no-card" "LP_544_80_12 -card-mto" "TN_144_2_13 -no-card" "LP_340_56_8 -no-card"; do
  set -- $c; echo "$1 $2 $m"; done; done | xargs -P4 -L1 sh -c '"$0" -v $4 $3 -cpu-lim=30 $2 > "$1/$2$3$4.log" 2>&1' "$B" "$O"
