# GH22 Tier0 preparation

This support plan is recorded before any local execution. Windows slot pending.
The production candidate remains596510c (one Solver.cc activity-index byte).
Hosted ordinary CI37800958166 and cross-repo37800958168 succeeded; raw audit
is being retained. Hosted timings are informational only.

Focused test calls actual production uncheckedEnqueueForLK, propagateForLK and
lookbackResetTrail with a real hard binary clause. 128 fixed cases cover both
VSIDS states, conflicting literal signs, enqueue orientation, ordinary/soft
variables, both last flags and two finite activity increments. Baseline and
candidate have their separately expected activity deltas; all other rollback,
conflict-explanation and clause states must match. No cloned implementation,
timing conclusion, or production instrumentation. Checks use explicit require
because the normal engine build defines NDEBUG.

Generic correctness follows the existing independently enumerable CSS1/4/5
Pauli oracle, original WCNF comparison, both LP34 smoke modes, four LP340 genuine
one-second TIMEOUT checks with every bound validated. Also run the four fixed
small partial MaxSAT graph instances and32 fixed seeded supported unweighted
PMS cases with exhaustive assignment oracle. Keep all stdout/stderr/argv,
input/binary/source/runtime hashes, resources and cleanup outcomes.

Windows Cygwin baseline standalone Main.cc has unresolved memUsedPeak because
its unsupported-platform System.cc branch only defines memUsed. If needed,
link a TEST-ONLY shim returning existing memUsed for this unsupported statistic,
identically for baseline and candidate. Never link it into production
DistQLDPC or modify upstream/downstream source for this preparation limitation.
Build the supported production bin/distqldpc target with untouched O3 flags.
Use native DLL PATH for executables and POSIX PATH only for make; stage the
verified LP34 input files for smoke. No repository or global runtime settings
changed. Preparation failures retain engineering INCONCLUSIVE evidence;
actual scientific mismatch/crash stops and rejects as required by policy.

After Tier0 PASS, four prerecorded baseline-only LP34/LP136 OFF/MTO120/135s
diagnostic solves count VSIDS binary-conflict events and distinct variables.
Counters cannot establish runtime share. No comparative Tier1 in this slot.
Resource guards: global spare>50%, one named runner/single logical CPU,
AboveNormal owned Windows Job,2s telemetry and bounded owned-child cleanup;
verify affinity/priority/sleep restoration. No test/build until assignment.
