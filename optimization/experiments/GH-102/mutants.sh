#!/bin/bash
# GH-102 mutation checks of tests/test_incremental_dualshare.cc (each mutant must be detected: exit 1).
# usage (repo root, after make; TMPDIR must be space-free): mutants.sh N OUTFILE
#   m1: bounds shared without a verified dual map (share whenever both halves exist)
#   m2: shared lb off by one (max(lb_X, lb_Z) + 1 written into both halves)
#   m1s: m1 with the bookkeeping check off (GH102_SEMANTIC_ONLY=1): must be caught by the d/LB/UB checks
#   m3: variant B follower probes cap U-1 instead of U (may end NONE: the contradiction guard must refuse)
N=${1:-2000}; OUT=$2; R=$(pwd)
T=$(mktemp -d "${TMPDIR:-/tmp}/gh102mut.XXXXXX")
# relative include/object paths (the repo path contains spaces); run from the repo root
CF="-Isrc/solver -Wall -Wno-parentheses -O3 -g -D__STDC_LIMIT_MACROS -D__STDC_FORMAT_MACROS -DNDEBUG"
OBJS="build/SimpSolver.o build/Solver.o build/Options.o build/System.o"
: > "$OUT"
mk() {  # name perl-substitution description [env assignment for the test run]
  mkdir -p "$T/$1/src/core" "$T/$1/tests"
  cp "$R/tests/test_incremental_dualshare.cc" "$T/$1/tests/"
  perl -0pe "$2" "$R/src/core/distqldpc.cc" > "$T/$1/src/core/distqldpc.cc"
  if cmp -s "$R/src/core/distqldpc.cc" "$T/$1/src/core/distqldpc.cc"; then echo "mutation $1: substitution did not apply" >> "$OUT"; return; fi
  echo "mutation $1: $3" >> "$OUT"
  diff "$R/src/core/distqldpc.cc" "$T/$1/src/core/distqldpc.cc" >> "$OUT"
  c++ -Wno-reserved-user-defined-literal $CF "$T/$1/tests/test_incremental_dualshare.cc" $OBJS -lz -o "$T/$1/t" >> "$OUT" 2>&1
  # under the 2 GB cap (capped.py / memlimit.run); the test verdict (stderr) is what gets captured
  python3 -B optimization/experiments/GH-102/capped.py "$T/$1/err" 3600 bash -c "env $4 $T/$1/t $N 2>&1 >/dev/null" > "$T/$1/caprc"
  cat "$T/$1/caprc" >> "$OUT";   rc=$(grep -o 'rc=[^ ]*' "$T/$1/caprc" | cut -c4-); [ "$rc" = 0 ] || rc=1; head -3 "$T/$1/err" >> "$OUT"; tail -1 "$T/$1/err" >> "$OUT"; echo "rc=$rc" >> "$OUT"
  echo "$1 rc=$rc $(tail -1 "$T/$1/err" | grep -o 'failures=[0-9]*')"
}
mk m1 's/share = !dm\.maps\.empty\(\);/share = true; if (dm.maps.empty()) dm.maps.push_back("UNVERIFIED");/' "bounds shared without a verified dual map (whenever both halves exist)"
mk m1s 's/share = !dm\.maps\.empty\(\);/share = true; if (dm.maps.empty()) dm.maps.push_back("UNVERIFIED");/' "m1, test run with GH102_SEMANTIC_ONLY=1 (caught by d/LB/UB checks alone)" GH102_SEMANTIC_ONLY=1
mk m2 's/hs\[0\]\.lb = hs\[1\]\.lb = L;/hs[0].lb = hs[1].lb = L + 1;/' "shared lb off by one (L+1)"
mk m3 's/st = run_css_half\(Z, U, true,/st = run_css_half(Z, U - 1, true,/' "variant B follower cap U-1 instead of U"
rm -rf "$T"
