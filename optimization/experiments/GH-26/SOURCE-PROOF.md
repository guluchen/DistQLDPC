# GH26 source proof and preregistered refinement

Recorded before implementation; original proposal bf5cfa1 remains intact.

## Selected scope refinement
Use one-step, gap-one fixed-cap2 FLA: invoke ONLY after ordinary lookahead actually exhausts pickAuxiVar with nbConfl == (UB - falseLits.size()) - 1. Select original weight-one cores with at most two distinct active soft literals, deterministic original core/literal order. Independently falsify every member on a PURE snapshot. Probe positive currently available soft literals in variable-index order; passive unlocking uses full old-core weights. Stop each branch on hard contradiction or a newly falsified available soft literal. Every member must be covered. No RL, alternative threshold, sweep, encoding/compiler bundle.

For the first covered core only, conservatively merge ALL old disjoint cores and ALL active residual soft literals into a single certificate of weight nbConfl+1. This is a weakening of paper Algorithm1's minimal intersecting-core union. It may make reasons longer and cannot add more than one bound unit. No production K mutation, persistent FLA cores or quasi-hardening from FLA certificates. Success directly prunes under current UB. Failure retains ordinary exact behavior.

This restriction is selected before measurements to reduce the downstream core/reason/lifetime surface; it is not a new optimization bundled with A. It may sacrifice benefits of repeated/minimal FLA merging. No claim of faithful full-paper replication.

## Source audit at immutable24572d6
- lookahead4802–5053 performs positive soft assumptions, passive unlocking, backtrace/merge and quasi-hardening. It has no independent false-member branch coverage.
- lookaheadForRestart3332–3483 also assumes positive soft literals, extracts hard disjunctions and retains root cores; no FLA false-member coverage. Remains unchanged.
- simple helpers5598–5860 probe positive literals; initial simplelookahead call6571 is commented; no equivalent active FLA found in these paths.
- uncheckedEnqueueForLK3898–3934 handles false locked members by decreasing isetLock and reinserting unlocked members.
- seeUnlockLits4050 and lookbackResetTrail4067 follow falsification reasons. A reasonless assumption p is inserted into isetsLits as p; directly passing a negative FLA decision to this routine is UNSAFE without adaptation.
- setConflict4250 merges disjoint components. A final root's constituent component count is its guaranteed falsification weight before speculative assignments; isetLock at exhaustion is remaining lock, NOT original weight. Snapshot reconstructs all constituent members and original component count.
- analyzeSoftConflict2190 reads false base literals plus involvedLits when UBconflictFlag. A complete negated nonroot base assignment is a conservative valid conditional conflict seed if the base has no feasible extension with residual cost<UB. Existing analyzer/learned-clause lifetime still needs actual tests.
- hardenFromQuasiSoftConflict4691 rolls temporary assignments back, resets K and makes bound-dependent implications. FLA does NOT reuse this to harden from merged certificate.
- auxiVar is exactly softLits[v]!=lit_Undef (Solver.h729). This alone is NOT sufficient residual-cost bookkeeping; see the later offset audit below. Snapshot skips selected K with base-assigned members, duplicate membership or incompatible literals.
- active hard constraints are recovered from attached watcher CRefs (long/binary), deduplicated and excluding mark1. Root-unit constraints are represented by base trail. This includes temporary cardinality/hardening constraints and valid learned clauses under CURRENT bound. Their existing lifecycle must be exercised when UB changes.
- Pure snapshot assignments/counters/occurrences do not modify solver assignment, reason, trail, qhead, watches/clauses, activity, K or queues. Production watcher movement from ordinary lookahead already occurred; snapshot retains it unchanged.
- On certified prune, rollback original speculative suffix using original quasi-conflict restoration, resetConflicts/bumpConflVars as normal successful LA, set existing soft/UB flags and record all negated nonroot base trail literals in involvedLits. No changes to solution offsets, UB update, timeout/result output or parent pipe.

## Reasoning, not executed correctness evidence
Let alpha be the base trail, K disjoint certified cores, w_i their weights, F its already falsified active soft literals. Eligible kappa has weight1. Every alpha extension falsifies a member l of kappa. In each l=false probe, order positive assumptions A1,...,At, chosen only outside locked cores.

For a feasible extension beta of alpha with l=false, inspect its first falsified positive assumption A_j. All earlier positive assumptions and their UP consequences hold in beta. If A_j is outside K, it contributes one beyond all K obligations. If A_j lies in an unlocked K_i, earlier consequences already falsify w_i DIFFERENT members of K_i; A_j contributes one more. The selected branch l is not a positive assumption. If beta satisfies all positive assumptions, a newly falsified available soft literal is the additional distinct falsification; a hard contradiction rules this beta out. Thus every covered branch requires |F|+sum w_i+1 active falsifications or is hard-infeasible. Covering EVERY member of kappa proves that lower bound for all extensions of alpha. Taking all active residual literals and all K is conservative; no overlapping weights are separately added.

Safety preconditions: K disjoint, members active/distinct/base-unassigned, positive weights agree with constituent components; base facts already counted separately; newly falsified available soft literal checked BEFORE incrementing its core's falsification count; no recount of the member that merely reaches an old weight. One uncovered branch makes FLA fail. No empty-core-as-failure confusion for hard-infeasible branch.

Conditional nogood: the disjunction of negations of all alpha nonroot assignments is valid in the search subproblem with cost<UB if the lower bound reaches UB. Root facts persist within that subproblem. Existing conflict analysis can resolve that valid conditional clause with existing valid reason clauses; this still demands instrumented learned-clause validation and bound-lifetime tests. It is not an unconditional hard clause across relaxed UB.

## Execution gates
No source proof is labeled Tier0PASS. No host slot/build/solver/diagnostic/timing assigned.
Before any comparative performance: independent residual brute-force oracle checks every kernel true result against all feasible completions; full-condition learned clauses checked under current bound and lifecycle; positive/negative signs, hard infeasibility, overlap rejection, weight>1 passive unlocking, missing coverage, no-extra repeated falsification, base facts; CSS bounds/timeout/results and required hosted correctness.
Opportunity diagnostic after assignment: original eligible-core frequency, attempted/covered probes, extraUP and exact valid pruning. No frequency/time share inferred from oldset diagnostics.

## Later source-only offset and bound-lifetime audit (before any engine hook)

solve_6574–6600 filters root-assigned objectives and stores their falsified cost
in fixedCostBySearch. softLits can still identify these as auxiliary variables.
After a successful bound, solve_6760–6790 cancels to root, transfers root falseLits
into fixedCostBySearch and clears falseLits, while the objective-literal arrays
can retain those assigned literals. Therefore using ALL auxiVar base falsities
as residual F would DOUBLE COUNT offsets. No production adapter is written.

Required adapter rule: start from current normalized allSoftLits, validate every
literal against softLits[var], and EXCLUDE a currently base-false soft literal
unless it appears in the exact current falseLits. Preserve base assignment as a
hard fact even when its objective cost is excluded. Validate one-to-one
membership and equality between mapped objective base-false count and
falseLits.size(); any uncertainty declines FLA without changing solver state.
Include currently undefined and true active literals normally. K members must
belong to that residual objective and be base-undefined. This makes the snapshot
generic cost match the current residual cost, while solutionCost,
fixedCostBySearch, derivedCost and relaxedCost remain the original offsets.

The kernel itself has no DistQLDPC offsets and its oracle uses exactly its
declared objective; a model PASS would not prove the future adapter invariant.
Independent future adapter tests must manufacture nonzero initial fixed cost,
derived cost and later root-cost transfer, verifying residual UB and full
reported bounds/optimum against original objectives.

UB is NOT globally monotone. Failed-bound updates relax residual UB after
cancelUntilBeginning(beginning), then removeLearntClauses6720–6750 deletes all
three learned lists and hardening/cardinality/iset constraints. The snapshot
certificate and nogood are valid only for the CURRENT strict residual bound.
After a feasible solution, the next search tightens the TOTAL objective bound;
the fixed-root transfer shifts the residual coordinate, and CORE clauses may
survive while local/tier2 are deleted. Proof obligation: old conditional
nogood remains valid for the smaller total-bound feasible set under retained
root facts. Source indicates the intended lifecycle, but direct tests of
learning, root transfer, tightening and relaxation remain mandatory. Do not
claim monotone residual UB or persist a certificate through bound relaxation.
