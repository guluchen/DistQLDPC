# GH-16 / H010: PGO only

Preregistered2026-10-08 before implementation. Owner codex-primary-20261008,
[issue16](https://github.com/guluchen/DistQLDPC/issues/16), shared scheduler
[issue15](https://github.com/guluchen/DistQLDPC/issues/15).
Baseline24572d6d09cce9a4a5faa58300a89e0feba9da6a;
branch experiment/gh16-pgo, independent worktree GH16-PGO.

Hypothesis: compiler profile feedback reduces per-operation cost in the unchanged
embedded downstream MaxCDCL engine. This is PGO only, distinct from E004 LTO;
no encoding/heuristic/refactoring/native-ISA/fast-math combination. All three
Round5 proposals and ranking remain in the history branch; H011/H012 unselected.

## Implementation scope

Instrument only four existing engine translation units. Leave application/Main
translation units uninstrumented. Makefile provides explicit off/generate/use
modes and profile-directory selection, using baseline CXXFLAGS unchanged.
Generation adds GCC profile instrumentation/coverage notes to engine compilation;
links libgcov, enables a training-only application macro, and flushes engine
profiles before the child's existing _exit. Production off/use builds exclude
that hook. The hook is training support, not a production performance change.
Never replace _exit or alter pipe/timeout behavior. Preserve all engine source.

All modes rebuild after explicit clean of this worktree's generated build/bin
outputs, using the same object/output paths for profile identity. Preserve the
baseline production binary separately before training. Keep profile data outside
build, record SHA256 and freeze before evaluation. Missing/mismatched profiles
are fatal; no warning suppression/fallback. Final candidate does not link gcov.

Planned command sequence in the verified GCC host environment, serial -j1:

```sh
make -j1 PGO=off bin/distqldpc
# archive/hash baseline executable in experiment artifacts
make clean
make -j1 PGO=generate PGO_DIR="$PWD/pgo-data" bin/distqldpc
./bin/distqldpc LP_34_20_2 -no-card -cpu-lim=120
./bin/distqldpc LP_34_20_2 -card-mto -cpu-lim=120
./bin/distqldpc LP_136_32_4 -no-card -cpu-lim=120
./bin/distqldpc LP_136_32_4 -card-mto -cpu-lim=120
# validate completed results and nonzero Solver search/propagate coverage;
# retain gcov reports, engine gcno/gcda, hashes and training logs before clean
make clean
make -j1 PGO=use PGO_DIR="$PWD/pgo-data" bin/distqldpc
# archive/hash final executable; prove training hook/gcov absent
```

Training is fixed, no Tier1/2/3 evaluation instances, no feedback-based profile
selection. LP136 is an existing Tier0 pilot, not an independent performance
holdout; do not call its eventual Tier0 timing a generalization result.
Confirm LP136 committed input identity/location before execution. Timeout or
missing solver counters invalidates this training plan rather than permitting
silent parameter/case substitution. Four training solves at120s maximum each;
instrumented timings are not performance results.

## Tier0 and experiment gates

First require successful baseline/generation/candidate builds and valid profiles.
Verify default off build semantics and final candidate hook absence, identical
dumped original WCNFs and small exhaustive CSS results in OFF/MTO, smoke/pinned
QDistSAT pilot, original result/bounds and timeout cleanup. Hosted ordinary and
cross-repo checks required; shared timings informational. Any semantic mismatch,
wrong bound/distance/crash/output change rejects and stops performance.

Only then Tier1 BB_90_8_10, GB_144_12_8, BB_108_8_10, LP_238_44_6:
OFF/MTO separately, baseline/candidate3 times each, serial AB/BA/AB same CPU,
48 solves,180s parent/195s watchdog. Preserve samples, medians, identity/science,
variability, capacity/contention and cleanup. No pooling across protocols/hosts.
Require reproducible positive direction with no material regression. Uncertain
interference remains INCONCLUSIVE. Diagnostic results never become controlled
evidence merely because science matches. Tier2 LP34012 solves600/615s only after
positive gate, or a separately scoped documented user exploratory exception.
No Tier3 from this preregistration.

Team-aggregate global spare>50%, use<=half spare. One runner per host assigned
through issue15. Server probe currently45.12% idle: no remote workload eligible.
Windows fallback may be used if resource guard allows. Training/build resource
accounting also applies; no other agent may benchmark concurrently on that host.

## Risk, interpretation and learning

Main risks: _exit profile loss, fork profile merging, unrepresentative training,
code growth, profile path/source identity and optimizer-sensitive latent defects.
Prove nonzero solver search/propagation counts, not merely gcda existence or
frontend activity. Source/science preservation is necessary but not a speedup.

E001/E002/E006 show encoding reduction can increase search work; E003 did not
prove allocation dominance. H010 tests code-generation cost independently of
those mechanisms; E004 LTO's shelving does not establish PGO failure or success.
No predicted percentage. Expected cost three serial builds, up to8min training,
Tier0 plus bounded filters (Tier1 watchdog worst156min, Tier2 worst123min).
Runtime estimates are budgets, not measured results.

References: GCC14.4 Optimize Options (fprofile-use), current Instrumentation
Options, GCC Gcov-and-Optimization (__gcov_dump); check installed GCC behavior.
Ordinary compiler optimization, no invented MaxSAT paper attribution.

Status: PROPOSED/IMPLEMENTATION STARTING, candidate unset, no correctness or
timing result yet. Record exact executed argv/artifacts and candidate SHA later.

Preparation review repairs before performance: enforce explicit-clean mode/
profile-directory/compiler-flags transitions using a Make configuration stamp;
training-only GCC header uses C linkage on Cygwin. Attempt01 failed training
link (undefined __gcov_dump C++ symbol), with no training/solver mismatch and
successful cleanup; retained as build preparation failure, not scientific REJECT.
Hosted cross-repo build now generates/trains/uses its own GCC profiles with the
same fixed small cases and verifies nonzero solver coverage/hook absence before
comparing the actual PGO-use candidate. Ordinary CI still validates default off.
Shared hosted training/pilot timing remains informational, no performance gate.
