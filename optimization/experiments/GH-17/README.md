# GH-17: caller-local core-merge scratch reuse

Owner: independent-brain-20261008. [Issue17](https://github.com/guluchen/DistQLDPC/issues/17).
Baseline24572d6d09cce9a4a5faa58300a89e0feba9da6a.
Disposition: UNTESTED / NOT ADOPTED. Tier0/1/2 NOT RUN. No performance claim.
Host slot NONE; primary currently owns Windows host preparation. Nothing in
this record starts a workload or grants a resource lease.

Selected GH-17-A from the three proposals recorded in PROPOSAL.md. Exactly one
production concept: caller-local oldset capacity reuse across cores in each
lookahead invocation. No changed core merge/order, constraints, thresholds,
compiler flags, bound/output/timeout interpretation or scientific semantics
intended. Correctness still requires the tests below. Preserve downstream
MaxCDCL attribution; MODIFICATIONS/NOTICE describe this isolated patch.

## Prepared checks, not executed

- test_core_scratch.cc invokes the original/candidate PRODUCTION method on
 4096 length-three core sequences, emits active core ownership/membership,
 representatives, weights, seen flags and unlocked-variable snapshots for bytewise
 comparison, and separately asserts overlapping-component weight, deduplication,
 empty/disjoint calls, unlock increment and restart reset invariants.
 It uses existing downstream public methods/fields and a test-only subclass
 accessor for protected seen flags, without production test hooks.
- run_tier0.py compares those traces, independently enumerates Pauli-distance
 oracles on three tiny CSS fixtures, checks exact exported initial CNF, both
 modes smoke/known bounds, help and forced wall-timeout behavior. Raw stdout,
 stderr, command metadata, identities and SHA256 manifest are retained.
- prepare_diagnostic.py copies a separate immutable baseline snapshot and
 adds only counters, with normalized baseline Solver.cc hash guard. It does
 NOT instrument final candidate. allocation_diagnostic.h aggregates actual
 capacity crossings and predicts reuse growth inside each caller; these counts
 do not measure a time share or speedup.
- run_allocation_diagnostic.py runs exactly four diagnostic calls, LP34/LP136
 OFF/MTO,120s parent/135s watchdog. Checks exact expected results, retains all
 aggregates and outputs; never computes a performance ratio.

Helper source and scripts are prepared but UNVALIDATED by compilation/execution.
Windows host use must remain serially scheduled; resource/affinity/job guards
come from the assigned runner, not runner_common.py or --run-assignment text.
The common helper terminates only its owned process tree on watchdog/interruption.
Its cleanup must be verified under the eventual host's resource wrapper before
measurements; there is no claim that the helper provides CPU isolation itself.

## Exact POSIX commands after explicit hub15 assignment

Run all commands inside an eligible assigned resource wrapper. These commands
are prepared, NOT executed. Use one build worker; training/diagnostics/builds
count toward team resources. Keep a fresh output directory per attempt.

```sh
# candidate is the isolated pinned-SHA checkout prepared for this issue.
candidate="$PWD/GH17-SCRATCH"
runroot="$PWD/GH17-assigned-run-01"
mkdir "$runroot"
mkdir "$runroot/baseline"
git -C "$candidate" archive 24572d6d09cce9a4a5faa58300a89e0feba9da6a | tar -xf - -C "$runroot/baseline"
base="$runroot/baseline"
record="$candidate/optimization/experiments/GH-17"

make -C "$base" -j1 bin/distqldpc
make -C "$candidate" -j1 bin/distqldpc
g++ -I"$base/src/solver" -O2 -std=gnu++11 -DGH17_BASELINE \
 "$record/test_core_scratch.cc" "$base/build/SimpSolver.o" "$base/build/Solver.o" \
 "$base/build/Options.o" "$base/build/System.o" -lz -o "$runroot/baseline-probe"
g++ -I"$candidate/src/solver" -O2 -std=gnu++11 \
 "$record/test_core_scratch.cc" "$candidate/build/SimpSolver.o" "$candidate/build/Solver.o" \
 "$candidate/build/Options.o" "$candidate/build/System.o" -lz -o "$runroot/candidate-probe"

python3 "$record/run_tier0.py" \
 --baseline-bin "$base/bin/distqldpc" --candidate-bin "$candidate/bin/distqldpc" \
 --baseline-probe "$runroot/baseline-probe" --candidate-probe "$runroot/candidate-probe" \
 --data-root "$base/data/matrices" --out "$runroot/tier0" \
 --run-assignment "<actual hub15 assignment URL>"

# Any correctness mismatch stops/rejects: do not run the following diagnostic.
python3 "$record/prepare_diagnostic.py" --source "$base" --out "$runroot/diagnostic-baseline"
make -C "$runroot/diagnostic-baseline" -j1 bin/distqldpc
python3 "$record/run_allocation_diagnostic.py" \
 --binary "$runroot/diagnostic-baseline/bin/distqldpc" --data-root "$base/data/matrices" \
 --out "$runroot/allocation" --run-assignment "<actual hub15 assignment URL>"
```

Record compiler version/options, Git baseline/candidate IDs, binary/source/input
hashes, run assignment, host environment and actual resource telemetry alongside
each output. Cygwin/native-Python invocation can use --cygwin to convert argument
paths; it still requires the primary runner's validated Windows capacity/Job
wrapper. No Windows run attempted; no automatic choice of compiler/runtime.

Hosted ordinary CI and required QDistSAT cross-repo checks on pinned candidate
must also pass. Persist their correctness evidence; shared timing informational.
If diagnostic shows no saved-allocation opportunity, record mechanism rejection
without expensive performance tiers. Presence of saved allocations does not prove
worthwhile speedup: it only supports proceeding to the common Tier1 filter.

## Performance gates pending

Tier1 BB90/GB144/BB108/LP238, OFF/MTO,3/version/case/mode (48 serial solves);
180/195s limits, AB/BA/AB same CPU, raw results/medians/variability/telemetry.
Tier2 LP34012 solves600/615s only if reproducible positive Tier1/no serious
regression. No Tier3 authorization from this record. Scheduler assigns a single
runner per host; aggregate spare>50%, at most half spare. No available controlled
window means INCONCLUSIVE plus reproducible package, never an invented ACCEPT.

Retain failed or uncertain data. Follow continuing fresh-three-proposal Brain
loop after recording learning; do not silently repeat until favorable. No global
H/E allocation, shared index edits or optimization combination.
