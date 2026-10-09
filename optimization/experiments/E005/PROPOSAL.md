# E005 / H-008: one bounded SLS warm start

Preregistered before implementation,2026-10-08. Existing Round2 revision #2,
selected by fresh [Round3](../../brain/2026-10-08-round3.md), user requests next
proposal after [shelving LTO](../E004/DISPOSITION-2026-10-08.md).

Hypothesis: one deterministic-budget stochastic local search on the original
hard/soft CNF can obtain a feasible objective cap, reducing loose exact-BnB
probes enough to offset capture/search/verification overhead. Baseline24572d6;
independent candidate worktree E005-SLS. Original-O3, no LTO or other source
optimization. One newly authored lightweight WalkSAT-style backend, seed1,
10000 flips, noise25%, one random initial assignment, no restarts/seed sweeps.
Hard clause score weight n+1; unit-soft weight1. Select an unsatisfied hard
clause preferentially, otherwise an unsatisfied soft; random flip25%, otherwise
greedy weighted score delta with deterministic RNG tie-breaking. Keep the best
hard-feasible assignment found during this single call. No external code import.

Capture original clauses during normal encoding, preserving the solver's exact
clauses/order. Independently verify every original hard clause, original soft
cost, decoded x/z commutation against Hx/Hz, nontrivial logical predicate against
Gx/Gz and union Pauli weight. Pass only a verified original cost to existing
initUB. Invalid/no witness follows original exact path; SLS never returns RESULT,
claims optimality or supplies a lower bound. initUB residual offsets/+1 and
inclusive feasibility checked. No model/phase transfer, original-row initializer,
core-guided rewriting, new bound strategy or engine changes. Original parent
wall timeout includes all warm-start work; no budget reset. Verbose diagnostics
identify flips/cap/witness/time; scientific output/parser unchanged.

Expected affected cases: original upper-bound acquisition may help BB108/LP340;
generic SLS may fail on dense parity CNF. No predicted speedup. Risks: infeasible
assignment, wrong cost/offset/strict bound, original/simplified mapping, seed
dependence and overhead. Exact CNF/timeout/output must remain unchanged.

Tier0: build, generic exhaustive small-formula/model checker tests, matrix witness
validation, tiny exhaustive CSS distance fixtures with feasible-cap endpoint,
ordinary smoke, unchanged QDistSAT LP136/BB108 both modes and one-second UNKNOWN/
sound-bound probes. Required hosted cross-repo PR check uses the actual candidate.
Mismatch immediately REJECTED, no performance. No upstream MaxCDCL patch change;
update MODIFICATIONS/NOTICE only if engine patch set actually changes.

Tier1 only after Tier0 PASS: BB90_8_10,GB144_12_8,BB108_8_10,LP238_44_6;
OFF/MTO,3 repeats/version/mode,48 serial solves, ABBAAB,180s internal/195s
watchdog. Same single-core job affinity/AboveNormal both versions, initial and
preflight pair>=95% idle, sibling>=95% active, global>50%, <=half spare,
30s preflight wait. Resource loss stops the round INCONCLUSIVE with all partial
evidence. No timing-based retries; no pooling with earlier experiments. Median/
range gate unchanged; report witness acquisition and overhead alongside total
whole-solve timing. Expected build/tests minutes plus ~5--10min Tier1;
maximum144 solver-min Tier1. If quiet resources unavailable, preserve exact
server commands and mark INCONCLUSIVE rather than invent a result. Tier2 LP340
only with justified positive Tier1 evidence; no automatic heavy Tier3.

Prior relations: E001 changed logical basis, E002 XOR sharing failed locally,
E003 buffer reuse unproven, E004 LTO shelved. H003 row-only cap never implemented;
do not bundle it. Formal acceptance requires correctness/reproducible gains/no
material regression. Partial warm-start failure is not scientific infeasibility.
# Literature provenance supplement (2026-10-08)

BibTeX key lubke2025sls in [references.bib](../../references.bib); CP2025
SLS-Enhanced Core-Boosted Linear Search for Anytime Maximum Satisfiability.
[Source/adaptation mapping](../../REFERENCES.md) records the initial verified-cap
idea versus our single bounded original-CNF call, not a reproduction of the
full paper. This supplement leaves the original preregistration/results unchanged.
