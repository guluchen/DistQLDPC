# H003 scope and source obligations

Baseline24572d6; prerecord12e2343 before implementation. Existing code references
below are source analysis, not a Tier0 PASS. Independent review and actual tests
remain required before performance runs.

For a Gz row r as x=r,z=0, all Hx.z parity checks are automatically zero. Check
every original Hz.r parity is zero, r is nonzero, and at least one original
Gx.r parity is one. Then choose w=x OR z and set each logical a to its encoded
parity: every original hard constraint is satisfied. The pure-Z case reverses
Hx/Hz and Gx/Gz. Its objective is exactly popcount(r), not separate-component
weight. Invalid/non-logical/zero rows are skipped. No valid row leaves the
original INT32_MAX sentinel. Original rows/order are preserved, X then Z,
strict minimum gives deterministic ties. No filename ground truth is consulted.

Only S.initUB changes. The original CNF, soft literals/weights and original
SimpSolver simplification are unchanged. Soft variables are frozen by existing
setFrozenVars; elimination of hard-only variables preserves existential hard
satisfiability. Monotone assignments may satisfy additional soft clauses,
which cannot invalidate a feasible inclusive upper bound. Existing presearch
normalization represents total cost as solutionCost+fixedCostBySearch+
derivedCost+relaxedCost+residual false literals. This objective-preservation
assumption already underlies the original solver, and must be independently
exercised with nonzero-offset tiny PMS fixtures.

Solver.cc6625 computes providedUB=w-offset+1 only when w>=offset; otherwise it
falls back to the original sentinel. Initial search still uses UB=1. A failed
pre-feasible bound cancels to beginning and removes bound-dependent learned,
hardened/cardinality/iset clauses before raising UB, capped by providedUB.
FixedCostBySearch increments only after a feasible model in this loop; the
pre-feasible cap must not be re-used with a changed offset. After feasibility,
a failed bound breaks before that cap branch. First successful search calls
noteBestSolution, then transfers root false literals and tightens the original
search interval. A valid witness guarantees some model has residual cost less
than the strict providedUB; it does not supply a model or optimality proof.

Solver emitBoundsUpdate emits UB only if bestSolutionFound; hasCostUB uses the
same flag. The input cap must never alter these flags or call noteBestSolution.
Parent timeout remains TIMEOUT/c d UNKNOWN/s UNKNOWN with exit1; no o line on
this baseline timeout path. Preserve actual current source behavior despite
older README wording. Test cap-only/no-found-model and actual-found-model
timeout cases explicitly, using a test-only deterministic interruption hook
if necessary, never adding a delay/hook to the timed production executable.

Independent reviewer confirms offset writes/calls: solutionCost addClause_1364
and addHardClausesForSoftClauses5076 occur before cap; derivedCost partition5461
has sole call5594 in findConflictSoftLits before cap; relaxedCost initialized6598;
fixedCostBySearch transfer6786 occurs after feasible. Invalid too-low caps can
terminate without a feasible model; witness validity is therefore essential,
not an optional heuristic assumption. No new engine fix is included.

Scope narrowed following review: shared builder retains INT32_MAX. Only actual
maxsat search caller sets the verified cap immediately before solveLimited;
dump-only and RoundingSat paths do not acquire unnecessary witness scans.
Application helper semantics/selected conceptual mechanism unchanged. The
first hosted7566ffb check preceded this scope correction; its source is preserved,
but latest candidate needs its own hosted checks and artifacts.

Review remaining before performance: independently confirm no
offset changes during pre-feasible retries; test exact strict-bound inclusivity,
nonzero offsets, simplification, invalid fallback and model-dependent output.
Any ambiguous scientific assumption stops for clarification rather than
changing the engine to accommodate this hypothesis.
