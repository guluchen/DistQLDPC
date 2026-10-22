#!/usr/bin/env bash
# GH-138: every tier0-3 code with -engine=cc under several rule sets; answer must equal the stem distance.
# usage: answers.sh BIN CORE  (run from a worktree root; each process pinned, 4 GB cap)
B="$1"; C="$2"
for t in 0 1 2 3; do
  for f in data/matrices/tier$t/*_Hx.txt; do
    c=$(basename "$f" _Hx.txt); d=$(echo "$c" | cut -d_ -f4)
    if [ $t -le 1 ]; then V="-cc-rules=excl,pack,orbf,parity,leaf|-cc-rules=excl,pack,orbf,parity,leaf,overlap|-cc-rules=overlap|-cc-rules=excl,overlap|-cc-rules=excl,pack,orbf,parity,leaf,overlap,mrv|-cc-seed=1|-cc-seed=2 -cc-dual=off|-no-symbreak -cc-seed=3"
    else V="-cc-rules=excl,pack,orbf,parity,leaf|-cc-rules=excl,pack,orbf,parity,leaf,overlap|-cc-rules=excl,pack,overlap|-cc-rules=excl,pack,orbf,parity,leaf,overlap,mrv|-cc-seed=1|-cc-seed=2 -cc-dual=off|-no-symbreak -cc-seed=3"; fi
    IFS='|' read -ra VS <<< "$V"
    for v in "${VS[@]}"; do
      o=$(taskset -c "$C" prlimit --as=4294967296 -- "$B" -engine=cc $v -cpu-lim=1800 "${f%_Hx.txt}" 2>&1 < /dev/null | sed -n 's/^o //p' | tail -1)
      if [ -z "$o" ]; then st=TIMEOUT; elif [ "$o" = "$d" ]; then st=OK; else st=WRONG; fi
      echo "tier$t $c [$v] o=$o $st"
    done
  done
done
echo DONE
