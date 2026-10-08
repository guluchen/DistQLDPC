# GH-22: symmetric lookahead binary-conflict VSIDS activity

Preregistered before implementation2026-10-08. Owner codex-primary-next-20261008.
[Selection22](https://github.com/guluchen/DistQLDPC/issues/22),
[hub15](https://github.com/guluchen/DistQLDPC/issues/15).
Baseline24572d6d09cce9a4a5faa58300a89e0feba9da6a;
isolated GH22-VSIDS, branch experiment/gh22-vsids.

Exactly one performance change: lookbackResetTrail's binary-conflict VSIDS
branch currently bumps binConfl[0] twice at weight.1. Replace only the second
index0 with1. Preserve both weights and all other branch/restart/LRB/activity
rules, source instrumentation, objective/bound logic, encoding and build flags.
No PGO/LTO/O2/scratch/watch-copy combination. This re-ranks GH20's unselected B,
with own inspected rationale and open/closed claim search; no novelty claim.

Hypothesis: treating the binary conflict's two variables symmetrically reduces
orientation bias and improves initial/alternating VSIDS search. Pinned baseline
normal analyze1683/1684 already bumps both variables; this does not establish a
bug in the lookahead path4077/4078. VSIDS initialization/phase switching6652–6701
is active. Actual event frequency/time share remains unknown. No predicted gain.
Expected cases: either mode where VSIDS lookahead binary conflicts occur;
LRB-only portions unaffected. Any search trajectory/counter change is expected
and must not be confused with scientific result equivalence.

Scope: one Solver.cc index token plus directly supporting validation and
MODIFICATIONS/NOTICE patch-set description, preserving original MIT headers.
Risks: family-dependent branching regressions, changed activity rescale timing,
rare/zero applicability, latent implementation defects exposed by search order.
Correctness assumptions and CSS/QECC distance, logical operators, Pauli weight,
ground truth, objective/timeout/bound semantics remain unchanged.

Before timing, build and Tier0 independently verify small exact MaxSAT residual
optima/partial bounds and CSS Pauli oracles, original CNF, smoke, valid UNKNOWN/
timeout output, and required hosted ordinary/cross-repo checks. Do not compare
heuristic search counters for equality. Any scientific mismatch/crash/wrong
distance/bound/output semantics immediately rejects and stops; escalate evidence.

Separate baseline-only diagnostic counts VSIDS CRef_Bin bump events and whether
variable indices differ, not time savings. Four fixed LP34/LP136 OFF/MTO solves
at120s parent/135s watchdog after host assignment; never compile diagnostic
instrumentation into timed production candidate. Zero opportunity can shelve
the mechanism; nonzero counts do not prove an allocation/cache/time bottleneck.

Tier1 fourBB90/GB144/BB108/LP238, modes separately,3baseline3candidate AB/BA/AB,
48serial solves180/195s, retain allscience/rawtimings/medians/ranges/identities.
Promote only reproducible positive direction without material regression.
Tier2LP34012solves600/615s only genuine gate or separately prerecorded explicit
user exploratory exception. No Tier3 from this initial plan. Shared CI timing
informational; resource/noise uncertainty stays INCONCLUSIVE with exactcommands.
Expected engineering hours/day; common watchdog budgets156minTier1/123minTier2,
not expected runtime or evidence. One coordinator-assigned runner perhost;
globalspare>50%, team use<=halfspare, serial sameCPU, complete owned cleanup.

Prior learning: E001/E002/E006 showed search can dominate encoding-size savings;
E003/GH17 did not establish allocator dominance (GH17 saved9/328 predicted
allocations/8byte peak, performanceINCONCLUSIVE/shelved). E004 LTO shelved;
E005 fixed SLS had no verified caps. GH16 PGO Tier1~2%positive but noise-inconclusive;
LP340 exploratory still running at prerecord, no invented final disposition.
This tests a distinct heuristic alone, not a combined or universal improvement.

State: PROPOSED/SELECTED, no candidate or correctness/performance evidence yet.
No host slot/build/test/timing while GH16 owns Windows. See [three methods](THREE_METHODS.md).
