# Exact independent controlled-server Tier1 replay

**Do not run now.** Execute only after coordinator assigns this experiment a
controlled physical-CPU/sibling lease and the existing resource monitor confirms
global spare>50%, team compute<=half spare throughout. A taskset mask alone is
not a reservation. Stop on loss of resource/lease conditions. Do not run any old
E004 LTO/PGO runner or higher-tier automatic runner. These commands run precisely
GH22 Tier0 fixtures plus one standard48-solve Tier1; no Tier2/3, no other concept.
The server must have git, GNU make/g++, zlib headers, GNU time/timeout/taskset,
Python3, and the same compiler/options for both versions. Record its actual
compiler and reservation evidence; Linux results are not bit-identical Windows builds.

Start in a new empty directory on the dedicated server, inside its existing
approved lease/resource monitor. Set BENCH_CPU to the assigned CPU and
RESERVATION_NOTE to that lease's exact identity. Acquire the experiment record
from PR25 / experiment/gh22-vsids, including RESULT.md and this file.

```bash
set -euo pipefail
: "${BENCH_CPU:?assigned reserved CPU required}"
: "${RESERVATION_NOTE:?actual controlled reservation identity required}"
CXX="${CXX:-g++}"
export LC_ALL=C OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1
git clone https://github.com/guluchen/DistQLDPC.git repository
git -C repository fetch origin experiment/gh22-vsids
git -C repository worktree add --detach ../record origin/experiment/gh22-vsids
git -C repository worktree add --detach ../baseline 24572d6d09cce9a4a5faa58300a89e0feba9da6a
git -C repository worktree add --detach ../candidate 596510ccda48361b34158927607a58988402ff91
rec="$PWD/record/optimization/experiments/GH-22"
mkdir raw
printf '%s\n' "$RESERVATION_NOTE" >raw/reservation.txt
uname -a >raw/uname.txt
"$CXX" --version >raw/compiler.txt
git -C record rev-parse HEAD >raw/record-commit.txt
cat /proc/cpuinfo >raw/cpuinfo.txt
cat "/sys/devices/system/cpu/cpu${BENCH_CPU}/topology/thread_siblings_list" >raw/siblings.txt
python3 - "$rec/tier1-input-sha256.json" baseline/data/matrices <<'PY'
import sys,json,hashlib,pathlib
for name,digest in json.load(open(sys.argv[1])).items():
    assert hashlib.sha256((pathlib.Path(sys.argv[2])/name).read_bytes()).hexdigest()==digest,name
PY
for version in baseline candidate; do
  make -C "$version" -j1 CXX="$CXX" bin/distqldpc >"raw/build-$version.stdout" 2>"raw/build-$version.stderr"
  sha256sum "$version/bin/distqldpc" >"raw/binary-$version.sha256"
  expected_sym=0
  if test "$version" = candidate; then expected_sym=1; fi
  for fixture in test_binary_activity; do
    "$CXX" -I"$version/src/solver" -O2 -std=gnu++11 "-DEXPECT_SYMMETRIC=$expected_sym" "$rec/$fixture.cc" \
      "$version/build/SimpSolver.o" "$version/build/Solver.o" \
      "$version/build/Options.o" "$version/build/System.o" -lz -o "raw/$version-$fixture"
    timeout --kill-after=5s 30s taskset -c "$BENCH_CPU" "raw/$version-$fixture" \
      >"raw/$version-$fixture.stdout" 2>"raw/$version-$fixture.stderr"
    test ! -s "raw/$version-$fixture.stderr"
  done
done
for fixture in test_binary_activity; do
  cmp "raw/baseline-$fixture.stdout" "raw/candidate-$fixture.stdout"
done
for version in baseline candidate; do
  timeout --kill-after=5s 20s bash "$version/scripts/smoke_test.sh" "$PWD/$version/bin/distqldpc" \
    >"raw/smoke-$version.stdout" 2>"raw/smoke-$version.stderr"
  for fixture in css1 css4 css5; do
    expected=1
    if test "$fixture" = css4; then expected=2; fi
    for mode in no-card card-mto; do
      label="$fixture-$mode-$version"
      timeout --kill-after=5s 20s taskset -c "$BENCH_CPU" \
        "$version/bin/distqldpc" -v -cpu-lim=5 "-$mode" "$rec/raw/windows-tier0-01/$fixture" \
        >"raw/$label.stdout" 2>"raw/$label.stderr"
      python3 "$rec/check_science.py" --stdout "raw/$label.stdout" --returncode 0 \
        --expected "$expected" >"raw/$label.science.json"
      "$version/bin/distqldpc" "-$mode" -dump-only "-dump-wcnf=$PWD/raw/$label.wcnf" \
        "$rec/raw/windows-tier0-01/$fixture"
    done
  done
done
for fixture in css1 css4 css5; do
  for mode in no-card card-mto; do
    cmp "raw/$fixture-$mode-baseline.wcnf" "raw/$fixture-$mode-candidate.wcnf"
  done
done
# Original standalone Main, Linux needs no Cygwin test stats shim.
for version in baseline candidate; do
  "$CXX" -I"$version/src/solver" -O3 -g -DNDEBUG -std=gnu++11 \
    "$version/src/solver/Main.cc" "$version/build/SimpSolver.o" \
    "$version/build/Solver.o" "$version/build/Options.o" \
    "$version/build/System.o" -lz -o "raw/$version-pms"
done
for input in "$rec"/raw/windows-tier0-01/pms-*.wcnf; do
  stem=$(basename "$input" .wcnf)
  for version in baseline candidate; do
    set +e
    timeout --kill-after=5s 20s taskset -c "$BENCH_CPU" "raw/$version-pms" -verb=1 "$input" \
      >"raw/$stem-$version.stdout" 2>"raw/$stem-$version.stderr"
    rc=$?
    set -e
    printf '%s\n' "$rc" >"raw/$stem-$version.returncode"
    python3 "$rec/check_pms.py" "$input" "raw/$stem-$version.stdout" "$rc"
  done
done
for version in baseline candidate; do
  for mode in no-card card-mto; do
    label="timeout-$version-$mode"
    set +e
    timeout --kill-after=5s 20s taskset -c "$BENCH_CPU" "$version/bin/distqldpc" \
      "-$mode" -cpu-lim=1 "$PWD/baseline/data/matrices/LP_340_56_8" \
      >"raw/$label.stdout" 2>"raw/$label.stderr"
    rc=$?
    set -e
    python3 "$rec/check_science.py" --stdout "raw/$label.stdout" --returncode "$rc" \
      --expected 8 --timeout >"raw/$label.science.json"
  done
done
for case in BB_90_8_10 GB_144_12_8 BB_108_8_10 LP_238_44_6; do
  expected="${case##*_}"
  for mode in no-card card-mto; do
    for repeat in 1 2 3; do
      versions='baseline candidate'
      if test "$repeat" = 2; then versions='candidate baseline'; fi
      for version in $versions; do
        label="$case-$mode-$repeat-$version"
        set +e
        /usr/bin/time -f '%e' -o "raw/$label.wall_seconds" \
          timeout --signal=TERM --kill-after=5s 195s taskset -c "$BENCH_CPU" \
          "$version/bin/distqldpc" -v -cpu-lim=180 "-$mode" "$PWD/baseline/data/matrices/$case" \
          >"raw/$label.stdout" 2>"raw/$label.stderr"
        rc=$?
        set -e
        printf '%s\n' "$rc" >"raw/$label.returncode"
        if test "$rc" = 124 || test "$rc" = 137; then
          printf '%s\n' 'External watchdog; INCONCLUSIVE, stop and retain partial raw evidence' >raw/STOP.txt
          exit 1
        fi
        python3 "$rec/check_science.py" --stdout "raw/$label.stdout" \
          --returncode "$rc" --expected "$expected" >"raw/$label.science.json"
      done
    done
  done
done
sha256sum baseline/bin/distqldpc candidate/bin/distqldpc >raw/final-binary.sha256
find raw -type f ! -name SHA256.txt -print0 | sort -z | xargs -0 sha256sum >raw/SHA256.txt
```

Do not reinterpret rc1 or watchdog as a completed timing sample. Preserve partial
logs if any step fails; any wrong distance/bound/output stops as a scientific
rejection. Confirm the lease supervisor has no remaining owned processes and
restores its CPU/resource configuration before declaring this controlled run valid.
Keep its continuous resource/sibling telemetry with raw/. Report every3/version
median and8 ratios, using the preregistered numeric filter; do not retune thresholds
or repeat only unfavorable cases. The existing Windows diagnostic is retained
separately, with its actual binary/runtime identities and measured negative direction.

Replays generic GH22 for controlled corroboration only; current local disposition REJECT/NOT ADOPTED. Not GH30 MTO-gated candidate, no higher tier. All compilation/smoke/fixtures/solves above must run INSIDE assigned existing lease/resource monitor; the commands do not themselves reserve resources. Record all original tinyPMS input/output semantics; Main defaults BOTH, focused production fixture covers its activity change independently. Existing hosted checks are a separate prerequisite.
