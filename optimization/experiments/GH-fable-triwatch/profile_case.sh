#!/bin/bash
# usage: profile_case.sh <bin> <case> <mode-flag> <outprefix>
BIN=$1; CASE=$2; MODE=$3; OUT=$4
"$BIN" -v $MODE "$CASE" > "$OUT.log" 2>&1 &
PPID_=$!
# wait for child
for i in $(seq 1 100); do
  CHILD=$(pgrep -P $PPID_ | head -1)
  [ -n "$CHILD" ] && break
  sleep 0.05
done
if [ -z "$CHILD" ]; then echo "no child"; wait $PPID_; exit 0; fi
START=$(date +%s.%N)
sample $CHILD 120 1 -mayDie -file "$OUT.sample" >/dev/null 2>&1
wait $PPID_
END=$(date +%s.%N)
echo "$CASE $MODE wall=$(echo "$END - $START" | bc) result=$(grep -E '^(o |s )' "$OUT.log" | tail -1)"
