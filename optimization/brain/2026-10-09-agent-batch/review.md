# Independent review-agent Brain after GH83: exactly three proposals

Owner: review_agent_workflow. Source/private prerecord only, 2026-10-09.
Immutable source baseline: corrected `72d1fe18ccd91d061d0c6f1d9816d1c96ed685c7` (B002, issue62).
No production edits, new worktree, compilation, solver, SSH, or host assignment in this round.
The human subsequently requested pausing after this proposal batch; finish this receipt, then pause.

DistQLDPC has its own instrumented and optimized MaxCDCL-derived engine; it is not identical to upstream MaxCDCL. QDistSAT remains the separate benchmark platform. Scientific distance, CSS/QECC, logical predicates, Pauli OR weight, weighted objective, ground truth, model interpretation, sound bounds, timeout/result/output semantics and attribution stay fixed. Exactly ONE future conceptual change is selected; no earlier candidate is stacked.

## Evidence and duplicate search

Read corrected-source AGENTS and optimization-loop policy, legacy STATE/HYPOTHESES, earlier proposal records, actual corrected core/solver sources, GitHub all-state issue inventory through87, and latest hub comments through GH89's registration. Active claims include split/incremental/symmetry/dual skipping, engine LBD specialization, and prefetch. These are not this proposal.

Root's independently audited GH83 fixed native Tier1 has48 scientific solves/192 fields correct but original numeric REJECT: OFF median GM +8.665%, MTO -14.797%, approximately20% OFF regressions for GB144/BB108. That rejects the generic balanced-stabilizer association candidate, not all XOR encoding optimizations. Its four MTO signals do not certify another mechanism.

Peers disclosed their new selected concepts before this choice: academic MTO-only balanced original stabilizer association, and independent agent removal of the implied physical nonzero OR clause. Our selected final-gate fusion differs from both. GH83 preserves m-1 XOR gates/auxiliaries; our proposal preserves the original left-fold association but omits its final parity auxiliary. No selected exact fusion duplicate was identified. Alternatives below disclose earlier unselected ideas rather than claiming novelty.

## A — SELECTED, rank1: fuse final stabilizer XOR with its fixed equality

**Hypothesis.** In the live MaxCDCL application path only, original Hx/Hz rows of support m>=2 can use their final parity=0 condition directly, avoiding an auxiliary and temporary clauses; lower construction/preprocessing/memory cost may improve end-to-end solving without changing the projected problem.

**Mechanism.** Original `add_xor_equals` makes m-1 four-clause `xor2` gates and fixes the last output with one negative unit. Keep the original ascending row leaves and first m-2 gates. If `a` is the unchanged prefix parity and `b` the last signed literal, add only `(~a OR b)` and `(a OR ~b)`, enforcing a=b. For m=2 the prefix is the first leaf. For m=0/1 preserve the original no-op/unit behavior exactly. This saves one auxiliary and three submitted clauses per eligible row: original4(m-1)+1 versus4(m-2)+2. No balanced association, redundant-row addition, preprocessing option, engine change, compiler change or mode gate.

**Implementation scope.** A separate application helper for original Hx/Hz parity0 rows and a default-false builder opt-in enabled only by the existing live solver caller. Keep shared dump-only/WCNF/OPB/RoundingSat callers on original encoding. Do not alter `add_xor_equals` used by logical Gx/Gz rows, nontriviality clauses, weight variables, objective/cardinality, bounds or reporting. Original base-variable offsets remain fixed; later auxiliary IDs necessarily shift and must be validated by role, not mistaken for original variable identities. Embedded engine is byte unchanged; attribution retained. Document application encoding change and projected equivalence.

**Affected cases / source opportunity.** Bounded local CPU0 metadata counting of the immutable-checkout matrix Hx/Hz text found every original stabilizer row eligible:

| Case | Hx+Hz rows / eligible | Auxiliaries avoided | Submitted clauses avoided |
|---|---:|---:|---:|
| BB_90_8_10 |90/90|90|270|
| GB_144_12_8 |132/132|132|396|
| BB_108_8_10 |108/108|108|324|
| LP_238_44_6 |210/210|210|630|
| LP_340_56_8 |300/300|300|900|

These are source structure counts, not retained solver-clause counts, time shares or performance evidence. Original root propagation and simplification may already eliminate much of this redundancy, leaving negligible benefit. Fresh canonical Git exports must authenticate the counts again before a future experiment.

**Correctness proof and required gates.** Original XOR gate plus fixed output projects exactly to a=b. Prefix gates have a unique auxiliary extension for each satisfying signed leaf assignment. Candidate preserves that uniqueness but has one fewer output auxiliary. Independently enumerate length0..8/signed/repeated leaves, both baseline and candidate captured CNFs, empty/one/two cases, multirow ranges and later logical suffix variable mapping. The focused mock proves only CNF projection/structure; it must not substitute for actual SimpSolver and full application correctness. Then original300B optimum5 regression, 80+1 partition tests and existing directed engine evidence/reuse roles, tiny CSS Pauli OR exhaustive ground truth, actual dumped-WCNF/live-Main crosschecks, all card modes, all emitted/interim bounds, pre/post-incumbent genuine timeouts and ordinary/cross-repo CI. Original dump path should remain unchanged; it is not a candidate-encoding certificate by itself.

**Risks.** Clause allocation/order and auxiliary numbering change solver branching, elimination, reasons and learnt paths despite exact projection. GH83 already shows mode-sensitive association effects; fewer clauses cannot be presumed faster. Already-forced final auxiliaries may carry useful preprocessing relationships. Signed/repeated literals, m=0, UNSAT during construction and logical suffix offsets need explicit tests. No paper supplies an engine correctness assumption here; this is ordinary Boolean constraint simplification.

**Expected cost.** Future one bounded focused build/check, nominal <=240s compilation aggregate and <=120s focused execution aggregate, plus one finite actual application Tier0 worker<=3600s/outer<=3660s+10s cleanup with remaining-time caps. Those are budgets, not completion guarantees. Only after actual audited correctness: fixed48 Tier1 (four mandated cases, OFF/MTO, three baseline/three candidate, AB/BA/AB, original180s/195s per solve), one controlled named resource lease, worker<=6600s/outer<=6660s+8s cleanup. Aggregate budget expiration preserves INCONCLUSIVE, not a smaller-corpus PASS. No Tier2/3 unless the existing decision/explicit one-tier exception is separately preregistered. No timing or count sweep now.

**Prior relation / choice rationale.** New distinct terminal-gate simplification, not a resurrection of balanced GH83 or a combination with peers. Rank1 because source shows a finite, nonzero construction/allocation reduction in every mandated case and it has a small independent projected-truth proof. It may still fail performance; preserving association avoids repeating GH83's exact tree change but does not promise unchanged search. This is preferable to selecting another unsupported single-instruction hotpath guess.

## B — rank2, UNSELECTED: cover the second half in existing binary-resolution minimization

**Mechanism and scope.** Fresh72 only: change existing `binResMinimize` interior scan limit from `out_learnt.size()/2` to the full existing learnt size, retaining the same original binary-resolution predicate, first-literal pass, seen2/counter, shrink/reorder and learnt accounting. No extra resolution algorithm or other defaults.

**Affected cases.** Conflict-heavy long learnt clauses with removable literals currently outside the scanned first half; not predicted by code family alone.

**Risks.** Extra adjacency scanning can exceed shorter-clause benefit; shared seen2/counter, stale binary watches and membership mutation require direct state/equivalence proof. Clause shape/LBD/backjump and search change, though sound resolution should preserve formula semantics. No result/bound correctness shortcut is allowed.

**Cost.** Future focused resolution oracle/lifetime tests and full finite Tier0 before the same fixed48 Tier1; bounded3600/6600 worker budgets, no broad parameter sweep. Need baseline-only second-half opportunity counts if later selected, without presenting counts as speed evidence.

**Prior relation.** Explicit rerank of unselected GH63-B. Not selected now because there is no current retained evidence of substantial second-half opportunities, and extra hot-path work could dominate.

## C — rank3, UNSELECTED: demand-clean lookahead watch lists

**Mechanism and scope.** Fresh72 only: replace `propagateForLK`'s eager `watches.cleanAll()/watches_bin.cleanAll()` with dirty-aware `lookup(p)` for the lists actually consumed. Keep clause order and all propagation/conflict/enqueue/cursor logic. No change to simple/ordinary propagation, other cleanup or allocator collection boundaries.

**Affected cases.** Many dirty lists but a short lookahead touched-literal set, especially calls ending early on soft conflict. Dirty-free calls offer little opportunity and gain an extra lookup branch.

**Risks.** Baseline `operator[]` is raw, not lazy-cleaning. All later raw consumers, destination watch insertion, binResMinimize, removal, garbage collection and detach paths must tolerate delayed cleanup; otherwise decline rather than delete eager cleanup blindly. Deferred dirties can accumulate duplicate indices. This is currently a proof-gated possibility, not a correctness claim.

**Cost.** Source/lifetime proof first; bounded baseline-only dirty/touched/cleaned census if later selected, then focused watched/GC tests and full Tier0/fixed48 Tier1 under existing finite budgets. No profiler or broad workload now.

**Prior relation.** Reranks repeated unselected demand-watch-cleaning ideas in older proposals including GH83-C and the independent agent's current alternative. No active selected ownership identified, but no novelty claim. Rank3 due to larger lifetime proof burden and no authenticated cleaning-time share.

## Disposition and provenance

Proposal A selected; B/C are not authorized implementations. All are ordinary program/Boolean optimization proposals derived from this repository's source inspection; no paper-derived method is claimed, hence no invented citation or BibTeX entry. Prior experimental statements above are specific retained/root-reported evidence and do not transfer a performance effect to A/B/C.

Current disposition: PROPOSED / NOT_IMPLEMENTED / NOT_RUN / PAUSED_AFTER_PROPOSAL_BATCH. Root may publish this owner-selected receipt on GitHub. Independent author/reviewer separation, frozen corrected baseline, exact source/binary/input identities and named per-host resource ownership are required before future work. No speed conclusion, adoption or research claim has been made.
