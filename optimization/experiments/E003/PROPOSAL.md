# E003 / H-004: reuse the XOR gate clause buffer

Preregistered before implementation and timing, 2026-10-07. The user explicitly
requested another independent engineering loop and clarified that general
engineering techniques are eligible. This is a newly selected hypothesis, not
a claimed recovery of the original Brain wording. H-003 (verified initUB witness)
remains deferred: it changes search-bound initialization and needs a separate
witness/bounds review. Do not combine it here.

## Hypothesis and mechanism

Eliminate short-lived heap containers inside application xor2. Currently each
gate builds four std::vector clauses (each growing to three literals) and copies
each into a fresh solver vec. Replace these with one local solver vec whose
capacity is retained across the four addClause_ calls. Refill after each call
because addClause_ may sort/shrink its input. Keep identical signed literals,
clause order, weight, auxiliary IDs and error handling. No static/global buffer,
cross-gate sharing, encoding rewrite, cache or engine change.

Expected affected cases: parity-heavy matrices, including all Tier 1 cases;
the benefit is limited to construction and may be negligible next to search.
Risk: incorrect refill after solver mutation; test actual generated clauses and
byte-identical WCNF exports. No anticipated search change; this is a hypothesis,
not an established hot spot or performance claim.

## Evidence and relation to previous attempts

E001/E002 passed correctness but changed search structure and failed local
numeric filters. Start from original baseline
24572d6d09cce9a4a5faa58300a89e0feba9da6a, exclude both changes, retain their records.
Scope: src/core/distqldpc.cc xor2 only; validation/record/runner support. Embedded
MaxCDCL and downstream attribution unchanged; DistQLDPC is not upstream MaxCDCL.

Research reviewed: Schidler, IPEC 2025, PACE Solver Description (section 4)
https://doi.org/10.4230/LIPIcs.IPEC.2025.37 uses an initial feasible upper bound in
a different OLL/MIP architecture; Zhang et al., Integer Linear Programming
Preprocessing for Maximum Satisfiability (2025), https://arxiv.org/abs/2506.06216
studies ILP preprocessing. Neither establishes this allocation hypothesis or
performance on CSS distance. No algorithm/dependency from these papers imported.
This round instead follows direct inspection of the temporary clause containers.

## Gates, cost and decision rule

Tier 0: identical application compiler flags, unchanged verified engine objects;
production signed/repeated XOR truth-table projection; byte-identical WCNF on
six representative matrices; exhaustive small CSS distances in default/OFF/MTO;
smoke; pinned QDistSAT pilot OFF/MTO; six forced timeouts. Any semantic mismatch
rejects immediately; no timing. Hosted cross-repo PR check remains required
before merge; a local pilot does not replace it.

Tier 1 Windows diagnostics: four policy cases, OFF/MTO separately, 3/version,
AB/BA/AB serial, same inputs, verbose, 180s internal/195s watchdog, retain 48
raw outputs and all medians. Reuse the unchanged preregistered E001/E002 judge:
disjoint candidate-min > baseline-max rejects locally; numeric pass requires
all medians nonworse and mode-wise geometric mean(candidate max/baseline min)<1
in BOTH modes. Overlap/incomplete results inconclusive. No sample removal or
post-hoc threshold change. Expected minutes; worst Tier 1 budget 144 min.

Interactive unreserved Windows host cannot pass the original controlled-host
gate. Overall INCONCLUSIVE pending controlled measurement absent a correctness
failure; local rejection prevents promotion. No local Tier 2/3. Prepare exact
offline commands/package for exclusive Linux Tier 0/1 and conditional Tier 2
LP_340_56_8; no Tier 3 runner or merge. Scientific semantics unchanged.
