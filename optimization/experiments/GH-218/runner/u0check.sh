#!/bin/bash
# u0check.sh CORE: ub-pre U0 per seed/mode for the Tier 1-4 TN codes (no probe reaches cap 16 iff U0 <= 16... checked: U0 = d)
core=$1; cd ~/mac-agent-20261009/gh218-60fec5b
C=~/mac-agent-20261009/frozen/server-gh218-60fec5b/distqldpc
for p in tier2/TN_108_2_12 tier2/TN_200_10_10 tier3/TN_144_2_13 tier4/TN_250_10_15; do for md in -no-card -card-mto; do for s in 0 1 2 3 4; do
  out=$(taskset -c $core prlimit --as=4294967296 -- $C $md -seed=$s -v -cpu-lim=75 data/matrices/$p 2>&1 < /dev/null | grep -E "^c ub-pre: |c CSS interleave: . half cap|OVERLAP-PILOT|stab-overlap pilot" | head -12)
  u0=$(grep -o "^c ub-pre: U0 after [^)]*); [0-9]*\|^c ub-pre: .*" <<<"$out" | head -1 | cut -c1-120)
  caps=$(grep -o "half cap [0-9]*" <<<"$out" | awk '{print $3}' | tr '\n' ',')
  pil=$(grep -c "pilot" <<<"$out")
  echo "$p $md s$s | $u0 | caps $caps | pilot_lines $pil"
done; done; done; echo DONE
