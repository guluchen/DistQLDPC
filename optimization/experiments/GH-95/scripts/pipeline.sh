#!/bin/bash
# GH-95 Tier0 pipeline: acquire the Mac timing lock atomically, run all solver work, release.
S="$(cd "$(dirname "$0")" && pwd)"
W="/Users/yfc/Library/Application Support/Claude/scratch-workspaces/1417068f-a9d4-4e40-a6ba-6b2464faa27e/de902d21-d9e1-45a1-a1dd-f95718bf744f/scratch-2026-10-08-ce0ddb"
LOCK="/private/tmp/claude-501/-Users-yfc-Library-Application-Support-Claude-scratch-workspaces-1417068f-a9d4-4e40-a6ba-6b2464faa27e-de902d21-d9e1-45a1-a1dd-f95718bf744f-scratch-2026-10-08-ce0ddb/0c1b524e-a9a2-4adc-9aa0-a630e73d8d02/scratchpad/coord/TIMING_LOCK"
BASE="$W/frozen-main7e/distqldpc"; CAND="$W/frozen95/cand/distqldpc"
BASEM="$S/base/bin/maxcdcl"; CANDM="$W/frozen95/cand/maxcdcl"
R="$S/results"; mkdir -p "$R"
log() { echo "$(date '+%F %T') $*" | tee -a "$R/pipeline.log"; }
MSG="GH-95 trace batch $(date)"
while true; do
  if [ ! -e "$LOCK" ] && ( set -o noclobber; echo "$MSG" > "$LOCK" ) 2>/dev/null; then break; fi
  sleep 10
done
log "lock acquired: $(cat "$LOCK")"
release() { if [ "$(cat "$LOCK" 2>/dev/null)" = "$MSG" ]; then rm -f "$LOCK"; log "lock released"; fi; }
trap release EXIT

log "baseline full batch"; "$S/batch.sh" "$BASE" "$R/base" 20 "$S/full.list"
log "candidate full batch"; "$S/batch.sh" "$CAND" "$R/cand" 20 "$S/full.list"
python3 -B "$W/cand95/optimization/experiments/GH-95/cmp_traces.py" "$R/base" "$R/cand" "$S/full.list" > "$R/cmp_pass1.txt"
grep 'needs rerun' "$R/cmp_pass1.txt" | awk '{print $1, $2}' > "$S/rerun.list"
if [ -s "$S/rerun.list" ]; then log "candidate reruns (cpu-lim=30): $(wc -l < "$S/rerun.list")"; "$S/batch.sh" "$CAND" "$R/cand_rerun30" 30 "$S/rerun.list"; else mkdir -p "$R/cand_rerun30"; fi
python3 -B "$W/cand95/optimization/experiments/GH-95/cmp_traces.py" "$R/base" "$R/cand" "$S/full.list" "$R/cand_rerun30" > "$R/cmp_final.txt"; log "$(tail -1 "$R/cmp_final.txt")"

log "per-commit quick checks"
: > "$R/quick_commits.txt"
for c in $(git -C "$W/cand95" rev-list --reverse beb5638..refactor/gh-95-engine-modules); do
  [ -x "$S/commits/$c/distqldpc" ] || continue
  "$S/batch.sh" "$S/commits/$c/distqldpc" "$R/quick/$c" 20 "$S/quick.list"
  echo "$c $(python3 -B "$W/cand95/optimization/experiments/GH-95/cmp_traces.py" "$R/base" "$R/quick/$c" "$S/quick.list" | tail -1)" >> "$R/quick_commits.txt"
done
log "quick done: $(grep -c 'fail=0' "$R/quick_commits.txt") of $(wc -l < "$R/quick_commits.txt") commits fail=0"

log "smoke + partition tests"
( cd "$W/cand95" && bash scripts/smoke_test.sh "$CAND" && python3 -B scripts/test_partition_soft_literals.py --binary "$CANDM" | tail -2 && build/test_partition_soft_literals | tail -3 ) > "$R/tests.txt" 2>&1; echo "exit=$?" >> "$R/tests.txt"

log "maxcdcl oracle"
mkdir -p "$R/dumps/base" "$R/dumps/cand"
for code in LP_136_32_4 BB_72_12_6 TN_36_8_4; do
  ( cd "$S/base" && "$BASE" -dump-wcnf="$R/dumps/base/$code.wcnf" -dump-only "$code" > "$R/dumps/base/$code.log" 2>&1
    "$CAND" -dump-wcnf="$R/dumps/cand/$code.wcnf" -dump-only "$code" > "$R/dumps/cand/$code.log" 2>&1 )
done
( cd "$R/dumps" && for f in base/*.wcnf; do n=$(basename $f); if cmp -s "base/$n" "cand/$n"; then echo "$n dump IDENTICAL $(shasum -a 256 base/$n | cut -c1-16) $(head -1 base/$n)"; else echo "$n dump DIFF"; fi; done ) > "$R/dumps_cmp.txt"
MAXCDCL_FLAGS="-cpu-lim=60" "$S/maxcdcl_cmp.sh" "$BASEM" "$CANDM" "$R/maxcdcl" "$W/cand95/src/solver/clq-n100e2500g1" "$W/cand95/src/solver/clq-n150e10058g1" "$W/cand95/tests/fixtures/partition-retired-soft.wcnf" "$R"/dumps/base/*.wcnf > "$R/maxcdcl_cmp.txt" 2>&1
log "all done"
