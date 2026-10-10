#!/bin/bash
# usage: maxcdcl_cmp.sh BASE_MAXCDCL CAND_MAXCDCL OUTDIR WCNF...
# Compares full output (and exit status) after normalising only timing/memory values:
# rates "(N /sec)" and the numbers on lines containing "time" or "Memory".
b="$1"; c="$2"; out="$3"; shift 3; mkdir -p "$out"
norm() { sed -E 's/\( *[0-9.e+-]+ \/sec\)/(R \/sec)/g; /[Tt]ime|Memory/s/[0-9]+(\.[0-9]+)?(e[+-]?[0-9]+)?/N/g' "$1"; }
for f in "$@"; do
  n=$(basename "$f")
  "$b" $MAXCDCL_FLAGS "$f" > "$out/$n.base" 2>&1; echo "exit=$?" >> "$out/$n.base"
  "$c" $MAXCDCL_FLAGS "$f" > "$out/$n.cand" 2>&1; echo "exit=$?" >> "$out/$n.cand"
  bo=$(grep -o 'optimal:[^,]*' "$out/$n.base" | tr '\n' ' '); co=$(grep -o 'optimal:[^,]*' "$out/$n.cand" | tr '\n' ' ')
  if cmp -s <(norm "$out/$n.base") <(norm "$out/$n.cand"); then v=IDENTICAL; else v=DIFF; fi
  echo "$n $v base[$bo] cand[$co] $(tail -1 "$out/$n.base") lines=$(wc -l < "$out/$n.base")"
done
