#!/bin/bash
# GH-99 Tier0 short follow-ups (each < 10 min, at most 4 parallel jobs):
#  rerun30  exact identity reruns at -cpu-lim=30 for candidate-shorter timeouts (GH-95 rule)
#  wc       work counts with the counter build (4 cases x {off, exact, fast}, -cpu-lim=30)
#  fuzz     maxcdcl oracle on 300 random unit-soft WCNFs (base GH-95, cand fast, check exact)
#  mcmp     maxcdcl exact vs GH-95 maxcdcl full-output comparison (GH-95 set)
# usage: tier0_post.sh OUTROOT STEP...
W="/Users/yfc/Library/Application Support/Claude/scratch-workspaces/1417068f-a9d4-4e40-a6ba-6b2464faa27e/de902d21-d9e1-45a1-a1dd-f95718bf744f/scratch-2026-10-08-ce0ddb"
R="$W/cand99"; E="$R/optimization/experiments/GH-99"; S="$E/scripts"; O="$1"; shift
for step in "$@"; do case "$step" in
  rerun30) "$S/batch.sh" "$W/frozen99/exact/distqldpc" "$O/exact_rerun30" 30 "$R" none "$O/rerun.list" 4;;
  wc) mkdir -p "$O/wc"; cd "$R"
      for m in -no-lkskip -lkskip=exact -lkskip=fast; do for c in "GB_144_12_12 -no-card" "LP_544_80_12 -card-mto" "TN_144_2_13 -no-card" "LP_340_56_8 -no-card"; do
        set -- $c; echo "$1 $2 $m"; done; done | xargs -P4 -L1 sh -c '"$0" -v $3 $4 -cpu-lim=30 $2 > "$1/$2$3$4.log" 2>&1' "$O/../bins/stats/distqldpc" "$O/wc";;
  fuzz) python3 -B "$S/fuzz2.py" --base "$W/frozen95/cand/maxcdcl" --cand "$W/frozen99/fast/maxcdcl" --extra "$W/frozen99/exact/maxcdcl" \
          --brute "$O/../brute" --out "$O/fuzz" --n 300 --seed0 990000 --lim 20 > "$O/fuzz.log" 2>&1; echo "fuzz rc=$?";;
  mcmp) mkdir -p "$O/dumps"; cd "$R"
        for c in BB_72_12_6 LP_136_32_4 TN_36_8_4; do "$W/frozen99/exact/distqldpc" -dump-wcnf="$O/dumps/$c.wcnf" -dump-only $c > /dev/null 2>&1; done
        bash "$R/optimization/experiments/GH-95/scripts/maxcdcl_cmp.sh" "$W/frozen95/cand/maxcdcl" "$W/frozen99/exact/maxcdcl" "$O/mcmp" \
          src/solver/clq-n100e2500g1 src/solver/clq-n150e10058g1 tests/fixtures/partition-retired-soft.wcnf "$O"/dumps/*.wcnf > "$O/mcmp.txt"; cat "$O/mcmp.txt";;
esac; done
