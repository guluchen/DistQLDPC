# E005 reproduction

Workspace root, existing Cygwin/package identities described in README and
raw validation environment. Candidate worktree at commit749391c, independent
baseline package at24572d6. Use new output directories; do not overwrite evidence.

```powershell
python -X utf8 DistQLDPC/optimization/experiments/E005/tier0_windows.py --out E005-validation-new
```

Hosted CI status for the same candidate is recorded separately in validation03.
For reproducing the strict Tier1 plan, use verified validation03 with its hosted
status receipt and unchanged binaries/sources. This configuration is rejected
on mechanism evidence, so no further performance run is scheduled:

```powershell
python -X utf8 DistQLDPC/optimization/experiments/E005/run_windows_tier1.py --prior E004-windows-tier2-02 --cygwin-root E004-windows-runtime/cygwin --candidate-tree E005-SLS --validation E005-validation-03 --output E005-windows-tier1-new --preflight-wait-sec 30 --priority-class above-normal
```

Separate one-second mechanism screen, fixed output E005-mechanism-screen-01
must be unused (preserve/move prior evidence first):

```powershell
python -X utf8 DistQLDPC/optimization/experiments/E005/mechanism_screen.py
```

Dedicated Linux server mechanism reproduction, from an eligible/reserved core
with sibling idle>=95%, global spare>50% and allocation<=half spare. BENCH_CPU
must be the actually eligible allocated core, not an invented index. Sample
telemetry throughout; stop on resource loss. No Linux execution occurred for E005:

```sh
git clone --branch experiment/h008-sls-warm-start https://github.com/guluchen/DistQLDPC.git e005-candidate
cd e005-candidate
git checkout --detach 749391c9aab5389965822cac94d90aa360446f9a
taskset -c "$BENCH_CPU" make -j1 bin/distqldpc
taskset -c "$BENCH_CPU" g++ -Isrc/solver -O2 -std=gnu++11 tests/sls_warm_probe.cc build/SimpSolver.o build/Solver.o build/Options.o build/System.o -lz -o build/sls_warm_probe
taskset -c "$BENCH_CPU" ./build/sls_warm_probe > sls-probe.log 2>&1
mkdir mechanism-results
for case in BB_90_8_10 GB_144_12_8 BB_108_8_10 LP_238_44_6; do
  for mode in no-card card-mto; do
    taskset -c "$BENCH_CPU" ./bin/distqldpc -v -cpu-lim=1 -"$mode" "$case" > "mechanism-results/$case-$mode.stdout" 2> "mechanism-results/$case-$mode.stderr"
    printf '%s\n' "$?" > "mechanism-results/$case-$mode.exit"
  done
done
```

The above is short feasibility/timeout reproduction, not a substitute for Tier1
three-repeat baseline/candidate performance. A server performance revisit would
require separate registration/validation on that compiler/environment and the
same four-case/two-mode/three-repeat ABBAAB protocol; this rejected mechanism
does not justify scheduling it now. Baseline clone/ref24572d6, no candidate LTO.
