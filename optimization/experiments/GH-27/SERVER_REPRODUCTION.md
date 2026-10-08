# Conditional dedicated-server reproduction — NOT EXECUTED

No server slot is assigned. Local guarded Tier0 remains pending. These commands
are a reproducible preparation/fixture and future Tier1 plan, not permission to
run, proof of live isolation, or a complete Linux Tier0 PASS. The coordinator
must assign the host and verify installed helper identity/live partition/cleanup/
recovery and spare>50%/team<=half spare first. Taskset alone is insufficient.
Linux binaries are rebuilt and separately validated; Windows hashes cannot certify them.

Source-reviewed installed helper CLI (primary repository
optimization/server/isolation/cpu_run.py):
`sudo -n /usr/local/sbin/distqldpc-cpu-run run --cwd <absolute> -- <absolute executable> ...`.
It drops to yfc, reserves102/sibling230, monitors active2s capacity/partition,
uses bounded cgroup cleanup, and strips custom environment variables.
Any acquisition/capacity/partition failure is INCONCLUSIVE; do not retry until
favorable or count an invalid attempt as a completed solve. No live validation claimed here.

After a fresh assignment, in a new empty user-owned directory:

```bash
set -euo pipefail
: "${GH27_RECORD_COMMIT:?exact coordinator-frozen replay/support commit required}"
test ! -e repository && test ! -e baseline && test ! -e candidate && test ! -e record && test ! -e raw
git clone https://github.com/guluchen/DistQLDPC.git repository
git -C repository fetch origin experiment/gh27-lk-enqueue
git -C repository worktree add --detach ../baseline 24572d6d09cce9a4a5faa58300a89e0feba9da6a
git -C repository worktree add --detach ../candidate 58fbae546e74c158c21070cd10106e94d6bd2b98
git -C repository worktree add --detach ../record "$GH27_RECORD_COMMIT"
rec="$PWD/record/optimization/experiments/GH-27"
mkdir raw
git -C record rev-parse HEAD >raw/record-commit.txt
git -C candidate diff 24572d6 HEAD -- src Makefile >raw/production.diff
lease() {
  local label="$1" seconds="$2"; shift 2
  local rc=0
  sudo -n /usr/local/sbin/distqldpc-cpu-run run --cwd "$PWD" -- \
    /bin/bash -c 'seconds="$1"; output="$2"; shift 2; exec /usr/bin/timeout --signal=TERM --kill-after=5s "$seconds" "$@" >"$output.stdout" 2>"$output.stderr"' \
    gh27 "$seconds" "$PWD/raw/$label" "$@" >"raw/$label.lease.stdout" 2>"raw/$label.lease.stderr" || rc=$?
  printf '%s\n' "$rc" >"raw/$label.returncode"
  # Validate actual acquisition/release and reject supervisor/resource errors.
  /usr/bin/python3 - "raw/$label.lease.stdout" "raw/$label.lease.stderr" <<'PY'
import json,pathlib,sys
rows=[json.loads(s) for s in pathlib.Path(sys.argv[1]).read_text().splitlines()]
assert any(r.get('event')=='acquired' and r.get('cpus')==[102,230] for r in rows)
assert rows and rows[-1].get('event')=='released'
assert 'ISOLATION_ERROR' not in pathlib.Path(sys.argv[2]).read_text()
PY
  return "$rc"
}
lease compiler 20s /usr/bin/g++ --version
lease compiler-version 20s /bin/bash -c 'test "$(/usr/bin/g++ -dumpfullversion)" = 14.4.0'
for version in baseline candidate; do
  lease "build-$version" 300s /usr/bin/make -C "$PWD/$version" -j1 CXX=/usr/bin/g++ bin/distqldpc
  sha256sum "$version/bin/distqldpc" >"raw/$version.binary.sha256"
  for fixture in test_enqueue_prefix test_watch_tail test_watch_tail_gc; do
    lease "$version-$fixture-build" 120s /usr/bin/g++ -I"$PWD/$version/src/solver" -O3 -std=gnu++11 \
      "$rec/$fixture.cc" "$PWD/$version/build/Solver.o" "$PWD/$version/build/Options.o" \
      "$PWD/$version/build/System.o" -lz -o "$PWD/raw/$version-$fixture"
    lease "$version-$fixture-trace" 30s "$PWD/raw/$version-$fixture"
    test ! -s "raw/$version-$fixture-trace.stderr"
  done
  lease "smoke-$version" 20s /bin/bash "$PWD/$version/scripts/smoke_test.sh" "$PWD/$version/bin/distqldpc"
done
for fixture in test_enqueue_prefix test_watch_tail test_watch_tail_gc; do
  cmp "raw/baseline-$fixture-trace.stdout" "raw/candidate-$fixture-trace.stdout"
done
```

Reviewed support7a25708 contains the corrected480-case fixture and Windows driver;
later recordc54efb2 adds this document/parser/input map. Freeze an exact replay
record including all of them in GH27_RECORD_COMMIT before an actual server run.
Default-O3 and assertion-enabled debug method fixtures,
tiny12 CSS/6 paired WCNF comparisons,72 exact tiny PMS solves and four genuine
1s LP340 UNKNOWN timeouts must all pass Linux Tier0 before any timing. The commands
above cover only release fixtures/original smoke; do not label them the full gate.
Windows-specific statistics shim must never be linked on Linux. Reuse exact
fixtures/oracles/limits in TIER0_DRIVER_PREREGISTRATION.md and prepare/review the
Linux adapter under the assigned host before execution. No unreviewed cross-platform
assumption or automatic performance escalation is authorized by this plan.

Once FULL Linux Tier0 is independently recorded PASS and a fresh controlled
Tier1 assignment is issued, use exactly the following per-solve command inside
the reviewed lease wrapper (absolute binary/matrix/raw paths, fresh labels):

```bash
sudo -n /usr/local/sbin/distqldpc-cpu-run run --cwd "$PWD" -- \
  /bin/bash -c 'exec /usr/bin/timeout --signal=TERM --kill-after=5s 195s /usr/bin/time -f "%e" -o "$1.elapsed" "$2" -v -cpu-lim=180 "-$3" "$4" >"$1.stdout" 2>"$1.stderr"' \
  gh27 "$PWD/raw/$label" "$binary" "$mode" "$matrix_stem" \
  >"raw/$label.lease.stdout" 2>"raw/$label.lease.stderr"
```

Exact order: BB90,GB144,BB108,LP238; each no-card then card-mto; repeats1/2/3;
versions baseline/candidate, candidate/baseline, baseline/candidate =48 solves.
Exact stems are BB_90_8_10,GB_144_12_8,BB_108_8_10,LP_238_44_6. Use BASE matrix
bytes matching tier1-input-sha256.json (all16 directly match baseline Git blobs,
metadata verified). Validate every interim/final numeric field/status/exit using
check_science.py; genuine rc1 UNKNOWN or watchdog is incomplete and stops filtering.
Retain each wrapper resource/acquisition/release log; recheck input/binary/compiler/
runtime hashes and empty released cgroup. GNU time %e has centisecond precision;
small overlapping differences remain INCONCLUSIVE, never invent precision.
Report8 medians/ranges and OFF/MTO geometric means separately using preregistered
positive direction/no serious regression/beyond-variability gate. No tuning,
repeat-until-favorable, Tier2/3, PGO/O2/native flag or stacked previous candidate.
