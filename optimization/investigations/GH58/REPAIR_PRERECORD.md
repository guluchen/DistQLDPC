# One minimal correctness repair: retire both soft-literal lists after partition

Before implementation, originalnative states prove trail literal-2/lit_Undef
is indexed into watches_bin, SIGSEGV at wbin[k].blocker. Original process
VmPeak13988kB/VmHWM4884kB, not massiveallocation. Supported source mechanism:
partition creates representative pp for a pairwise conflicting soft set, clears
OLD member mappings, and compacts ONLYunitSoftLits. detectInitConflicts can
enqueue lit_Undef from a stale nonUnitSoftLits mapping. Exact old nonUnit map
values were not printed; causal dataflow plus capturedinvalidtrail supports this
target. Do not invent those missing dynamic fields or universal OOMexclusion.

Selected correctness change ONLY: after existing unit compaction, compact
nonUnitSoftLits with the SAME active-map predicate, preserve surviving order,
including newly appended aggregate representatives. Rebuild heaps iff either
list lost entries, preserving the existing unit condition. No arbitrary enqueue
guard, reinterpretation of missing literals, decision initialization cleanup,
search heuristic, compiler flag, encoding, timeout/result/model/groundtruth change.
Preserve MaxCDCL attribution; update MODIFICATIONS/NOTICE for this downstream fix.

Independent source review proves existing transformation's cost identity for
a hard-feasible pairwise conflicting set of m members: at most one is true,
originalcost m-s = (m-1)+(1-OR). Existing derivedCost+=m-1 and newpp<->OR
are unchanged; old mappings already invalidated, newpp remains active. Retiring
those old list entries is bookkeeping, not dropping original objective costs.
No changes to conflictLits/core assumptions or scientific assumptions.

Validation before newbaseline proposal or performance: cleanoriginalO3 candidate
builds; exact mandatory original crash fixture must now complete with cost5 and
valid originalstatus, independentlyenumerated1024truth/witness472. Adjacent
opposite/duplicate unit-soft cases, polarity/clause-order variants with exact
brute-force oracle; direct partition-list invariants retain new representatives,
remove allinactive members and preserve oldunitheapcondition. Run original
build/smokes, tinyCSS/PMS oracles and every5cardinality mode, unchangedWCNF,
real no-model/post-model timeout outputsemantics, required hosted cross-repo.
Original knownfailure remains retained; it is expected failing regression for a
correctness repair, never a waived passing baseline result. Actual candidate
wrongdistance/cost/bound/status/crash STOP; retain failure and investigate.

One named runner/host, originalpins/globalspare>50%/<=halfspare/fixedlease, serial
build -j1; metadataCPU0. No performance/Tier1/2/3 or acceptance claim, no new
baseline designation until verifiedreviewable correctness evidence. Expected
targetedbuild/regression minutes, fullcorrectness tens ofminutes; no broad sweeps.
