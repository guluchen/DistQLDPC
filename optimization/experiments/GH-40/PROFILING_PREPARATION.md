# Mechanism profiling preparation (unexecuted)

Existing solver output includes nbLK/nbSuccLK/nbLKup, bound-phase conflict/core
counts and hardened variables. These distinguish search-path changes (GH30 had
roughly doubled lookahead work), not function self time or memory stalls.
GCOV counts from GH16 training represent fixed LP34/LP136 workloads, not Tier1
runtime proportions. Direct child profiling must account for fork and _exit:
normal atexit GCOV output is insufficient. GH40 baseline-only counters explicitly
dump/flush just before original _exit in the disposable diagnostic copy. Timed
production sources/binaries must contain no dump/event symbols.

External GH34 Mac sample/counter observations are attributed in PROPOSAL. They
motivate measuring ternary tail opportunity here; they are not Windows evidence
and do not prove load/branch stalls from a marginal sign-XOR speedup. Proposed
fixed counters partition visits into blocker/load then first-hit/ternary/other,
and eligible ternary into undefined/true/false, without modifying visit order.
Count reductions from a structural specialization still require measured timing.

For a future named dedicated-server quiet window, freeze exact BASE245 production,
compiler/runtime/input/binary hashes and resource/physical-pair lease before any
probe. Do not assume the installed fixed102/230 lease can migrate to another pair.
An idle sample or taskset mask alone is not a reservation. No server worker runs
from this document. First inspect available profiler and permissions/resource
attestation; unsupported perf events must be reported, not replaced with assumed
hardware conclusions. The following is a *proposed* bounded baseline-only capture
inside that future owned window, not a timing comparison or authorization:

```bash
# Only after named host assignment, actual paired-core lease and fresh guards.
# BASE_BIN absolute pinned baseline executable; INPUT_PREFIX absolute pinned LP136.
: "${BASE_BIN:?}" "${INPUT_PREFIX:?}" "${BENCH_CPU:?}" "${PROFILE_OUT:?}"
mkdir "$PROFILE_OUT" # fresh output required
perf --version >"$PROFILE_OUT/perf-version.txt"
timeout --kill-after=5s 135s taskset -c "$BENCH_CPU" perf stat \
  -e task-clock,cycles,instructions,branches,branch-misses,cache-references,cache-misses \
  -o "$PROFILE_OUT/perf-stat.txt" -- \
  "$BASE_BIN" -v -no-card -cpu-lim=120 "$INPUT_PREFIX" \
  >"$PROFILE_OUT/solver.stdout" 2>"$PROFILE_OUT/solver.stderr"
```

Record exact raw exit/science/all interim bounds/command/posthashes, unavailable
event errors and lease/resource telemetry. Parent and child contributions must
be explicitly understood from the actual profiler configuration before reporting
solver-only counts; do not call aggregate measurements child self time. A separate
future registered sampling capture may measure function distribution if supported.
This capture cannot substitute for unprofiled baseline/candidate performance tiers,
nor authorize the unselected prefetch mechanism without actual relevant evidence.
