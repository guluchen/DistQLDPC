# GH41 full Tier 0 preregistration

Status: PREPARED / NOT EXECUTED. No performance conclusion.

Baseline: `24572d6d09cce9a4a5faa58300a89e0feba9da6a`.
Production candidate: `66cf8be5a4881643f2063471325e33cecaa0caf1`.
This is a fresh mode-scoped experiment, not acceptance of the GH36 MTO subset.

The actual application helper is included by the fixture. The independent full
Pauli truth-table oracle checks all 4,368 original one-row inputs across each of
the five original modes (21,840 checks), plus multiple-row minima. Only explicit
MTO receives the independently validated scalar; OFF, SINZ, BOTH and BOTH_FORCE
must return INT32_MAX. Each actual shared builder retains its original initial
bound, and applying the scalar must never fabricate a model or hasCostUB.

The supervisor derives from the executed GH36 full Tier0 supervisor. Both builds
use fresh exports and original O3 flags, one make job, and pinned original GCC14.4
runtime. Makefile and smoke shell files are LF-normalized; other source bytes
remain exact git-archive exports. Git archive can apply core.autocrlf, so exported
source bytes are not falsely described as identical to raw Git blobs.

Retain all 16 small CSS scientific solves, eight identical WCNF comparisons,
40 independent PMS truth-table cases and the 162 complete capped/uncapped Main
runs, including O1/P1/P2 and a tight positive cap after UB1 fails. Preserve the
original finite-optimal Main SAT/10 or UNSAT/20 outcome and all bounds/objectives.
Retain two original smoke tests, four real production one-second timeout probes
(an independently valid early completion is permitted), and eight symmetric
test-only pre-search/post-model timeout probes. Forced hooks never replace the
production binaries. UNKNOWN/TIMEOUT emits no objective; numeric upper bounds
must correspond to a real model.

Budget: 2,700 seconds aggregate, builds at most 300 seconds each, fixture build
120 seconds, fixture execution 30 seconds. Retain the executed supervisor's
2.1-second capacity preflight, two-second active observations, one guarded Job,
global spare CPU greater than 50 percent, no more than half the spare capacity,
and all original cleanup/identity/restoration gates. No other host CPU experiment
may overlap. Current driver is disabled until a fresh public named assignment
is frozen together with the actual support commit and driver SHA256.

Any actual semantic mismatch, crash, wrong distance/bound/objective or timeout
regression stops the experiment and rejects the candidate. An evidenced fixture
or build infrastructure error is retained and investigated without declaring a
scientific pass. Hosted ordinary and QDistSAT cross-repo checks are required for
the current production tree before performance timing. Hosted timing is diagnostic.

Only after all actual Tier0 gates pass: preregister fresh Tier1 baseline and
candidate three times per four named cases and both OFF/MTO modes, retain all
timings/medians/scientific fields/resource records. Earlier GH36 measurements do
not count as GH41 measurements. Tier2 and Tier3 remain NOT RUN.
